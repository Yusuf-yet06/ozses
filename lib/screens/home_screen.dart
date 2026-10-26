// ignore_for_file: unused_local_variable

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // 🎯 Hızlı favori okuması için
import 'package:http/http.dart'
    as http; // 🎯 SİBER HAMLE: Keşfetten gelenlerin plak kapağı için
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../main.dart';
import '../models/song_model.dart';
import '../services/vibe_engine.dart';
import '../services/playlist_controller.dart';
import '../services/playlist_service.dart';
import '../services/ai_commander.dart';
import '../services/audio_handler.dart';
import '../services/services.dart';
import '../services/offline_cache_service.dart';
import '../services/weather_service.dart';
import '../widgets/weather_mix_sheet.dart';
import '../services/siber_theme_service.dart';
import '../widgets/siber_theme_sheet.dart';
 // 🎯 SİBER KÖPRÜ (OzsesBridge İçin)
import '../services/storage_service.dart';
import '../widgets/auto_playlist_sheet.dart';
import '../widgets/sonic_aura_sheet.dart';
import '../services/siber_ip_service.dart'; // 🎯 SİBER HAMLE: Otonom IP yönetimi
import '../services/audio_analysis_service.dart'; // 🎯 SİBER HAMLE: Gerçek Zamanlı Analiz
import '../services/file_picker_service.dart'; // 🎯 SİBER HAMLE: Dışarı çıkardığımız dosya seçici servisi
import '../services/id3_service.dart'; // 🎯 SİBER HAMLE: ID3 okuyucu servis
import '../services/timer_service.dart'; // 🎯 SİBER HAMLE: Uyku zamanlayıcısı servisi
import '../services/history_service.dart'; // 🎯 SİBER HAMLE: Geçmiş dinleme servisi

