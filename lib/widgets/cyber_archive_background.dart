import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/siber_theme_service.dart';

/// 🔮 SİBER ARŞİV ARKA PLAN MOTORU
/// Ana arşiv ekranını düz siyahlıktan kurtarıp lüks, fütüristik, siber-akustik bir
/// derinlik ve zarif geometrik doku kazandırır.
class CyberArchiveBackground extends StatelessWidget {
  final Color themeColor;
  final double neonScale;
  final bool isPlaying;

  const CyberArchiveBackground({
    super.key,
    required this.themeColor,
    this.neonScale = 1.0,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    // 🍃 SADE MOD: Sıfır GPU yükü, saf mat modern koyu arayüz
    if (SiberThemeService.instance.isMinimalMode.value) {
      return Positioned.fill(
        child: Container(
          color: const Color(0xFF101010),
        ),
      );
    }

    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Zemin Rengi (Lüks OLED Derin Grafit)
          Container(
            color: const Color(0xFF080A12),
          ),

          // 2. Üst-Sağ Siber Radyal Aura Işıması
          Positioned(
            top: -60,
            right: -60,
            width: 320,
            height: 320,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    themeColor.withValues(alpha: (0.16 * neonScale).clamp(0.06, 0.35)),
                    themeColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // 3. Alt-Sol Camgöbeği/Mor Radyal Aura Işıması
          Positioned(
            bottom: 120,
            left: -80,
            width: 300,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.cyanAccent.withValues(alpha: (0.08 * neonScale).clamp(0.03, 0.2)),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 4. Zarif Geometrik Siber Doku & Akustik Izgara Çizimi
          CustomPaint(
            painter: _CyberAcousticMeshPainter(
              themeColor: themeColor,
              neonScale: neonScale,
              isPlaying: isPlaying,
            ),
          ),

          // 5. İç Karartma & Yumuşak Odak Gradyanı
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🎨 Özel Siber Izgara ve Akustik Geometri Çizicisi
class _CyberAcousticMeshPainter extends CustomPainter {
  final Color themeColor;
  final double neonScale;
  final bool isPlaying;

  _CyberAcousticMeshPainter({
    required this.themeColor,
    required this.neonScale,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // A. Akustik Nokta Matrisi (Dot Matrix)
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    final activeDotPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.07 * neonScale)
      ..style = PaintingStyle.fill;

    const double spacing = 42.0;
    final int cols = (size.width / spacing).ceil() + 1;
    final int rows = (size.height / spacing).ceil() + 1;

    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        final double x = i * spacing;
        final double y = j * spacing;

        // Belli noktalarda tema rengiyle parıldayan hafif ritmik düğümler
        if ((i + j) % 5 == 0) {
          canvas.drawCircle(Offset(x, y), 1.6, activeDotPaint);
        } else {
          canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
        }
      }
    }

    // B. Siber Köşe Telemetri İşaretleri (Futuristic HUD Brackets)
    final bracketPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const double bSize = 18.0;
    // Sol üst köşe braketi
    canvas.drawLine(const Offset(16, 16), const Offset(16 + bSize, 16), bracketPaint);
    canvas.drawLine(const Offset(16, 16), const Offset(16, 16 + bSize), bracketPaint);

    // Sağ üst köşe braketi
    canvas.drawLine(Offset(size.width - 16, 16), Offset(size.width - 16 - bSize, 16), bracketPaint);
    canvas.drawLine(Offset(size.width - 16, 16), Offset(size.width - 16, 16 + bSize), bracketPaint);

    // C. Hafif Çapraz Siber Frekans Çizgileri (Ambient Diagonal Acoustics)
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.015)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (double i = -size.height; i < size.width; i += 120) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height * 0.7, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CyberAcousticMeshPainter oldDelegate) {
    return oldDelegate.themeColor != themeColor ||
        oldDelegate.neonScale != neonScale ||
        oldDelegate.isPlaying != isPlaying;
  }
}
