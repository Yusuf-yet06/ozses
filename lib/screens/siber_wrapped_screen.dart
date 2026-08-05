import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:ui';
import '../services/analytics_service.dart';

class SiberWrappedScreen extends StatefulWidget {
  @override
  _SiberWrappedScreenState createState() => _SiberWrappedScreenState();
}

class _SiberWrappedScreenState extends State<SiberWrappedScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 6;
  Timer? _timer;
  
  // Veriler
  int _totalTime = 0;
  String _topChannel = 'Bilinmiyor';
  List<Map<String, dynamic>> _topSongs = [];
  String _persona = 'Bilinmiyor';
  bool _isLoading = true;

  // Animasyonlar
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // Her sayfa 5 saniye
    );
    
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextPage();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final analytics = AnalyticsService();
      await analytics.addMockDataIfEmpty(); // Geliştirme için test verisi at

      final totalTime = await analytics.getTotalListeningTime();
      final topChannel = await analytics.getTopChannel();
      final topSongs = await analytics.getTopSongs(limit: 5);
      final persona = await analytics.getListeningPersona();

      setState(() {
        _totalTime = totalTime;
        _topChannel = topChannel;
        _topSongs = topSongs;
        _persona = persona;
        _isLoading = false;
      });

      _progressController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bir hata oluştu: $e')),
        );
      }
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context); // Bitince geri dön
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            _previousPage();
          } else {
            _nextPage();
          }
        },
        onLongPressDown: (details) => _progressController.stop(),
        onLongPressUp: () => _progressController.forward(),
        child: Stack(
          children: [
            // Siber Arkaplan Efekti
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            
            // Sayfalar
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Kaydırmayı kapat
              onPageChanged: (idx) {
                setState(() => _currentPage = idx);
                _progressController.reset();
                _progressController.forward();
              },
              children: [
                _buildIntroPage(),
                _buildTimePage(),
                _buildTopChannelPage(),
                _buildTopSongsPage(),
                _buildPersonaPage(),
                _buildOutroPage(),
              ],
            ),

            // Hikaye Çubuğu (Progress Bars)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              right: 10,
              child: Row(
                children: List.generate(_totalPages, (index) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          double progress = 0.0;
                          if (index < _currentPage) {
                            progress = 1.0;
                          } else if (index == _currentPage) {
                            progress = _progressController.value;
                          }
                          return LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 3,
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            // Kapat Butonu
            Positioned(
              top: MediaQuery.of(context).padding.top + 30,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroPage() {
    return _buildSlide(
      title: "Hazır mısın?",
      subtitle: "Siber Karargah ile bir yılı daha geride bıraktık. Senin için verileri derledik.",
      icon: Icons.rocket_launch,
      color: Colors.deepPurpleAccent,
    );
  }

  Widget _buildTimePage() {
    int minutes = _totalTime ~/ 60;
    return _buildSlide(
      title: "Müziğe Doymadın!",
      subtitle: "Bu yıl tamı tamına \$minutes dakika müzik dinledin. Kulaklıkların alev almış olmalı!",
      icon: Icons.timer_outlined,
      color: Colors.orangeAccent,
    );
  }

  Widget _buildTopChannelPage() {
    return _buildSlide(
      title: "Sanki Sadece Onu Dinledin",
      subtitle: "En çok takıldığın frekans: \$_topChannel",
      icon: Icons.mic_external_on_outlined,
      color: Colors.pinkAccent,
    );
  }

  Widget _buildTopSongsPage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Top 5 Şarkın",
            style: GoogleFonts.bungee(fontSize: 40, color: Colors.cyanAccent),
          ),
          const SizedBox(height: 30),
          ...List.generate(_topSongs.length, (index) {
            final s = _topSongs[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Text("\${index + 1}", style: const TextStyle(color: Colors.white54, fontSize: 30, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['title'], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text("\${s['play_count']} kez dinledin", style: const TextStyle(color: Colors.cyan, fontSize: 14)),
                      ],
                    ),
                  )
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPersonaPage() {
    return _buildSlide(
      title: "Sen Bir \$_persona'sun!",
      subtitle: "Dinleme saatlerine baktık ve kararımızı verdik. Tarzın ortada.",
      icon: Icons.psychology_outlined,
      color: Colors.greenAccent,
    );
  }

  Widget _buildOutroPage() {
    return Container(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, color: Colors.blueAccent, size: 120),
          const SizedBox(height: 30),
          Text(
            "2026 Siber Özetin",
            style: GoogleFonts.bungee(fontSize: 40, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            "Bizimle kaldığın için teşekkürler gardaşım. Seneye daha güçlü, daha siber!",
            style: const TextStyle(color: Colors.white70, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 50),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            icon: const Icon(Icons.share, color: Colors.white),
            label: const Text("Özetimi Paylaş", style: TextStyle(color: Colors.white, fontSize: 18)),
            onPressed: () {
              // TODO: Screenshot alıp paylaşma mantığı eklenebilir
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Siber paylaşım modülü hazırlanıyor...')),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildSlide({required String title, required String subtitle, required IconData icon, required Color color}) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 150, color: color),
          const SizedBox(height: 50),
          Text(
            title,
            style: GoogleFonts.bungee(fontSize: 40, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 22, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
