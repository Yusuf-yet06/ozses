import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_io/io.dart';

import '../firebase_options.dart';
import 'offline_cache_service.dart';
import 'radar_filter.dart';

/// FCM arka plan işleyicisi (top-level olmak ZORUNDA).
/// Sistem, "notification" alanlı mesajları arka planda kendisi gösterir;
/// kullanıcı duyuru kanalını kapattıysa zaten topic aboneliği iptal edilmiştir.
@pragma('vm:entry-point')
Future<void> ozsesFirebaseBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
}

/// 🔔 ÖZSES merkez bildirim servisi
///  1) Favori sanatçı yeni şarkı (Shorts filtreli & Sıfır Arka Plan Uyanıklığı: YT/Spotify isteklerine entegre)
///  2) Admin / genel duyurular (FCM topic)
///  3) İndirme bildirimi + canlı yüzde çubuğu
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  // ── Tercih anahtarları (profildeki çekmece bunları okur/yazar) ──
  static const String prefFavArtists = 'notif_fav_artists';
  static const String prefAnnouncements = 'notif_announcements';
  static const String prefDownloads = 'notif_downloads';

  static const String _prefSeenPrefix = 'notif_seen_ids_';

  // ── Kanal kimlikleri ──
  static const String chDownloads = 'ozses_downloads';
  static const String chArtists = 'ozses_artists';
  static const String chAnnouncements = 'ozses_announcements';

  /// FCM'de admin duyurularının gönderileceği topic adı.
  static const String announcementsTopic = 'ozses_announcements';

  /// Bu süreden kısa içerikler (Shorts / teaser / kesit) bildirime ALINMAZ.
  static const int minFullSongSeconds = 75;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // İndirme takibi
  final Map<String, String> _titleCache = {};
  final Map<String, int> _lastPercent = {};
  Set<String> _activeIds = {};

  // ───────────────────────── BAŞLATMA ─────────────────────────
  Future<void> init() async {
    if (_initialized || !_supported) return;
    _initialized = true;

    try {
      await _plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ));

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        chDownloads, 'İndirmeler',
        description: 'Şarkı indirme durumu ve yüzdesi',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ));
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        chArtists, 'Favori Sanatçılar',
        description: 'Favori sanatçılarından yeni çıkan şarkılar',
        importance: Importance.defaultImportance,
      ));
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        chAnnouncements, 'Duyurular',
        description: 'ÖZSES yönetici ve genel duyuruları',
        importance: Importance.high,
      ));
    } catch (e) {
      debugPrint('❌ Bildirim init hatası: $e');
    }

    await _initFcm();
    _hookDownloads();
    // Not: Ekstra arka plan zamanlayıcısı (wake-lock) KULLANILMAZ.
    // Favori sanatçı kontrolü, Keşfet'teki mevcut YT ve Spotify isteklerinin
    // arasına entegre filtreleme (piggyback) ile sıfır ek yükle çalışır.
  }

  Future<bool> requestPermission() async {
    if (!_supported) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final ok = await android?.requestNotificationsPermission();
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final iosOk =
          await ios?.requestPermissions(alert: true, badge: true, sound: true);
      return (ok ?? iosOk ?? true);
    } catch (_) {
      return false;
    }
  }

  // ───────────────────────── TERCİHLER ─────────────────────────
  Future<bool> isEnabled(String key) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(key) ?? true; // varsayılan: açık
  }

  Future<void> setEnabled(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
    if (value) await requestPermission();
    if (key == prefAnnouncements) await _syncAnnouncementsTopic(value);
  }

  // ───────────────────────── 2) DUYURULAR (FCM) ─────────────────────────
  Future<void> _initFcm() async {
    try {
      FirebaseMessaging.onBackgroundMessage(ozsesFirebaseBackgroundHandler);
      final fcm = FirebaseMessaging.instance;
      await _syncAnnouncementsTopic(await isEnabled(prefAnnouncements));

      // Uygulama açıkken gelen duyuruyu kendimiz gösteririz
      FirebaseMessaging.onMessage.listen((RemoteMessage m) async {
        if (!await isEnabled(prefAnnouncements)) return;
        final n = m.notification;
        final title = n?.title ?? m.data['title'] ?? 'ÖZSES';
        final body = n?.body ?? m.data['body'] ?? '';
        await _show(
          id: m.hashCode & 0x7fffffff,
          title: title,
          body: body,
          channel: chAnnouncements,
          channelName: 'Duyurular',
          importance: Importance.high,
        );
      });
      debugPrint('🔔 FCM hazır, token: ${await fcm.getToken()}');
    } catch (e) {
      debugPrint('❌ FCM init hatası: $e');
    }
  }

  Future<void> _syncAnnouncementsTopic(bool on) async {
    if (!_supported) return;
    try {
      final fcm = FirebaseMessaging.instance;
      if (on) {
        await fcm.subscribeToTopic(announcementsTopic);
      } else {
        await fcm.unsubscribeFromTopic(announcementsTopic);
      }
    } catch (e) {
      debugPrint('❌ Topic senkron hatası: $e');
    }
  }

  // ───────────────────────── 3) İNDİRME + YÜZDE ─────────────────────────
  void _hookDownloads() {
    final cache = OfflineCacheService();

    cache.downloadTitles.addListener(() {
      _titleCache.addAll(cache.downloadTitles.value);
    });

    cache.downloadProgress.addListener(() async {
      final progress = cache.downloadProgress.value;
      final current = progress.keys.toSet();

      // Listeden düşenler: iptal/bitiş → ilerleme bildirimini kaldır
      for (final gone in _activeIds.difference(current)) {
        _lastPercent.remove(gone);
        try { await _plugin.cancel(_idFor(gone)); } catch (_) {}
      }
      _activeIds = current;

      if (!await isEnabled(prefDownloads)) return;

      progress.forEach((videoId, value) {
        final pct = (value * 100).clamp(0, 100).round();
        if (_lastPercent[videoId] == pct) return; // gereksiz güncelleme yok
        _lastPercent[videoId] = pct;
        final title = _titleCache[videoId] ?? cache.downloadTitles.value[videoId] ?? 'Şarkı';
        _showDownloadProgress(videoId, title, pct);
      });
    });

    cache.onDownloadCompleted.listen((videoId) async {
      if (!await isEnabled(prefDownloads)) return;
      final title = _titleCache[videoId] ?? 'Şarkı';
      await _show(
        id: _idFor(videoId),
        title: 'İndirme tamamlandı',
        body: '$title artık internetsiz dinlenebilir',
        channel: chDownloads,
        channelName: 'İndirmeler',
        importance: Importance.low,
      );
    });
  }

  int _idFor(String videoId) => videoId.hashCode & 0x7fffffff;

  Future<void> _showDownloadProgress(String videoId, String title, int pct) async {
    try {
      await _plugin.show(
        _idFor(videoId),
        title,
        'İndiriliyor… %$pct',
        NotificationDetails(
          android: AndroidNotificationDetails(
            chDownloads, 'İndirmeler',
            channelDescription: 'Şarkı indirme durumu ve yüzdesi',
            importance: Importance.low,
            priority: Priority.low,
            showProgress: true,
            maxProgress: 100,
            progress: pct,
            ongoing: true,
            onlyAlertOnce: true,
            autoCancel: false,
            playSound: false,
            enableVibration: false,
            icon: '@mipmap/launcher_icon',
          ),
          iOS: const DarwinNotificationDetails(presentSound: false),
        ),
      );
    } catch (_) {}
  }

  // ───────── 1) FAVORİ SANATÇI + SHORTS FİLTRESİ (SIFIR WAKE-LOCK, PIGGYBACK) ─────────

  /// Shorts / teaser / kesit mi? (true ise bildirim gönderilmez)
  static bool isShortOrTeaser({Duration? duration, String title = ''}) {
    if (duration != null && duration.inSeconds < minFullSongSeconds) return true;
    return SiberStreamFilterEngine.isShortOrTeaserTrack({
      'title': title,
      'duration': duration?.inSeconds ?? 180,
    });
  }

  /// Keşfet'in halihazırda çektiği YT/Spotify sanatçı verilerini süzgeçten geçirir.
  /// Ekstra uyanık tutma (wake-lock) olmadan, yeni tam şarkı yakalarsa bildirim atar.
  Future<void> inspectPiggybackArtistTracks(
    String artist,
    List<dynamic> fetchedTracks,
  ) async {
    if (!_supported || fetchedTracks.isEmpty) return;
    if (!await isEnabled(prefFavArtists)) return;

    final cleanArtist = artist.trim();
    if (cleanArtist.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefSeenPrefix${SiberStreamFilterEngine.normalizeTr(cleanArtist)}';
    final seenList = prefs.getStringList(key);
    final seen = (seenList ?? <String>[]).toSet();
    final firstRun = seenList == null;

    bool notified = false;
    for (final item in fetchedTracks) {
      if (item is! Map) continue;
      if (SiberStreamFilterEngine.isShortOrTeaserTrack(item)) continue;

      final id = (item['videoId'] ?? item['id'] ?? item['video_id'])?.toString() ?? '';
      final title = (item['title'] ?? item['baslik'] ?? '').toString().trim();
      if (id.isEmpty || title.isEmpty) continue;

      if (seen.contains(id)) continue;
      seen.add(id);

      // İlk kez taranıyorsa mevcut şarkıları sessizce kaydet (bildirim yağmuru olmasın)
      if (firstRun || notified) continue;

      await _show(
        id: _idFor('artist_$id'),
        title: '🎵 $cleanArtist yeni şarkı radarına takıldı!',
        body: title,
        channel: chArtists,
        channelName: 'Favori Sanatçılar',
        importance: Importance.defaultImportance,
      );
      notified = true;
    }

    await prefs.setStringList(key, seen.take(80).toList());
  }

  /// Genel trend / yeni çıkanlar listesi çekildiğinde kullanıcının favori sanatçısı
  /// varsa sıfır ek ağ isteğiyle kontrol eder.
  Future<void> inspectPiggybackFeedForFavorites(List<dynamic> feedTracks) async {
    if (!_supported || feedTracks.isEmpty) return;
    if (!await isEnabled(prefFavArtists)) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('siber_personal_artists') ?? '';
    final favArtists = raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (favArtists.isEmpty) return;

    for (final artist in favArtists) {
      final normArtist = SiberStreamFilterEngine.normalizeTr(artist);
      final matches = feedTracks.where((t) {
        if (t is! Map) return false;
        final nTitle = SiberStreamFilterEngine.normalizeTr((t['title'] ?? '').toString());
        final nChan = SiberStreamFilterEngine.normalizeTr((t['channel'] ?? '').toString());
        return nTitle.contains(normArtist) || nChan.contains(normArtist);
      }).toList();

      if (matches.isNotEmpty) {
        await inspectPiggybackArtistTracks(artist, matches);
      }
    }
  }

  // ───────────────────────── ORTAK GÖSTERİM ─────────────────────────
  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String channel,
    required String channelName,
    required Importance importance,
  }) async {
    try {
      await _plugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel, channelName,
            importance: importance,
            priority: importance == Importance.high ? Priority.high : Priority.defaultPriority,
            icon: '@mipmap/launcher_icon',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('❌ Bildirim gösterilemedi: $e');
    }
  }
}
