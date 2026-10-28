import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'siber_wrapped_screen.dart';
import '../widgets/cyber_story_canvas.dart'; // 🚀 Siber Özet Ekranı
import '../widgets/siber_premium_sheet.dart'; // 👑 Premium Ekranı
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../services/settings_service.dart';
import '../services/services.dart';
import '../services/auth_service.dart'; // 🎯 Auth Motoru
import '../services/subscription_manager.dart';
import '../screens/siber_payment_screen.dart';
import '../services/history_service.dart';
import 'package:screenshot/screenshot.dart'; // 🎯 SİBER HAMLE: Wrapped
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../services/siber_theme_service.dart'; // 🔮 Siber Tema Bağlantısı
import '../widgets/siber_theme_picker_sheet.dart'; // 🎨 Yeni Tema Rengi Seçici
import '../widgets/siber_istatistik_sheet.dart'; // 📊 İstatistik Radarı
import '../widgets/legal_sheets.dart'; // 🎯 MAĞAZA UYUMLULUK: Gizlilik ve EULA
import 'listening_mode_screen.dart'; // 🎯 Dinlenme Modu
import '../services/rank_manager.dart';
import '../services/cloud_library_service.dart';
import '../services/analytics_service.dart';
import '../widgets/personal_discover_setup_sheet.dart';
import '../widgets/notification_settings_sheet.dart'; // Bildirim cekmecesi
import '../widgets/siber_feedback_sheet.dart'; // Geri bildirim & destek cekmecesi


class ProfileScreen extends StatefulWidget {
  final VoidCallback? onGenerateAIPlaylists;
  final VoidCallback? onScanFolderForMusic;
  final VoidCallback? onShowIPSettings;
  final VoidCallback? onShowSleepTimer;
  final VoidCallback? onLaunchPersonalDiscover;
  final VoidCallback? onScanNewRecruits;

