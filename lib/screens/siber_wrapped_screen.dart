import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../services/analytics_service.dart';
import '../services/history_service.dart';
import '../widgets/cyber_rotary_knob.dart';
import '../widgets/cyber_wireframe_grid.dart';
import '../widgets/cyber_story_canvas.dart';

/// 🚀 ÖZSES 2026 SİBER WRAPPED (YIL SONU İNTERAKTİF SİBER ÖZETİ)
/// 4 Adımlı Profesyonel Siber Karusel:
/// 01 - Sözün & Dönemin (Hologram Plak + %65 Arabesk Slider + Canlı Sayıcı + Top 3 Sanatçı)
/// 02 - Sesin & Oranın (Döner Potansiyometre + 3D Siber Grid + Sosyal Medya)
/// 03 - Zaman & Ritim Matrisi (Gece Kuşu / Biyoritim + 24 Saatlik Çubuk Grafiği + Seri)
/// 04 - Dinleme Haritan & Hikaye Stüdyosu (Top 5 Sanatçı Toggle + 9:16 Hikaye Dışa Aktarma)
class SiberWrappedScreen extends StatefulWidget {
  final CyberStoryCardType? initialCardType;
  final bool autoOpenStudio;

  const SiberWrappedScreen({
    super.key,
    this.initialCardType,
    this.autoOpenStudio = false,
  });

  @override
  State<SiberWrappedScreen> createState() => _SiberWrappedScreenState();
}

