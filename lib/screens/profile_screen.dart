import 'package:flutter/material.dart';
import 'siber_wrapped_screen.dart'; // 🚀 Siber Özet Ekranı
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
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../services/history_service.dart';
import '../services/auth_service.dart'; // 🎯 SİBER HAMLE: Gerçek Auth Motoru
import 'package:screenshot/screenshot.dart'; // 🎯 SİBER HAMLE: Wrapped
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../services/siber_theme_service.dart'; // 🔮 Siber Tema Bağlantısı
import '../widgets/siber_theme_picker_sheet.dart'; // 🎨 Yeni Tema Rengi Seçici
import '../widgets/siber_istatistik_sheet.dart'; // 📊 İstatistik Radarı
import 'listening_mode_screen.dart'; // 🎯 Dinlenme Modu


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  String _username = 'Siber Ajan';
  String _email = 'Bağlı hesap yok';
  String _rank = 'Acemi Dinleyici';
  String _nextRank = 'Çırak Taktisyen';
  int _totalListenHours = 0;
  int _hoursForNextRank = 5;
  double _rankProgress = 0.0;
  bool _isAccountLinked = false;

  // 🎯 VİZYON DEĞİŞKENLERİ

  String _avatarUrl = 'https://robohash.org/siber_ajan.png?set=set3';
  // 🎯 YENİ SİBER HAMLE: Otonom Sanatçı Podyumu ve YouTube Zekası
  List<MapEntry<String, int>> _topArtists = [];
  Map<String, String> _artistImages = {};
  bool _isLoadingImages = false;

  // 🎯 YENİ: Haftalık Ruh Hali Motoru
  Map<String, int> _moodStats = {};
  final String _dominantMood = 'Belirsiz';
  Color _auraColor = Colors.cyanAccent;

  bool _isSyncing = false;
  double _syncProgress = 0.0;
  String _lastSync = 'Senkronize Edilmedi';

  String _instagramHandle = '';
  String _twitterHandle = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // 🎯 SİBER HAMLE: İstihbarat Verilerini ve Bağlı Hesabı Otonom Yükle
  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final linked = prefs.getBool('siber_is_linked') ?? false;
    final name = prefs.getString('siber_username') ?? 'Siber Ajan';
    final email = prefs.getString('siber_email') ?? 'Bağlı hesap yok';
    // final auraValue =
    // prefs.getInt...
    final avatar = prefs.getString('siber_avatar_url') ??
        'https://robohash.org/$name.png?set=set3';
    final lastSyncTime =
        prefs.getString('siber_last_sync') ?? 'Henüz mühürlenmedi';
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
    String nextRank = 'Amatör';
    int hoursForNextRank = 5;
    double rankProgress = 0.0;

    final List<Map<String, dynamic>> rankTiers = [
      {'name': 'Yeni Dinleyici', 'hours': 0},
      {'name': 'Amatör', 'hours': 5},
      {'name': 'Müziksever', 'hours': 25},
      {'name': 'Ritim Tutkunu', 'hours': 75},
      {'name': 'Melodi Ustası', 'hours': 150},
      {'name': 'Ses Gurmesi', 'hours': 300},
      {'name': 'ÖZSES Efsanesi', 'hours': 500},
    ];

    for (int i = 0; i < rankTiers.length; i++) {
      if (totalHours >= rankTiers[i]['hours']) {
        rank = rankTiers[i]['name'];
        if (i < rankTiers.length - 1) {
          nextRank = rankTiers[i + 1]['name'];
          int currentTierHours = rankTiers[i]['hours'];
          int nextTierHours = rankTiers[i + 1]['hours'];
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

    if (mounted) {
      setState(() {
        _isAccountLinked = linked;
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
    if (_rank == 'ÖZSES VETERANI') return Colors.redAccent;
    if (_rank == 'Kıdemli Komutan') return Colors.orangeAccent;
    if (_rank == 'Usta Analist') return Colors.purpleAccent;
    if (_rank == 'Siber İstihbaratçı') return Colors.tealAccent;
    if (_rank == 'Saha Operatörü') return Colors.greenAccent;
    if (_rank == 'Çırak Taktisyen') return Colors.lightBlueAccent;
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
                      'Siber buluta bağlanmak için kimliğini doğrula.',
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
                        passwordController, 'Siber Şifre', Icons.lock,
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
                                    content: const Text('Siber Ağa Başarıyla Bağlanıldı!'),
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
                                String errorMsg = 'Siber Hata Oluştu.';
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
                                  'Lütfen siber mühür için tüm alanları doldur!'),
                              backgroundColor: Colors.redAccent,
                            ));
                          }
                        },
                        child: Text(
                            isLoginMode ? 'GİRİŞ YAP' : 'KAYIT OL & MÜHÜRLE',
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
                                scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Siber ağa başarıyla bağlanıldı (Google).'), backgroundColor: Colors.green));
                              }
                            }
                          } catch (e) {
                            scaffoldMessenger.showSnackBar(SnackBar(content: Text('Bağlantı hatası: Google Play Hizmetleri erişimi reddetti (SHA-1 Hatası)'), backgroundColor: Colors.red));
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Apple Button (Passive)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.apple, color: Colors.white, size: 28),
                        label: const Text('Apple ile Bağlan (Çok Yakında)', style: TextStyle(color: Colors.white70)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          side: const BorderSide(color: Colors.white24, width: 1),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Apple bağlantısı şu anda yapım aşamasında. Çok yakında!'), backgroundColor: Colors.orange)
                          );
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

  // 🎯 SİBER HAMLE: Hesabı Koparma Motoru
  void _unlinkAccount() async {
    // 1. Gerçek Çıkış İşlemi
    await AuthService().signOut();

    // 2. Arayüzü Yenile
    _loadProfileData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Hesap siber ağdan koparıldı.'),
        backgroundColor: Colors.orangeAccent,
      ));
    }
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
                const Text('Siber profiline bu platformu mühürle.',
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
                    content: Text('$platform başarıyla mühürlendi!'),
                    backgroundColor: platformColor,
                  ));
                }
              },
              child: const Text('Mühürle',
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
            title: Text('SİBER KİMLİK KARTI',
                style:
                    TextStyle(color: _auraColor, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      'Siber ajan adını ve avatarını güncelleyebilirsin.',
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
                    label: const Text('Otonom Yüz Üret'),
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
                child: Text('Mühürle',
                    style: TextStyle(
                        color: _auraColor, fontWeight: FontWeight.bold)),
              )
            ],
          );
        });
  }

  // 🎯 SİBER HAMLE: Bulut Senkronizasyon Simülasyonu
  Future<void> _startCloudSync() async {
    if (_isSyncing) return;
    setState(() {
      _isSyncing = true;
      _syncProgress = 0.0;
    });

    Timer.periodic(const Duration(milliseconds: 50), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _syncProgress += 0.02;
      });
      if (_syncProgress >= 1.0) {
        timer.cancel();
        final prefs = await SharedPreferences.getInstance();
        final now = DateTime.now();
        String timeStr =
            '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}';
        await prefs.setString('siber_last_sync', timeStr);
        setState(() {
          _isSyncing = false;
          _lastSync = timeStr;
        });
      }
    });
  }

  // 🎯 SİBER HAMLE: Keşfet Profilini Güncelleme Modülü
  void _showPersonalSurveyDialog() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> availableGenres = [
      'Türkçe Rap',
      'Arabesk',
      'Akustik',
      'Deep House',
      'Pop',
      'Rock',
      'Türkü',
      'R&B',
      'Özgün Müzik',
      'Slow'
    ];
    List<String> selectedGenres =
        prefs.getStringList('siber_personal_genres') ?? [];
    TextEditingController artistController = TextEditingController(
        text: prefs.getString('siber_personal_artists') ?? '');

    if (!mounted) return;

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: _auraColor),
              ),
              title: Text('KEŞFET PROFİLİNİ GÜNCELLE',
                  style: TextStyle(
                      color: _auraColor, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        'Siber yapay zekanın seni tanıması için dinlediğin müzik türlerini seç (Maks 4):',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableGenres.map((genre) {
                        final isSelected = selectedGenres.contains(genre);
                        return ChoiceChip(
                          label: Text(genre,
                              style: TextStyle(
                                  color:
                                      isSelected ? Colors.black : Colors.white,
                                  fontSize: 11)),
                          selected: isSelected,
                          selectedColor: _auraColor,
                          backgroundColor: Colors.black45,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                if (selectedGenres.length < 4) {
                                  selectedGenres.add(genre);
                                }
                              } else {
                                selectedGenres.remove(genre);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text('Favori Sanatçıların (Virgülle ayırarak yaz):',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: artistController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Örn: Sagopa, Müslüm, Ceza...',
                        hintStyle: const TextStyle(color: Colors.white30),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: _auraColor)),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: _auraColor)),
                      ),
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _auraColor),
                  onPressed: () async {
                    await prefs.setStringList(
                        'siber_personal_genres', selectedGenres);
                    await prefs.setString(
                        'siber_personal_artists', artistController.text.trim());
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text('Keşfet Profilin Başarıyla Güncellendi!'),
                        backgroundColor: _auraColor,
                      ));
                    }
                  },
                  child: const Text('Mühürle',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          });
        });
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
      return 'Siber veri akışı tespit edilemedi. Nöronlarını müzikle beslemeye devam et.';
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
        return 'SİSTEM TEŞHİSİ: Nöronların alev alev! Ağ bağlantıların maksimum hızda. $artist ritimleriyle sistemine enerji pompalıyorsun. Tam bir siber savaşçı!';
      case 'Odaklanma':
      case 'Rahatlatıcı':
      case 'Uyku Öncesi':
      case 'Mistik':
        return 'SİSTEM TEŞHİSİ: Meditasyon ve mutlak odak hali. $artist frekansları zihnindeki gürültüyü arındırıyor. Siber huzura ulaşıldı.';
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
                '🧠 SİBER ZEKANIN TEŞHİSİ',
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

  // 🎯 YENİ SİBER HAMLE: Otonom Sanatçı Podyumu (YouTube Entegrasyonlu)
  Widget _buildArtistPodium() {
    if (_topArtists.isEmpty) {
      return const Text('Henüz yeterli veri yok.',
          style: TextStyle(color: Colors.white38));
    }

    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('🏆 SİBER SANATÇI PODYUMU',
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
        title: Text('SİBER KARARGAH',
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
            onPressed: () async {
              final subManager = SubscriptionManager();
              if (!await subManager.canViewStatsReport()) {
                if (mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SiberPaymentScreen(themeColor: _auraColor)));
                }
                return;
              }
              await subManager.updateStatsReportDate();

              if (mounted) {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => SiberIstatistikSheet(themeColor: _auraColor),
                );
              }
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
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
                // 🎯 PROFİL AVATARI VE BİLGİLERİ
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _getRankColor().withValues(alpha: 0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: _getRankColor().withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 5),
                    ],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _showEditProfileDialog,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _auraColor.withValues(alpha: 0.8),
                                    blurRadius: 25,
                                    spreadRadius: 5,
                                  ),
                                  BoxShadow(
                                    color: _auraColor.withValues(alpha: 0.4),
                                    blurRadius: 50,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 55,
                                backgroundColor: Colors.white10,
                                backgroundImage: _avatarUrl.startsWith('http') 
                                    ? NetworkImage(_avatarUrl) as ImageProvider
                                    : FileImage(File(_avatarUrl)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: _auraColor, shape: BoxShape.circle),
                              child: const Icon(Icons.edit,
                                  color: Colors.black, size: 16),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      GestureDetector(
                        onTap: _showEditProfileDialog,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_username,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Icon(Icons.edit, color: _auraColor, size: 18),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(_email,
                          style: TextStyle(
                              color: _isAccountLinked
                                  ? _auraColor
                                  : Colors.white54,
                              fontSize: 13)),
                      const SizedBox(height: 15),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: _getRankColor().withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.military_tech,
                                        color: _getRankColor(), size: 24),
                                    const SizedBox(width: 8),
                                    Text(_rank,
                                        style: TextStyle(
                                            color: _getRankColor(),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                  ],
                                ),
                                if (_nextRank != 'MAX SEVİYE')
                                  Text('Hedef: $_nextRank',
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Stack(
                              children: [
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _rankProgress,
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _getRankColor(),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                            color: _getRankColor()
                                                .withValues(alpha: 0.5),
                                            blurRadius: 8)
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (_nextRank != 'MAX SEVİYE')
                              Text(
                                  'Terfi için $_hoursForNextRank saat daha dinlemelisin.',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 11))
                            else
                              const Text("SİBER KARARGAH'IN ZİRVESİNDESİN",
                                  style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
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
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: _getRankColor().withValues(alpha: 0.5)),
                        boxShadow: [
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
                                const Text('Siber Bulut Mührü',
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
                if (!_isAccountLinked)
                  _buildProfileButton(
                    title: 'SİBER HESABI BAĞLA',
                    subtitle: 'Sisteme giriş yap ve profilini mühürle',
                    icon: Icons.link,
                    color: _auraColor,
                    onTap: _showLinkAccountDialog,
                  )
                else
                  _buildProfileButton(
                    title: 'HESABIN BAĞINI KOPAR',
                    subtitle: 'Sistemden güvenli şekilde çıkış yap',
                    icon: Icons.link_off,
                    color: Colors.redAccent,
                    onTap: _unlinkAccount,
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
                  title: 'SİBER KARARGAH (PREMİUM)',
                  subtitle: 'Özel Ayrıcalıklar ve Siber Ligler',
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

                // 🚀 YILLIK SİBER ÖZETİN
                _buildProfileButton(
                  title: 'YILLIK SİBER ÖZETİN (YENİ!)',
                  subtitle: 'Spotify Wrapped tarzı yıllık müzik karnen hazır!',
                  icon: Icons.auto_awesome,
                  color: Colors.purpleAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SiberWrappedScreen(),
                      ),
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
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _auraColor.withValues(alpha: 0.3)),
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
                                const Text('Haftalık Siber Ruh Hali Raporu',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold)),
                              ],
                            )),
                        const SizedBox(height: 15),
                        if (_moodStats.isEmpty)
                          const Text('Son 7 günde yeterli veri toplanmadı.',
                              style: TextStyle(color: Colors.white38))
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
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ), // Screenshot bitişi

                const SizedBox(height: 15),
                // 📸 SİBER PAYLAŞIM BUTONU (ÖZSES WRAPPED)
                _buildProfileButton(
                  title: 'ÖZETİMİ PAYLAŞ',
                  subtitle: 'Dinleme istatistiklerini arkadaşlarınla paylaş',
                  icon: Icons.share,
                  color: Colors.purpleAccent,
                  onTap: _shareCyberIdentity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 📸 YENİ SİBER HAMLE: Sosyal Medya Paylaşım Motoru (Wrapped)
  Future<void> _shareCyberIdentity() async {
    try {
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/siber_kimlik.png';

      final imageBytes = await _screenshotController.capture(
          delay: const Duration(milliseconds: 20));
      if (imageBytes != null) {
        final file = File(imagePath);
        await file.writeAsBytes(imageBytes);

        await Share.shareXFiles(
          [XFile(imagePath)],
          text: 'ÖZSES Müzik Karnem! 🎵 Sen de keşfetmek için indir.',
        );
      }
    } catch (e) {
      debugPrint('Siber Kimlik Paylaşım Hatası: $e');
    }
  }

  Widget _buildProfileButton(
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withValues(alpha: 0.5)),
            boxShadow: [
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

  // 🎯 YENİ: Rütbe ve Ödüller Detay Sayfası (Canavar Sistem - Kümülatif Ödüller)
  void _showRankDetailsBottomSheet(BuildContext context) {
    final List<Map<String, dynamic>> rankDetails = [
      {
        'name': 'Yeni Dinleyici',
        'hours': 0,
        'icon': Icons.headphones,
        'color': Colors.white54,
        'perk': 'Temel Dinleme ve Keşfet Erişimi',
        'bonus': '',
      },
      {
        'name': 'Çırak Taktisyen',
        'hours': 5,
        'icon': Icons.music_note,
        'color': Colors.greenAccent,
        'perk': '30 Dk Reklamsız Dinleme',
        'bonus': '',
      },
      {
        'name': 'Müziksever',
        'hours': 25,
        'icon': Icons.radar,
        'color': Colors.blueAccent,
        'perk': 'Ruh Hali Analizi (Günde 1 Kez)',
        'bonus': '+ 30 Dk Reklamsız Dinleme Hediye',
      },
      {
        'name': 'Ritim Tutkunu',
        'hours': 75,
        'icon': Icons.mic_external_on,
        'color': Colors.purpleAccent,
        'perk': 'Özel Karaoke Modu (Günde 2 Şarkı)',
        'bonus': '+ Ruh Hali Analizi + 30 Dk Reklamsız',
      },
      {
        'name': 'Melodi Ustası',
        'hours': 150,
        'icon': Icons.auto_awesome,
        'color': Colors.orangeAccent,
        'perk': 'Şahsi Keşfet: AI Albüm (Haftalık 1)',
        'bonus': '+ Karaoke + Ruh Hali + 1 Saat Reklamsız',
      },
      {
        'name': 'Ses Gurmesi',
        'hours': 300,
        'icon': Icons.card_giftcard,
        'color': Colors.redAccent,
        'perk': 'ÖZSES Özel Gün Özetleri (Wrapped)',
        'bonus': '+ AI Albüm + Karaoke + Ruh Hali + 2 Saat Reklamsız',
      },
      {
        'name': 'ÖZSES Efsanesi',
        'hours': 500,
        'icon': Icons.diamond,
        'color': Colors.amber,
        'perk': 'Tam Yetkili Siber Ajan Sürümü',
        'bonus':
            '+ Haftalık 8 Saat Reklamsız + Sınırsız AI Liste + Limitsiz Karaoke',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
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
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'SİBER KARİYER ÖDÜLLERİ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const Text(
                'Dinledikçe rütbe atla, geçmişteki yeteneklerini de katlayarak taşı.',
                style: TextStyle(color: Colors.white54, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: rankDetails.length,
                  itemBuilder: (context, index) {
                    final rank = rankDetails[index];
                    bool isAchieved = _totalListenHours >= rank['hours'];
                    bool isCurrent = _rank == rank['name'];
                    Color activeColor =
                        isAchieved ? rank['color'] : Colors.white24;

                    return Opacity(
                      opacity: isAchieved ? 1.0 : 0.4,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? activeColor.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isCurrent
                                ? activeColor.withValues(alpha: 0.5)
                                : Colors.white10,
                            width: isCurrent ? 2.0 : 1.0,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                      color: activeColor.withValues(alpha: 0.2),
                                      blurRadius: 10)
                                ]
                              : [],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sol İkon
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isAchieved
                                    ? activeColor.withValues(alpha: 0.2)
                                    : Colors.black26,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAchieved ? rank['icon'] : Icons.lock,
                                color: activeColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 15),

                            // Orta Detaylar
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        rank['name'],
                                        style: TextStyle(
                                          color: isAchieved
                                              ? Colors.white
                                              : Colors.white54,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (isCurrent)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 8.0),
                                          child: Icon(Icons.my_location,
                                              color: activeColor, size: 14),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "Gereksinim: ${rank['hours']} Saat Dinleme",
                                    style: TextStyle(
                                      color: isAchieved
                                          ? Colors.white70
                                          : Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        isAchieved
                                            ? Icons.military_tech
                                            : Icons.lock_outline,
                                        size: 14,
                                        color: activeColor.withValues(alpha: 0.8),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          rank['perk'],
                                          style: TextStyle(
                                            color: activeColor.withValues(alpha: 0.9),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (rank['bonus'] != '') ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.add,
                                          size: 12,
                                          color: Colors.greenAccent
                                              .withValues(alpha: 0.7),
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            rank['bonus'],
                                            style: TextStyle(
                                              color: Colors.greenAccent
                                                  .withValues(alpha: 0.7),
                                              fontSize: 10,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Sağ Statüs
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
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
                                isAchieved ? 'AKTİF' : 'KİLİTLİ',
                                style: TextStyle(
                                  color:
                                      isAchieved ? Colors.green : Colors.grey,
                                  fontSize: 8,
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
              const SizedBox(height: 20),
            ],
          ),
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