  const ProfileScreen({
    super.key,
    this.onGenerateAIPlaylists,
    this.onScanFolderForMusic,
    this.onShowIPSettings,
    this.onShowSleepTimer,
    this.onLaunchPersonalDiscover,
    this.onScanNewRecruits,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  String _username = 'Müziksever';
  String _email = 'Bağlı hesap yok';
  String _rank = 'Acemi Dinleyici';
  String _nextRank = 'Çırak Taktisyen';
  int _totalListenHours = 0;
  int _hoursForNextRank = 5;
  double _rankProgress = 0.0;
  bool _isAccountLinked = false;
  String _listeningPersona = 'Keşfetmeye Hazır';
  String _topAnalyzedSong = '—';

  // 🎯 VİZYON DEĞİŞKENLERİ

  String _avatarUrl = 'https://robohash.org/siber_ajan.png?set=set3';
  // 🎯 YENİ SİBER HAMLE: Otonom Sanatçı Podyumu ve YouTube Zekası
  List<MapEntry<String, int>> _topArtists = [];
  Map<String, String> _artistImages = {};
  bool _isLoadingImages = false;

  // 🎯 YENİ: Haftalık Ruh Hali Motoru
  Map<String, int> _moodStats = {};
  String _dominantMood = 'Belirsiz';
  Color _auraColor = Colors.cyanAccent;

  bool _isSyncing = false;
  double _syncProgress = 0.0;
  String _lastSync = 'Senkronize Edilmedi';

  String _instagramHandle = '';
  String _twitterHandle = '';

  // 🕵️‍♂️ SİBER LABORATUVAR: Gizli Yıl Sonu Özeti Tetikleyicisi (5 Tık)
  int _secretWrappedTapCount = 0;
  DateTime? _lastSecretTapTime;

  void _handleSecretWrappedTrigger() {
    final now = DateTime.now();
    if (_lastSecretTapTime == null || now.difference(_lastSecretTapTime!) > const Duration(seconds: 3)) {
      _secretWrappedTapCount = 1;
    } else {
      _secretWrappedTapCount++;
    }
    _lastSecretTapTime = now;

    if (_secretWrappedTapCount >= 5) {
      _secretWrappedTapCount = 0;
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.lock_open_rounded, color: Colors.black, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🔓 GİZLİ KUTU AÇILDI! 2026 Yıl Sonu Özeti Devrede!',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF00FFE0),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SiberWrappedScreen(
              initialCardType: CyberStoryCardType.siberAnaliz,
              autoOpenStudio: true,
            ),
          ),
        );
      }
    } else {
      HapticFeedback.selectionClick();
      final remaining = 5 - _secretWrappedTapCount;
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _secretWrappedTapCount == 1 
                  ? '🔒 Gizli Kutu: Kilidi açmak için 3 sn içinde 5 kez tıkla! (1/5)' 
                  : "🔒 Gizli Kutu: $remaining tık kaldı... ($_secretWrappedTapCount/5)",
              style: const TextStyle(color: Color(0xFF00FFE0), fontSize: 12, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF14151E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0x3300FFE0)),
            ),
            duration: const Duration(milliseconds: 700),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // 🎯 SİBER HAMLE: İstihbarat Verilerini ve Bağlı Hesabı Otonom Yükle
  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final linked = prefs.getBool('siber_is_linked') ?? false;
    final name = prefs.getString('siber_username') ?? 'Müziksever';
    final email = prefs.getString('siber_email') ?? 'Bağlı hesap yok';
    // final auraValue =
    // prefs.getInt...
    final avatar = prefs.getString('siber_avatar_url') ??
        'https://robohash.org/$name.png?set=set3';
    final lastSyncTime =
        prefs.getString('siber_last_sync') ?? 'Henüz eşitlenmedi';
    final instagram = prefs.getString('siber_instagram') ?? '';
    final twitter = prefs.getString('siber_twitter') ?? '';

    final historyList = await HistoryService.getHistory();
    int totalSeconds = 0;
    Map<String, int> artistCounts = {};

    for (var item in historyList) {
      totalSeconds += item.totalListenSeconds;

      // 🎯 KİM NE KADAR DİNLENDİ? (Sanatçı Analizi - Tüm Zamanlar)
      String sName = item.name;
      if (sName.contains('-')) {
        String artist = sName.split('-').first.trim();
        if (artist.isNotEmpty) {
          artistCounts[artist] = (artistCounts[artist] ?? 0) + item.playCount;
        }
      }
    }
    int totalHours = totalSeconds ~/ 3600;

    // En çok dinlenen 3 sanatçı
    var sortedArtists = artistCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 🎯 YENİ 7 KADEMELİ RÜTBE SİSTEMİ
    String rank = 'Yeni Dinleyici';
    String nextRank = 'Çırak Taktisyen';
    int hoursForNextRank = 5;
    double rankProgress = 0.0;

    final rankTiers = RankManager.allTiers;

    for (int i = 0; i < rankTiers.length; i++) {
      if (totalHours >= rankTiers[i].hours) {
        rank = rankTiers[i].name;
        if (i < rankTiers.length - 1) {
          nextRank = rankTiers[i + 1].name;
          int currentTierHours = rankTiers[i].hours;
          int nextTierHours = rankTiers[i + 1].hours;
          hoursForNextRank = nextTierHours - totalHours;
          int hoursInCurrentTier = totalHours - currentTierHours;
          int tierSpan = nextTierHours - currentTierHours;
          rankProgress = (hoursInCurrentTier / tierSpan).clamp(0.0, 1.0);
        } else {
          nextRank = 'MAX SEVİYE';
          hoursForNextRank = 0;
          rankProgress = 1.0;
        }
      }
    }

    // 🎯 HAFTALIK RUH HALİ MOTORU (Sadece son 7 gün)
    final weeklyHistory = await HistoryService.getWeeklyHistory();
    Map<String, int> weeklyMoodCounts = {};
    for (var item in weeklyHistory) {
      String mood = _analyzeSongMood(item.name);
      weeklyMoodCounts[mood] =
          (weeklyMoodCounts[mood] ?? 0) + item.totalListenSeconds;
    }

    String dominantMood = 'Belirsiz';
    if (weeklyMoodCounts.isNotEmpty) {
      var sortedMoods = weeklyMoodCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      dominantMood = sortedMoods.first.key;
    }

    String persona = 'Keşfetmeye Hazır';
    String topSong = '—';
    try {
      persona = await AnalyticsService().getListeningPersona();
      final songs = await AnalyticsService().getTopSongs(limit: 1);
      if (songs.isNotEmpty) {
        topSong = songs.first['title'] ?? '—';
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isAccountLinked = linked;
        _listeningPersona = persona;
        _topAnalyzedSong = topSong;
        _username = name;
        _email = email;
        _rank = rank;
        _nextRank = nextRank;
        _totalListenHours = totalHours;
        _hoursForNextRank = hoursForNextRank;
        _rankProgress = rankProgress;
        
        final avatar = prefs.getString('siber_avatar_url');
        if (avatar != null && avatar.isNotEmpty) {
          _avatarUrl = avatar;
        } else {
          _avatarUrl = "https://robohash.org/${name.replaceAll(' ', '_')}?set=${_getAvatarSetByRank(rank)}";
        }
        
        _lastSync = lastSyncTime;
        _topArtists = sortedArtists.take(3).toList();
        _moodStats = weeklyMoodCounts;
        _dominantMood = dominantMood;
        _auraColor = _getMoodColor(dominantMood); // 🎯 DİNAMİK AURA MOTORU
        _instagramHandle = instagram;
        _twitterHandle = twitter;
      });
      // 🎯 SİBER HAMLE: Profil verisi yüklendikten sonra otonom olarak YT Podyum resimlerini çek!
      _fetchArtistImages();
    }
  }

  // 🎯 YENİ SİBER HAMLE: Sanatçıların YouTube Profil Fotolarını Çek (Otonom)
  Future<void> _fetchArtistImages() async {
    if (_topArtists.isEmpty) return;

    setState(() {
      _isLoadingImages = true;
    });

    final yt = YoutubeExplode();
    Map<String, String> fetchedImages = {};

    for (var artist in _topArtists) {
      String artistName = artist.key;
      try {
        // YouTube'da sanatçıyı arat
        var searchResults =
            await yt.search.search('$artistName Official Channel');
        if (searchResults.isNotEmpty) {
          // İlk videonun kanal bilgisini çek
          var firstVideo = searchResults.first;
          var channel = await yt.channels.get(firstVideo.channelId);
          fetchedImages[artistName] = channel.logoUrl;
        }
      } catch (e) {
        debugPrint('YouTube PP Çekme Hatası ($artistName): $e');
      }
    }

    yt.close();

    if (mounted) {
      setState(() {
        _artistImages = fetchedImages;
        _isLoadingImages = false;
      });
    }
  }

  // 🎯 SİBER HAMLE: Canavar Ruh Hali Motoru (Monster Mood Engine)
  String _analyzeSongMood(String name) {
    final n = name.toLowerCase();

    if (n.contains('yavaş') ||
        n.contains('slow') ||
        n.contains('hüzün') ||
        n.contains('ayrılık') ||
        n.contains('yalnızlık') ||
        n.contains('gözyaşı')) {
      return 'Melankolik';
    }
    if (n.contains('arabesk') ||
        n.contains('damar') ||
        n.contains('acı') ||
        n.contains('meyhane') ||
        n.contains('yara') ||
        n.contains('dert')) {
      return 'Efkârlı';
    }
    if (n.contains('rap') ||
        n.contains('trap') ||
        n.contains('drill') ||
        n.contains('beat') ||
        n.contains('sokak') ||
        n.contains('ghetto') ||
        n.contains('çete') ||
        n.contains('ezhel') ||
        n.contains('ceza')) {
      return 'Sokak Ritmi';
    }
    if (n.contains('remix') ||
        n.contains('club') ||
        n.contains('dance') ||
        n.contains('bass') ||
        n.contains('party') ||
        n.contains('kop')) {
      return 'Kopmalık';
    }
    if (n.contains('pop') ||
        n.contains('hareketli') ||
        n.contains('neşeli') ||
        n.contains('mutlu') ||
        n.contains('yaz') ||
        n.contains('hit') ||
        n.contains('enerji')) {
      return 'Enerjik';
    }
    if (n.contains('focus') ||
        n.contains('study') ||
        n.contains('piano') ||
        n.contains('klasik') ||
        n.contains('zihin') ||
        n.contains('work')) {
      return 'Odaklanma';
    }
    if (n.contains('lofi') ||
        n.contains('chill') ||
        n.contains('relax') ||
        n.contains('doğa') ||
        n.contains('huzur') ||
        n.contains('meditasyon') ||
        n.contains('akustik')) {
      return 'Rahatlatıcı';
    }
    if (n.contains('uyku') ||
        n.contains('sleep') ||
        n.contains('gece') ||
        n.contains('rain') ||
        n.contains('ninni')) {
      return 'Uyku Öncesi';
    }
    if (n.contains('rock') ||
        n.contains('metal') ||
        n.contains('isyan') ||
        n.contains('hard') ||
        n.contains('heavy') ||
        n.contains('öfke')) {
      return 'İsyankâr';
    }
    if (n.contains('gym') ||
        n.contains('workout') ||
        n.contains('motivasyon') ||
        n.contains('antrenman') ||
        n.contains('power') ||
        n.contains('epic')) {
      return 'Motivasyon';
    }
    if (n.contains('90lar') ||
        n.contains('80ler') ||
        n.contains('nostalji') ||
        n.contains('kaset') ||
        n.contains('eski') ||
        n.contains('unutulmaz')) {
      return 'Nostaljik';
    }
    if (n.contains('türkü') ||
        n.contains('bağlama') ||
        n.contains('ney') ||
        n.contains('anadolu') ||
        n.contains('etnik') ||
        n.contains('doğu')) {
      return 'Mistik';
    }
    if (n.contains('cyber') ||
        n.contains('synthwave') ||
        n.contains('elektronik') ||
        n.contains('edm') ||
        n.contains('techno')) {
      return 'Siber';
    }

    return 'Dengeli';
  }

  // 🎯 SİBER HAMLE: Ruh Haline Göre Neon Aura Rengi
  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'Melankolik':
        return Colors.blue.shade800; // Deep Blue
      case 'Efkârlı':
        return Colors.grey.shade600; // Smoke Grey
      case 'Sokak Ritmi':
        return Colors.redAccent.shade700; // Blood Red
      case 'Kopmalık':
        return Colors.deepOrangeAccent; // Neon Orange
      case 'Enerjik':
        return Colors.pinkAccent; // Hot Pink
      case 'Odaklanma':
        return Colors.greenAccent.shade700; // Emerald Green
      case 'Rahatlatıcı':
        return Colors.cyanAccent; // Cyan
      case 'Uyku Öncesi':
        return Colors.indigo.shade900; // Midnight Blue
      case 'İsyankâr':
        return Colors.purple.shade900; // Deep Purple
      case 'Motivasyon':
        return Colors.amber; // Gold
      case 'Nostaljik':
        return Colors.brown.shade400; // Amber/Brown
      case 'Mistik':
        return Colors.lime.shade800; // Olive
      case 'Siber':
        return Colors.lightBlueAccent; // Neon Blue
      default:
        return Colors.cyanAccent;
    }
  }

  // 🎯 Rütbeye Göre Çerçeve Rengi Seçici
  Color _getRankColor() {
    if (_rank == 'ÖZSES Efsanesi') return Colors.amber;
    if (_rank == 'Ses Gurmesi') return Colors.redAccent;
    if (_rank == 'Melodi Ustası') return Colors.orangeAccent;
    if (_rank == 'Ritim Tutkunu') return Colors.purpleAccent;
    if (_rank == 'Müziksever') return Colors.blueAccent;
    if (_rank == 'Çırak Taktisyen') return Colors.greenAccent;
    return Colors.white54;
  }

  // 🎯 SİBER HAMLE: Hesap Bağlama (Giriş Yap / Kayıt Ol) Paneli
  void _showLinkAccountDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final usernameController = TextEditingController();
    bool isLoginMode = true; // 🎯 SİBER HAMLE: Otonom Geçiş Anahtarı

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.cyanAccent, width: 1.5),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () => setDialogState(() => isLoginMode = true),
                    child: Text('GİRİŞ YAP',
                        style: TextStyle(
                            color: isLoginMode ? _auraColor : Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                  const Text('|',
                      style: TextStyle(color: Colors.white24, fontSize: 18)),
                  GestureDetector(
                    onTap: () => setDialogState(() => isLoginMode = false),
                    child: Text('KAYIT OL',
                        style: TextStyle(
                            color: !isLoginMode ? _auraColor : Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Bulut senkronizasyonu için kimliğinizi doğrulayın.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    if (!isLoginMode) ...[
                      _buildTextField(
                          usernameController, 'Kullanıcı Adı', Icons.person),
                      const SizedBox(height: 10),
                    ],
                    _buildTextField(emailController, 'E-Posta', Icons.email),
                    const SizedBox(height: 10),
                    _buildTextField(
                        passwordController, 'Şifre', Icons.lock,
                        isPassword: true),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _auraColor.withValues(alpha: 0.8),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if (emailController.text.isNotEmpty &&
                              passwordController.text.isNotEmpty &&
                              (isLoginMode ||
                                  usernameController.text.isNotEmpty)) {
                            final email = emailController.text.trim();
                            final pass = passwordController.text;
                            final username = usernameController.text.trim();

                            try {
                              if (isLoginMode) {
                                await AuthService().signInWithEmailAndPassword(email, pass);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  _loadProfileData(); // Arayüzü güncelle
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: const Text('Hesabınıza Başarıyla Giriş Yapıldı!'),
                                    backgroundColor: _auraColor,
                                  ));
                                }
                              } else {
                                await AuthService().registerWithEmailAndPassword(username, email, pass);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: const Text('Kayıt tamam! E-postana bir doğrulama linki gönderdik. Onayladıktan sonra giriş yapabilirsin!'),
                                    backgroundColor: _auraColor,
                                    duration: const Duration(seconds: 4),
                                  ));
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                String errorMsg = 'Hata oluştu.';
                                if (e.toString().contains('email_not_verified')) {
                                  errorMsg = 'E-postanı henüz doğrulamamışsın! Lütfen mail kutunu kontrol et.';
                                } else if (e.toString().contains('email-already-in-use')) {
                                  errorMsg = 'Bu e-posta zaten sistemde kayıtlı!';
                                } else if (e.toString().contains('user-not-found') || e.toString().contains('wrong-password') || e.toString().contains('invalid-credential')) {
                                  errorMsg = 'E-posta veya şifre hatalı!';
                                } else if (e.toString().contains('weak-password')) {
                                  errorMsg = 'Şifren çok zayıf, daha güçlü bir şifre belirle!';
                                }
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(errorMsg),
                                  backgroundColor: Colors.redAccent,
                                ));
                              }
                            }
                          } else {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text(
                                  'Lütfen tüm alanları doldurun!'),
                              backgroundColor: Colors.redAccent,
                            ));
                          }
                        },
                        child: Text(
                            isLoginMode ? 'GİRİŞ YAP' : 'HESAP OLUŞTUR',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white24)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('VEYA', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ),
                        Expanded(child: Divider(color: Colors.white24)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Google Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 30),
                        label: const Text('Google ile Bağlan', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);
                          try {
                            final success = await AuthService().signInWithGoogle();
                            if (success) {
                              _loadProfileData();
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Başarıyla giriş yapıldı (Google).'), backgroundColor: Colors.green));
                              }
                            }
                          } catch (e) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(e.toString().replaceAll('Exception: ', '')),
                                backgroundColor: Colors.redAccent,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Apple Button
                    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS))
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.apple, color: Colors.white, size: 28),
                          label: const Text('Apple ile Bağlan', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            side: const BorderSide(color: Colors.white24, width: 1),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            Navigator.pop(context);
                            try {
                              final user = await AuthService().signInWithApple();
                              if (user != null) {
                                _loadProfileData();
                                if (mounted) {
                                  scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Başarıyla giriş yapıldı (Apple).'), backgroundColor: Colors.green));
                                }
                              }
                            } catch (e) {
                              scaffoldMessenger.showSnackBar(SnackBar(content: Text('Bağlantı hatası: $e'), backgroundColor: Colors.red));
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🎯 SİBER HAMLE: Sosyal Medya Şık Buton Tasarımı
  Widget _buildSocialButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, IconData icon,
      {bool isPassword = false, Color? customColor}) {
    final color = customColor ?? _auraColor;
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: color),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color),
        ),
        filled: true,
        fillColor: Colors.black45,
      ),
    );
  }

  // 🎯 SİBER HAMLE: Google Hesabını Bağlama Motoru
  Future<void> _linkGoogleAccount() async {
    try {
      final success = await AuthService().signInWithGoogle();
      if (success) {
        if (CloudLibraryService().isUserLoggedIn) {
          await CloudLibraryService().fullSync();
        }
        await _loadProfileData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Google Hesabı başarıyla bağlandı ve bulut arşivi eşitlendi!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // 🎯 SİBER HAMLE: Hesabı Koparma Motoru
  void _unlinkAccount() async {
    // 1. Gerçek Çıkış İşlemi
    await AuthService().signOut();

    // 2. Arayüzü Yenile
    _loadProfileData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Hesap bağlantısı kesildi.'),
        backgroundColor: Colors.orangeAccent,
      ));
    }
  }

  // 🎯 MAĞAZA UYUMLULUK: Hesabı Tamamen Silme
  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.redAccent),
              SizedBox(width: 8),
              Expanded(child: Text('Hesabımı Sil', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16))),
            ],
          ),
          content: const Text(
            'Bu işlem geri alınamaz. Bulut arşivinizdeki tüm şarkılar, oynatma listeleriniz, dinleme geçmişiniz ve profil verileriniz kalıcı olarak silinecektir.\n\nEmin misiniz?',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.pop(context); // Dialogu kapat
                try {
                  await AuthService().deleteAccount();
                  _loadProfileData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hesabınız ve verileriniz başarıyla silindi.'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (e.toString().contains('requires-recent-login')) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Güvenlik nedeniyle hesabı silmeden önce tekrar giriş yapmalısınız.'), backgroundColor: Colors.orangeAccent),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Hesap silme başarısız: $e'), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                }
              },
              child: const Text('Kalıcı Olarak Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // 🎯 SİBER HAMLE: Sosyal Medya Bağlantı Paneli
  void _showSocialLinkDialog(
      String platform, String prefKey, Color platformColor) {
    TextEditingController handleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: platformColor, width: 1.5),
          ),
          title: Row(
            children: [
              Icon(Icons.link, color: platformColor),
              const SizedBox(width: 8),
              Text('$platform Bağla',
                  style: TextStyle(
                      color: platformColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Profiline bu platformu bağla.',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 15),
                _buildTextField(handleController, 'Kullanıcı Adı / Handle',
                    Icons.alternate_email,
                    customColor: platformColor),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('İptal', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: platformColor.withValues(alpha: 0.8),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(prefKey, handleController.text.trim());
                if (mounted) {
                  setState(() {
                    if (prefKey == 'siber_instagram') {
                      _instagramHandle = handleController.text.trim();
                    }
                    if (prefKey == 'siber_twitter') {
                      _twitterHandle = handleController.text.trim();
                    }
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('$platform başarıyla kaydedildi!'),
                    backgroundColor: platformColor,
                  ));
                }
              },
              child: const Text('Kaydet',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSocialLinkTile({
    required String platform,
    required String handle,
    required IconData icon,
    required Color color,
    required String prefKey,
  }) {
    bool isLinked = handle.isNotEmpty;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(platform,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(isLinked ? '@$handle' : 'Henüz bağlanmadı',
          style: TextStyle(
              color: isLinked ? color : Colors.white38, fontSize: 12)),
      trailing: isLinked
          ? IconButton(
              icon: const Icon(Icons.link_off, color: Colors.redAccent),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove(prefKey);
                setState(() {
                  if (prefKey == 'siber_instagram') _instagramHandle = '';
                  if (prefKey == 'siber_twitter') _twitterHandle = '';
                });
              },
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.2),
                side: BorderSide(color: color.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _showSocialLinkDialog(platform, prefKey, color),
              child: Text('Bağla', style: TextStyle(color: color)),
            ),
    );
  }

  // 🎯 SİBER HAMLE: Profil Düzenleyici
  void _showEditProfileDialog() {
    TextEditingController urlController =
        TextEditingController(text: _avatarUrl);
    TextEditingController usernameController =
        TextEditingController(text: _username);
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: _auraColor)),
            title: Text('PROFİLİ DÜZENLE',
                style:
                    TextStyle(color: _auraColor, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      'Profil adını ve avatarını güncelleyebilirsin.',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 15),
                  _buildTextField(
                      usernameController, 'Kullanıcı Adı', Icons.person),
                  const SizedBox(height: 15),
                  _buildTextField(
                      urlController, 'Resim URL (http...)', Icons.image),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _auraColor,
                        foregroundColor: Colors.black),
                    icon: const Icon(Icons.smart_toy),
                    label: const Text('Rastgele Avatar'),
                    onPressed: () async {
                      String randId =
                          DateTime.now().millisecondsSinceEpoch.toString();
                      String newUrl =
                          'https://robohash.org/siber_$randId.png?set=set3';
                      if (mounted) {
                        setState(() => urlController.text = newUrl);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        foregroundColor: Colors.white),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galeriden Seç'),
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.pickFiles(
                        type: FileType.image,
                      );
                      if (result != null && result.files.single.path != null) {
                        if (mounted) {
                          setState(() => urlController.text = result.files.single.path!);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal',
                    style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  if (urlController.text.isNotEmpty) {
                    await prefs.setString(
                        'siber_avatar_url', urlController.text);
                  }
                  if (usernameController.text.trim().isNotEmpty) {
                    await prefs.setString(
                        'siber_username', usernameController.text.trim());
                  }
                  if (mounted) {
                    setState(() {
                      if (urlController.text.isNotEmpty) {
                        _avatarUrl = urlController.text;
                      }
                      if (usernameController.text.trim().isNotEmpty) {
                        _username = usernameController.text.trim();
                      }
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text('Kaydet',
                    style: TextStyle(
                        color: _auraColor, fontWeight: FontWeight.bold)),
              )
            ],
          );
        });
  }

  // 🎯 SİBER HAMLE: Bulut Senkronizasyonu (Gerçek Firestore & SQLite)
  Future<void> _startCloudSync() async {
    if (_isSyncing) return;
    setState(() {
      _isSyncing = true;
      _syncProgress = 0.2;
    });

    try {
      if (CloudLibraryService().isUserLoggedIn) {
        setState(() => _syncProgress = 0.6);
        await CloudLibraryService().fullSync();
      }
      setState(() => _syncProgress = 1.0);
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      String timeStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      await prefs.setString('siber_last_sync', timeStr);
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _lastSync = timeStr;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Bulut senkronizasyonu başarıyla tamamlandı!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Senkronizasyon uyarısı: $e'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  // 🎯 SİBER HAMLE: Keşfet Profilini Güncelleme Modülü (Genel Keşfet ile 100% Uyumlu)
  void _showPersonalSurveyDialog() {
    PersonalDiscoverSetupSheet.show(
      context,
      themeColor: _auraColor,
      isInitialSetup: false,
      onCompleted: () {
        if (mounted) setState(() {});
      },
    );
  }


  String _getAvatarSetByRank(String rank) {
    if (rank == 'Yeni Dinleyici' || rank == 'Çırak Taktisyen') {
      return 'set1'; // Sevimli Robotlar
    }
    if (rank == 'Müziksever' || rank == 'Ritim Tutkunu') {
      return 'set2'; // Yaratıklar
    }
    if (rank == 'Melodi Ustası' || rank == 'Ses Gurmesi') {
      return 'set5'; // İnsansı Robotlar
    }
    return 'set3'; // ÖZSES Efsanesi (Cyborg kafaları)
  }

  // 🎯 YENİ SİBER HAMLE: Yapay Zeka Ruh Hali Yorumcusu
  String _generateCyberDiagnosis() {
    if (_dominantMood == 'Belirsiz') {
      return 'Yeterli dinleme verisi tespit edilemedi. Müzik dinledikçe raporunuz burada oluşacak.';
    }

    String artist = _topArtists.isNotEmpty
        ? _topArtists.first.key
        : 'Bilinmeyen Frekanslar';

    switch (_dominantMood) {
      case 'Melankolik':
      case 'Efkârlı':
      case 'Nostaljik':
        return 'SİSTEM TEŞHİSİ: Ruhunda derin bir arayış algılandı. $artist tınıları ve yavaş ritimler veri akışını tamamen ele geçirmiş. Gece dinlemeleri tavsiye edilir.';
      case 'Sokak Ritmi':
      case 'İsyankâr':
        return 'SİSTEM TEŞHİSİ: Sistemde yüksek distorsiyon ve isyan saptandı! $artist frekansları kanındaki adrenalini tetikliyor. Bu tempoyu asla bozma!';
      case 'Enerjik':
      case 'Kopmalık':
      case 'Motivasyon':
      case 'Siber':
        return 'MÜZİK ANALİZİ: Ritimlerin alev alev! $artist ezgileriyle enerjini maksimuma çıkarıyorsun. Müzik tutkun zirvede!';
      case 'Odaklanma':
      case 'Rahatlatıcı':
      case 'Uyku Öncesi':
      case 'Mistik':
        return 'MÜZİK ANALİZİ: Meditasyon ve mutlak odak hali. $artist frekansları zihnini dinlendiriyor. Müzik huzuruna ulaşıldı.';
      default:
        return 'SİSTEM TEŞHİSİ: Kompleks bir veri denizi. $artist ağırlıklı eşsiz bir frekans sentezi ruhunu sarmalıyor.';
    }
  }

  Widget _buildCyberDiagnosisBox() {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _getMoodColor(_dominantMood).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _getMoodColor(_dominantMood).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: _getMoodColor(_dominantMood).withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology,
                  color: _getMoodColor(_dominantMood), size: 18),
              const SizedBox(width: 8),
              Text(
                '🧠 YAPAY ZEKA TEŞHİSİ',
                style: TextStyle(
                  color: _getMoodColor(_dominantMood),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _generateCyberDiagnosis(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // 🔮 SİBER SES İZİ (SONIC AURA ANALİZİ)
  Widget _buildSonicAuraSection() {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      child: InkWell(
        onTap: _showSonicAuraDialog,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _auraColor.withValues(alpha: 0.18),
                Colors.black.withValues(alpha: 0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _auraColor.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: _auraColor.withValues(alpha: 0.1),
                blurRadius: 12,
                spreadRadius: 2,
              )
            ],
          ),
          child: Row(
            children: [
              // Animasyonlu 3D Aura Küresi
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _auraColor,
                      _auraColor.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _auraColor.withValues(alpha: 0.6),
                      blurRadius: 18,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 26),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'SES İZİ',
                          style: TextStyle(
                            color: _auraColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.open_in_new_rounded, color: _auraColor.withValues(alpha: 0.8), size: 14),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dominantMood != 'Belirsiz'
                          ? 'Baskın Tarz: ${_dominantMood.toUpperCase()} FREKANSI'
                          : 'Baskın Tarz: KARANLIK POP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Frekans spektrumu ve 3D aura küreni incelemek için dokun',
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSonicAuraDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          height: 430,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0C16),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _auraColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: _auraColor.withValues(alpha: 0.5),
                blurRadius: 35,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SES İZİN',
                style: TextStyle(
                  color: _auraColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 25),
              // Animasyonlu 3D Küre
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.85, end: 1.15),
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut,
                builder: (context, val, child) {
                  return Container(
                    width: 130 * val,
                    height: 130 * val,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _auraColor,
                          _auraColor.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _auraColor.withValues(alpha: 0.8),
                          blurRadius: 40 * val,
                          spreadRadius: 10 * val,
                        )
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 50),
                    ),
                  );
                },
              ),
              const SizedBox(height: 25),
              Text(
                _dominantMood != 'Belirsiz'
                    ? 'Baskın Akustik Rezonans:\n${_dominantMood.toUpperCase()} DALGASI'
                    : 'Baskın Akustik Rezonans:\nKARANLIK POP',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _auraColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Kapat', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // 🎯 SİBER HAMLE: Çoklu Hesap Bağlama & Entegrasyon Merkezi
  Widget _buildConnectedAccountsHub() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _auraColor.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _auraColor.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _auraColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.hub_rounded, color: _auraColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HESAP BAĞLANTI & BULUT MERKEZİ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Google, E-Posta & Bulut Entegrasyonu',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 14),

          // 1. GOOGLE HESAP SATIRI
          _buildAccountTile(
            icon: Icons.g_mobiledata_rounded,
            iconColor: Colors.redAccent,
            title: 'Google Hesabı',
            subtitle: _isAccountLinked
                ? (_email != 'Bağlı hesap yok' ? _email : 'Google ile Bağlandı')
                : 'Bulut arşivi ve listeleri otomatik eşitle',
            isConnected: _isAccountLinked,
            connectedLabel: 'Bağlı',
            actionButtonText: _isAccountLinked ? 'Kopar' : 'Bağla',
            actionButtonColor: _isAccountLinked ? Colors.orangeAccent : Colors.redAccent,
            onAction: _isAccountLinked ? _unlinkAccount : _linkGoogleAccount,
          ),

          const SizedBox(height: 12),

          // 2. E-POSTA / SİBER HESAP GİRİŞİ
          _buildAccountTile(
            icon: Icons.alternate_email_rounded,
            iconColor: _auraColor,
            title: 'E-Posta Hesabı',
            subtitle: _isAccountLinked
                ? 'Hesap bağlı ($_username)'
                : 'E-posta ve şifre ile kayıt ol veya giriş yap',
            isConnected: _isAccountLinked,
            connectedLabel: 'Kayıtlı',
            actionButtonText: _isAccountLinked ? null : 'Giriş / Kayıt',
            actionButtonColor: _auraColor,
            onAction: _isAccountLinked ? null : _showLinkAccountDialog,
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 14),

          // BULUT KİTAPLIĞI EŞİTLE BUTONU
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSyncing ? null : _startCloudSync,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.cloud_sync_rounded, size: 20),
              label: Text(
                _isSyncing ? 'BULUTLA EŞİTLENİYOR...' : 'BULUT KİTAPLIĞINI EŞİTLE',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _auraColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // HESAP SİLME BUTONU (MAĞAZA ZORUNLULUĞU - SADECE HESAP BAĞLIYSA GÖRÜNÜR)
          if (_isAccountLinked) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _deleteAccount,
                icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 18),
                label: const Text(
                  'HESABIMI VE TÜM VERİLERİMİ SİL',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Hesap bağlama satırı bileşeni
  Widget _buildAccountTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isConnected,
    required String connectedLabel,
    String? actionButtonText,
    required Color actionButtonColor,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? iconColor.withValues(alpha: 0.4) : Colors.white10,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (isConnected) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5), width: 0.8),
                        ),
                        child: Text(
                          connectedLabel,
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (actionButtonText != null && onAction != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  backgroundColor: actionButtonColor.withValues(alpha: 0.15),
                  foregroundColor: actionButtonColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: actionButtonColor.withValues(alpha: 0.4)),
                  ),
                ),
                child: Text(
                  actionButtonText,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 🎯 Müzik Analizi & Dinleme Raporu Kartı
  Widget _buildAnalysisAndStatsCard() {
    final isMinimal = SiberThemeService.instance.isMinimalMode.value;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isMinimal ? const Color(0xFF18181C) : Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isMinimal ? Colors.white12 : Colors.purpleAccent.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: isMinimal
            ? null
            : [
                BoxShadow(
                  color: Colors.purpleAccent.withValues(alpha: 0.08),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isMinimal ? const Color(0xFF24242A) : Colors.purpleAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: isMinimal ? Colors.white70 : Colors.purpleAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MÜZİK ANALİZİ & KARNE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Yapay Zeka Müzik DNA ve Dinleme Raporu',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 14),

          // DİNLERKEN KİMLİK / PERSONA ROZETİ (5 Kez Tıklayınca Gizli 2026 Wrapped Açar)
          GestureDetector(
            onTap: _handleSecretWrappedTrigger,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMinimal ? const Color(0xFF1E1E24) : null,
                gradient: isMinimal
                    ? null
                    : LinearGradient(
                        colors: [
                          Colors.purple.withValues(alpha: 0.2),
                          Colors.indigo.withValues(alpha: 0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isMinimal ? Colors.white10 : Colors.purpleAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isMinimal ? const Color(0xFF282830) : Colors.purpleAccent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.psychology_rounded,
                      color: isMinimal ? Colors.white70 : Colors.purpleAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DİNLERKEN KİŞİLİĞİ',
                          style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.0, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _listeningPersona,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // İKİLİ BİLGİ KUTUCUKLARI (En Çok Dinlenen & Toplam Saat)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.headset_rounded, color: Colors.cyanAccent, size: 14),
                          SizedBox(width: 6),
                          Text('TOPLAM DİNLEME', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$_totalListenHours Saat',
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.military_tech_rounded, color: Colors.amberAccent, size: 14),
                          SizedBox(width: 6),
                          Text('DİNLEYİCİ RÜTBESİ', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _rank,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // AKSİYON BUTONU (İstatistikler)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => SiberIstatistikSheet(themeColor: _auraColor),
                );
              },
              icon: const Icon(Icons.bar_chart_rounded, size: 20),
              label: const Text('MÜZİK İSTATİSTİKLERİ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isMinimal ? const Color(0xFF222228) : Colors.cyanAccent.shade700,
                foregroundColor: Colors.white,
                elevation: isMinimal ? 0 : 2,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: isMinimal ? const BorderSide(color: Colors.white12) : BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 YENİ SİBER HAMLE: Otonom Sanatçı Podyumu (YouTube Entegrasyonlu)
  Widget _buildArtistPodium() {
      if (_topArtists.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)],
          ),
          child: Column(
            children: [
              Icon(Icons.mic_off, color: Colors.white24, size: 40),
              const SizedBox(height: 12),
              const Text('SANATÇI LİSTESİ BOŞ', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              const Text('Sanatçı podyumu için henüz yeterli veri yok. Ritimleri keşfetmeye başla!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        );
      }

    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('🏆 SANATÇI PODYUMU',
              style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // 2. Sıra (Sol Gümüş)
              if (_topArtists.length > 1)
                Positioned(
                  left: 20,
                  bottom: 0,
                  child: _buildPodiumItem(_topArtists[1].key,
                      _topArtists[1].value, 2, Colors.blueGrey.shade300, 60),
                ),
              // 3. Sıra (Sağ Bronz)
              if (_topArtists.length > 2)
                Positioned(
                  right: 20,
                  bottom: 0,
                  child: _buildPodiumItem(
                      _topArtists[2].key,
                      _topArtists[2].value,
                      3,
                      Colors.deepOrangeAccent.shade200,
                      50),
                ),
              // 1. Sıra (Orta Altın Şampiyon)
              Positioned(
                bottom: 20,
                child: _buildPodiumItem(_topArtists[0].key,
                    _topArtists[0].value, 1, Colors.amber, 80),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumItem(String artistName, int playCount, int rank,
      Color glowColor, double size) {
    bool hasImage = _artistImages.containsKey(artistName) &&
        _artistImages[artistName] != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rank == 1)
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Icon(Icons.workspace_premium, color: Colors.amber, size: 30),
          ),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            border: Border.all(color: glowColor, width: rank == 1 ? 3 : 2),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.6),
                blurRadius: rank == 1 ? 20 : 10,
                spreadRadius: rank == 1 ? 5 : 2,
              )
            ],
          ),
          child: ClipOval(
            child: _isLoadingImages
                ? Padding(
                    padding: EdgeInsets.all(size * 0.25),
                    child: CircularProgressIndicator(
                        color: glowColor, strokeWidth: 2),
                  )
                : (hasImage
                    ? CachedNetworkImage(imageUrl: _artistImages[artistName]!, placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber)),
                        fit: BoxFit.cover)
                    : Icon(Icons.person, color: glowColor, size: size * 0.5)),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: glowColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: glowColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            '#$rank',
            style: TextStyle(
                color: glowColor, fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: size * 1.5,
          child: Text(
            artistName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          '$playCount Kez',
          style: const TextStyle(color: Colors.white54, fontSize: 9),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('HESAP & PROFİL',
            style: TextStyle(
                color: _auraColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart_rounded, color: _auraColor),
            tooltip: 'Dinleme İstatistikleri',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => SiberIstatistikSheet(themeColor: _auraColor),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.palette_rounded, color: _auraColor),
            tooltip: 'Tema Rengi Değiştir',
            onPressed: () {
              if (!SubscriptionManager().canChangeAuraTheme()) {
                if (mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SiberPaymentScreen(themeColor: _auraColor)));
                }
                return;
              }

              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => SiberThemePickerSheet(
                  currentColor: _auraColor,
                  onColorChanged: (color) {
                    if (mounted) setState(() => _auraColor = color);
                  },
                ),
              );
            },
          )
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: SiberThemeService.instance.isMinimalMode,
        builder: (context, isMinimal, _) {
          return Container(
            decoration: BoxDecoration(
              color: isMinimal ? const Color(0xFF121214) : null,
              gradient: isMinimal
                  ? null
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_auraColor.withValues(alpha: 0.15), Colors.black],
                    ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // 🎯 AMBİYANS / SADE PROFİL KARTI
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                      decoration: BoxDecoration(
                        color: isMinimal ? const Color(0xFF18181C) : null,
                        gradient: isMinimal
                            ? null
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF141A29).withValues(alpha: 0.95),
                                  const Color(0xFF0D111A).withValues(alpha: 0.98),
                                  _auraColor.withValues(alpha: 0.12),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isMinimal ? Colors.white12 : _auraColor.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: isMinimal
                            ? null
                            : [
                                BoxShadow(
                                  color: _auraColor.withValues(alpha: 0.18),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Column(
                        children: [
                          // Üst Durum Rozeti (Çevrimdışı / Bulut)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _isAccountLinked
                                      ? Colors.greenAccent.withValues(alpha: 0.12)
                                      : (isMinimal ? Colors.white.withValues(alpha: 0.05) : _auraColor.withValues(alpha: 0.12)),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _isAccountLinked
                                        ? Colors.greenAccent.withValues(alpha: 0.4)
                                        : (isMinimal ? Colors.white12 : _auraColor.withValues(alpha: 0.4)),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isAccountLinked
                                          ? Icons.cloud_done_rounded
                                          : Icons.music_note_rounded,
                                      size: 14,
                                      color: _isAccountLinked
                                          ? Colors.greenAccent
                                          : (isMinimal ? Colors.white70 : _auraColor),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isAccountLinked
                                          ? 'BULUT SENKRONİZE'
                                          : 'YEREL PROFİL • ÇEVRİMDİŞİ',
                                      style: TextStyle(
                                        color: _isAccountLinked
                                            ? Colors.greenAccent
                                            : (isMinimal ? Colors.white70 : _auraColor),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Avatar Çerçevesi
                          GestureDetector(
                            onTap: _showEditProfileDialog,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isMinimal ? const Color(0xFF222228) : null,
                                    gradient: isMinimal
                                        ? null
                                        : LinearGradient(
                                            colors: [
                                              _auraColor,
                                              _getRankColor(),
                                            ],
                                          ),
                                    border: isMinimal ? Border.all(color: Colors.white24, width: 2) : null,
                                    boxShadow: isMinimal
                                        ? null
                                        : [
                                            BoxShadow(
                                              color: _auraColor.withValues(alpha: 0.5),
                                              blurRadius: 24,
                                              spreadRadius: 3,
                                            ),
                                          ],
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0D111A),
                                      shape: BoxShape.circle,
                                    ),
                                    child: CircleAvatar(
                                      radius: 52,
                                      backgroundColor: Colors.white10,
                                      backgroundImage: _avatarUrl.startsWith('http')
                                          ? NetworkImage(_avatarUrl) as ImageProvider
                                          : FileImage(File(_avatarUrl)),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: isMinimal ? const Color(0xFF2C2C34) : _auraColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black, width: 2),
                                    boxShadow: isMinimal
                                        ? null
                                        : [
                                            BoxShadow(
                                              color: _auraColor.withValues(alpha: 0.6),
                                              blurRadius: 8,
                                            ),
                                          ],
                                  ),
                                  child: Icon(
                                    Icons.edit_rounded,
                                    color: isMinimal ? Colors.white : Colors.black,
                                    size: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Kullanıcı Adı & Düzenleme Butonu
                          GestureDetector(
                            onTap: _showEditProfileDialog,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _username,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isMinimal ? Colors.white24 : _auraColor.withValues(alpha: 0.3),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.edit_rounded,
                                            color: isMinimal ? Colors.white70 : _auraColor,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Düzenle',
                                            style: TextStyle(
                                              color: isMinimal ? Colors.white70 : _auraColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isAccountLinked
                                      ? _email
                                      : 'Müziklerin ve ayarların cihazında saklanır',
                                  style: TextStyle(
                                    color: _isAccountLinked
                                        ? (isMinimal ? Colors.white70 : _auraColor)
                                        : Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                      // Müzik Seviyesi ve Terfi İlerleme Kartı
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isMinimal ? const Color(0xFF1E1E24) : null,
                          gradient: isMinimal
                              ? null
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.6),
                                    _getRankColor().withValues(alpha: 0.1),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isMinimal ? Colors.white10 : _getRankColor().withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: _getRankColor()
                                            .withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.workspace_premium_rounded,
                                          color: _getRankColor(), size: 20),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _rank,
                                      style: TextStyle(
                                        color: _getRankColor(),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_nextRank != 'MAX SEVİYE')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Sonraki: $_nextRank',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // İlerleme Çubuğu
                            Stack(
                              children: [
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _rankProgress.clamp(0.0, 1.0),
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isMinimal ? _getRankColor() : null,
                                      gradient: isMinimal
                                          ? null
                                          : LinearGradient(
                                              colors: [
                                                _getRankColor().withValues(alpha: 0.7),
                                                _getRankColor(),
                                              ],
                                            ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: isMinimal
                                          ? null
                                          : [
                                              BoxShadow(
                                                color: _getRankColor()
                                                    .withValues(alpha: 0.6),
                                                blurRadius: 8,
                                              ),
                                            ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (_nextRank != 'MAX SEVİYE')
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.schedule_rounded,
                                      size: 13, color: Colors.white54),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Terfi için $_hoursForNextRank saat daha dinlemelisin',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              )
                            else
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.stars_rounded,
                                      color: Colors.amber, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    "ÖZSES'İN ZİRVESİNDESİN 👑",
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                // 🎯 YENİ: Rütbe ve Ödüller Butonu
                GestureDetector(
                  onTap: () => _showRankDetailsBottomSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                        color: isMinimal ? const Color(0xFF18181C) : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isMinimal ? Colors.white12 : _getRankColor().withValues(alpha: 0.5),
                        ),
                        boxShadow: isMinimal
                            ? null
                            : [
                                BoxShadow(
                                  color: _getRankColor().withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                )
                              ]),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stars, color: _getRankColor(), size: 20),
                        const SizedBox(width: 10),
                        const Text(
                          'RÜTBE VE ÖDÜL DETAYLARI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(Icons.arrow_forward_ios,
                            color: Colors.white54, size: 12),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // 🎯 VİZYON 4: BULUT SENKRONİZASYON PANELİ
                if (_isAccountLinked)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.cloud_done,
                                    color: _auraColor, size: 20),
                                const SizedBox(width: 8),
                                const Text('Bulut Senkronizasyonu',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            TextButton(
                              onPressed: _isSyncing ? null : _startCloudSync,
                              child: Text(
                                  _isSyncing
                                      ? 'Eşitleniyor...'
                                      : 'Şimdi Eşitle',
                                  style: TextStyle(
                                      color: _auraColor, fontSize: 12)),
                            )
                          ],
                        ),
                        if (_isSyncing)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: LinearProgressIndicator(
                                value: _syncProgress,
                                backgroundColor: Colors.white10,
                                color: _auraColor),
                          )
                        else
                          Text('Son Eşitleme: $_lastSync',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),

                // 🎯 İŞLEM BUTONLARI (KONTROL PANELİ)
                _buildConnectedAccountsHub(),

                const SizedBox(height: 20),

                _buildAnalysisAndStatsCard(),

                const SizedBox(height: 20),

                // 🎯 MAĞAZA UYUMLULUK: Yasal Belgeler
                _buildProfileButton(
                  title: 'GİZLİLİK POLİTİKASI & KULLANIM KOŞULLARI',
                  subtitle: 'Yasal haklarınızı ve veri politikamızı inceleyin',
                  icon: Icons.policy,
                  color: Colors.blueAccent,
                  onTap: () => showLegalDocsModal(context, themeColor: _auraColor),
                ),

                const SizedBox(height: 15),

                _buildProfileButton(
                  title: 'BİLDİRİMLER',
                  subtitle: 'Favori sanatçı, duyuru ve indirme bildirimleri',
                  icon: Icons.notifications_active,
                  color: _auraColor,
                  onTap: () => showNotificationSettingsSheet(context, themeColor: _auraColor),
                ),

                const SizedBox(height: 15),

                _buildProfileButton(
                  title: 'GERİ BİLDİRİM & HATA BİLDİR',
                  subtitle: 'Hata, öneri veya şarkı isteğini doğrudan ekibimize ilet',
                  icon: Icons.support_agent_rounded,
                  color: Colors.tealAccent,
                  onTap: () => showSiberFeedbackSheet(context, themeColor: _auraColor),
                ),

                const SizedBox(height: 15),

                _buildProfileButton(
                  title: 'KEŞFET PROFİLİNİ GÜNCELLE',
                  subtitle: 'Yapay zeka için müzik zevkini yenile',
                  icon: Icons.person_search,
                  color: _auraColor,
                  onTap: _showPersonalSurveyDialog,
                ),

                const SizedBox(height: 15),

                // 👑 SİBER KARARGAH (PREMIUM)
                _buildProfileButton(
                  title: 'ÖZSES PREMİUM',
                  subtitle: 'Sınırsız Ayrıcalıklar ve Özel Paketler',
                  icon: Icons.workspace_premium,
                  color: Colors.amber,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) => SiberPremiumSheet(themeColor: _auraColor),
                    );
                  },
                ),

                const SizedBox(height: 15),

                _buildProfileButton(
                  title: 'DİNLENME MODU',
                  subtitle: 'Arka plan tınılarıyla zihnini dinlendir',
                  icon: Icons.waves_rounded,
                  color: Colors.cyanAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ListeningModeScreen(),
                      ),
                    );
                  },
                ),



                const SizedBox(height: 25),

                // İstihbarat Özet Kartı
                // 🎯 VİZYON 1: SİBER İSTİHBARAT KARNESİ (WRAPPED MODU)
                _buildSectionTitle('İSTİHBARAT KARNESİ', Icons.insights),
                Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isMinimal ? const Color(0xFF18181C) : Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isMinimal ? Colors.white12 : _auraColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        // 1. Dinleme Süresi
                        Row(
                          children: [
                            Icon(Icons.timer, color: _auraColor, size: 35),
                            const SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Toplam Mesai',
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 12)),
                                Text('$_totalListenHours Saat',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            child: Divider(color: Colors.white10)),

                        // 2. En Çok Dinlenen Sanatçılar (SİBER PODYUM)
                        _buildArtistPodium(),

                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            child: Divider(color: Colors.white10)),

                        // 3. HAFTALIK SİBER RUH HALİ RAPORU
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Icon(Icons.psychology,
                                    color: _auraColor, size: 20),
                                const SizedBox(width: 8),
                                const Text('Haftalık Müzik ve Ruh Hali Raporu',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold)),
                              ],
                            )),
                        const SizedBox(height: 15),
                        if (_moodStats.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white10),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)],
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.radar, color: Colors.white24, size: 40),
                                const SizedBox(height: 12),
                                const Text('VERİ BULUNAMADI', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                const SizedBox(height: 8),
                                const Text('Son 7 günde yeterli dinleme verisi toplanmadı. Müzik dinlemeye devam et.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
                              ],
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                    color: _getMoodColor(_dominantMood)
                                        .withValues(alpha: 0.5)),
                                boxShadow: [
                                  BoxShadow(
                                      color: _getMoodColor(_dominantMood)
                                          .withValues(alpha: 0.1),
                                      blurRadius: 10)
                                ]),
                            child: Column(
                              children: [
                                const Text('BU HAFTAKİ VİZYONUN',
                                    style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                        letterSpacing: 2)),
                                const SizedBox(height: 5),
                                Text(_dominantMood.toUpperCase(),
                                    style: TextStyle(
                                        color: _getMoodColor(_dominantMood),
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2)),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: CustomPaint(
                                        painter: MoodPieChartPainter(
                                            data: _moodStats),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: CustomPaint(
                                        painter: MusicDnaRadarPainter(
                                            moodStats: _moodStats,
                                            auraColor:
                                                _getMoodColor(_dominantMood)),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: _moodStats.entries.map((e) {
                                          Color c = _getMoodColor(e.key);
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 6),
                                            child: Row(
                                              children: [
                                                Container(
                                                    width: 12,
                                                    height: 12,
                                                    decoration: BoxDecoration(
                                                        color: c,
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                              color: c,
                                                              blurRadius: 5)
                                                        ])),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                    child: Text(e.key,
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 12))),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    )
                                  ],
                                ),
                                 // 🎯 SİBER TEŞHİS KUTUSU
                                 _buildCyberDiagnosisBox(),
                                 // 🔮 SİBER SES İZİ VE FREKANS ANALİZİ
                                 _buildSonicAuraSection(),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ), // Screenshot bitişi

                const SizedBox(height: 15),
                // 🎁 GİZLİ SİBER KUTU (2026 YIL SONU KAPSÜLÜ - 3 Saniyede 5 Tık Kilidi)
                _buildProfileButton(
                  title: 'GİZLİ SİBER KUTU (2026)',
                  subtitle: 'Yıl sonu özeti kilitli • Açmak için 3 sn içinde 5 kez bas!',
                  icon: Icons.lock_clock_rounded,
                  color: const Color(0xFF00FFE0),
                  onTap: _handleSecretWrappedTrigger,
                ),
              ],
            ),
          ),
        ),
      );
    },
  ),
);
}

  // 📸 SİBER HAMLE: Sosyal Medya Paylaşım Motoru - 2026 Hikaye Stüdyosu
  Future<void> _shareCyberIdentity() async {
    HapticFeedback.heavyImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SiberWrappedScreen(
          initialCardType: CyberStoryCardType.siberAnaliz,
          autoOpenStudio: true,
        ),
      ),
    );
  }

  Widget _buildProfileButton(
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    final isMinimal = SiberThemeService.instance.isMinimalMode.value;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: isMinimal ? const Color(0xFF18181C) : Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isMinimal ? Colors.white12 : color.withValues(alpha: 0.5),
            ),
            boxShadow: isMinimal
                ? null
                : [
                    BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10),
                  ]),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        children: [
          Icon(icon, color: _auraColor, size: 18),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
        ],
      ),
    );
  }

  // 🎯 YENİ: Rütbe ve Ödüller Detay Sayfası (Kümülatif Abonelik Ayrıcalıkları)
  void _showRankDetailsBottomSheet(BuildContext context) {
    final rankIcons = {
      SiberRank.yeniDinleyici: Icons.headphones_rounded,
      SiberRank.cirakTaktisyen: Icons.military_tech_rounded,
      SiberRank.muziksever: Icons.radar_rounded,
      SiberRank.ritimTutkunu: Icons.graphic_eq_rounded,
      SiberRank.melodiUstasi: Icons.auto_awesome_rounded,
      SiberRank.sesGurmesi: Icons.workspace_premium_rounded,
      SiberRank.ozsesEfsanesi: Icons.diamond_rounded,
    };

    final rankColors = {
      SiberRank.yeniDinleyici: Colors.white54,
      SiberRank.cirakTaktisyen: Colors.greenAccent,
      SiberRank.muziksever: Colors.blueAccent,
      SiberRank.ritimTutkunu: Colors.purpleAccent,
      SiberRank.melodiUstasi: Colors.orangeAccent,
      SiberRank.sesGurmesi: Colors.redAccent,
      SiberRank.ozsesEfsanesi: Colors.amber,
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: BoxDecoration(
                  color: const Color(0xFF0F0F1A),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(25)),
                  border: Border.all(color: Colors.white10),
                  boxShadow: [
                    BoxShadow(
                      color: _getRankColor().withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ]),
              child: Column(
                children: [
                  // Çentik
                  Container(
                    margin: const EdgeInsets.only(top: 15, bottom: 10),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.military_tech_rounded, color: Colors.amber, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'RÜTBE VE ÖDÜL SİSTEMİ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Dinledikçe rütbe atla; geçici reklamsız dinleme süreleri, ek indirme ve AI liste haklarını hesabına ücretsiz kat!',
                      style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Bilgilendirme Kutucuğu (Abonelik Entegrasyonu)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getRankColor().withValues(alpha: 0.15),
                          Colors.purple.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getRankColor().withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.workspace_premium_rounded, color: _getRankColor(), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Şu anki dinleme süren: $_totalListenHours Saat | Rütben: $_rank',
                            style: TextStyle(
                              color: _getRankColor(),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      itemCount: RankManager.allTiers.length,
                      itemBuilder: (context, index) {
                        final tier = RankManager.allTiers[index];
                        bool isAchieved = _totalListenHours >= tier.hours;
                        bool isCurrent = _rank == tier.name;
                        Color activeColor = rankColors[tier.rank] ?? Colors.white54;
                        IconData iconData = rankIcons[tier.rank] ?? Icons.headphones_rounded;

                        return Opacity(
                          opacity: isAchieved ? 1.0 : 0.45,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? activeColor.withValues(alpha: 0.12)
                                  : Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCurrent
                                    ? activeColor.withValues(alpha: 0.6)
                                    : (isAchieved ? Colors.white24 : Colors.white10),
                                width: isCurrent ? 2.0 : 1.0,
                              ),
                              boxShadow: isCurrent
                                  ? [
                                      BoxShadow(
                                          color: activeColor.withValues(alpha: 0.25),
                                          blurRadius: 12)
                                    ]
                                  : [],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Sol İkon Rozeti
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isAchieved
                                        ? activeColor.withValues(alpha: 0.2)
                                        : Colors.black38,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isAchieved ? activeColor.withValues(alpha: 0.5) : Colors.white12,
                                    ),
                                  ),
                                  child: Icon(
                                    isAchieved ? iconData : Icons.lock_outline_rounded,
                                    color: isAchieved ? activeColor : Colors.white38,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Orta Detaylar
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            tier.name,
                                            style: TextStyle(
                                              color: isAchieved
                                                  ? Colors.white
                                                  : Colors.white54,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          if (isCurrent) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: activeColor.withValues(alpha: 0.25),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: activeColor, width: 1),
                                              ),
                                              child: Text(
                                                'MEVCUT RÜTBEN',
                                                style: TextStyle(color: activeColor, fontSize: 9, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        tier.hours == 0
                                            ? "Gereksinim: Başlangıç Seviyesi"
                                            : "Gereksinim: ${tier.hours} Saat Dinleme",
                                        style: TextStyle(
                                          color: isAchieved
                                              ? Colors.white70
                                              : Colors.white38,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Ana Ayrıcalık
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 15,
                                            color: isAchieved ? activeColor : Colors.white38,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              tier.perk,
                                              style: TextStyle(
                                                color: isAchieved ? activeColor : Colors.white60,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Ekstra Bonus Ayrıcalık
                                      if (tier.bonus.isNotEmpty) ...[
                                        const SizedBox(height: 5),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.stars_rounded,
                                              size: 14,
                                              color: isAchieved ? Colors.amberAccent : Colors.white30,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                tier.bonus,
                                                style: TextStyle(
                                                  color: isAchieved
                                                      ? Colors.amberAccent.withValues(alpha: 0.9)
                                                      : Colors.white38,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      // 🎯 GEÇİCİ REKLAMSIZ DİNLEME AKTİVASYON BUTONU
                                      if (tier.adFreeMinutes > 0) ...[
                                        const SizedBox(height: 8),
                                        FutureBuilder<bool>(
                                          future: SubscriptionManager().isRankAdFreeClaimed(tier.rank),
                                          builder: (context, snapshot) {
                                            final isClaimed = snapshot.data ?? false;
                                            final isCurrentlyAdFree = SubscriptionManager().isAdFree;
                                            final remainingText = SubscriptionManager().remainingAdFreeFormatted;

                                            if (SubscriptionManager().currentTier != SiberTier.free) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 13),
                                                    SizedBox(width: 4),
                                                    Text('Abonelikle Sınırsız Reklamsız', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              );
                                            }

                                            if (isClaimed) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: isCurrentlyAdFree ? Colors.green.withValues(alpha: 0.15) : Colors.white10,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: isCurrentlyAdFree ? Colors.greenAccent : Colors.white24),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(isCurrentlyAdFree ? Icons.timer_outlined : Icons.check_circle_outline, color: isCurrentlyAdFree ? Colors.greenAccent : Colors.white54, size: 13),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      isCurrentlyAdFree ? 'REKLAMSIZ MOD AKTİF ($remainingText)' : 'BU HEDİYE KULLANILDI',
                                                      style: TextStyle(color: isCurrentlyAdFree ? Colors.greenAccent : Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }

                                            if (isAchieved) {
                                              return InkWell(
                                                onTap: () async {
                                                  final success = await SubscriptionManager().claimAdFreePass(tier.rank);
                                                  if (success && context.mounted) {
                                                    setModalState(() {});
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('🎉 ${tier.name} hediyesi: ${tier.adFreeMinutes} Dakika Reklamsız Dinleme Başlatıldı!'),
                                                        backgroundColor: Colors.green,
                                                      ),
                                                    );
                                                  }
                                                },
                                                borderRadius: BorderRadius.circular(8),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(colors: [Colors.deepPurple, Colors.indigoAccent]),
                                                    borderRadius: BorderRadius.circular(8),
                                                    boxShadow: [
                                                      BoxShadow(color: Colors.deepPurpleAccent.withValues(alpha: 0.4), blurRadius: 6),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.flash_on_rounded, color: Colors.amberAccent, size: 14),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'REKLAMSIZ MODU BAŞLAT (+${tier.adFreeMinutes} Dk)',
                                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }

                                            return const SizedBox.shrink();
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Sağ Durum Rozeti
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                      color: isAchieved
                                          ? Colors.green.withValues(alpha: 0.2)
                                          : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isAchieved
                                            ? Colors.green.withValues(alpha: 0.5)
                                            : Colors.grey.withValues(alpha: 0.3),
                                      )),
                                  child: Text(
                                    isAchieved ? 'AÇIK' : 'KİLİTLİ',
                                    style: TextStyle(
                                      color:
                                          isAchieved ? Colors.greenAccent : Colors.grey,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // _showOTPDialog kaldırıldı, Firebase Auth entegre edildi.
}

// 🎯 SİBER HAMLE: Otonom Pasta Grafiği (Custom Painter)
class MoodPieChartPainter extends CustomPainter {
  final Map<String, int> data;
  MoodPieChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    double total = 0;
    for (var v in data.values) {
      total += v;
    }
    if (total == 0) return;

    double startAngle = -math.pi / 2;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    data.forEach((mood, value) {
      final sweepAngle = (value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = _getColor(mood)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round;

      // Neon Glow Etkisi
      final glowPaint = Paint()
        ..color = _getColor(mood).withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 25
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

      startAngle += sweepAngle;
    });
  }

  Color _getColor(String mood) {
    if (mood == 'Melankolik') return Colors.blueAccent;
    if (mood == 'Enerjik') return Colors.orangeAccent;
    if (mood == 'Sokak Ritmi') return Colors.redAccent;
    if (mood == 'Akustik') return Colors.greenAccent;
    return Colors.grey;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 🎯 YENİ SİBER HAMLE: Müzik DNA Radar Grafiği (Yetenek Ağacı)
class MusicDnaRadarPainter extends CustomPainter {
  final Map<String, int> moodStats;
  final Color auraColor;

  MusicDnaRadarPainter({required this.moodStats, required this.auraColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (moodStats.isEmpty) return;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = math.min(centerX, centerY) - 10;

    // Eksenleri belirle (5 Ana Parametre)
    Map<String, double> categories = {
      'Enerji': 0.0,
      'Melankoli': 0.0,
      'Odak': 0.0,
      'İsyan': 0.0,
      'Gizem': 0.0,
    };

    int totalScore = 0;
    moodStats.forEach((mood, score) {
      totalScore += score;
      if (mood == 'Enerjik' ||
          mood == 'Kopmalık' ||
          mood == 'Motivasyon' ||
          mood == 'Siber') {
        categories['Enerji'] = categories['Enerji']! + score;
      } else if (mood == 'Melankolik' ||
          mood == 'Efkârlı' ||
          mood == 'Nostaljik') {
        categories['Melankoli'] = categories['Melankoli']! + score;
      } else if (mood == 'Odaklanma' ||
          mood == 'Rahatlatıcı' ||
          mood == 'Uyku Öncesi') {
        categories['Odak'] = categories['Odak']! + score;
      } else if (mood == 'Sokak Ritmi' || mood == 'İsyankâr') {
        categories['İsyan'] = categories['İsyan']! + score;
      } else {
        categories['Gizem'] = categories['Gizem']! + score;
      }
    });

    if (totalScore == 0) return;

    // Normalizasyon (0.0 ile 1.0 arası)
    double maxVal = categories.values.reduce(math.max);
    if (maxVal == 0) maxVal = 1;

    categories.forEach((key, value) {
      categories[key] =
          (value / maxVal).clamp(0.1, 1.0); // Minimum %10 görünsün
    });

    const int sides = 5;
    const double angle = (math.pi * 2) / sides;

    Paint gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    Paint pathPaint = Paint()
      ..color = auraColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    Paint pathStrokePaint = Paint()
      ..color = auraColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3); // Neon Parlama

    // Çarkı Çiz (3 Kademeli Ağ)
    for (int i = 1; i <= 3; i++) {
      Path gridPath = Path();
      double currentRadius = radius * (i / 3);
      for (int j = 0; j < sides; j++) {
        double x = centerX + currentRadius * math.cos(j * angle - math.pi / 2);
        double y = centerY + currentRadius * math.sin(j * angle - math.pi / 2);
        if (j == 0) {
          gridPath.moveTo(x, y);
        } else {
          gridPath.lineTo(x, y);
        }
        // Merkezden köşelere çizgiler
        if (i == 3) {
          canvas.drawLine(Offset(centerX, centerY), Offset(x, y), gridPaint);
        }
      }
      gridPath.close();
      canvas.drawPath(gridPath, gridPaint);
    }

    // Değerleri Çiz (Müzik DNA'sı)
    Path dnaPath = Path();
    List<String> labels = categories.keys.toList();
    for (int j = 0; j < sides; j++) {
      double val = categories[labels[j]]!;
      double x = centerX + (radius * val) * math.cos(j * angle - math.pi / 2);
      double y = centerY + (radius * val) * math.sin(j * angle - math.pi / 2);
      if (j == 0) {
        dnaPath.moveTo(x, y);
      } else {
        dnaPath.lineTo(x, y);
      }

      // Noktaları belirginleştir
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = Colors.white);

      // Yazıları ekle
      final textPainter = TextPainter(
        text: TextSpan(
            text: labels[j],
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 8,
                fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      double textX = centerX +
          (radius + 15) * math.cos(j * angle - math.pi / 2) -
          (textPainter.width / 2);
      double textY = centerY +
          (radius + 15) * math.sin(j * angle - math.pi / 2) -
          (textPainter.height / 2);
      textPainter.paint(canvas, Offset(textX, textY));
    }
    dnaPath.close();

    canvas.drawPath(dnaPath, pathPaint);
    canvas.drawPath(dnaPath, pathStrokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