class _SiberWrappedScreenState extends State<SiberWrappedScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final ScreenshotController _screenshotController = ScreenshotController();
  final ScreenshotController _modalScreenshotController = ScreenshotController();

  late final AnimationController _vinylAnimController;

  int _activeTabIndex = 0;
  bool _isLoading = true;

  // 📊 VERİ MODELİ
  final String _primaryGenre = 'ARABESK';
  double _primaryGenrePercent = 65.0;

  double _genreRap = 42.0;
  double _genrePop = 28.0;
  double _genreOzgun = 30.0;
  double _genreRock = 20.0;

  double _knobMasterValue = 0.5;
  double _knob1Value = 0.65;
  double _knob2Value = 0.45;
  double _knobSensitivity = 0.75;
  double _knobRhythm = 0.60;

  String _listeningPersona = 'GECE OZANI';
  int _totalListenHours = 247;
  final String _nightRatio = '%68 Gece';
  final int _streakDays = 34;
  String _topSongName = 'Azer Bülbül - Çoğu Gitti Azı Kaldı';

  List<_ArtistStat> _artists = [];
  bool _isSharing = false;

  // 🎨 Hikaye Stüdyosu Teması
  CyberStoryTheme _selectedStoryTheme = CyberStoryTheme.turkuaz;
  CyberStoryCardType _selectedStoryCardType = CyberStoryCardType.sanatcilar;

  @override
  void initState() {
    super.initState();
    if (widget.initialCardType != null) {
      _selectedStoryCardType = widget.initialCardType!;
    }
    _vinylAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _loadRealData();
  }

  @override
  void dispose() {
    _vinylAnimController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadRealData() async {
    try {
      final analytics = AnalyticsService();
      await analytics.addMockDataIfEmpty();

      final topSongs = await analytics.getTopSongs(limit: 5);
      final history = await HistoryService.getHistory();
      final persona = await analytics.getListeningPersona();
      final totalSec = await analytics.getTotalListeningTime();

      Map<String, int> artistHoursMap = {};
      int calcTotalSec = totalSec;

      for (var rec in history) {
        calcTotalSec += rec.totalListenSeconds;
        if (rec.name.contains('-')) {
          final artist = rec.name.split('-').first.trim();
          final hours = (rec.totalListenSeconds / 3600).round();
          artistHoursMap[artist] = (artistHoursMap[artist] ?? 0) + (hours > 0 ? hours : 1);
        }
      }

      List<_ArtistStat> loaded = [];
      if (artistHoursMap.isNotEmpty) {
        final sorted = artistHoursMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        loaded = sorted.take(5).map((e) {
          return _ArtistStat(name: e.key, hours: e.value, percent: 65, isEnabled: true);
        }).toList();
      }

      // Eğer veri kısıtlıysa zengin ve havalı fallback verileri
      if (loaded.isEmpty) {
        loaded = [
          _ArtistStat(name: 'Azer Bülbül', hours: 142, percent: 65, isEnabled: true),
          _ArtistStat(name: 'Müslüm Gürses', hours: 120, percent: 70, isEnabled: true),
          _ArtistStat(name: 'Ahmet Kaya', hours: 86, percent: 65, isEnabled: true),
          _ArtistStat(name: 'Ezhel', hours: 54, percent: 50, isEnabled: true),
          _ArtistStat(name: 'Sagopa Kajmer', hours: 31, percent: 45, isEnabled: true),
        ];
      }

      String topSong = 'Azer Bülbül - Çoğu Gitti Azı Kaldı';
      if (topSongs.isNotEmpty && topSongs.first['title'] != null) {
        topSong = '${topSongs.first['channel'] ?? ''} - ${topSongs.first['title']}';
      }

      final hoursCalculated = (calcTotalSec / 3600).round();

      if (mounted) {
        setState(() {
          _artists = loaded;
          if (_artists.isNotEmpty) {
            _primaryGenrePercent = _artists.first.percent.toDouble();
          }
          if (persona.isNotEmpty && persona != 'Bilinmiyor') {
            _listeningPersona = persona == 'Gece Kuşu' ? 'GECE OZANI' : (persona == 'Sabah İnsanı' ? 'ŞAFAK AVCISI' : 'SİBER GÖÇEBE');
          }
          if (hoursCalculated > 0) {
            _totalListenHours = hoursCalculated;
          }
          _topSongName = topSong;
          _isLoading = false;
        });
        if (widget.autoOpenStudio && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _openStoryStudio(context);
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _artists = [
            _ArtistStat(name: 'Azer Bülbül', hours: 142, percent: 65, isEnabled: true),
            _ArtistStat(name: 'Müslüm Gürses', hours: 120, percent: 70, isEnabled: true),
            _ArtistStat(name: 'Ahmet Kaya', hours: 86, percent: 65, isEnabled: true),
            _ArtistStat(name: 'Ezhel', hours: 54, percent: 50, isEnabled: true),
            _ArtistStat(name: 'Sagopa Kajmer', hours: 31, percent: 45, isEnabled: true),
          ];
          _isLoading = false;
        });
      }
    }
  }

  void _onTabSelected(int index) {
    HapticFeedback.selectionClick();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  // 📱 HİKAYE STÜDYOSU AÇILIŞ MODALI (9:16 ÖZEL DIŞA AKTARMA)
  void _openStoryStudio(BuildContext context) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final activeArtists = _artists
                .where((a) => a.isEnabled)
                .map((a) => StoryArtistItem(name: a.name, hours: a.hours, percent: a.percent))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.92,
              decoration: const BoxDecoration(
                color: Color(0xFF0C0E17),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(color: Color(0xFF00FFE0), blurRadius: 20, spreadRadius: -10),
                ],
              ),
              child: Column(
                children: [
                  // Üst Çekme Çubuğu
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Başlık Barı
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HİKAYE STÜDYOSU',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              '9:16 Instagram & Durum Formatı',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // 🃏 Kart Türü Seçici (Sanatçılar, Toplu İstatistik, Siber Analiz, Top Şarkılar)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCardTypePill(
                          title: '💿 Sanatçılar',
                          isSelected: _selectedStoryCardType == CyberStoryCardType.sanatcilar,
                          onTap: () {
                            setModalState(() => _selectedStoryCardType = CyberStoryCardType.sanatcilar);
                            setState(() => _selectedStoryCardType = CyberStoryCardType.sanatcilar);
                            HapticFeedback.selectionClick();
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildCardTypePill(
                          title: '📊 Toplu İstatistik',
                          isSelected: _selectedStoryCardType == CyberStoryCardType.topluIstatistik,
                          onTap: () {
                            setModalState(() => _selectedStoryCardType = CyberStoryCardType.topluIstatistik);
                            setState(() => _selectedStoryCardType = CyberStoryCardType.topluIstatistik);
                            HapticFeedback.selectionClick();
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildCardTypePill(
                          title: '🧠 Siber Analiz',
                          isSelected: _selectedStoryCardType == CyberStoryCardType.siberAnaliz,
                          onTap: () {
                            setModalState(() => _selectedStoryCardType = CyberStoryCardType.siberAnaliz);
                            setState(() => _selectedStoryCardType = CyberStoryCardType.siberAnaliz);
                            HapticFeedback.selectionClick();
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildCardTypePill(
                          title: '🏆 Top Şarkılar',
                          isSelected: _selectedStoryCardType == CyberStoryCardType.topSarkilar,
                          onTap: () {
                            setModalState(() => _selectedStoryCardType = CyberStoryCardType.topSarkilar);
                            setState(() => _selectedStoryCardType = CyberStoryCardType.topSarkilar);
                            HapticFeedback.selectionClick();
                          },
                        ),
                      ],
                    ),
                  ),

                  // 🎨 Tema Seçici Haplar (Turkuaz, Magenta, Altın)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildThemeSelectorPill(
                          title: 'Turkuaz',
                          color: const Color(0xFF00FFE0),
                          isSelected: _selectedStoryTheme == CyberStoryTheme.turkuaz,
                          onTap: () {
                            setModalState(() => _selectedStoryTheme = CyberStoryTheme.turkuaz);
                            setState(() => _selectedStoryTheme = CyberStoryTheme.turkuaz);
                            HapticFeedback.selectionClick();
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildThemeSelectorPill(
                          title: 'Magenta',
                          color: const Color(0xFFFF007F),
                          isSelected: _selectedStoryTheme == CyberStoryTheme.magenta,
                          onTap: () {
                            setModalState(() => _selectedStoryTheme = CyberStoryTheme.magenta);
                            setState(() => _selectedStoryTheme = CyberStoryTheme.magenta);
                            HapticFeedback.selectionClick();
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildThemeSelectorPill(
                          title: 'Altın VIP',
                          color: const Color(0xFFFFD700),
                          isSelected: _selectedStoryTheme == CyberStoryTheme.altin,
                          onTap: () {
                            setModalState(() => _selectedStoryTheme = CyberStoryTheme.altin);
                            setState(() => _selectedStoryTheme = CyberStoryTheme.altin);
                            HapticFeedback.selectionClick();
                          },
                        ),
                      ],
                    ),
                  ),

                  // 📱 Canlı Önizleme Alanı (Screenshot Kapsülü)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                      child: Center(
                        child: Screenshot(
                          controller: _modalScreenshotController,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CyberStoryCanvas(
                              cardType: _selectedStoryCardType,
                              theme: _selectedStoryTheme,
                              primaryGenre: _primaryGenre,
                              primaryGenrePercent: _primaryGenrePercent,
                              persona: _listeningPersona,
                              totalHours: _totalListenHours,
                              nightOwlRatio: _nightRatio,
                              streakDays: _streakDays,
                              artists: activeArtists,
                              topSong: _topSongName,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Alt Butonlar: HİKAYEDE PAYLAŞ & GALERİYE KAYDET
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        // Galeriye Kaydet Butonu
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text('KAYDET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => _exportStoryCard(isSaveOnly: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Instagram / Doğrudan Paylaş Butonu
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: const Text('HİKAYEDE PAYLAŞ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00FFE0),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 6,
                              shadowColor: const Color(0xFF00FFE0).withValues(alpha: 0.5),
                            ),
                            onPressed: () => _exportStoryCard(isSaveOnly: false),
                          ),
                        ),
                      ],
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

  Widget _buildCardTypePill({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final activeColor = _selectedStoryTheme == CyberStoryTheme.magenta
        ? const Color(0xFFFF007F)
        : (_selectedStoryTheme == CyberStoryTheme.altin
            ? const Color(0xFFFFD700)
            : const Color(0xFF00FFE0));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white12,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelectorPill({
    required String title,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.white12,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🚀 HİKAYE KARTINI ÇIKARMA VE PAYLAŞMA
  Future<void> _exportStoryCard({required bool isSaveOnly}) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    HapticFeedback.heavyImpact();

    try {
      final imageBytes = await _modalScreenshotController.capture(
        pixelRatio: 3.0,
        delay: const Duration(milliseconds: 80),
      );

      if (imageBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${tempDir.path}/ozses_siber_story_$timestamp.png');
        await file.writeAsBytes(imageBytes);

        if (isSaveOnly) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF00FFE0)),
                    SizedBox(width: 8),
                    Expanded(child: Text('9:16 Hikaye kartı cihaza başarıyla kaydedildi!')),
                  ],
                ),
                backgroundColor: const Color(0xFF0C1625),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        } else {
          // ignore: deprecated_member_use
          await Share.shareXFiles(
            [XFile(file.path)],
            text: '🎧 ÖZSES 2026 Siber Müzik Özetim! İşte benim yılım.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paylaşım hatası: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF090A0F),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00FFE0)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      body: SafeArea(
        child: Column(
          children: [
            // 🏷️ ÜST 01 - 02 - 03 - 04 KONTROL KAPSÜLLERİ & EKOLAYZER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF00FFE0)),
                    onPressed: () => Navigator.pop(context),
                  ),

                  // 4'lü Kapsül Dizilimi
                  Row(
                    children: [
                      _buildTabPill('01', 0),
                      const SizedBox(width: 10),
                      _buildTabPill('02', 1),
                      const SizedBox(width: 10),
                      _buildTabPill('03', 2),
                      const SizedBox(width: 10),
                      _buildTabPill('04', 3),
                    ],
                  ),

                  // Mini Siber Ekolayzer
                  _buildAnimatedMiniEqualizer(),
                ],
              ),
            ),

            // 📱 4 SAYFALI SİBER GÖRÜNÜM
            Expanded(
              child: Screenshot(
                controller: _screenshotController,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _activeTabIndex = index);
                  },
                  children: [
                    _buildScreen01(),
                    _buildScreen02(),
                    _buildScreen03(),
                    _buildScreen04(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 💊 ÜST 01-02-03-04 SEKMELERİ
  Widget _buildTabPill(String title, int index) {
    final isActive = _activeTabIndex == index;
    return GestureDetector(
      onTap: () => _onTabSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 40,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFF00FFE0) : Colors.white12,
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF00FFE0).withValues(alpha: 0.35),
                    blurRadius: 10,
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? const Color(0xFF00FFE0) : Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedMiniEqualizer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (i) {
          return AnimatedBuilder(
            animation: _vinylAnimController,
            builder: (ctx, child) {
              final val = (math.sin(_vinylAnimController.value * 2 * math.pi * (i + 1)) + 1) / 2;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                width: 2.5,
                height: 6 + (val * 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FFE0),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  // ==========================================
  // 🌟 EKRAN 01: SÖZÜN & DÖNEMİN (AURA + PLAK)
  // ==========================================
  Widget _buildScreen01() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Column(
        children: [
          // Başlık Barı
          Column(
            children: [
              const Text(
                'ÖZSES',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              Text(
                '2026 SÖZÜN & DÖNEMİN',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 🧊 MERKEZİ BUZLU CAM KART (FROSTED GLASS CARD)
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.02),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.16),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hologram Dönen Mini Plak
                      RotationTransition(
                        turns: _vinylAnimController,
                        child: Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE040FB).withValues(alpha: 0.4),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          child: CustomPaint(
                            painter: _VinylPainter(color: const Color(0xFFE040FB)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'SENİN SÖZÜN EN ÇOK HANGİSİ?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        'BENİM DÖNEMİM',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Parlayan Canlı Sayıcı Yüzde & Tür
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: _primaryGenrePercent),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (ctx, animVal, _) {
                          return Text(
                            '$_primaryGenre %${animVal.round()}',
                            style: GoogleFonts.bungee(
                              fontSize: 30,
                              color: const Color(0xFFE040FB),
                              shadows: [
                                const Shadow(
                                  color: Color(0xFFE040FB),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),

                      // İnteraktif [-] ──●── [+] Slider
                      Row(
                        children: [
                          _buildStepButton(Icons.remove, () {
                            setState(() {
                              _primaryGenrePercent = (_primaryGenrePercent - 5).clamp(10, 100);
                            });
                            HapticFeedback.selectionClick();
                          }),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3.5,
                                activeTrackColor: const Color(0xFF00FFE0),
                                inactiveTrackColor: Colors.white12,
                                thumbColor: Colors.white,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                overlayColor: const Color(0xFF00FFE0).withValues(alpha: 0.2),
                              ),
                              child: Slider(
                                value: _primaryGenrePercent,
                                min: 10,
                                max: 100,
                                onChanged: (val) {
                                  setState(() => _primaryGenrePercent = val);
                                  HapticFeedback.selectionClick();
                                },
                              ),
                            ),
                          ),
                          _buildStepButton(Icons.add, () {
                            setState(() {
                              _primaryGenrePercent = (_primaryGenrePercent + 5).clamp(10, 100);
                            });
                            HapticFeedback.selectionClick();
                          }),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manuel Oran Ayarla',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 👥 TOP ARTISTS YÜZDELERİ
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Top Sanatçılar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _artists.take(3).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, idx) {
                      final art = _artists[idx];
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                art.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '%${art.percent}',
                                style: const TextStyle(
                                  color: Color(0xFF00FFE0),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: art.percent / 100.0,
                              minHeight: 4,
                              backgroundColor: Colors.white10,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00FFE0)),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 🚀 HİKAYE STÜDYOSUNA GEÇ BUTONU
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.auto_awesome_rounded, size: 20),
              label: const Text(
                'HİKAYE STÜDYOSUNU AÇ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              onPressed: () => _openStoryStudio(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FFE0),
                foregroundColor: Colors.black,
                elevation: 8,
                shadowColor: const Color(0xFF00FFE0).withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStepButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Icon(icon, color: Colors.white70, size: 16),
      ),
    );
  }

  // ==========================================
  // 🌟 EKRAN 02: SESİN, ORANIN & 3D GRİD
  // ==========================================
  Widget _buildScreen02() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Column(
        children: [
          // Üst Başlık
          Column(
            children: [
              const Text(
                'ÖZSES',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
              Text(
                '2026 SESİN & ORANIN',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Text(
            'SENİN SESİN,\nSENİN ORANIN',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),

          Text(
            'DİNLEME ORANLARIN',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),

          // 🎚️ 4 TANE BUZLU CAM SLIDER KARTI
          _buildGenreGlassSlider('Rap / Trap', _genreRap, (val) => setState(() => _genreRap = val)),
          const SizedBox(height: 8),
          _buildGenreGlassSlider('Pop / Elektronik', _genrePop, (val) => setState(() => _genrePop = val)),
          const SizedBox(height: 8),
          _buildGenreGlassSlider('Özgün / Türkü', _genreOzgun, (val) => setState(() => _genreOzgun = val)),
          const SizedBox(height: 8),
          _buildGenreGlassSlider('Rock / Alternatif', _genreRock, (val) => setState(() => _genreRock = val)),
          const SizedBox(height: 12),

          // 🎛️ DÖNER POTANSİYOMETRE (KNOB)
          CyberRotaryKnob(
            size: 50,
            value: _knobMasterValue,
            label: 'Canlı Modüle Et',
            onChanged: (val) {
              setState(() {
                _knobMasterValue = val;
                _genreRap = (30 + val * 40).clamp(10, 90);
                _genrePop = (20 + (1 - val) * 30).clamp(10, 80);
                _genreOzgun = (100 - _genreRap - _genrePop).clamp(10, 60);
              });
            },
          ),

          const Spacer(),

          // 🌐 3D SİBER TEL KAFES IZGARASI (CYBER WIREFRAME GRID)
          const CyberWireframeGrid(height: 80),

          // 📱 SOSYAL MEDYA İKONLARI
          Text(
            'Hikayede Canlı Paylaş',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialCircle(Icons.camera_alt_outlined, () => _openStoryStudio(context)),
              const SizedBox(width: 18),
              _buildSocialCircle(Icons.music_note_rounded, () => _openStoryStudio(context)),
              const SizedBox(width: 18),
              _buildSocialCircle(Icons.send_rounded, () => _openStoryStudio(context)),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildGenreGlassSlider(String title, double value, ValueChanged<double> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              Text('%${value.round()}', style: const TextStyle(color: Color(0xFF00FFE0), fontSize: 13, fontWeight: FontWeight.w800)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: const Color(0xFF00FFE0),
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value.clamp(0, 100),
              min: 0,
              max: 100,
              onChanged: (val) {
                onChanged(val);
                HapticFeedback.selectionClick();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialCircle(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  // ==========================================
  // 🌟 EKRAN 03: ZAMAN & RİTİM MATRİSİ (BİYORİTİM)
  // ==========================================
  Widget _buildScreen03() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Column(
        children: [
          Column(
            children: [
              const Text(
                'ÖZSES',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
              Text(
                '2026 ZAMAN & BİYORİTİM',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Text(
            'BİYORİTİM &\nDİNLEME MATRİSİ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),

          // Karakter Rozeti
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF7000FF).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF7000FF)),
            ),
            child: Text(
              'KARAKTER: $_listeningPersona ($_nightRatio)',
              style: const TextStyle(
                color: Color(0xFF00FFE0),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 📊 24-Saatlik Dağılım Çubuk Grafiği
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '24 Saatlik Akış Dağılımı',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildHourBar('00-06\nGece', 0.85, '%68', const Color(0xFF00FFE0)),
                    _buildHourBar('06-12\nSabah', 0.25, '%12', const Color(0xFF7000FF)),
                    _buildHourBar('12-18\nÖğle', 0.40, '%20', const Color(0xFFFF007F)),
                    _buildHourBar('18-24\nAkşam', 0.65, '%45', const Color(0xFFFFD700)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3'lü İstatistik Kartı (Saat, Seri, Şarkı)
          Row(
            children: [
              _buildSmallStatCard('TOPLAM', '$_totalListenHours SAAT', Icons.timelapse_rounded),
              const SizedBox(width: 8),
              _buildSmallStatCard('SERİ', '$_streakDays GÜN', Icons.local_fire_department_rounded),
              const SizedBox(width: 8),
              _buildSmallStatCard('TEKRAR', '48 KEZ', Icons.repeat_rounded),
            ],
          ),
          const SizedBox(height: 14),

          // Çift Döner Kadran
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CyberRotaryKnob(
                size: 52,
                value: _knobSensitivity,
                label: 'Filtre Hassasiyeti',
                onChanged: (val) => setState(() => _knobSensitivity = val),
              ),
              const SizedBox(width: 40),
              CyberRotaryKnob(
                size: 52,
                value: _knobRhythm,
                label: 'Ritim Frekansı',
                onChanged: (val) => setState(() => _knobRhythm = val),
              ),
            ],
          ),

          const Spacer(),

          // Stüdyo Butonu
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.palette_rounded, size: 18),
              label: const Text('HİKAYE KARTINI HAZIRLA', style: TextStyle(fontWeight: FontWeight.w900)),
              onPressed: () => _openStoryStudio(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FFE0),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHourBar(String label, double fill, String percent, Color color) {
    return Column(
      children: [
        Text(percent, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: 60 * fill,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 9),
        ),
      ],
    );
  }

  Widget _buildSmallStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF00FFE0)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🌟 EKRAN 04: DİNLENME HARİTAN & TOP 5 TOGGLE
  // ==========================================
  Widget _buildScreen04() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Column(
        children: [
          // Üst Başlık
          Column(
            children: [
              const Text(
                'ÖZSES',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
              Text(
                '2026 SANATÇI KADRON',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),

          const Text(
            'DİNLENME\nHARİTAN',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // 🎛️ ÇİFT POTANSİYOMETRE (KULLANICI AYARI)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CyberRotaryKnob(
                size: 50,
                value: _knob1Value,
                label: 'Kullanıcı Ayarı',
                onChanged: (val) => setState(() => _knob1Value = val),
              ),
              const SizedBox(width: 40),
              CyberRotaryKnob(
                size: 50,
                value: _knob2Value,
                label: 'Hassasiyet',
                onChanged: (val) => setState(() => _knob2Value = val),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 🧊 TOP 5 ARTISTS BUZLU CAM KARTI + TOGGLE SWITCHLER
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 16),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Top 5 Sanatçı',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Hikayeye Ekle / Çıkar',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _artists.length,
                      separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 12),
                      itemBuilder: (context, idx) {
                        final artist = _artists[idx];
                        return Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: artist.isEnabled ? const Color(0xFF00FFE0).withValues(alpha: 0.15) : Colors.white10,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${idx + 1}',
                                  style: TextStyle(
                                    color: artist.isEnabled ? const Color(0xFF00FFE0) : Colors.white38,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    artist.name,
                                    style: TextStyle(
                                      color: artist.isEnabled ? Colors.white : Colors.white38,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${artist.hours} SAAT',
                                    style: TextStyle(
                                      color: artist.isEnabled ? const Color(0xFF00FFE0) : Colors.white24,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 🎚️ TOGGLE SWITCH
                            Switch(
                              value: artist.isEnabled,
                              activeThumbColor: const Color(0xFF00FFE0),
                              activeTrackColor: const Color(0xFF00FFE0).withValues(alpha: 0.35),
                              inactiveThumbColor: Colors.white38,
                              inactiveTrackColor: Colors.white10,
                              onChanged: (val) {
                                setState(() => artist.isEnabled = val);
                                HapticFeedback.selectionClick();
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 🚀 HİKAYE STÜDYOSUNU AÇ NEON BUTONU
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.share_outlined, color: Color(0xFF00FFE0), size: 18),
              label: const Text(
                'HİKAYE STÜDYOSUNU AÇ',
                style: TextStyle(
                  color: Color(0xFF00FFE0),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              onPressed: () => _openStoryStudio(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF00FFE0), width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: const Color(0xFF00FFE0).withValues(alpha: 0.08),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ArtistStat {
  final String name;
  final int hours;
  final int percent;
  bool isEnabled;

  _ArtistStat({
    required this.name,
    required this.hours,
    required this.percent,
    this.isEnabled = true,
  });
}

/// 💿 HAFİF PLAK ÇİZİCİSİ (Ekran 01 için)
class _VinylPainter extends CustomPainter {
  final Color color;

  _VinylPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final discPaint = Paint()..color = const Color(0xFF141620);
    canvas.drawCircle(center, radius, discPaint);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double r = radius * 0.4; r < radius * 0.9; r += 5.0) {
      canvas.drawCircle(center, r, linePaint);
    }

    final edgePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 1, edgePaint);

    final centerHolePaint = Paint()..color = Colors.black;
    canvas.drawCircle(center, 8, centerHolePaint);
  }

  @override
  bool shouldRepaint(covariant _VinylPainter oldDelegate) => oldDelegate.color != color;
}