import '../utils/song_media_utils.dart';
import '../utils/search_utils.dart';
import '../widgets/bottom_player_bar.dart';
import '../widgets/mode_indicator.dart';
import '../widgets/neon_search_bar.dart';
import '../widgets/mini_eq_visualizer.dart'; // 🎯 SİBER HAMLE: Yeni Ritim Widget'ı
import '../widgets/song_cover_art_tile.dart'; // 🎯 SİBER HAMLE: Yerel ve Çevrimdışı Kapak Widget'ı
import '../widgets/full_screen_player.dart'; // 🎯 SİBER HAMLE: Tam Ekran Oynatıcı Mührü
import '../services/settings_service.dart'; // 🎯 SİBER KARARGAH PANELİ BAĞLANTISI
import '../services/audio_engine.dart';
import '../widgets/siber_studio_panel.dart';
import '../widgets/siber_ad_widget.dart'; // 🎯 SİBER GÖRSEL AYARLAR İÇİN
import 'profile_screen.dart'; // 🎯 SİBER PROFİL BAĞLANTISI
import 'discover_screen.dart'; // 🎯 YOUTUBE MUSIC SİBER KLONU BAĞLANTISI
import 'listening_mode_screen.dart'; // 🎯 SİBER DİNLEME MODU BAĞLANTISI
import '../widgets/siber_sesli_komut_sheet.dart'; // 🎙️ SESLİ KOMUT
import '../widgets/siber_feedback_sheet.dart'; // 📩 GERİ BİLDİRİM & DESTEK
import '../services/subscription_manager.dart';
import '../services/auth_service.dart';
import '../widgets/siber_premium_sheet.dart';
import '../widgets/personal_discover_setup_sheet.dart';
import '../widgets/cyber_archive_background.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PlaylistController _playlistController = PlaylistController();
  final PlaylistService _playlistService = PlaylistService();
  final AICommander _commander = AICommander();
  final AudioAnalysisService _audioAnalysisService =
      AudioAnalysisService(); // 🎯 SİBER BEYİN

  bool _isPlaying = false;
  bool _isBuffering = false; // 🎯 SİBER HAMLE: Sonsuz Buffer (Yükleme) Kilidi
  String _currentSongName = 'Müzik Seçilmedi';
  String _currentArtist = 'Victus V7'; // 🎯 Sanatçı bilgisi
  Uint8List? _currentCoverBytes; // 🎯 Kapak resmi hafızası
  bool _isManuallyClosed = false; // 🛑 SİBER KALKAN: X'e basılınca player yeniden açılmasın
  List<SongModel> _playlist = [];
  List<SongModel> _emergentPlaylist = [];
  bool _isEmergentMode = false;
  String _searchQuery = '';
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  bool _isHandlerReady = false;
  int _repeatMode = 0;
  bool _isShuffle = false;
  Set<String> _favoritePaths = {}; // 🎯 Favori müziklerin hafızası
  int _sortMode = 0; // 🎯 Siber Sıralama Modu (0: Normal, 1: A-Z, 2: Z-A)
  String _lastRecordedSongId = ''; // 🎯 Siber Geçmiş kontrol mührü
  String _currentProcessedId =
      ''; // 🎯 Titremeyi (Flicker) engelleyen kimlik mührü
  double _neonScale = 1.0; // 🎯 SİBER RİTİM ÇARPAN
  String _waveType = 'Analiz Bekleniyor...'; // 🎯 SİBER RUH HALİ
  String _topHistorySongName =
      'Zirve Bekleniyor...'; // 🎯 SİBER HAMLE: Zirve Müzik
  String _topHistorySongPath = '';
  // 👤 SİBER PROFİL & HESAP BİLGİLERİ
  String _userName = 'Müziksever';
  String _userAvatarUrl = '';
  bool _isAccountLinked = false;

  // 🌤️ SİBER METEOROLOJİ & HAVA DURUMU
  Weather? _currentWeather;
  String _atmosphereMood = 'Genel';
  bool _isLoadingWeather = false;


  StreamSubscription? _mediaItemSub;
  StreamSubscription? _playbackStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription?
      _analysisSub; // 🎯 SİBER HAMLE: Analiz motoru için abonelik mührü
  final Map<String, Map<String, dynamic>> _downloadingTasks = {};
  final Map<String, Timer> _downloadTimers = {};

  @override
  void initState() {
    super.initState();
    SiberThemeService.instance.currentThemeColor.addListener(_onThemeChanged);
    SiberThemeService.instance.isMinimalMode.addListener(_onThemeChanged);
    OfflineCacheService().cacheChangeNotifier.addListener(_onOfflineCacheUpdated);
    OfflineCacheService().downloadProgress.addListener(_onOfflineProgressUpdated);
    SubscriptionManager().adFreeNotifier.addListener(_onAdFreeChanged);
    _checkHandlerAndInit();
  }

  void _onAdFreeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onOfflineCacheUpdated() {
    if (mounted) {
      _loadInitialPlaylist();
    }
  }

  void _onOfflineProgressUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _checkHandlerAndInit() async {
    // 🛡️ SİBER KALKAN: audioHandler zaten main.dart içinde runApp'ten önce mühürlendi.
    // Gereksiz null kontrolünü ve bekleme döngüsünü söküp attık!
    if (mounted) {
      setState(() => _isHandlerReady = true);
      _loadInitialPlaylist();
      _listenToAudioHandler();

      // 🎯 SİBER YAĞ GİBİ AKIŞ: Ağır SQLite, dosya tarama ve ağ isteklerini ilk kare boyandıktan sonraya ertele
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _initFavorites();
        _loadTopStats();
        _initAI();
        _initWeather();
        _loadUserProfile();
      });

      // 🎯 SİBER HAMLE: Canlı Frekans Dinleyicisi (150ms'de bir tüm ekranı dondurmaz, sadece mod değişince tetikler)
      _analysisSub = _audioAnalysisService.getAnalysisStream().listen((data) {
        if (!mounted || !_isPlaying) return;
        _neonScale = data.neonScale;
        if (data.waveType != _waveType) {
          setState(() {
            _waveType = data.waveType;
          });
        }
      });
    }
  }

  // 🌤️ SİBER HAMLE: Hava Durumunu Çek ve Modu Belirle
  Future<void> _initWeather() async {
    try {
      final w = await WeatherService.getCurrentWeather();
      if (w != null && mounted) {
        setState(() {
          _currentWeather = w;
          _atmosphereMood = WeatherService.getAtmosphereMood(w);
        });
      }
    } catch (e) {
      print('Siber Hava Durumu Çekilemedi: $e');
    }
  }

  // 🌤️ SİBER HAMLE: Hava Durumu & Müzik Zevki Mixini Aç
  void _launchWeatherMood(Color themeColor) async {
    // 🔒 SİBER KİLİT: Hava Durumu Mixi sadece Siber Öğrenci ve Imperium Premium'a özeldir!
    if (!SubscriptionManager().canUseWeatherMix()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              '🌤️ Atmosferik Hava Durumu Mixi, Öğrenci ve Premium üyelerine özeldir!'),
          backgroundColor: Colors.amber.shade800,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'İNCELE',
            textColor: Colors.white,
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => SiberPremiumSheet(themeColor: themeColor),
              );
              if (mounted) setState(() {});
            },
          ),
        ),
      );
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => SiberPremiumSheet(themeColor: themeColor),
      );
      if (mounted) setState(() {});
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WeatherMixSheet(
        currentWeather: _currentWeather,
        atmosphereMood: _atmosphereMood,
        themeColor: themeColor,
        onDownloadStart: _handleDownloadStart,
      ),
    );
  }

  // 🎯 SİBER HAMLE: En Çok Dinlenen Zirve Şarkıyı Analiz Et (Sadece Yerel Arşiv)
  Future<void> _loadTopStats() async {
    try {
      final historyList = await HistoryService.getHistory();
      final globalSongs = await loadGlobalLibrarySongs();
      final allStorageSongs = await StorageService().getPlaylist();
      final cachedSongs = OfflineCacheService().cachedSongs;

      final Set<String> archivePaths = {
        ...globalSongs.map((s) => s.path).whereType<String>(),
        ...allStorageSongs,
        ...cachedSongs.map((s) => s.path).whereType<String>(),
      }.where((p) => isPlayableSongPath(p) && !p.startsWith('http') && !p.startsWith('stream:')).toSet();

      final archiveHistory = historyList.where((h) => archivePaths.contains(h.path)).toList();

      if (archiveHistory.isNotEmpty && mounted) {
        archiveHistory.sort((a, b) {
          if (b.playCount != a.playCount) {
            return b.playCount.compareTo(a.playCount);
          }
          return b.totalListenSeconds.compareTo(a.totalListenSeconds);
        });
        setState(() {
          _topHistorySongName = archiveHistory.first.name
              .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '')
              .trim();
          if (_topHistorySongName.isEmpty) {
            _topHistorySongName = 'Bilinmeyen Müzik';
          }
          _topHistorySongPath = archiveHistory.first.path;
        });
      } else if (mounted) {
        setState(() => _topHistorySongName = 'Henüz Veri Yok');
      }
    } catch (e) {
      print('Siber İstatistik Hatası: $e');
    }
  }

  // 🎯 SİBER HAMLE: Favoriler Altyapısı
  Future<void> _initFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoritePaths = (prefs.getStringList('favorites') ?? []).toSet();
    });
    final names = await _playlistService.getAllPlaylistNames();
    if (!names.contains('Favorilerim')) {
      await _playlistService.createPlaylist('Favorilerim');
    }
    if (!names.contains('🔥 Zirvedekiler (Top 15)')) {
      await _playlistService.createPlaylist('🔥 Zirvedekiler (Top 15)');
    }
  }

  Future<void> _toggleFavorite(SongModel song) async {
    final safePath = song.path ?? 'bilinmeyen_yol';
    if (safePath == 'bilinmeyen_yol') return;
    final prefs = await SharedPreferences.getInstance();
    bool isFav = _favoritePaths.contains(safePath);
    if (isFav) {
      _favoritePaths.remove(safePath);
      await _playlistService.removeSongFromPlaylist('Favorilerim', safePath);
    } else {
      _favoritePaths.add(safePath);
      await _playlistService.addSongToPlaylist('Favorilerim', safePath);
    }
    await prefs.setStringList('favorites', _favoritePaths.toList());
    if (mounted) setState(() {});
  }

  // 🎯 SİBER OTONOM FAVORİ MOTORU: 3 kez dinlenen veya 5 dakikayı aşan şarkıyı otomatik kalple
  Future<void> _checkAndAutoFavorite(String path, String songTitle) async {
    if (path == 'bilinmeyen_yol' || path.isEmpty) return;
    if (_favoritePaths.contains(path)) return; // Zaten favorilerde

    try {
      final history = await HistoryService.getHistory();
      final rec = history.firstWhere(
        (e) => e.path == path,
        orElse: () => HistoryRecord(
          path: '',
          name: '',
          playCount: 0,
          totalListenSeconds: 0,
          lastPlayedTimestamp: 0,
        ),
      );

      // Eşik: 3 ve üzeri tam dinleme veya 300 saniye (5 dk) toplam dinleme süresi
      if (rec.playCount >= 3 || rec.totalListenSeconds >= 300) {
        final prefs = await SharedPreferences.getInstance();
        if (mounted) {
          setState(() {
            _favoritePaths.add(path);
          });
        }
        await _playlistService.addSongToPlaylist('Favorilerim', path);
        await prefs.setStringList('favorites', _favoritePaths.toList());

        Fluttertoast.showToast(
          msg: '🔥 "$songTitle" zirveye ulaştı, otomatik olarak Favorilerim\'e mühürlendi!',
          backgroundColor: Colors.deepOrangeAccent,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (e) {
      print('Otonom favori kontrol hatası: $e');
    }
  }

  void _listenToAudioHandler() {
    _mediaItemSub = audioHandler.mediaItem.listen((item) {
      if (item != null) {
        // 🛑 SİBER KALKAN: Kullanıcı X'e bastıysa player yeniden açılmasın
        if (_isManuallyClosed) return;
        bool isNewSong = _currentProcessedId != item.id;

        if (mounted) {
          setState(() {
            _currentSongName = item.title;
            _currentArtist = item.artist ?? 'Victus V7';
            _dur = item.duration ?? Duration.zero;
          });
        }

        // SADECE şarkı fiziksel olarak değiştiğinde ID3 yükle ve kapağı sıfırla
        if (isNewSong) {
          _currentProcessedId = item.id;
          if (mounted) {
            setState(() {
              _currentCoverBytes = null;
            });
          }

          // 🎯 SİBER HAMLE: Çevrimiçi Şarkı (Keşfet Kuyruğu) ise artUri Kullan (Plak Kapağı)
          _loadCoverForMediaItem(item);
        }

        // 🎯 SİBER GEÇMİŞ VE OTONOM FAVORİ MÜHRÜ
        if (item.id != 'bilinmeyen_yol') {
          if (_lastRecordedSongId != item.id) {
            _lastRecordedSongId = item.id;
            HistoryService.recordPlay(item.id, item.title).then((_) {
              _loadTopStats();
              _checkAndAutoFavorite(item.id, item.title);
            });
          }
          if (item.duration != null && item.duration!.inSeconds > 0) {
            HistoryService.updateDuration(item.id, item.duration!.inSeconds).then((_) {
              _checkAndAutoFavorite(item.id, item.title);
            });
          }
        }
      }
    });

    _playbackStateSub = audioHandler.playbackState.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          // 🎯 SİBER HAMLE: Slider titremesini (jitter) önlemek için _pos = state.position; söküldü!
          // StreamBuilder otonom olarak pozisyonu akıcı şekilde yönetecek.

          // 🎯 SİBER KALKAN: Sonsuz Yükleme Dairesi (Buffer Lock) Kökten Çözüldü!
          _isBuffering =
              state.processingState == AudioProcessingState.buffering ||
                  state.processingState == AudioProcessingState.loading;

          if (state.processingState == AudioProcessingState.ready ||
              state.processingState == AudioProcessingState.completed ||
              state.processingState == AudioProcessingState.idle ||
              state.processingState == AudioProcessingState.error) {
            // Motor hazırsa veya boşta/hatadaysa yüklemeyi kesinlikle durdur! 
            _isBuffering = false;
          }
        });
      }
    });

    // 🎯 SİBER HAMLE: Şarkı çalarken saniye saniye ilerlemesini (slider için) otonom dinliyoruz
    _positionSub = AudioService.position.listen((position) {
      if (mounted) {
        _pos =
            position; // 🎯 SİBER HAMLE: Toptan setState Kapatıldı! UI kilitlenmesi bitti.
      }
    });
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SiberThemeService.instance.currentThemeColor.removeListener(_onThemeChanged);
    SiberThemeService.instance.isMinimalMode.removeListener(_onThemeChanged);
    OfflineCacheService().cacheChangeNotifier.removeListener(_onOfflineCacheUpdated);
    OfflineCacheService().downloadProgress.removeListener(_onOfflineProgressUpdated);
    SubscriptionManager().adFreeNotifier.removeListener(_onAdFreeChanged);
    _mediaItemSub?.cancel();
    _playbackStateSub?.cancel();
    _positionSub?.cancel();
    _analysisSub
        ?.cancel(); // 🎯 SİBER KALKAN: Bellek sızıntısını (Memory Leak) önle!
    for (var timer in _downloadTimers.values) {
      timer.cancel();
    }
    _downloadTimers.clear();
    super.dispose();
  }

  Future<void> _initAI() async => await _commander.initCommander();
  Future<void> _loadInitialPlaylist() async => _toggleLibraryView(null);

  void _loadCoverForMediaItem(MediaItem item) {
    final vid = item.extras?['videoId']?.toString() ?? extractVideoIdFromPath(item.id);
    final uri = artUriForMediaId(
      item.id,
      videoId: vid,
      existing: item.artUri,
    );

    // 1. Önce yerel hafızadan (ID3 / M4A / Çevrimdışı Kapak) kontrol et (0ms & 0 kota)
    ID3Service.getCoverBytesForSong(item.id, videoId: vid, artUrl: item.artUri?.toString()).then((bytes) {
      if (bytes != null && mounted && _currentProcessedId == item.id) {
        setState(() => _currentCoverBytes = bytes);
        return;
      }

      // 2. İnternet URL'si varsa çek ve yerel belleğe mühürle
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        http.get(uri).then((response) {
          if (response.statusCode == 200 &&
              mounted &&
              _currentProcessedId == item.id) {
            setState(() => _currentCoverBytes = response.bodyBytes);
            if (vid != null && vid.isNotEmpty) {
              ID3Service.cacheCoverBytes(vid, response.bodyBytes);
            }
          }
        }).catchError((_) {
          _extractFallbackTags(item.id);
        });
        return;
      }

      _extractFallbackTags(item.id);
    }).catchError((_) {
      _extractFallbackTags(item.id);
    });
  }

  void _extractFallbackTags(String filePath) {
    if (filePath.startsWith('downloading:') || filePath == 'bilinmeyen_yol') {
      return;
    }

    ID3Service.extractTags(filePath).then((tags) {
      if (!mounted || _currentProcessedId != filePath) return;
      setState(() {
        final b = ID3Service.getCoverBytes(tags);
        if (b != null) _currentCoverBytes = b;
        final extractedArtist = tags['Artist']?.toString().trim();
        if (extractedArtist != null &&
            extractedArtist.isNotEmpty &&
            extractedArtist.toLowerCase() != 'null' &&
            extractedArtist.toLowerCase() != 'unknown') {
          _currentArtist = extractedArtist;
        }
        final extractedTitle = tags['Title']?.toString().trim();
        if (extractedTitle != null &&
            extractedTitle.isNotEmpty &&
            extractedTitle.toLowerCase() != 'null' &&
            extractedTitle.toLowerCase() != 'unknown') {
          _currentSongName = extractedTitle;
        }
      });
    });
  }

  Future<void> _toggleLibraryView(String? playlistName) async {
    if (mounted) setState(() => _isEmergentMode = false);
    if (playlistName == null) {
      _playlistController.isGlobalLibrary = true;
      _playlistController.currentPlaylistName = null;
    } else {
      _playlistController.isGlobalLibrary = false;
      _playlistController.currentPlaylistName = playlistName;
    }
    final newList = await _playlistController.loadTargetList();
    // ignore: unnecessary_null_comparison
    if (newList != null && mounted) {
      // 🎯 SİBER HAMLE: Uygulama kapansa bile listeyi hatırlayan Ana Arşiv Hafızası
      final globalSongs = await loadGlobalLibrarySongs();

      List<SongModel> mergedList = List.from(newList);
      if (playlistName == null) {
        for (var gs in globalSongs) {
          if (!mergedList.any((s) => s.path == gs.path)) {
            mergedList.add(gs);
          }
        }
        for (var cs in OfflineCacheService().cachedSongs) {
          if (!mergedList.any((s) => s.path == cs.path || (cs.videoId != null && s.videoId == cs.videoId))) {
            mergedList.add(cs);
          }
        }
      }

      setState(() {
        _playlist = mergedList;
        _searchQuery = '';
      });
    }
  }

  // 🎯 SİBER HAMLE: Arka Planda Şarkı İndirme Radarı (% ve MB Göstergesi İçin)
  void _handleDownloadStart(String videoId, String title) {
    if (!mounted) return;

    final dummyPath = 'downloading:$videoId';

    setState(() {
      _playlist.insert(0,
          SongModel(name: title, path: dummyPath, duration: 0, title: title));
      _downloadingTasks[videoId] = {'percent': '0%', 'mb': '0.0 / 0.0 MB'};
    });

    _downloadTimers[videoId] =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      final status = await OzsesBridge().getDownloadStatus(videoId);

      if (!mounted) {
        timer.cancel();
        return;
      }

      if (status['status'] == 'basarili') {
        timer.cancel();
        _downloadTimers.remove(videoId);

        final filePath = status['file_path']?.toString();
        if (filePath == null || !File(filePath).existsSync()) {
          setState(() {
            _downloadingTasks.remove(videoId);
            _playlist.removeWhere((s) => s.path == dummyPath);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('❌ $title arşive eklendi ama dosya bulunamadı!'),
              backgroundColor: Colors.redAccent,
            ));
          }
          return;
        }

        // 🎯 SİBER KALKAN: Eğer Android emülatörü kullanıyorsak ve şarkı PC'ye (Siber Beyin) indiyse HTTP akışı üzerinden çekeceğiz!
        String playPath = filePath;
        if (!kIsWeb && Platform.isAndroid && filePath.contains('siber_arsiv')) {
          final fileName = filePath.split('/').last.split('\\').last;
          final encodedFileName = Uri.encodeComponent(fileName);

          // 🎯 SİBER UYARI: Eğer uygulamayı GERÇEK BİR TELEFONDA test ediyorsan,
          // SİBER HAMLE: Artık gerçek cihazlara/sistemlere geçiyoruz!
          String siberIP = await SiberIPService.getMasterIP();
          playPath = 'http://$siberIP:8000/arsiv/$encodedFileName';
        }

        if (_playlistController.currentPlaylistName != null) {
          await _playlistService.addSongToPlaylist(
            _playlistController.currentPlaylistName!,
            playPath,
          );
        }
        final thumbUrl = 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
        final newSong = SongModel(
          name: title,
          path: playPath,
          duration: 0,
          title: title,
          videoId: videoId,
          artUrl: thumbUrl,
        );

        await addToGlobalLibrary(newSong);

        setState(() {
          _downloadingTasks.remove(videoId);
          int idx = _playlist.indexWhere((s) => s.path == dummyPath);
          if (idx != -1) {
            _playlist[idx] = newSong;
          } else {
            _playlist.insert(0, newSong);
          }
        });

        if (!_isEmergentMode) {
          final mediaItems = songsToMediaItems(_playlist);
          await audioHandler.updateQueue(mediaItems);
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ $title başarıyla arşive mühürlendi!'),
          backgroundColor: Colors.greenAccent,
        ));
      } else if (status['status'] == 'hata') {
        timer.cancel();
        _downloadTimers.remove(videoId);
        setState(() {
          _downloadingTasks.remove(videoId);
          _playlist.removeWhere((s) => s.path == dummyPath);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ $title arşive eklenemedi!'),
          backgroundColor: Colors.redAccent,
        ));
      } else if (status['status'] == 'indiriliyor') {
        setState(() {
          _downloadingTasks[videoId] = {
            'percent': status['percent'] ?? '0%',
            'mb': '${status['downloaded_mb']} / ${status['total_mb']} MB'
          };
        });
      } else if (status['status'] == 'converting') {
        setState(() {
          _downloadingTasks[videoId] = {
            'percent': '100%',
            'mb': 'Dönüştürülüyor...'
          };
        });
      }
    });
  }

  // 🎯 SİBER HAMLE 1: Çoklu Dosya Seçme ve Müzik Yükleme (Tam Otonom)
  Future<void> _scanFolderForMusic() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cihazınızdaki müzikler taranıyor...'),
            backgroundColor: Colors.deepPurpleAccent,
          ),
        );
      }
      List<String> foundPaths = await StorageService().autoScanMusicFolder();

      if (foundPaths.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Müzikler ekleniyor: ${foundPaths.length} müzik dosyası bulundu...'),
              backgroundColor: Colors.deepPurpleAccent,
            ),
          );
        }

        // 🎯 SİBER OTO-KAYIT: Şarkılar seçildiğinde aktif listeye (arşive) otonom kaydet
        if (_playlistController.currentPlaylistName != null) {
          for (var path in foundPaths) {
            await _playlistService.addSongToPlaylist(
              _playlistController.currentPlaylistName!,
              path,
            );
          }

          // 🎯 Listeyi tazeleyip, şarkıları tüm kuyrukla beraber motorun içine mühürle
          final newList = await _playlistController.loadTargetList();
          if (newList != null && mounted) {
            setState(() {
              _playlist = newList;
              _searchQuery = '';
            });
            // Yeni şarkıyı bulup DEV listeyle beraber çal
            if (newList.isNotEmpty) {
              final addedSong = newList.firstWhere(
                  (s) => s.path == foundPaths.first,
                  orElse: () => newList.last);
              await _playSong(addedSong);
            }
          }
        } else {
          // 🎯 SİBER HAMLE: Eğer arşiv seçili değilse, geçici kuyruğa ekle
          for (var path in foundPaths) {
            final newSong = SongModel(
                name: path.split('/').last.split('\\').last,
                path: path,
                duration: 0,
                title: '');
            _playlist.add(newSong);
          }
          
          // 🎯 SİBER KALKAN: Küresel arşivi kalıcı hafızaya mühürle ki uygulama kapanınca uçmasın!
          await saveGlobalLibrarySongs(_playlist);

          if (mounted) setState(() {});

          final mediaItems = _playlist
              .map((s) => MediaItem(
                    id: s.path ?? 'bilinmeyen_yol',
                    album: 'ÖZSES Arşivi',
                    title: _getSafeSongName(s),
                    artist: 'Victus V7',
                    duration: Duration(milliseconds: s.duration ?? 0),
                  ))
              .toList();

          await audioHandler.updateQueue(mediaItems);
          await audioHandler
              .skipToQueueItem(_playlist.length - foundPaths.length);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${foundPaths.length} Adet Müzik Yüklendi ve Mühürlendi!'),
              backgroundColor: Colors.greenAccent,
            ),
          );
        }
      }
    } catch (e) {
      print('Siber Hata: Tarama Çıktı -> $e');
    }
  }

  // 🎯 SİBER ZİRVEDEKİLER: Genel bazlı en çok dinlenen 15 şarkılık dinamik liste (SADECE YEREL ARŞİV)
  Future<void> _generateTop15Playlist(Color themeColor) async {
    try {
      final globalSongs = await loadGlobalLibrarySongs();
      final allStorageSongs = await StorageService().getPlaylist();
      final cachedSongs = OfflineCacheService().cachedSongs;

      final Set<String> archivePaths = {
        ...globalSongs.map((s) => s.path).whereType<String>(),
        ...allStorageSongs,
        ...cachedSongs.map((s) => s.path).whereType<String>(),
      }.where((p) => isPlayableSongPath(p) && !p.startsWith('http') && !p.startsWith('stream:')).toSet();

      if (archivePaths.isEmpty) {
        Fluttertoast.showToast(
          msg: 'Arşivinde henüz kayıtlı şarkı bulunmuyor!',
          backgroundColor: Colors.deepOrangeAccent,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
        return;
      }

      final history = await HistoryService.getHistory();
      // 🛡️ SİBER FİLTRE: Kesinlikle Keşfet online şarkıları karıştırılmaz, sadece yerel arşiv!
      final archiveHistory = history.where((h) => archivePaths.contains(h.path)).toList();

      if (archiveHistory.isEmpty) {
        Fluttertoast.showToast(
          msg: 'Henüz arşivden dinleme geçmişi oluşmadı! Arşivinden müzik dinledikçe Zirvedekiler burada toplanır.',
          backgroundColor: Colors.deepOrangeAccent,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
        return;
      }

      // Genel bazlı en çok dinlenenler (Önce çalma sayısı, sonra toplam dinleme süresi)
      archiveHistory.sort((a, b) {
        if (b.playCount != a.playCount) {
          return b.playCount.compareTo(a.playCount);
        }
        return b.totalListenSeconds.compareTo(a.totalListenSeconds);
      });

      final topPaths = archiveHistory
          .take(15)
          .map((h) => h.path)
          .toList();

      if (topPaths.isEmpty) {
        Fluttertoast.showToast(
          msg: 'Zirvede henüz yeterli şarkı bulunamadı!',
          backgroundColor: Colors.deepOrangeAccent,
          textColor: Colors.white,
        );
        return;
      }

      // Kalıcı olarak kaydet (Tekil Zirvedekiler listesi)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('playlist_🔥 Zirvedekiler (Top 15)', topPaths);
      await prefs.remove('playlist_🔥 Zirvedekiler (On Repeat)');

      // Listeyi kaydet
      await _playlistService.createPlaylist('🔥 Zirvedekiler (Top 15)');

      // Listeyi yükle ve göster
      await _toggleLibraryView('🔥 Zirvedekiler (Top 15)');

      Fluttertoast.showToast(
        msg: '🔥 Arşivinden en çok dinlediğin ${topPaths.length} şarkı Zirvedekiler listesi olarak hazırlandı!',
        backgroundColor: Colors.deepOrangeAccent,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    } catch (e) {
      print('Zirvedekiler oluşturma hatası: $e');
    }
  }

  // 🎯 SİBER YAPAY ZEKA: Gelişmiş Otonom Playlist Sınıflandırıcı Motoru
  Future<void> _generateAIPlaylists(Color themeColor) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber),
              SizedBox(width: 10),
              Text('Akıllı Algoritma arşivi derinlemesine analiz ediyor...'),
            ],
          ),
          backgroundColor: themeColor.withValues(alpha: 0.9),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // 1. Kütüphanedeki tüm şarkıları çek (Global Arşiv)
    final prefs = await SharedPreferences.getInstance();
    List<String> allSongPaths = prefs.getStringList('all_songs') ?? [];
    if (allSongPaths.isEmpty) {
      allSongPaths = _playlist.map((e) => e.path ?? '').where((e) => e.isNotEmpty).toList();
    }

    // 8 Gelişmiş Özel Kategori
    final Map<String, List<String>> generatedLists = {
      'Özel Mix: Rap & Sokak Trap': [],
      'Özel Mix: Arabesk & Damar': [],
      'Özel Mix: Deep Bass & Gece Sürüşü': [],
      'Özel Mix: Odaklanma & Ders Modu': [],
      'Özel Mix: Melankolik & Akustik': [],
      'Özel Mix: Enerji & Motivasyon': [],
      'Özel Mix: Türkçe Pop & Hit': [],
      'Özel Mix: Türkü & Anadolu Rock': [],
    };

    // Genişletilmiş Akıllı Anahtar Kelime & Sanatçı Sözlüğü
    final rapKeywords = [
      'rap', 'hiphop', 'ceza', 'sagopa', 'ezhel', 'khontkar', 'defkhan',
      'ben fero', 'şehinşah', 'beat', 'drill', 'uzi', 'cakal', 'reckol',
      'sansar', 'hidra', 'motive', 'ati242', 'blok3', 'lvbel', 'aspova', 'rota'
    ];
    final arabeskKeywords = [
      'arabesk', 'müslüm', 'ferdi', 'damar', 'azer', 'baba', 'bergen',
      'cengiz', 'güllü', 'tatlıses', 'ebru gündeş', 'gencebay', 'intizar',
      'serkan kaya', 'efkar', 'kader', 'haktan', 'yıldız tilbe'
    ];
    final bassKeywords = [
      'bass', 'remix', 'edm', 'trap', 'dj', 'club', 'mix', 'k-391',
      'alan walker', 'slowed', 'reverb', 'phonk', 'electronic', 'drift',
      'synthwave', 'speed up', 'bas', 'dance'
    ];
    final odakKeywords = [
      'lofi', 'chill', 'study', 'odak', 'ders', 'enstrümantal', 'instrumental',
      'piyano', 'piano', 'keman', 'klasik', 'relax', 'kütüphane', 'ambient',
      'meditasyon', 'huzur'
    ];
    final melankolikKeywords = [
      'slow', 'akustik', 'cover', 'duygusal', 'aşk', 'hüzün', 'melankolik',
      'yavaş', 'sad', 'can baydar', 'teoman', 'duman', 'madrigal',
      'yüzyüzeyken', 'pinhani', 'sezen aksu', 'emre aydın', 'mor ve ötesi'
    ];
    final motivasyonKeywords = [
      'gym', 'spor', 'fitness', 'workout', 'rock', 'metal', 'marş', 'hareketli',
      'motivasyon', 'rammstein', 'manga', 'şebnem ferah', 'hırs', 'enerji',
      'patlama', 'power'
    ];
    final popKeywords = [
      'pop', 'tarkan', 'murat boz', 'hadise', 'edis', 'zeynep', 'hit',
      'türkçe pop', 'gülşen', 'simge', 'hande yener', 'demet akalın',
      'irem derici', 'buray', 'aleyna'
    ];
    final turkuKeywords = [
      'türkü', 'anadolu', 'saz', 'bağlama', 'neşet ertaş', 'mahzuni',
      'aşık veysel', 'barış manço', 'cem karaca', 'selda bağcan',
      'koray avcı', 'türküler', 'ozan'
    ];

    for (String path in allSongPaths) {
      if (path.isEmpty || path == 'bilinmeyen_yol') continue;
      final fileName = path.split('/').last.split('\\').last.toLowerCase();

      // Hem dosya adını hem de ID3 etiketlerini (başlık, sanatçı) tara
      final songObj = _playlist.firstWhere(
        (s) => s.path == path,
        orElse: () => SongModel(name: '', path: path, duration: 0, title: ''),
      );
      final searchable = SearchUtils.normalizeForSearch('${songObj.title ?? ''} ${songObj.artist ?? ''} ${songObj.name} $fileName');

      if (rapKeywords.any((k) => searchable.contains(SearchUtils.normalizeForSearch(k)))) {
        generatedLists['Özel Mix: Rap & Sokak Trap']!.add(path);
      }
      if (arabeskKeywords.any((k) => searchable.contains(SearchUtils.normalizeForSearch(k)))) {
        generatedLists['Özel Mix: Arabesk & Damar']!.add(path);
      }
      if (bassKeywords.any((k) => searchable.contains(SearchUtils.normalizeForSearch(k)))) {
        generatedLists['Özel Mix: Deep Bass & Gece Sürüşü']!.add(path);
      }
      if (odakKeywords.any((k) => searchable.contains(SearchUtils.normalizeForSearch(k)))) {
        generatedLists['Özel Mix: Odaklanma & Ders Modu']!.add(path);
      }
      if (melankolikKeywords.any((k) => searchable.contains(SearchUtils.normalizeForSearch(k)))) {
        generatedLists['Özel Mix: Melankolik & Akustik']!.add(path);
      }
      if (motivasyonKeywords.any((k) => searchable.contains(SearchUtils.normalizeForSearch(k)))) {
        generatedLists['Özel Mix: Enerji & Motivasyon']!.add(path);
      }
      if (popKeywords.any((k) => searchable.contains(SearchUtils.normalizeForSearch(k)))) {
        generatedLists['Özel Mix: Türkçe Pop & Hit']!.add(path);
      }
      if (turkuKeywords.any((k) => searchable.contains(SearchUtils.normalizeForSearch(k)))) {
        generatedLists['Özel Mix: Türkü & Anadolu Rock']!.add(path);
      }
    }

    // 3. Veritabanına Yaz
    int totalGenerated = 0;
    for (var entry in generatedLists.entries) {
      if (entry.value.isNotEmpty) {
        await _playlistService.createPlaylist(entry.key);
        for (String songPath in entry.value) {
          await _playlistService.addSongToPlaylist(entry.key, songPath);
        }
        totalGenerated++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ Otonom Sınıflandırma Tamamlandı! $totalGenerated adet akıllı liste oluşturuldu.'),
          backgroundColor: Colors.greenAccent.shade700,
        ),
      );
      Navigator.pop(context); // Çekmeceyi kapat ki listeleri görsün
    }
  }



  String _getSafeSongName(SongModel song) => safeSongTitle(song);

  Future<void> _playSong(SongModel song) async {
    // 🛑 SİBER KALKAN: Yeni şarkıya basılınca kapat bayrağını sıfırla
    if (_isManuallyClosed) {
      setState(() => _isManuallyClosed = false);
    }
    if (!isPlayableSongPath(song.path)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu şarkı henüz hazır değil veya dosya bulunamadı.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return;
    }

    final targetList = _isEmergentMode ? _emergentPlaylist : _playlist;
    final playable =
        targetList.where((s) => isPlayableSongPath(s.path)).toList();
    final mediaItems = songsToMediaItems(playable);
    final index = playable.indexWhere((s) => s.path == song.path);
    if (index < 0) return;

    await audioHandler.updateQueue(mediaItems);
    await audioHandler.skipToQueueItem(index);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = SiberThemeService.instance.currentThemeColor.value;
    if (!_isHandlerReady) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    // 🎯 SİBER GÖRSEL UYUM: Şarkı adına göre değil, analiz edilen RUH HALİNE göre renk mühürle!
    final vibe = VibeEngine.getPackageByMode(_waveType);
    final sourceList = _isEmergentMode ? _emergentPlaylist : _playlist;
    List<SongModel> displayList = sourceList.where(
        (s) {
          if (_searchQuery.trim().isEmpty) return true;
          return SearchUtils.matchesSong(
            query: _searchQuery,
            title: s.title,
            artist: s.artist,
            name: s.name,
            path: s.path,
          );
        },
      ).toList();

    // 🎯 SİBER HAMLE: Otonom Sıralama Modeli
    if (_sortMode == 1) {
      displayList
          .sort((a, b) => _getSafeSongName(a).compareTo(_getSafeSongName(b)));
    } else if (_sortMode == 2) {
      displayList
          .sort((a, b) => _getSafeSongName(b).compareTo(_getSafeSongName(a)));
    }

    return Scaffold(
      onDrawerChanged: (isOpened) {
        if (isOpened) _loadUserProfile();
      },
      resizeToAvoidBottomInset: false, // 🛑 SİBER KALKAN: Klavye açılınca player bar yukarı fırlamaması için
      backgroundColor: const Color(0xFF080A12),
      drawer: Drawer(
        elevation: 0,
        backgroundColor: Colors.transparent, // 🎯 SİBER CAM EFEKTİ İÇİN ŞEFFAF
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75), // Biraz daha saydam
            border: Border(
                right: BorderSide(
                    color: themeColor.withValues(alpha: 0.4), width: 2.0)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  // 🎯 RESİMDEKİ GİBİ DAİRESEL PROFİL BUTONU & İSİM SOYİSİM & ÜYELİK ÇEŞİDİ
                  _buildDrawerProfileHeader(themeColor),
                  const SizedBox(height: 6),

                  // 💎 YENİ: ÇİFTE KEŞFET RADARI
                  _buildDiscoveryPanel(themeColor),
                  const SizedBox(height: 15),


                  
                  // 🎯 SİBER HIZLI İSTASYON (Zirve 15 Listesi & Zihin Ses Modu & Listeler)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: themeColor.withValues(alpha: 0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: themeColor.withValues(alpha: 0.15),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.bolt_rounded, color: Colors.amber, size: 22),
                                    SizedBox(width: 8),
                                    Text(
                                      'HIZLI İSTASYON',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _buildNeonButton(
                                  icon: Icons.local_fire_department_rounded,
                                  label: '🔥 ZİRVEDEKİLER (TOP 15)',
                                  themeColor: Colors.deepOrangeAccent,
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _generateTop15Playlist(themeColor);
                                  },
                                ),
                                _buildNeonButton(
                                  icon: Icons.auto_awesome,
                                  label: '🔮 MÜZİK METAMORFOZU',
                                  themeColor: Colors.amber,
                                  onPressed: () {
                                    Navigator.pop(context);
                                    if (!SubscriptionManager().canUseMetamorphosis()) {
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.transparent,
                                        isScrollControlled: true,
                                        builder: (context) => SiberPremiumSheet(themeColor: themeColor),
                                      );
                                      return;
                                    }
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        transitionDuration: const Duration(milliseconds: 250),
                                        reverseTransitionDuration: const Duration(milliseconds: 200),
                                        pageBuilder: (context, animation, secondaryAnimation) => DiscoverScreen(
                                          themeColor: themeColor,
                                          initialOpenMetamorphosis: true,
                                        ),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          return FadeTransition(opacity: animation, child: child);
                                        },
                                      ),
                                    );
                                  },
                                ),
                                _buildNeonButton(
                                  icon: Icons.queue_music_rounded,
                                  label: 'ÇALMA LİSTELERİ',
                                  themeColor: themeColor,
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showPlaylistSelectorBottomSheet(themeColor);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 15),

                  // 🎯 SİBER KOMUTA MERKEZİ (Ayarlar)
                  _buildSiberPanel(themeColor),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          CyberArchiveBackground(
            themeColor: themeColor,
            neonScale: _neonScale,
            isPlaying: _isPlaying,
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(themeColor),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ModeIndicator(
                          isGlobalLibrary: _isEmergentMode
                              ? false
                              : _playlistController.isGlobalLibrary,
                          playlistTitle: _isEmergentMode
                              ? 'OTONOM LİSTE'
                              : (_playlistController.currentPlaylistName ??
                                  'Arşiv'),
                          themeColor: themeColor,
                          onClose: () => _isEmergentMode
                              ? setState(() => _isEmergentMode = false)
                              : _toggleLibraryView(null),
                        ),
                      ),
                      if (_isEmergentMode)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: IconButton(
                            icon: Icon(Icons.save, color: themeColor),
                            tooltip: 'Otonom Listeyi Mühürle',
                            onPressed: () => _saveEmergentPlaylist(themeColor),
                          ),
                        ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () =>
                            _showPlaylistSelectorBottomSheet(themeColor),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: themeColor.withValues(alpha: 0.5),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: themeColor.withValues(alpha: 0.2),
                                  blurRadius: 10)
                            ],
                          ),
                          child: Icon(Icons.music_note,
                              color: themeColor, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: NeonSearchBar(
                        themeColor: themeColor,
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    PopupMenuButton<int>(
                      icon: Icon(Icons.sort, color: themeColor),
                      color: Colors.grey[900],
                      tooltip: 'Sıralama',
                      onSelected: (val) => setState(() => _sortMode = val),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 0,
                            child: Text('Sırayı Bozma',
                                style: TextStyle(color: Colors.white))),
                        const PopupMenuItem(
                            value: 1,
                            child: Text("A'dan Z'ye",
                                style: TextStyle(color: Colors.white))),
                        const PopupMenuItem(
                            value: 2,
                            child: Text("Z'den A'ya",
                                style: TextStyle(color: Colors.white))),
                      ],
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(
                        milliseconds: 120), // 🎯 SİBER RİTİM: Akıcı geçiş
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.black
                            .withValues(alpha: 0.35), // Daha zarif saydamlık
                        borderRadius:
                            BorderRadius.circular(25), // Yuvarlatma arttı
                        border: Border.all(
                            color: themeColor.withValues(alpha: 
                                (0.25 * _neonScale).clamp(0.0, 1.0)),
                            width: 1.5 +
                                (_neonScale > 1.0 ? (_neonScale - 1.0) : 0)),
                        boxShadow: [
                          BoxShadow(
                              color: themeColor.withValues(alpha: 
                                  (0.08 * _neonScale).clamp(0.0, 1.0)),
                              blurRadius: 20 * _neonScale,
                              spreadRadius: 2 +
                                  (5 *
                                      (_neonScale > 1.0
                                          ? _neonScale - 1.0
                                          : 0)))
                        ]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: _searchQuery.isNotEmpty
                            ? ListView.builder(
                                padding: const EdgeInsets.only(bottom: 110),
                                itemCount: displayList.length,
                                itemBuilder: (context, index) {
                                  final song = displayList[index];
                                  // 🎯 SİBER KALKAN: İsme göre değil, dosya yoluna (Parmak izine) göre eşleştirme!
                                  bool isSelected = _currentProcessedId ==
                                      (song.path ?? 'bilinmeyen_yol');
                                  return _buildSongTile(
                                      song, isSelected, themeColor);
                                },
                              )
                            : ReorderableListView.builder(
                                padding: const EdgeInsets.only(bottom: 110),
                                itemCount: displayList.length,
                                proxyDecorator: (child, index, animation) =>
                                    Material(
                                        color: Colors.transparent,
                                        child: child),
                                onReorder: (oldIndex, newIndex) {
                                  if (newIndex > oldIndex) newIndex -= 1;
                                  setState(() {
                                    _sortMode =
                                        0; // 🎯 SİBER HAMLE: Manuel sıralama yapıldığında oto-sıralamayı kapat!
                                    final item = displayList.removeAt(oldIndex);
                                    displayList.insert(newIndex, item);
                                    if (_isEmergentMode) {
                                      _emergentPlaylist = displayList;
                                    } else {
                                      _playlist = displayList;
                                    }
                                  });
                                  final mediaItems = displayList
                                      .map((s) => MediaItem(
                                            id: s.path ?? 'bilinmeyen_yol',
                                            album: 'ÖZSES Arşivi',
                                            title: _getSafeSongName(s),
                                            artist: 'Victus V7',
                                            duration: Duration(milliseconds: s.duration ?? 0),
                                          ))
                                      .toList();
                                  audioHandler.updateQueue(mediaItems);
                                },
                                itemBuilder: (context, index) {
                                  final song = displayList[index];
                                  // 🎯 SİBER KALKAN: Kaydırılabilir listede de Parmak İziyle eşleştirme!
                                  bool isSelected = _currentProcessedId ==
                                      (song.path ?? 'bilinmeyen_yol');
                                  return _buildSongTile(
                                      song, isSelected, themeColor);
                                },
                              ),
                      ),
                    ),
                  ),
                ValueListenableBuilder<bool>(
                  valueListenable: SubscriptionManager().adFreeNotifier,
                  builder: (context, isAdFree, _) {
                    if (isAdFree || SubscriptionManager().isAdFree) {
                      return const SizedBox.shrink();
                    }
                    return const SiberAdWidget();
                  },
                ),
                if (_currentSongName != 'Müzik Seçilmedi')
                  const SizedBox(height: 85)
                else
                  const SizedBox(height: 15),
              ],
            ),
          ),
          if (_currentSongName != 'Müzik Seçilmedi')
            Builder(builder: (context) {
              final currentList =
                  _isEmergentMode ? _emergentPlaylist : _playlist;
              final currentSong = currentList.firstWhere(
                  (s) => _getSafeSongName(s) == _currentSongName,
                  orElse: () => SongModel(
                      name: '',
                      path: 'bilinmeyen_yol',
                      duration: 0,
                      title: ''));
              final isCurrentFav = _favoritePaths.contains(currentSong.path);
              return Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 15,
                left: 15,
                right: 15,
                child: AnimatedContainer(
                  duration: const Duration(
                      milliseconds: 120), // 🎯 SİBER RİTİM MOTORU
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                          color: themeColor
                              .withValues(alpha: (0.6 * _neonScale).clamp(0.0, 1.0)),
                          width: 1.5 +
                              (_neonScale > 1.0 ? (_neonScale - 1.0) * 2 : 0)),
                      boxShadow: [
                        BoxShadow(
                            color: themeColor.withValues(alpha: 
                                (0.3 * _neonScale).clamp(0.0, 1.0)),
                            blurRadius: 20 * _neonScale,
                            spreadRadius: 2 +
                                (8 * (_neonScale > 1.0 ? _neonScale - 1.0 : 0)))
                      ]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: StreamBuilder<Duration>(
                        // 🎯 YUSUF USTA HAMLESİ: StreamBuilder ile kasmayan Slider
                        stream: AudioService.position,
                        builder: (context, posSnapshot) {
                          final currentPos = posSnapshot.data ?? _pos;
                          return BottomPlayerBar(
                            songName: _currentSongName,
                            artistName: _currentArtist,
                            coverBytes: _currentCoverBytes,
                            themeColor: themeColor,
                            position: currentPos,
                            duration: _dur,
                            isPlaying: _isPlaying,
                            isBuffering: _isBuffering,
                            isShuffle: _isShuffle,
                            isFavorite: isCurrentFav,
                            onFavoriteToggle: () =>
                                _toggleFavorite(currentSong),
                            trailingAccessory: MiniEqVisualizer(
                              themeColor: themeColor,
                              isPlaying: _isPlaying,
                            ),
                            repeatMode: _repeatMode,
                            onPlayPause: () => _isPlaying
                                ? audioHandler.pause()
                                : audioHandler.play(),
                            onNext: () => audioHandler.skipToNext(),
                            onPrevious: () => audioHandler.skipToPrevious(),
                            onSeek: (v) =>
                                audioHandler.seek(Duration(seconds: v.toInt())),
                            onShuffleToggle: () {
                              setState(() => _isShuffle = !_isShuffle);
                              audioHandler.setShuffleMode(_isShuffle
                                  ? AudioServiceShuffleMode.all
                                  : AudioServiceShuffleMode.none);
                            },
                            onRepeatToggle: () {
                              int nextMode = (_repeatMode + 1) % 3;
                              setState(() => _repeatMode = nextMode);
                              if (nextMode == 1) {
                                audioHandler
                                    .setRepeatMode(AudioServiceRepeatMode.one);
                              } else if (nextMode == 2) {
                                audioHandler
                                    .setRepeatMode(AudioServiceRepeatMode.all);
                              } else {
                                audioHandler
                                    .setRepeatMode(AudioServiceRepeatMode.none);
                              }
                            },
                            onExpand: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => FullScreenPlayer(
                                  themeColor: themeColor,
                                  checkIsFavorite: (path) =>
                                      _favoritePaths.contains(path),
                                  onToggleFavorite: (path) {
                                    final song = _playlist.firstWhere(
                                        (s) => s.path == path,
                                        orElse: () => SongModel(
                                            name: '',
                                            path: path,
                                            duration: 0,
                                            title: ''));
                                    if (song.path != 'bilinmeyen_yol') {
                                      _toggleFavorite(song);
                                    }
                                  },
                                  onAddToPlaylist: (path) =>
                                      _showAddToPlaylistDialog(path),
                                  onDelete: (path) {
                                    final song = _playlist.firstWhere(
                                        (s) => s.path == path,
                                        orElse: () => SongModel(
                                            name: '',
                                            path: path,
                                            duration: 0,
                                            title: ''));
                                    if (song.path != 'bilinmeyen_yol') {
                                      _deleteSong(song, path);
                                      Navigator.pop(context);
                                    }
                                  },
                                  onAddQueue: (path, playNext) {
                                    final song = _playlist.firstWhere(
                                        (s) => s.path == path,
                                        orElse: () => SongModel(
                                            name: '',
                                            path: path,
                                            duration: 0,
                                            title: ''));
                                    if (song.path != 'bilinmeyen_yol') {
                                      _addSongToQueue(song, playNext);
                                    }
                                  },
                                ),
                              );
                            },
                            onShowQueue: () =>
                                _showQueueBottomSheet(themeColor),
                            onClose: () {
                              _isManuallyClosed = true; // 🛑 SİBER KALKAN
                              audioHandler.stop();
                              setState(
                                  () => _currentSongName = 'Müzik Seçilmedi');
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              })
        ],
      ),
    );
  }

  // --- Widget Fonksiyonları ---

  // 👤 SİBER PROFİL VERİLERİNİ YÜKLE
  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _isAccountLinked = prefs.getBool('siber_is_linked') ?? false;
          _userName = prefs.getString('siber_username') ?? 'Müziksever';
          _userAvatarUrl = prefs.getString('siber_avatar_url') ?? '';
        });
      }
    } catch (_) {}
  }

  // ✏️ İSİM & SOYİSİM DÜZENLEME PENCERESİ
  void _showNameEditDialog(Color themeColor) {
    final controller = TextEditingController(text: _userName == 'Müziksever' ? '' : _userName);
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF14141E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: themeColor.withValues(alpha: 0.5), width: 1.5),
          ),
          title: Row(
            children: [
              Icon(Icons.edit_note_rounded, color: themeColor, size: 24),
              const SizedBox(width: 8),
              const Text(
                'İSİM & SOYİSİM',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Çekmecede ve profilinizde görünecek adınızı belirleyin:',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'Adınız Soyadınız',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  prefixIcon: Icon(Icons.person_outline_rounded, color: themeColor),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: themeColor, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('İPTAL', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('siber_username', newName);
                  if (mounted) {
                    setState(() {
                      _userName = newName;
                    });
                  }
                }
                Navigator.pop(dialogCtx);
              },
              child: const Text('KAYDET', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // 🛡️ PROFİL & HESAP SEÇENEKLERİ MENÜSÜ
  void _showProfileOptionsBottomSheet(Color themeColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF14141E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            border: Border(top: BorderSide(color: themeColor.withValues(alpha: 0.5), width: 1.5)),
            boxShadow: [
              BoxShadow(color: themeColor.withValues(alpha: 0.2), blurRadius: 20),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                ),
                Text(
                  _userName.isEmpty ? 'Kullanıcı Profili' : _userName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  _isAccountLinked ? '✅ Google Hesabı Bağlı' : 'Yerel Profil',
                  style: TextStyle(color: _isAccountLinked ? Colors.greenAccent : Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: Icon(Icons.edit_rounded, color: themeColor, size: 20),
                  ),
                  title: const Text('İsim & Soyisim Yaz / Değiştir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Kendi isminizi manuel olarak belirleyin', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showNameEditDialog(themeColor);
                  },
                ),
                if (!_isAccountLinked)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.account_circle, color: Colors.redAccent, size: 22),
                    ),
                    title: const Text('Google Hesabını Bağla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Google adı ve profil resmini hemen aktar', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        Fluttertoast.showToast(msg: 'Google Girişi Başlatılıyor...');
                        final ok = await AuthService().signInWithGoogle();
                        if (ok) {
                          await _loadUserProfile();
                          Fluttertoast.showToast(msg: 'Google Hesabı Başarıyla Bağlandı! 🎉');
                        }
                      } catch (e) {
                        Fluttertoast.showToast(msg: 'Giriş: $e');
                      }
                    },
                  ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded, color: Colors.amber, size: 20),
                  ),
                  title: const Text('Tam Profil & Hesap Merkezi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Rütbe, istatistikler ve rozetler', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    Navigator.pop(context); // Çekmeceyi kapat
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                    if (mounted) _loadUserProfile();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🎯 SİBER PROFİL BAŞLIĞI (DAİRESEL BUTON + İSİM SOYİSİM + ÜYELİK ÇEŞİDİ)
  Widget _buildDrawerProfileHeader(Color themeColor) {
    final tier = SubscriptionManager().currentTier;
    String tierName;
    Color tierColor;
    IconData tierIcon;

    if (tier == SiberTier.premium) {
      tierName = 'Imperium Premium';
      tierColor = Colors.amber;
      tierIcon = Icons.stars_rounded;
    } else if (tier == SiberTier.student) {
      tierName = 'Öğrenci Planı';
      tierColor = Colors.cyanAccent;
      tierIcon = Icons.school_rounded;
    } else {
      tierName = 'Ücretsiz Üye';
      tierColor = Colors.white70;
      tierIcon = Icons.bolt_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: themeColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: themeColor.withValues(alpha: 0.12),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _showProfileOptionsBottomSheet(themeColor),
            splashColor: themeColor.withValues(alpha: 0.2),
            highlightColor: themeColor.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
              child: Row(
                children: [
                  // 🎯 RESİMDEKİ GİBİ DAİRESEL PROFİL BUTONU (AVATAR)
                  Stack(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black54,
                          border: Border.all(
                            color: _isAccountLinked ? Colors.greenAccent : themeColor.withValues(alpha: 0.8),
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isAccountLinked ? Colors.greenAccent : themeColor).withValues(alpha: 0.25),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _userAvatarUrl.isNotEmpty
                              ? Image.network(
                                  _userAvatarUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.face_unlock_rounded,
                                    size: 30,
                                    color: themeColor,
                                  ),
                                )
                              : Icon(
                                  Icons.face_unlock_rounded,
                                  size: 30,
                                  color: themeColor,
                                ),
                        ),
                      ),
                      if (_isAccountLinked)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // 🎯 İSİM SOYİSİM & ÜYELİK ÇEŞİDİ ALANI
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // İsim Soyisim Satırı
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _userName.isEmpty ? 'İsim Soyisim Yazın' : _userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(
                              _isAccountLinked ? Icons.verified_rounded : Icons.edit_note_rounded,
                              size: 16,
                              color: _isAccountLinked ? Colors.greenAccent : themeColor.withValues(alpha: 0.8),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),

                        // Altında Küçük Şekilde Üyelik Çeşidi
                        Row(
                          children: [
                            Icon(tierIcon, size: 13, color: tierColor),
                            const SizedBox(width: 4),
                            Text(
                              tierName,
                              style: TextStyle(
                                color: tierColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),

                        if (!_isAccountLinked) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Google Hesabını Bağla >',
                            style: TextStyle(
                              color: themeColor.withValues(alpha: 0.9),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Sağ Ok
                  Icon(
                    Icons.chevron_right_rounded,
                    color: themeColor.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🎯 SİBER HAMLE: Çifte Keşfet (Radar) Paneli
  Widget _buildDiscoveryPanel(Color themeColor) {
    // Hava durumuna göre simge ve açıklama
    IconData weatherIcon = Icons.wb_sunny_rounded;
    Color weatherColor = Colors.amberAccent;
    if (_atmosphereMood == 'Melankolik') {
      weatherIcon = Icons.water_drop_rounded;
      weatherColor = Colors.blueAccent;
    } else if (_atmosphereMood == 'Akustik') {
      weatherIcon = Icons.ac_unit_rounded;
      weatherColor = Colors.tealAccent;
    } else if (_atmosphereMood == 'Odaklanma') {
      weatherIcon = Icons.cloud_rounded;
      weatherColor = Colors.lightBlueAccent;
    }

    final tempText = _currentWeather?.temperature?.celsius != null
        ? " (${_currentWeather!.temperature!.celsius!.toStringAsFixed(0)}°C)"
        : "";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: themeColor.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: themeColor.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.radar, color: themeColor, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'KEŞFET RADARI',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _buildNeonButton(
                          icon: Icons.travel_explore,
                          label: 'ŞAHSİ',
                          themeColor: Colors.purpleAccent,
                          onPressed: () => _launchPersonalDiscover(themeColor),
                          onLongPress: () => _showPersonalSurveyDialog(themeColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildNeonButton(
                          icon: Icons.new_releases,
                          label: 'GENEL',
                          themeColor: Colors.cyanAccent,
                          onPressed: () => _scanNewRecruits(themeColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 🌤️ SİBER HAMLE: Keşfetin Altında Hava Durumuna Göre Mod
                  _buildNeonButton(
                    icon: weatherIcon,
                    label: 'HAVA MODU: $_atmosphereMood$tempText',
                    themeColor: weatherColor,
                    onPressed: () => _launchWeatherMood(themeColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildSiberPanel(Color themeColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5), // Buzul Cam Etkisi
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: themeColor.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: themeColor.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                iconColor: themeColor,
                collapsedIconColor: Colors.white70,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle),
                  child: Icon(Icons.settings_suggest_rounded, color: themeColor, size: 20),
                ),
                title: const Text(
                  'ARAÇLAR VE SİSTEM',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8.0),
                    child: Column(
                      children: [
                        _buildNeonButton(
                          icon: Icons.folder_special_rounded,
                          label: 'CİHAZDAN MÜZİK EKLE',
                          themeColor: themeColor,
                          onPressed: _scanFolderForMusic,
                        ),
                        _buildNeonButton(
                          icon: Icons.nights_stay_rounded,
                          label: 'UYKU ZAMANLAYICI',
                          themeColor: Colors.indigoAccent,
                          onPressed: () => _showSiberSleepBottomSheet(themeColor),
                        ),
                        _buildNeonButton(
                          icon: Icons.palette_rounded,
                          label: 'TEMA MERKEZİ (24 RENK)',
                          themeColor: Colors.pinkAccent,
                          onPressed: () {
                            Navigator.pop(context); // Çekmeceyi kapat
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) => SiberThemeSheet(),
                            );
                          },
                        ),
                        _buildNeonButton(
                          icon: Icons.backup_rounded,
                          label: 'ARŞİV YEDEKLEME',
                          themeColor: Colors.lightBlueAccent,
                          onPressed: () {
                            Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Arşiv Yedekleme ve Dışa Aktarma modülü başlatılıyor...')));
                          },
                        ),
                        _buildNeonButton(
                          icon: Icons.feedback_outlined,
                          label: 'GERİ BİLDİRİM & HATA BİLDİR',
                          themeColor: Colors.tealAccent,
                          onPressed: () {
                            Navigator.pop(context);
                            _showFeedbackBottomSheet(themeColor);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  // 🎯 SİBER GERİ BİLDİRİM & HATA BİLDİRİMİ (n8n + VPS + Firestore 3'lü Kalkan)
  void _showFeedbackBottomSheet(Color themeColor) {
    showSiberFeedbackSheet(context, themeColor: themeColor);
  }

  // 🎯 SİBER HAMLE: Playlist Oluşturma Tipi Seçim Ekranı
  // 🎯 SİBER HAMLE: Playlist Oluşturma Tipi Seçim Ekranı
  void _showPlaylistTypeSelectionDialog(BuildContext context, Color themeColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(top: BorderSide(color: themeColor.withValues(alpha: 0.5), width: 2)),
            boxShadow: [
              BoxShadow(color: themeColor.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5)
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.library_add, color: themeColor, size: 28),
                        const SizedBox(width: 10),
                        Text('YENİ LİSTE OLUŞTUR', style: TextStyle(color: themeColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ],
                    ),
                    const SizedBox(height: 25),
                    _buildSelectionTile(
                      context: context,
                      title: 'Manuel Oluştur',
                      subtitle: 'Boş bir liste açıp şarkıları tek tek ekleyin.',
                      icon: Icons.edit_rounded,
                      color: Colors.cyanAccent,
                      onTap: () {
                        Navigator.pop(context);
                        _showCreateDialog(context, themeColor);
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildSelectionTile(
                      context: context,
                      title: 'Akıllı Mix (Otonom Çark)',
                      subtitle: 'Ruh halinize ve müzik türüne göre özel liste hazırlasın.',
                      icon: Icons.auto_awesome_rounded,
                      color: Colors.orangeAccent,
                      onTap: () {
                        Navigator.pop(context);
                        _showOfflineAutoPlaylistDialog(context, themeColor);
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildSelectionTile(
                      context: context,
                      title: 'Sanatçıya Özel Otonom Liste',
                      subtitle: 'Kütüphanenizdeki bir sanatçının solo ve düet parçalarından liste üretir.',
                      icon: Icons.mic_external_on_rounded,
                      color: Colors.pinkAccent,
                      onTap: () {
                        Navigator.pop(context);
                        _showArtistAutoPlaylistDialog(context, themeColor);
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildSelectionTile(
                      context: context,
                      title: 'Arşivi Otomatik Sınıflandır',
                      subtitle: 'Tüm şarkıları tarzlarına göre 8 akıllı listeye böler.',
                      icon: Icons.hub_rounded,
                      color: Colors.purpleAccent,
                      onTap: () {
                        Navigator.pop(context);
                        _generateAIPlaylists(themeColor);
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectionTile({required BuildContext context, required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }

  // 🎯 SİBER HAMLE: Çevrimdışı Kütüphane İçin Hızlı Otomatik Liste Menüsü
  // 🎯 SİBER HAMLE: Çevrimdışı Kütüphane İçin Hızlı Otomatik Liste Menüsü
  // 🎯 SİBER HAMLE: Çevrimdışı Kütüphane İçin Hızlı Otomatik Liste Menüsü (ÇİFT ÇARK)
  void _showOfflineAutoPlaylistDialog(BuildContext context, Color themeColor) {
    final List<Map<String, dynamic>> moods = [
      {'name': 'Melankolik', 'icon': Icons.water_drop, 'color': Colors.blueAccent},
      {'name': 'Efkârlı', 'icon': Icons.smoke_free, 'color': Colors.grey},
      {'name': 'Enerjik', 'icon': Icons.local_fire_department, 'color': Colors.orangeAccent},
      {'name': 'Kopmalık', 'icon': Icons.celebration, 'color': Colors.amberAccent},
      {'name': 'Rahatlatıcı', 'icon': Icons.spa, 'color': Colors.tealAccent},
      {'name': 'Odaklanma', 'icon': Icons.psychology_alt, 'color': Colors.green},
      {'name': 'Motivasyon', 'icon': Icons.fitness_center, 'color': Colors.red},
      {'name': 'Nostaljik', 'icon': Icons.history_toggle_off, 'color': Colors.brown},
      {'name': 'İsyankâr', 'icon': Icons.bolt, 'color': Colors.deepPurpleAccent},
      {'name': 'Uyku Öncesi', 'icon': Icons.nights_stay, 'color': Colors.indigo},
    ];
    
    final List<Map<String, dynamic>> genres = [
      {'name': 'Türkçe Pop', 'icon': Icons.star, 'color': Colors.pinkAccent},
      {'name': 'Yabancı Pop', 'icon': Icons.public, 'color': Colors.lightBlueAccent},
      {'name': 'Arabesk', 'icon': Icons.local_drink, 'color': Colors.purpleAccent},
      {'name': 'Rap / Sokak', 'icon': Icons.sports_kabaddi, 'color': Colors.redAccent},
      {'name': 'Rock / Metal', 'icon': Icons.album, 'color': Colors.blueGrey},
      {'name': 'Anadolu Rock', 'icon': Icons.landscape, 'color': Colors.orange},
      {'name': 'Türkü', 'icon': Icons.music_video, 'color': Colors.brown},
      {'name': 'Akustik', 'icon': Icons.music_note, 'color': Colors.lime},
      {'name': 'Elektronik', 'icon': Icons.graphic_eq, 'color': Colors.cyanAccent},
      {'name': 'Klasik Müzik', 'icon': Icons.piano, 'color': Colors.amber},
      {'name': 'Musiki', 'icon': Icons.queue_music, 'color': Colors.tealAccent},
      {'name': 'Marşlar', 'icon': Icons.military_tech, 'color': Colors.redAccent},
    ];

    int selectedMoodIndex = 0;
    int selectedGenreIndex = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: 485,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border(top: BorderSide(color: themeColor.withValues(alpha: 0.5), width: 2)),
                boxShadow: [
                  BoxShadow(color: themeColor.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 5)
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 15, bottom: 15),
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, color: themeColor, size: 28),
                          const SizedBox(width: 10),
                          Text('AKILLI MİX MOTORU', style: TextStyle(color: themeColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _showArtistAutoPlaylistDialog(context, themeColor);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.mic_external_on_rounded, color: Colors.pinkAccent, size: 13),
                              SizedBox(width: 5),
                              Text('Sanatçıya Özel Otonom Liste Aç', style: TextStyle(color: Colors.pinkAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                              SizedBox(width: 4),
                              Icon(Icons.chevron_right_rounded, color: Colors.pinkAccent, size: 14),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Ruh hali ve Müzik Türünü çevirerek seç', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(child: Center(child: Text("RUH HALİ", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 14)))),
                            Expanded(child: Center(child: Text("MÜZİK TÜRÜ", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 14)))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // 🎯 SİBER ÇİFT ÇEVİRMELİ TEKERLEK
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Seçili öğe arka planı (Highlight)
                            Container(
                              height: 50,
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                                boxShadow: [
                                  BoxShadow(color: themeColor.withValues(alpha: 0.05), blurRadius: 10)
                                ]
                              ),
                            ),
                            Row(
                              children: [
                                // RUH HALI TEKERLEĞİ
                                Expanded(
                                  child: ListWheelScrollView.useDelegate(
                                    itemExtent: 50,
                                    physics: const FixedExtentScrollPhysics(),
                                    diameterRatio: 1.5,
                                    onSelectedItemChanged: (index) {
                                      setState(() {
                                        selectedMoodIndex = index;
                                      });
                                    },
                                    childDelegate: ListWheelChildBuilderDelegate(
                                      childCount: moods.length,
                                      builder: (context, index) {
                                        final item = moods[index];
                                        final isSelected = index == selectedMoodIndex;
                                        return AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          alignment: Alignment.center,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(item['icon'], color: isSelected ? item['color'] : Colors.white24, size: isSelected ? 18 : 14),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  item['name'],
                                                  style: TextStyle(
                                                    color: isSelected ? Colors.white : Colors.white38,
                                                    fontSize: isSelected ? 16 : 13,
                                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                // TÜR TEKERLEĞİ
                                Expanded(
                                  child: ListWheelScrollView.useDelegate(
                                    itemExtent: 50,
                                    physics: const FixedExtentScrollPhysics(),
                                    diameterRatio: 1.5,
                                    onSelectedItemChanged: (index) {
                                      setState(() {
                                        selectedGenreIndex = index;
                                      });
                                    },
                                    childDelegate: ListWheelChildBuilderDelegate(
                                      childCount: genres.length,
                                      builder: (context, index) {
                                        final item = genres[index];
                                        final isSelected = index == selectedGenreIndex;
                                        return AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          alignment: Alignment.center,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(item['icon'], color: isSelected ? item['color'] : Colors.white24, size: isSelected ? 18 : 14),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  item['name'],
                                                  style: TextStyle(
                                                    color: isSelected ? Colors.white : Colors.white38,
                                                    fontSize: isSelected ? 16 : 13,
                                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 10,
                            shadowColor: themeColor.withValues(alpha: 0.5),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            final selection = "${moods[selectedMoodIndex]['name']} - ${genres[selectedGenreIndex]['name']}";
                            _handleOfflineAutoPlaylist(selection, themeColor);
                          },
                          child: const Text('Otonom Listeyi Başlat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }
  
  // 🎯 SİBER HAMLE: Çevrimdışı Kütüphane İçin Sanatçıya Özel Otonom Liste Menüsü
  void _showArtistAutoPlaylistDialog(BuildContext context, Color themeColor) {
    if (_playlist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Kütüphanenizde henüz şarkı bulunmuyor!'),
        backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
      ));
      return;
    }

    // 1. Kütüphanedeki tüm sanatçıları tara ve sıklıklarını hesapla
    final Map<String, int> artistCounts = {};
    for (var song in _playlist) {
      String rawArtist = (song.artist ?? '').trim();
      if (rawArtist.isEmpty || rawArtist.toLowerCase() == '<unknown>' || rawArtist.toLowerCase() == 'unknown') {
        if (song.title != null && song.title!.contains(' - ')) {
          rawArtist = song.title!.split(' - ')[0].trim();
        }
      }
      if (rawArtist.isNotEmpty && rawArtist.toLowerCase() != '<unknown>' && rawArtist.toLowerCase() != 'unknown') {
        // Düet/ortaklık ayraçlarını bölerek ana sanatçıları tespit et
        final parts = rawArtist.split(RegExp(r'\s*(,|&|x|/|\+|feat\.?|ft\.?|ile)\s*', caseSensitive: false));
        for (var p in parts) {
          final trimmed = p.trim();
          if (trimmed.length > 1 && trimmed.toLowerCase() != 'feat' && trimmed.toLowerCase() != 'ft') {
            artistCounts[trimmed] = (artistCounts[trimmed] ?? 0) + 1;
          }
        }
      }
    }

    final sortedArtists = artistCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final TextEditingController searchCtrl = TextEditingController();
    bool includeSolo = true;
    bool includeDuet = true;
    String selectedArtist = sortedArtists.isNotEmpty ? sortedArtists.first.key : '';
    if (selectedArtist.isNotEmpty) {
      searchCtrl.text = selectedArtist;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final query = searchCtrl.text.trim().toLowerCase();
            final filteredArtists = query.isEmpty
                ? sortedArtists.take(16).toList()
                : sortedArtists
                    .where((e) => e.key.toLowerCase().contains(query))
                    .take(16)
                    .toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: 520,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border(top: BorderSide(color: Colors.pinkAccent.withValues(alpha: 0.6), width: 2)),
                  boxShadow: [
                    BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.15), blurRadius: 30, spreadRadius: 4),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Üst Tutamaç (Handle)
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 15, bottom: 12),
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        // Başlık
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mic_external_on_rounded, color: Colors.pinkAccent, size: 26),
                            SizedBox(width: 10),
                            Text(
                              'SANATÇI OTONOM MOTORU',
                              style: TextStyle(
                                color: Colors.pinkAccent,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Center(
                          child: Text(
                            'Kütüphanendeki sanatçının solo ve düet parçalarını otonom derle',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Sanatçı Arama / Yazma Kutusu
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
                            ),
                            child: TextField(
                              controller: searchCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              onChanged: (val) {
                                setSheetState(() {
                                  selectedArtist = val.trim();
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Sanatçı adı ara veya yazın...',
                                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                                prefixIcon: const Icon(Icons.search_rounded, color: Colors.pinkAccent, size: 20),
                                suffixIcon: searchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                                        onPressed: () {
                                          setSheetState(() {
                                            searchCtrl.clear();
                                            selectedArtist = '';
                                          });
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Hızlı Sanatçı Çipleri Başlığı
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'KÜTÜPHANENDEN ÖNERİLENLER',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Sanatçı Çipleri (Wrap/Scrollable)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: filteredArtists.isEmpty
                                ? Center(
                                    child: Text(
                                      searchCtrl.text.trim().isNotEmpty
                                          ? '"${searchCtrl.text.trim()}" için özel arama yapılacak'
                                          : 'Kütüphanede sanatçı bulunamadı',
                                      style: const TextStyle(color: Colors.white38, fontSize: 13),
                                    ),
                                  )
                                : SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: filteredArtists.map((entry) {
                                        final isSel = selectedArtist.toLowerCase() == entry.key.toLowerCase();
                                        return InkWell(
                                          onTap: () {
                                            setSheetState(() {
                                              selectedArtist = entry.key;
                                              searchCtrl.text = entry.key;
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(20),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                            decoration: BoxDecoration(
                                              color: isSel
                                                  ? Colors.pinkAccent.withValues(alpha: 0.25)
                                                  : Colors.white.withValues(alpha: 0.05),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: isSel
                                                    ? Colors.pinkAccent
                                                    : Colors.white.withValues(alpha: 0.15),
                                                width: isSel ? 1.5 : 1,
                                              ),
                                              boxShadow: isSel
                                                  ? [
                                                      BoxShadow(
                                                        color: Colors.pinkAccent.withValues(alpha: 0.3),
                                                        blurRadius: 8,
                                                      )
                                                    ]
                                                  : null,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.person_rounded,
                                                  size: 14,
                                                  color: isSel ? Colors.pinkAccent : Colors.white70,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  entry.key,
                                                  style: TextStyle(
                                                    color: isSel ? Colors.white : Colors.white70,
                                                    fontSize: 12,
                                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: isSel
                                                        ? Colors.pinkAccent.withValues(alpha: 0.6)
                                                        : Colors.white12,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    '${entry.value}',
                                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                          ),
                        ),
                        // Solo & Düet Seçim Çipleri
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    if (!includeSolo && !includeDuet) return;
                                    setSheetState(() {
                                      includeSolo = !includeSolo;
                                      if (!includeSolo && !includeDuet) includeDuet = true;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: includeSolo ? Colors.cyanAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: includeSolo ? Colors.cyanAccent : Colors.white24),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(includeSolo ? Icons.check_circle_rounded : Icons.radio_button_unchecked, color: includeSolo ? Colors.cyanAccent : Colors.white38, size: 16),
                                        const SizedBox(width: 6),
                                        const Text('👑 Solo Eserler', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    if (!includeSolo && !includeDuet) return;
                                    setSheetState(() {
                                      includeDuet = !includeDuet;
                                      if (!includeSolo && !includeDuet) includeSolo = true;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: includeDuet ? Colors.purpleAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: includeDuet ? Colors.purpleAccent : Colors.white24),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(includeDuet ? Icons.check_circle_rounded : Icons.radio_button_unchecked, color: includeDuet ? Colors.purpleAccent : Colors.white38, size: 16),
                                        const SizedBox(width: 6),
                                        const Text('🤝 Düet & Feat', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Başlat Butonu
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedArtist.isNotEmpty ? Colors.pinkAccent : Colors.white12,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: selectedArtist.isNotEmpty ? 8 : 0,
                              shadowColor: Colors.pinkAccent.withValues(alpha: 0.5),
                            ),
                            onPressed: selectedArtist.isNotEmpty
                                ? () {
                                    Navigator.pop(context);
                                    _handleArtistAutoPlaylist(
                                      selectedArtist,
                                      includeSolo,
                                      includeDuet,
                                      themeColor,
                                    );
                                  }
                                : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.rocket_launch_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  selectedArtist.isNotEmpty
                                      ? '"$selectedArtist" Otonom Listesini Başlat'
                                      : 'Sanatçı Seçin',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🎯 SİBER HAMLE: Sanatçıya Özel Otonom Liste Motorunu Çalıştırma
  void _handleArtistAutoPlaylist(
    String artistQuery,
    bool includeSolo,
    bool includeDuet,
    Color themeColor,
  ) {
    if (_playlist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Hata: Kütüphanenizde hiç şarkı yok!'),
        backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
      ));
      return;
    }

    final cleanQuery = artistQuery.trim();
    if (cleanQuery.isEmpty) return;

    final escaped = RegExp.escape(cleanQuery);
    final artistRegex = RegExp(r'(^|[\s\(\[\-\_\,\.\&])' + escaped + r'($|[\s\)\]\-\_\,\.\&])', caseSensitive: false);
    final duetRegex = RegExp(r'\b(feat\.?|ft\.?|&|x|\+|ile|düet|duet)\b', caseSensitive: false);

    List<SongModel> soloMatches = [];
    List<SongModel> duetMatches = [];

    for (var song in _playlist) {
      final title = (song.title ?? '').trim();
      final artist = (song.artist ?? '').trim();
      final name = (song.name ?? '').trim();
      final combined = '$title $artist $name';

      final isMatch = artistRegex.hasMatch(combined) || combined.toLowerCase().contains(cleanQuery.toLowerCase());
      if (isMatch) {
        final isDuet = duetRegex.hasMatch(combined);
        if (isDuet) {
          duetMatches.add(song);
        } else {
          soloMatches.add(song);
        }
      }
    }

    List<SongModel> finalSongs = [];
    if (includeSolo) finalSongs.addAll(soloMatches);
    if (includeDuet) finalSongs.addAll(duetMatches);

    if (finalSongs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('⚠️ Kütüphanenizde "$cleanQuery" sanatçısına ait parça bulunamadı.'),
        backgroundColor: Colors.amber.shade900,
      ));
      return;
    }

    setState(() {
      _emergentPlaylist = finalSongs;
      _isEmergentMode = true;
      _waveType = '$cleanQuery Otonom';
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🎙️ "$cleanQuery" Otonom Listesi hazırlandı (${finalSongs.length} şarkı: ${soloMatches.length} solo, ${duetMatches.length} düet)!'),
      backgroundColor: Colors.pinkAccent.withValues(alpha: 0.85),
      duration: const Duration(seconds: 4),
    ));

    _playSong(finalSongs[0]);
  }
  
  void _showIPSettingsDialog(Color themeColor) async {
    String currentIP = await SiberIPService.getMasterIP();
    TextEditingController ipController = TextEditingController(text: currentIP);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.black87,
            title: Row(
              children: [
                Icon(Icons.router_rounded, color: themeColor),
                const SizedBox(width: 8),
                const Text('Masaüstü Bağlantı IP', style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
            content: TextField(
              controller: ipController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'PC\'nin Yerel IP Adresi',
                labelStyle: TextStyle(color: themeColor.withValues(alpha: 0.7)),
                hintText: 'Örn: 192.168.1.55',
                hintStyle: const TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: themeColor.withValues(alpha: 0.5))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: themeColor)),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                onPressed: () async {
                  await SiberIPService.setMasterIP(ipController.text);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('IP Adresi güncellendi: ${ipController.text}'),
                      backgroundColor: Colors.green,
                    ));
                  }
                },
                child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildNeonButton({
    required IconData icon,
    required String label,
    required Color themeColor,
    required VoidCallback onPressed,
    VoidCallback? onLongPress,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: themeColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              onLongPress: onLongPress,
              splashColor: themeColor.withValues(alpha: 0.2),
              highlightColor: themeColor.withValues(alpha: 0.1),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    Icon(icon, color: themeColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: themeColor.withValues(alpha: 0.6), size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }


  // 🎯 SİBER HAMLE: Çevrimdışı (İndirilenler) İçin Otonom Liste Motoru
  // 🎯 SİBER HAMLE: Çevrimdışı (İndirilenler) İçin Gelişmiş Otonom Liste Motoru
  void _handleOfflineAutoPlaylist(String selection, Color themeColor) {
    if (_playlist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Hata: Cihazınızda hiç şarkı yok!'),
        backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
      ));
      return;
    }

    // Seçim formatı: 'Melankolik - Türkçe Pop'
    final parts = selection.split(' - ');
    final mood = parts.isNotEmpty ? parts[0].trim().toLowerCase() : '';
    final genre = parts.length > 1 ? parts[1].trim().toLowerCase() : '';

    List<SongModel> matchedSongs = [];
    List<SongModel> secondarySongs = [];

    for (var song in _playlist) {
      final text = '${song.title ?? ''} ${song.artist ?? ''} ${song.name} ${song.path}'.toLowerCase();
      bool moodMatch = false;
      bool genreMatch = false;

      // 1. Ruh Hali Analizi
      if (mood.contains('melankolik') || mood.contains('efk') || mood.contains('hüzün')) {
        moodMatch = text.contains('slow') || text.contains('akustik') || text.contains('hüzün') || text.contains('efkar') || text.contains('damar') || text.contains('cover') || text.contains('sad');
      } else if (mood.contains('enerjik') || mood.contains('kopmalık') || mood.contains('motivasyon') || mood.contains('isyank')) {
        moodMatch = text.contains('remix') || text.contains('bass') || text.contains('beat') || text.contains('drill') || text.contains('hızlı') || text.contains('rock') || text.contains('rap') || text.contains('metal') || text.contains('phonk');
      } else if (mood.contains('rahatlat') || mood.contains('odak') || mood.contains('uyku')) {
        moodMatch = text.contains('lofi') || text.contains('chill') || text.contains('piyano') || text.contains('klasik') || text.contains('akustik') || text.contains('sakin') || text.contains('enstrümantal') || text.contains('instrumental');
      } else if (mood.contains('nostalji')) {
        moodMatch = text.contains('90') || text.contains('80') || text.contains('eski') || text.contains('nostalji') || text.contains('klasik') || text.contains('retro') || text.contains('özgün');
      }

      // 2. Müzik Türü Analizi
      if (genre.contains('pop')) {
        genreMatch = text.contains('pop') || text.contains('hit') || text.contains('tarkan') || text.contains('edis') || text.contains('hadise') || text.contains('gülşen') || text.contains('murat boz');
      } else if (genre.contains('arabesk')) {
        genreMatch = text.contains('arabesk') || text.contains('damar') || text.contains('müslüm') || text.contains('ferdi') || text.contains('azer') || text.contains('bergen') || text.contains('tatlıses');
      } else if (genre.contains('rap')) {
        genreMatch = text.contains('rap') || text.contains('hiphop') || text.contains('trap') || text.contains('drill') || text.contains('beat') || text.contains('uzi') || text.contains('ceza') || text.contains('sagopa') || text.contains('motive');
      } else if (genre.contains('rock') || genre.contains('metal')) {
        genreMatch = text.contains('rock') || text.contains('metal') || text.contains('duman') || text.contains('manga') || text.contains('mor ve ötesi') || text.contains('şebnem');
      } else if (genre.contains('türkü') || genre.contains('anadolu')) {
        genreMatch = text.contains('türkü') || text.contains('bağlama') || text.contains('saz') || text.contains('ozan') || text.contains('neşet') || text.contains('barış manço');
      } else if (genre.contains('elektronik')) {
        genreMatch = text.contains('edm') || text.contains('remix') || text.contains('bass') || text.contains('phonk') || text.contains('club') || text.contains('synthwave');
      } else if (genre.contains('akustik')) {
        genreMatch = text.contains('akustik') || text.contains('gitar') || text.contains('cover') || text.contains('unplugged');
      }

      if (moodMatch && genreMatch) {
        matchedSongs.add(song);
      } else if (moodMatch || genreMatch) {
        secondarySongs.add(song);
      }
    }

    List<SongModel> finalList = [...matchedSongs, ...secondarySongs];
    if (finalList.isEmpty) {
      finalList = List.from(_playlist)..shuffle();
      finalList = finalList.take(15).toList();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Akıllı Mix: '$selection' için en uyumlu şarkılar harmanlandı!"),
        backgroundColor: themeColor.withValues(alpha: 0.8),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('🎵 "$selection" listesi hazırlandı (${finalList.length} şarkı)!'),
        backgroundColor: themeColor.withValues(alpha: 0.8),
      ));
    }

    setState(() {
      _emergentPlaylist = finalList;
      _isEmergentMode = true;
      _waveType = selection;
    });

    _playSong(finalList[0]);
  }

  // 🎯 SİBER HAMLE: Otonom Listeyi Kalıcı Olarak Mühürleme (Kaydetme)
  void _saveEmergentPlaylist(Color themeColor) {
    if (_emergentPlaylist.isEmpty) return;
    
    final TextEditingController tc = TextEditingController(text: '$_waveType Mix');
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: themeColor.withValues(alpha: 0.5)),
          ),
          title: Text('OTONOM LİSTEYİ MÜHÜRLE',
              style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: tc,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Bir liste adı girin...',
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepPurple)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Liste adı boş olamaz!';
                if (!RegExp(r'^[a-zA-Z0-9 ğüşöçİĞÜŞÖÇ]+$').hasMatch(value)) return 'Özel karakter kullanılamaz!';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor.withValues(alpha: 0.5),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final pName = tc.text.trim();
                  if (pName.isNotEmpty) {
                    await _playlistService.createPlaylist(pName);
                    for (var song in _emergentPlaylist) {
                      if (song.path != null) {
                        await _playlistService.addSongToPlaylist(pName, song.path!);
                      }
                    }
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("'$pName' başarıyla oluşturuldu!"),
                        backgroundColor: Colors.greenAccent,
                      ));
                      setState(() {
                        _isEmergentMode = false;
                      });
                      await _toggleLibraryView(pName);
                    }
                  }
                }
              },
              child: const Text('Mühürle', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppBar(Color themeColor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ÖZSES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.0,
                    shadows: [
                      Shadow(
                        color: themeColor.withValues(alpha: 0.9),
                        blurRadius: 16,
                      ),
                      Shadow(
                        color: themeColor.withValues(alpha: 0.4),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // 🎯 SİBER HAMLE: Canlı Geri Sayım Göstergesi (Sadece aktifse görünür)
          ValueListenableBuilder<int>(
            valueListenable: globalSleepTimer,
            builder: (context, remainingSeconds, child) {
              if (remainingSeconds <= 0) return const SizedBox.shrink();
              final minutes = (remainingSeconds / 60).floor();
              final seconds = remainingSeconds % 60;
              return Container(
                margin: const EdgeInsets.only(right: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.8), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      blurRadius: 25,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Row(
                      children: [
                        const Icon(Icons.timer,
                            color: Colors.redAccent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}",
                          style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          // 🧭 TEK TUŞLA KEŞFET BUTONU
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 250),
                  reverseTransitionDuration: const Duration(milliseconds: 200),
                  pageBuilder: (context, animation, secondaryAnimation) => DiscoverScreen(
                    themeColor: themeColor,
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: themeColor.withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.25),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.explore_rounded, color: themeColor, size: 17),
                  const SizedBox(width: 6),
                  const Text(
                    'KEŞFET',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 🍃 SADE / ⚡ SİBER MOD BUTONU
          ValueListenableBuilder<bool>(
            valueListenable: SiberThemeService.instance.isMinimalMode,
            builder: (context, isMinimal, _) {
              return GestureDetector(
                onTap: () {
                  SiberThemeService.instance.toggleMinimalMode();
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            !isMinimal ? Icons.eco_rounded : Icons.bolt_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            !isMinimal
                                ? '🍃 Sade Mod Aktif'
                                : '✨ Parlak Mod Aktif',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      backgroundColor: !isMinimal ? const Color(0xFF1E293B) : (themeColor == Colors.black ? Colors.deepPurple : themeColor),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isMinimal
                        ? const Color(0xFF1E1E1E)
                        : themeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isMinimal ? Colors.white24 : themeColor.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                    boxShadow: isMinimal
                        ? null
                        : [
                            BoxShadow(
                              color: themeColor.withValues(alpha: 0.25),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMinimal ? Icons.eco_rounded : Icons.auto_awesome_rounded,
                        color: isMinimal ? Colors.white70 : themeColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isMinimal ? 'SADE' : 'PARLAK',
                        style: TextStyle(
                          color: isMinimal ? Colors.white70 : themeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 🎵 Çalma Listesine Ekleme Modülü (Hazır Listeleri Gösterir)
  void _showAddToPlaylistDialog(String songPath) {
    final themeColor = SiberThemeService.instance.currentThemeColor.value;
    final song = _playlist.firstWhere(
      (s) => s.path == songPath,
      orElse: () => SongModel(name: '', path: songPath, duration: 0, title: ''),
    );
    final songTitle = _getSafeSongName(song);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF10131E),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                border: Border.all(color: themeColor.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.15),
                    blurRadius: 25,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sürükleme Çizgisi
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Başlık ve Şarkı Adı
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.playlist_add_rounded, color: themeColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Çalma Listesine Ekle',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (songTitle.isNotEmpty)
                              Text(
                                songTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Yeni Liste Oluştur Butonu
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.pop(context);
                      _showCreatePlaylistAndAddDialog(songPath, themeColor);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: themeColor.withValues(alpha: 0.4), width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline_rounded, color: themeColor, size: 22),
                          const SizedBox(width: 12),
                          Text(
                            'Yeni Çalma Listesi Oluştur',
                            style: TextStyle(
                              color: themeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Mevcut Listeler Başlığı
                  const Text(
                    'Mevcut Listelerin',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Listeler
                  Flexible(
                    child: FutureBuilder<List<String>>(
                      future: _playlistService.getAllPlaylistNames(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final playlists = snapshot.data ?? [];
                        if (playlists.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.queue_music_rounded, color: Colors.white24, size: 36),
                                  SizedBox(height: 8),
                                  Text(
                                    'Henüz oluşturulmuş bir liste yok',
                                    style: TextStyle(color: Colors.white38, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          itemCount: playlists.length,
                          separatorBuilder: (_, __) => Divider(
                            color: Colors.white.withValues(alpha: 0.05),
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final pName = playlists[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.queue_music_rounded, color: themeColor, size: 20),
                              ),
                              title: Text(
                                pName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: Icon(
                                Icons.add_circle_rounded,
                                color: themeColor.withValues(alpha: 0.8),
                                size: 22,
                              ),
                              onTap: () async {
                                await _playlistService.addSongToPlaylist(pName, songPath);
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text("Şarkı '$pName' listesine eklendi!"),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.black.withValues(alpha: 0.9),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ➕ Yeni Çalma Listesi Oluşturup Şarkıyı Ekleme Penceresi
  void _showCreatePlaylistAndAddDialog(String songPath, Color themeColor) {
    final TextEditingController nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141A29),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: themeColor.withValues(alpha: 0.4)),
          ),
          title: Row(
            children: [
              Icon(Icons.playlist_add_rounded, color: themeColor, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Yeni Çalma Listesi',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: TextField(
            controller: nameCtrl,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Liste adı girin (Örn: Favorilerim)...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: themeColor.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: themeColor, width: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final pName = nameCtrl.text.trim();
                if (pName.isNotEmpty) {
                  await _playlistService.createPlaylist(pName);
                  await _playlistService.addSongToPlaylist(pName, songPath);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
                            const SizedBox(width: 10),
                            Expanded(child: Text("'$pName' oluşturuldu ve şarkı eklendi!")),
                          ],
                        ),
                        backgroundColor: Colors.black.withValues(alpha: 0.9),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('Oluştur & Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // 🎯 SİBER HAMLE: Şarkı Silme Operasyonu (Hem kaydırarak hem 3 noktadan)
  Future<void> _deleteSong(SongModel song, String safePath) async {
    // 1. UI'dan anında yok et (Hız için)
    setState(() {
      _playlist.remove(song);
      if (_isEmergentMode) _emergentPlaylist.remove(song);
    });

    // 🎯 SİBER HAMLE: Oynatıcı kuyruğundan da otonom sök at!
    final queueItems = audioHandler.queue.value;
    for (var item in queueItems) {
      if (item.id == safePath) {
        audioHandler.removeQueueItem(item);
      }
    }

    // 2. Arka planda mühürleri sök (Eğer bir playlist içindeysek)
    if (_playlistController.currentPlaylistName != null) {
      await _playlistService.removeSongFromPlaylist(
        _playlistController.currentPlaylistName!,
        safePath,
      );
    }

    // 🎯 SİBER HAMLE: Şarkı silinince kalıcı arşivden de kaldır
    final globalSongs = await loadGlobalLibrarySongs();
    globalSongs.removeWhere((s) => s.path == safePath);
    await saveGlobalLibrarySongs(globalSongs);
    try {
      final file = File(safePath);
      if (await file.exists()) await file.delete();
      final lrcFile = File(safePath.replaceAll(RegExp(r'\.[^.]+$'), '.lrc'));
      if (await lrcFile.exists()) await lrcFile.delete();
    } catch (e) {}

    if (!mounted) return; // 🛡️ SİBER KALKAN: Güvenli çıkış
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_getSafeSongName(song)} sistemden söküldü!'),
        backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 🎯 SİBER HAMLE: Şarkıyı Aktif Kuyruğa (Play Next / Add to Queue) Ekleme
  Future<void> _addSongToQueue(SongModel song, bool playNext) async {
    final safePath = song.path ?? 'bilinmeyen_yol';
    if (safePath == 'bilinmeyen_yol') return;

    final mediaItem = MediaItem(
      id: safePath,
      album: 'ÖZSES Arşivi',
      title: _getSafeSongName(song),
      artist: 'Victus V7',
    );

    if (playNext) {
      // Sıradakine ekle (Mevcut indexin 1 fazlası)
      int nextIndex = (audioHandler.playbackState.value.queueIndex ?? 0) + 1;
      await audioHandler.insertQueueItem(nextIndex, mediaItem);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${mediaItem.title} sıradakine mühürlendi!'),
            backgroundColor: Colors.cyanAccent,
            duration: const Duration(seconds: 1)));
      }
    } else {
      // En sona ekle
      await audioHandler.addQueueItem(mediaItem);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${mediaItem.title} kuyruğun sonuna mühürlendi!'),
            backgroundColor: Colors.greenAccent,
            duration: const Duration(seconds: 1)));
      }
    }
  }

  Widget _buildSongTile(SongModel song, bool isSelected, Color themeColor) {
    final safePath = song.path ?? 'bilinmeyen_yol';
    final safeName = _getSafeSongName(song);
    final bool isFav = _favoritePaths.contains(safePath);

    final offlineProgress = song.videoId != null ? OfflineCacheService().downloadProgress.value[song.videoId] : null;
    bool isDownloading = safePath.startsWith('downloading:') || offlineProgress != null;
    String videoId = isDownloading ? (song.videoId ?? (safePath.startsWith('downloading:') ? safePath.substring(12) : '')) : '';
    Map<String, dynamic>? dTask = isDownloading ? _downloadingTasks[videoId] : null;
    if (dTask == null && offlineProgress != null) {
      dTask = {
        'percent': '%${(offlineProgress * 100).toInt()}',
        'mb': 'İndirilen',
      };
    }

    return Slidable(
      key: ValueKey(safePath.isNotEmpty ? safePath : song.hashCode.toString()),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: isDownloading ? null : (context) => _deleteSong(song, safePath),
            backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
            icon: Icons.delete_sweep,
            label: 'Sök At',
          ),
        ],
      ),
      child: Opacity(
        opacity: isDownloading ? 0.4 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutExpo,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // 🎯 Daha geniş aralık, kart görünümü
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? [
                      themeColor.withValues(alpha: (0.2 * _neonScale).clamp(0.0, 1.0)),
                      Colors.black.withValues(alpha: 0.8),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.6),
                    ],
            ),
            borderRadius: BorderRadius.circular(20), // 🎯 Daha yuvarlak köşeler
            border: Border.all(
              color: isSelected
                  ? themeColor.withValues(alpha: (0.6 * _neonScale).clamp(0.0, 1.0))
                  : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 1.5 + (_neonScale > 1.0 ? _neonScale - 1.0 : 0) : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: themeColor.withValues(alpha: (0.2 * _neonScale).clamp(0.0, 1.0)),
                      blurRadius: 15 * _neonScale,
                      spreadRadius: 2 * _neonScale,
                    )
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
                onTap: isDownloading ? null : () => _playSong(song),
                splashColor: themeColor.withValues(alpha: 0.3),
                highlightColor: themeColor.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // 🎯 SİBER KAPAK VEYA İKON ALANI
                      SongCoverArtTile(
                        song: song,
                        isSelected: isSelected,
                        isPlaying: _isPlaying,
                        themeColor: themeColor,
                        size: 55,
                      ),
                      const SizedBox(width: 16),
                      // 🎯 ŞARKI BİLGİLERİ
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              safeName,
                              style: TextStyle(
                                color: isSelected ? themeColor : Colors.white,
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (isDownloading && dTask != null) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "📥 İniyor: ${dTask['percent']}  •  ${dTask['mb']}",
                                      style: const TextStyle(
                                        color: Colors.cyanAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  // 🛑 İPTAL BUTONU
                                  GestureDetector(
                                    onTap: () {
                                      if (song.videoId != null) {
                                        OfflineCacheService().cancelDownload(song.videoId!);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                                      ),
                                      child: const Text(
                                        '× İptal',
                                        style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: offlineProgress ?? (double.tryParse(dTask['percent']?.toString().replaceAll('%', '') ?? '0') ?? 0) / 100.0,
                                  minHeight: 3.5,
                                  color: Colors.cyanAccent,
                                  backgroundColor: Colors.white10,
                                ),
                              ),
                            ]
                            else
                              Text(
                                "Arşiv • V7", // Yerel müzik olduğu için
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // 🎯 SEÇENEKLER (3 NOKTA)
                      if (!isDownloading)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded,
                              color: isSelected ? themeColor : Colors.white54),
                          color: Colors.black.withValues(alpha: 0.9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: themeColor.withValues(alpha: 0.5)),
                          ),
                          onSelected: (value) {
                            if (value == 'add_playlist') _showAddToPlaylistDialog(safePath);
                            else if (value == 'favorite') _toggleFavorite(song);
                            else if (value == 'delete') _deleteSong(song, safePath);
                            else if (value == 'play_next') _addSongToQueue(song, true);
                            else if (value == 'add_queue') _addSongToQueue(song, false);
                          },
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem(
                              value: 'favorite',
                              child: Row(
                                children: [
                                  Icon(isFav ? Icons.favorite : Icons.favorite_border_rounded,
                                      color: Colors.redAccent, size: 20),
                                  const SizedBox(width: 12),
                                  Text(isFav ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'play_next',
                              child: Row(
                                children: [
                                  Icon(Icons.skip_next_rounded, color: themeColor, size: 20),
                                  const SizedBox(width: 12),
                                  const Text('Sıradakini Çal', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'add_queue',
                              child: Row(
                                children: [
                                  Icon(Icons.queue_music_rounded, color: themeColor, size: 20),
                                  const SizedBox(width: 12),
                                  const Text('Kuyruğa Ekle', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'add_playlist',
                              child: Row(
                                children: [
                                  const Icon(Icons.playlist_add_rounded, color: Colors.cyanAccent, size: 20),
                                  const SizedBox(width: 12),
                                  const Text("Playlist'e Ekle", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 20),
                                  SizedBox(width: 12),
                                  Text('Sök At (Sil)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
  }

  void _showPlaylistSelectorBottomSheet(Color themeColor) async {
    final playlists = await _playlistService.getAllPlaylistNames();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        List<String> currentPlaylists = List.from(playlists);

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.70,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F121E),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border(top: BorderSide(color: themeColor.withValues(alpha: 0.6), width: 2)),
                boxShadow: [
                  BoxShadow(color: themeColor.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 5)
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 15, bottom: 15),
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.library_music_rounded, color: themeColor, size: 28),
                                const SizedBox(width: 10),
                                Text('ÇALMA LİSTELERİ',
                                    style: TextStyle(
                                        color: themeColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        letterSpacing: 1.2)),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.cyanAccent.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5))
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.add_rounded, color: Colors.cyanAccent),
                                tooltip: 'Yeni Playlist Oluştur',
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showPlaylistTypeSelectionDialog(context, themeColor);
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Divider(color: Colors.white24, thickness: 1),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          shrinkWrap: true,
                          children: [
                            _buildPlaylistTile(
                              title: 'Ana Arşiv (Tüm Müzikler)',
                              icon: Icons.all_inclusive_rounded,
                              color: themeColor,
                              isCurrent: _playlistController.currentPlaylistName == null && !_isEmergentMode,
                              onTap: () {
                                Navigator.pop(context);
                                _toggleLibraryView(null);
                              }
                            ),
                            const SizedBox(height: 10),
                            ...currentPlaylists.map((pName) {
                              final isCurrent = _playlistController.currentPlaylistName == pName && !_isEmergentMode;
                              final isFav = pName == 'Favorilerim';
                              final isOnRepeat = pName.contains('Zirvedekiler');
                              final canDelete = !isFav && !isOnRepeat;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildPlaylistTile(
                                  title: pName,
                                  icon: isFav
                                      ? Icons.favorite
                                      : (isOnRepeat
                                          ? Icons.local_fire_department_rounded
                                          : Icons.queue_music_rounded),
                                  color: isFav
                                      ? Colors.redAccent
                                      : (isOnRepeat ? Colors.deepOrangeAccent : themeColor),
                                  isCurrent: isCurrent,
                                  onTap: () {
                                    Navigator.pop(context);
                                    _toggleLibraryView(pName);
                                  },
                                  onDelete: canDelete ? () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (dCtx) => AlertDialog(
                                        backgroundColor: const Color(0xFF141724),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5), width: 1.5),
                                        ),
                                        title: const Row(
                                          children: [
                                            Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 24),
                                            SizedBox(width: 8),
                                            Text('Listeyi Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                          ],
                                        ),
                                        content: Text(
                                          '"$pName" çalma listesini silmek istediğinizden emin misiniz?\n\n(Şarkılarınız arşivden silinmez, sadece bu liste kaldırılır.)',
                                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(dCtx, false),
                                            child: const Text('Vazgeç', style: TextStyle(color: Colors.white54)),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            onPressed: () => Navigator.pop(dCtx, true),
                                            child: const Text('Listeyi Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await _playlistService.deletePlaylist(pName);
                                      if (_playlistController.currentPlaylistName == pName) {
                                        _toggleLibraryView(null);
                                      }
                                      setSheetState(() {
                                        currentPlaylists.remove(pName);
                                      });
                                      Fluttertoast.showToast(
                                        msg: '🗑️ "$pName" listesi silindi',
                                        backgroundColor: Colors.redAccent,
                                      );
                                    }
                                  } : null,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlaylistTile({
    required String title,
    required IconData icon,
    required Color color,
    required bool isCurrent,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isCurrent ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? color.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.1),
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: isCurrent ? color : Colors.white70, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isCurrent ? Colors.white : Colors.white70,
                        fontSize: 15,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCurrent) ...[
                    Icon(Icons.check_circle_rounded, color: color, size: 22),
                    const SizedBox(width: 8),
                  ],
                  if (onDelete != null)
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- DİALOG METOTLARI (Ayarlar Paneli İçin) ---
  // 🎯 SİBER HAMLE: Gelişmiş Uyku Zamanlayıcı (Müzik Çalardaki Gibi Premium Bottom Sheet)
  void _showSiberSleepBottomSheet(Color themeColor) {
    final TextEditingController tc = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.55,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border(top: BorderSide(color: themeColor.withValues(alpha: 0.5), width: 2)),
              boxShadow: [
                BoxShadow(color: themeColor.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 5)
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 20),
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.nights_stay_rounded, color: themeColor, size: 28),
                        const SizedBox(width: 10),
                        Text('UYKU ZAMANLAYICI',
                            style: TextStyle(
                                color: themeColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          _buildSleepCard(context, '15 Dakika', 'Hafif kestirme', 15, themeColor),
                          const SizedBox(height: 10),
                          _buildSleepCard(context, '30 Dakika', 'Standart uyku', 30, themeColor),
                          const SizedBox(height: 10),
                          _buildSleepCard(context, '60 Dakika', 'Derin uyku döngüsü', 60, themeColor),
                          const SizedBox(height: 10),
                          _buildSleepCard(context, 'Uyku Modunu İptal Et', 'Zamanlayıcıyı durdurur', 0, Colors.redAccent),
                          
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(color: Colors.white24),
                          ),
                          
                          // Manuel Giriş
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.timer_rounded, color: themeColor),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: tc,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      hintText: 'Manuel dakika gir...',
                                      hintStyle: TextStyle(color: Colors.white38),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.play_arrow_rounded, color: themeColor, size: 30),
                                  onPressed: () {
                                    final int? minutes = int.tryParse(tc.text);
                                    if (minutes != null && minutes > 0) {
                                      startSleepTimer(minutes);
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Sistem $minutes dakika sonra kapanacak.'), backgroundColor: themeColor),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSleepCard(BuildContext context, String title, String subtitle, int minutes, Color color) {
    return InkWell(
      onTap: () {
        startSleepTimer(minutes);
        if (minutes > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sistem $minutes dakika sonra kapanacak.'), backgroundColor: color),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Zamanlayıcı iptal edildi.'), backgroundColor: Colors.redAccent),
          );
        }
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(minutes == 0 ? Icons.alarm_off_rounded : Icons.access_time_rounded, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24)
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, Color themeColor) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: themeColor.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(color: themeColor.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5)
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note_rounded, color: themeColor, size: 30),
                        const SizedBox(width: 10),
                        Text('YENİ PLAYLİST', style: TextStyle(color: themeColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Form(
                      key: formKey,
                      child: TextFormField(
                        controller: controller,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Liste adı...',
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: themeColor, width: 1.5),
                          ),
                          errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Liste adı boş olamaz usta!';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9 ğüşöçİĞÜŞÖÇ]+$').hasMatch(value)) {
                            return 'Özel karakter kullanılamaz!';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('İptal', style: TextStyle(color: Colors.white54)),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final newName = controller.text.trim();
                              final existingPlaylists = await _playlistService.getAllPlaylistNames();
                              if (existingPlaylists.contains(newName)) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.error_outline, color: Colors.white),
                                          const SizedBox(width: 10),
                                          Expanded(child: Text("Hata: '$newName' adında bir liste zaten mevcut!", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                        ],
                                      ),
                                      backgroundColor: Colors.redAccent.shade700,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      margin: const EdgeInsets.all(10),
                                    ),
                                  );
                                }
                                return; // DO NOT SAVE, JUST RETURN
                              }
                              await _playlistService.createPlaylist(newName);
                              if (context.mounted) {
                                Navigator.pop(context);
                                _toggleLibraryView(newName);
                              }
                            }
                          },
                          child: const Text('Oluştur', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🎯 SİBER HAMLE: Alttan Açılan Kuyruk Paneli (Bottom Sheet)
  void _showQueueBottomSheet(Color themeColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: themeColor.withValues(alpha: 0.5), width: 1),
      ),
      builder: (context) {
        return StreamBuilder<List<MediaItem>>(
          stream: audioHandler.queue,
          builder: (context, snapshot) {
            final queue = snapshot.data ?? [];
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 5),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.queue_music, color: themeColor, size: 20),
                      const SizedBox(width: 8),
                      Text('ÇALMA KUYRUĞU (${queue.length})',
                          style: TextStyle(
                              color: themeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10),
                if (queue.isEmpty)
                  const Expanded(
                      child: Center(
                          child: Text('Kuyruk boş usta!',
                              style: TextStyle(color: Colors.white54))))
                else
                  Expanded(
                    child: StreamBuilder<PlaybackState>(
                        stream: audioHandler.playbackState,
                        builder: (context, stateSnapshot) {
                          final currentIndex =
                              stateSnapshot.data?.queueIndex ?? -1;
                          return ReorderableListView.builder(
                            itemCount: queue.length,
                            proxyDecorator: (child, index, animation) =>
                                Material(
                                    color: Colors.transparent, child: child),
                            onReorder: (oldIndex, newIndex) {
                              if (newIndex > oldIndex) newIndex -= 1;
                              audioHandler.moveQueueItem(oldIndex, newIndex);
                            },
                            itemBuilder: (context, index) {
                              final item = queue[index];
                              final isPlaying = index == currentIndex;
                              return ListTile(
                                key: ValueKey(item
                                    .hashCode), // 🛡️ SİBER KALKAN: Reorder için eşsiz mühür şart
                                leading: isPlaying
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: MiniEqVisualizer(
                                          themeColor: themeColor,
                                          isPlaying:
                                              _isPlaying, // Şarkı durursa animasyon da dursun
                                        ),
                                      )
                                    : const Icon(Icons.music_note,
                                        color: Colors.white24),
                                title: Text(item.title,
                                    style: TextStyle(
                                        color: isPlaying
                                            ? themeColor
                                            : Colors.white,
                                        fontSize: 13,
                                        fontWeight: isPlaying
                                            ? FontWeight.bold
                                            : FontWeight.normal),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(item.artist ?? 'Bilinmeyen',
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 11)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: Colors.redAccent, size: 20),
                                  onPressed: () =>
                                      audioHandler.removeQueueItem(item),
                                ),
                                onTap: () {
                                  audioHandler.skipToQueueItem(index);
                                  audioHandler.play();
                                },
                              );
                            },
                          );
                        }),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // 🎯 SİBER HAMLE: Alttan Açılan Geçmiş (History) Paneli
  void _showHistoryBottomSheet(Color themeColor) async {
    final historyList = await HistoryService.getHistory();
    if (!mounted) return;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.black.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: themeColor.withValues(alpha: 0.5), width: 1),
        ),
        builder: (context) {
          return StatefulBuilder(builder: (context, setModalState) {
            return SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 5),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.history, color: themeColor, size: 24),
                            const SizedBox(width: 8),
                            Text('DİNLEME GEÇMİŞİ',
                                style: TextStyle(
                                    color: themeColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    letterSpacing: 1.2)),
                          ],
                        ),
                        IconButton(
                            icon: const Icon(Icons.delete_sweep,
                                color: Colors.redAccent),
                            tooltip: 'Geçmişi Sök At',
                            onPressed: () async {
                              await HistoryService.clearHistory();
                              setModalState(() => historyList.clear());
                            })
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  if (historyList.isEmpty)
                    const Expanded(
                        child: Center(
                            child: Text('Geçmiş tertemiz!',
                                style: TextStyle(color: Colors.white54))))
                  else
                    Expanded(
                      child: ListView.builder(
                          itemCount: historyList.length,
                          itemBuilder: (context, index) {
                            final item = historyList[index];
                            final mins = item.totalListenSeconds ~/ 60;
                            final secs = item.totalListenSeconds % 60;
                            return ListTile(
                              leading: Icon(Icons.music_note,
                                  color: themeColor.withValues(alpha: 0.6)),
                              title: Text(item.name,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                  '${item.playCount} Kez Mühürlendi • Toplam: $mins Dk $secs Sn',
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 11)),
                              onTap: () {
                                Navigator.pop(context);
                                final s = SongModel(
                                    name: item.name,
                                    path: item.path,
                                    duration: 0,
                                    title: item.name);
                                if (!_playlist
                                    .any((x) => x.path == item.path)) {
                                  setState(() => _playlist.insert(0, s));
                                }
                                _playSong(s);
                              },
                            );
                          }),
                    )
                ]));
          });
        });
  }

  // 🎯 SİBER HAMLE: Şarkı Adından Ruh Hali Analizi (Geçici/Emaneten)
  String _analyzeSongMoodFromName(String name) {
    final n = name.toLowerCase();
    // Efkarlı / Hüzünlü
    if (n.contains('aşk') ||
        n.contains('sevda') ||
        n.contains('gitti') ||
        n.contains('ayrılık') ||
        n.contains('hüzün') ||
        n.contains('acı') ||
        n.contains('kalp')) {
      return 'Melankolik';
    }
    // Hareketli / Enerjik
    if (n.contains('dans') ||
        n.contains('party') ||
        n.contains('club') ||
        n.contains('enerji') ||
        n.contains('hadi') ||
        n.contains('kop')) {
      return 'Enerjik';
    }
    // Rap / Sokak
    if (n.contains('sokak') ||
        n.contains('mahalle') ||
        n.contains('trap') ||
        n.contains('drill') ||
        n.contains('rap')) {
      return 'Sokak Ritmi';
    }
    // Sakin / Akustik
    if (n.contains('akustik') ||
        n.contains('unplugged') ||
        n.contains('yavaş') ||
        n.contains('sakin') ||
        n.contains('slow')) {
      return 'Akustik';
    }
    return 'Dengeli';
  }

  // 🎯 SİBER HAMLE: Siber Ses Stüdyosu (Efekt ve EQ Merkezi)
  void _showCyberStudioBottomSheet(Color themeColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SiberStudioPanel(themeColor: themeColor);
      },
    );
  }

  Widget _buildStudioCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white24)
          ],
        ),
      ),
    );
  }


  // 🎯 SİBER HAMLE: Profesyonel Şahsi Keşfet (Yapay Zeka Destekli Öneri Motoru)
  void _scanDarkZone(Color themeColor) async {
    // 1. Siber Radar Görseli
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.radar, color: Colors.purpleAccent),
            SizedBox(width: 10),
            Expanded(
                child: Text(
                    'Yapay Zeka Analizi: Dinleme geçmişin ve günün saati taranıyor...')),
          ],
        ),
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.purpleAccent, width: 1)),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      // 2. İstihbarat Verilerini Topla (Geçmiş)
      final historyList = await HistoryService.getHistory();
      final historyMap = {
        for (var item in historyList) item.path: item.playCount
      };

      // 3. Kullanıcının Favori Ruh Halini Belirle (Dinleme Süresine Göre)
      final Map<String, int> moodDurations = {};
      for (var item in historyList) {
        final mood = _analyzeSongMoodFromName(item.name);
        moodDurations[mood] =
            (moodDurations[mood] ?? 0) + item.totalListenSeconds;
      }

      String favoriteMood = 'Dengeli';
      if (moodDurations.isNotEmpty) {
        favoriteMood = moodDurations.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      // 4. Günün Saatine Göre Psikolojik Mod Belirle
      final int currentHour = DateTime.now().hour;
      String timeMood = 'Dengeli';
      if (currentHour >= 6 && currentHour < 12) {
        timeMood = 'Enerjik'; // Sabah
      } else if (currentHour >= 12 && currentHour < 18) {
        timeMood = 'Sokak Ritmi'; // Öğle
      } else if (currentHour >= 18 && currentHour < 23) {
        timeMood = 'Akustik'; // Akşam
      } else {
        timeMood = 'Melankolik'; // Gece
      }

      // 5. Arşivdeki Tüm Müzikleri Çek
      final bool wasGlobal = _playlistController.isGlobalLibrary;
      final String? previousPlaylist = _playlistController.currentPlaylistName;

      _playlistController.isGlobalLibrary = true;
      _playlistController.currentPlaylistName = null;
      final allSongs = await _playlistController.loadTargetList();

      _playlistController.isGlobalLibrary = wasGlobal;
      _playlistController.currentPlaylistName = previousPlaylist;

      if (allSongs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kütüphane boş usta! Önce sisteme müzik mühürle.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      // 6. PROFESYONEL SKORLAMA (ÖNERİ) ALGORİTMASI
      List<Map<String, dynamic>> scoredSongs = [];
      for (var song in allSongs) {
        final path = song.path ?? 'bilinmeyen_yol';
        if (path == 'bilinmeyen_yol') continue;

        double score = 0;
        final playCount = historyMap[path] ?? 0;
        final songMood = _analyzeSongMoodFromName(song.name ?? '');

        // Kriter A: Unutulmuşluk Seviyesi (En önemli etken, çünkü "Keşfet")
        if (playCount == 0) {
          score += 100; // Karanlık bölge, hiç açılmamış
        } else if (playCount < 3) {
          score += 60; // Çok az dinlenmiş
        } else if (playCount < 10) {
          score += 20; // Normal
        } else {
          score -=
              (playCount * 2); // Zaten çok dinlenen şarkıları keşfete koyma
        }

        // Kriter B: Kişisel Zevk (Kullanıcının en çok dinlediği ruh hali)
        if (songMood == favoriteMood) {
          score += 40;
        }

        // Kriter C: Günün Saatine Uyum (Biyolojik Ritme Göre)
        if (songMood == timeMood) {
          score += 30;
        }

        // Kriter D: Rastgelelik (Aynı şarkılar gelmesin diye tuzlama)
        score += (math.Random().nextInt(20));

        scoredSongs.add({'song': song, 'score': score});
      }

      // Skorlara göre listeyi büyükten küçüğe sırala
      scoredSongs.sort(
          (a, b) => (b['score'] as double).compareTo(a['score'] as double));

      // En iyi 25 şarkıyı seç (Şahsi Mix)
      List<SongModel> personalDiscoverList =
          scoredSongs.take(25).map((e) => e['song'] as SongModel).toList();

      await Future.delayed(const Duration(milliseconds: 2500)); // Analiz hissi

      if (mounted && personalDiscoverList.isNotEmpty) {
        setState(() {
          _emergentPlaylist = personalDiscoverList;
          _isEmergentMode = true; // SİBER OTONOM modunda aç
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '🎵 Şahsi Mix Hazır! Favori modun: $favoriteMood. En iyi ${personalDiscoverList.length} öneri yüklendi.'),
            backgroundColor: Colors.greenAccent.withValues(alpha: 0.8),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Keşfet yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // 🎯 SİBER HAMLE: Yeni Mühimmat Taraması (Taze Müzikler) Tetikleyicisi
  void _scanNewRecruits(Color themeColor) async {
    // 🚀 SİBER ROKET: Yağ gibi pürüzsüz 250ms Geçiş Motoru
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) => DiscoverScreen(
          themeColor: themeColor,
          onDownloadStart: _handleDownloadStart,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  // 🎯 SİBER HAMLE: Şahsi Keşfet Tercih & Kurulum Çekmecesi (Genel Keşfet Uyumlu & Ultra Şık)
  void _showPersonalSurveyDialog(Color themeColor) {
    PersonalDiscoverSetupSheet.show(
      context,
      themeColor: themeColor,
      isInitialSetup: true,
      onCompleted: () => _launchPersonalDiscover(themeColor),
    );
  }


  // 🎯 SİBER HAMLE: Şahsi Keşfeti Otonom Başlatıcı
  Future<void> _launchPersonalDiscover(Color themeColor) async {
    final prefs = await SharedPreferences.getInstance();
    final genres = prefs.getStringList('siber_personal_genres') ?? [];
    final artists = prefs.getString('siber_personal_artists') ?? '';

    // Eğer kullanıcı daha önce sistemi doldurmadıysa (ilk tık)
    if (genres.isEmpty && artists.isEmpty) {
      _showPersonalSurveyDialog(themeColor);
    } else {
      // Profil zaten mühürlüyse hiç sormadan direkt Şahsi Keşfet'e gir (Normal Keşfet Gibi)
      if (!mounted) return;
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (context, animation, secondaryAnimation) => DiscoverScreen(
            themeColor: themeColor,
            isPersonalMode: true,
            onDownloadStart: _handleDownloadStart,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }
}

// 🌊 NEON WAVE GÖRSELLEŞTİRİCİ
class NeonWaveBackground extends StatefulWidget {
  final bool isPlaying;
  final Color themeColor;
  final double neonScale;
  const NeonWaveBackground({
    super.key,
    required this.isPlaying,
    required this.themeColor,
    this.neonScale = 1.0,
  });

  @override
  State<NeonWaveBackground> createState() => _NeonWaveBackgroundState();
}

class _NeonWaveBackgroundState extends State<NeonWaveBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SiberThemeService.instance.currentThemeColor.removeListener(_onThemeChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) { final themeColor = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 🛡️ SİBER KALKAN: Çizim alanını tüm ekrana zorla yay ki boyut (NaN) hatası yok olsun!
        return SizedBox.expand(
          child: CustomPaint(
            painter: WavePainter(
              progress: _controller.value,
              isPlaying: widget.isPlaying,
              color: widget.themeColor,
              neonScale: widget.neonScale,
            ),
          ),
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final Color color;
  final double neonScale;
  WavePainter({
    required this.progress,
    required this.isPlaying,
    required this.color,
    required this.neonScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 🛡️ SİBER KALKAN: Ekran boyutları henüz çizilmemişse NaN (geçersiz sayı) hatasını kökünden engelle!
    if (size.width <= 0 || size.height <= 0) return;

    // 🎯 SİBER KALKAN: Eğer görsel efektler kapalıysa ve mod Dark (Karanlık) ise direkt çık
    if (!AudioEngine.visualEffectsEnabled && AudioEngine.darkMode == 1) return;

    bool isOcean =
        AudioEngine.visualEffectsEnabled && AudioEngine.visualMode == 1;
    bool isNight =
        !AudioEngine.visualEffectsEnabled && AudioEngine.darkMode == 0;

    final paint = Paint()
      ..color = isNight
          ? Colors.white.withValues(alpha: 0.05)
          : color.withValues(alpha: isOcean ? 0.15 : 0.3)
      ..style = isOcean ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = isOcean ? 0.0 : 3.0
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isOcean ? 30 : 15);

    final path = Path();
    final double amplitude =
        (isPlaying ? 35.0 : 8.0) * neonScale; // 🎯 GERÇEK RİTİM SIÇRAMASI!
    final double wavelength = size.width / 1.3;
    final double baseHeight = size.height *
        0.55; // 🎯 SİBER HAMLE: Dalgaları alt çubuğun arkasından kurtarıp ekranın ortasına taşıdık!

    if (wavelength <= 0) return; // Siber Güvenlik

    if (isOcean) {
      path.moveTo(0, size.height);
      path.lineTo(0, baseHeight);
    } else {
      path.moveTo(0, baseHeight);
    }

    for (double x = 0; x <= size.width; x++) {
      double y = baseHeight +
          math.sin((x / wavelength) + (progress * math.pi * 2)) * amplitude;

      // Çift dalga etkisi (Okyanus) veya Çok hafif dalga (Night)
      if (isOcean) {
        y += math.cos((x / (wavelength * 0.8)) - (progress * math.pi * 1.5)) *
            (amplitude * 0.5);
      } else if (isNight) {
        y = size.height *
                0.70 + // 🎯 Night modunu da görünür alana yukarı çektik
            math.sin((x / wavelength) + (progress * math.pi)) *
                (amplitude * 0.2); // Çok hafif
      }

      // 🛡️ SİBER KALKAN: Trigonometrik hesaplamada saçmalama olursa Android motorunun çökmesini engelle
      if (y.isNaN || y.isInfinite) continue;

      path.lineTo(x, y);
    }

    if (isOcean) {
      path.lineTo(size.width, size.height);
      path.close();
    }
    canvas.drawPath(path, paint);

    // 🎯 SİBER ÇİZGİSEL MOD: Altından geçen otonom ince ritim hattı
    if (AudioEngine.visualEffectsEnabled &&
        AudioEngine.visualMode == 0 &&
        !isOcean &&
        !isNight) {
      final paint2 = Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final path2 = Path();
      path2.moveTo(0, baseHeight);
      for (double x = 0; x <= size.width; x++) {
        double y = baseHeight +
            math.sin((x / wavelength) + (progress * math.pi * 2.2)) *
                (amplitude * 0.8);
        if (y.isNaN || y.isInfinite) continue;
        path2.lineTo(x, y);
      }
      canvas.drawPath(path2, paint2);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
