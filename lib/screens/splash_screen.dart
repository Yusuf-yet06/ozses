import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../responsive/responsive_layout.dart';
import '../services/siber_theme_service.dart';
import '../widgets/siber_animated_logo.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    // ⚡ SİBER PC GİRİŞ ANİMASYONU: 1.30 KAT DAHA HIZLI (2000ms / 1.30 ≈ 1538ms)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1538), 
    );

    // Yazı ve Glass çerçeve yumuşakça belirecek
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Yazı hafifçe aşağıdan yukarı veya küçükten büyüğe gelecek
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // ⚡ 1.30 KAT HIZLI: 2800ms / 1.30 ≈ 2150ms sonra ana sayfaya yönlendir
    _navigationTimer = Timer(const Duration(milliseconds: 2150), () async {
      // Arka plan servisleri (Firebase, RevenueCat, Bellek) henüz bitmediyse bitene kadar bekle
      if (OzsesMusicApp.backgroundServicesFuture != null) {
        try {
          await OzsesMusicApp.backgroundServicesFuture;
        } catch (_) {}
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (context, animation, secondaryAnimation) => const ResponsiveLayout(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: ValueListenableBuilder<Color>(
        valueListenable: SiberThemeService.instance.currentThemeColor,
        builder: (context, themeColor, child) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final fadeVal = _fadeAnimation.value.clamp(0.0, 1.0);
              return Stack(
                children: [
                  // --- NEON KÜRELER (Arkada dinamik siber aura katar - BoxShadow ile 0ms GPU maliyeti) ---
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.15,
                    left: -30,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: themeColor.withValues(alpha: (0.35 * fadeVal).clamp(0.0, 1.0)),
                            blurRadius: 60,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.15,
                    right: -30,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: themeColor.withValues(alpha: (0.25 * fadeVal).clamp(0.0, 1.0)),
                            blurRadius: 50,
                            spreadRadius: 15,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- MERKEZİ İÇERİK ---
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 1. DİNAMİK CANLI VEKTÖR LOGO (Kodlanmış Canlı Ekolayzer ve Neon Nota)
                        Transform.scale(
                          scale: _scaleAnimation.value,
                          child: SiberAnimatedLogo(
                            size: 155,
                            themeColor: themeColor,
                            isAnimated: true,
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // 2. GLASSMORPHISM YAZI KART (Neon Glass Efekti)
                        Opacity(
                          opacity: fadeVal,
                          child: Transform.scale(
                            scale: _scaleAnimation.value,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 25),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05), // Buzlu Cam Şeffaflığı
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15), // Cam Çerçevesi
                                    width: 1.5,
                                  ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: themeColor.withValues(alpha: 0.1),
                                        blurRadius: 30,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'ÖZSES',
                                        style: TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 10,
                                          color: Colors.white.withValues(alpha: 0.95),
                                          shadows: [
                                            Shadow(color: themeColor, blurRadius: 20 * fadeVal),
                                            Shadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 10 * fadeVal),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: themeColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(15),
                                          border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          'SİBER MÜZİK MOTORU V7',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 3,
                                            color: Colors.white.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
