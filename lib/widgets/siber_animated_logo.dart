import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 🔮 SİBER CANLI LOGO (ÖZSES V7)
/// Tamamen kod ile çizilen (vector/canvas), dinamik ekolayzer dalgalarına sahip,
/// neon parıltılı ve tema rengine duyarlı canlı müzik logosu.
class SiberAnimatedLogo extends StatefulWidget {
  final double size;
  final Color themeColor;
  final bool isAnimated;

  const SiberAnimatedLogo({
    super.key,
    this.size = 150,
    required this.themeColor,
    this.isAnimated = true,
  });

  @override
  State<SiberAnimatedLogo> createState() => _SiberAnimatedLogoState();
}

class _SiberAnimatedLogoState extends State<SiberAnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    if (widget.isAnimated) {
      _animController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SiberAnimatedLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimated && !_animController.isAnimating) {
      _animController.repeat();
    } else if (!widget.isAnimated && _animController.isAnimating) {
      _animController.stop();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _SiberLogoPainter(
            progress: _animController.value,
            themeColor: widget.themeColor,
          ),
        );
      },
    );
  }
}

class _SiberLogoPainter extends CustomPainter {
  final double progress;
  final Color themeColor;

  _SiberLogoPainter({
    required this.progress,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.46;

    // --- 1. DIŞ SQUIRCLE / ARKA PLAN ÇERÇEVESİ ---
    final squircleRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.94,
      height: size.height * 0.94,
    );
    final squircleRRect = RRect.fromRectAndRadius(
      squircleRect,
      Radius.circular(size.width * 0.24),
    );

    // Dış Neon Gölge
    final shadowPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.1);
    canvas.drawRRect(squircleRRect, shadowPaint);

    // Koyu Siber Cam Arka Plan
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.2, -0.3),
        radius: 0.9,
        colors: [
          Color(0xFF161524),
          Color(0xFF090810),
          Color(0xFF040407),
        ],
      ).createShader(squircleRect);
    canvas.drawRRect(squircleRRect, bgPaint);

    // Squircle Dış Çerçeve Kenarlığı
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          themeColor.withValues(alpha: 0.6),
          Colors.white.withValues(alpha: 0.15),
          themeColor.withValues(alpha: 0.3),
        ],
      ).createShader(squircleRect);
    canvas.drawRRect(squircleRRect, borderPaint);

    // --- 2. RADYAL FREKANS / EKOLAYZER HALKASI ---
    const int barCount = 44;
    final ringRadius = baseRadius * 0.68;
    final maxBarHeight = size.width * 0.13;
    final minBarHeight = size.width * 0.025;

    // Döngüsel frekans çubukları
    for (int i = 0; i < barCount; i++) {
      final angle = (i / barCount) * 2 * math.pi;

      // Dinamik ritmik dalga simülasyonu
      final wave1 = math.sin(angle * 3 + progress * 2 * math.pi);
      final wave2 = math.cos(angle * 5 - progress * 4 * math.pi);
      final wave3 = math.sin(angle * 2 + progress * 2 * math.pi);
      final normalizedWave = ((wave1 * 0.5 + wave2 * 0.3 + wave3 * 0.2) + 1.0) / 2.0;

      final barHeight = minBarHeight + (maxBarHeight - minBarHeight) * normalizedWave.clamp(0.0, 1.0);

      final innerPoint = Offset(
        center.dx + ringRadius * math.cos(angle),
        center.dy + ringRadius * math.sin(angle),
      );
      final outerPoint = Offset(
        center.dx + (ringRadius + barHeight) * math.cos(angle),
        center.dy + (ringRadius + barHeight) * math.sin(angle),
      );

      // Çubuk rengi ve parlaklığı
      final barAlpha = (0.4 + 0.6 * normalizedWave).clamp(0.0, 1.0);
      final barColor = Color.lerp(
        themeColor,
        Colors.white,
        (normalizedWave * 0.4).clamp(0.0, 1.0),
      )!;

      final barPaint = Paint()
        ..color = barColor.withValues(alpha: barAlpha)
        ..strokeWidth = size.width * 0.016
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(innerPoint, outerPoint, barPaint);

      // Zirve noktası parlama efekti (ufak neon pikseller)
      if (normalizedWave > 0.65) {
        final tipPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..strokeWidth = size.width * 0.018
          ..strokeCap = StrokeCap.round;
        canvas.drawCircle(outerPoint, size.width * 0.008, tipPaint);
      }
    }

    // --- 3. İÇ NEON HALKA ---
    final innerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = themeColor.withValues(alpha: 0.85);

    // İç halka parlama aurası
    final innerRingGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = themeColor.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(center, ringRadius - 1.0, innerRingGlow);
    canvas.drawCircle(center, ringRadius - 1.0, innerRingPaint);

    // --- 4. MERKEZ SİBER NEON MÜZİK NOTASI (♪) ---
    _drawGlowingMusicNote(canvas, center, size.width * 0.42, progress);
  }

  void _drawGlowingMusicNote(Canvas canvas, Offset center, double noteSize, double animProgress) {
    // Nabız gibi hafif nefes alma efekti
    final pulseScale = 1.0 + 0.04 * math.sin(animProgress * 2 * math.pi);
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(pulseScale);

    // Nota koordinatları normalize (100x100 ölçek tabanında)
    final scale = noteSize / 100.0;
    canvas.scale(scale);

    // Nota Yolu (Path) - İnce, zarif, modern siber sekizlik nota (♪)
    final notePath = Path();

    // Nota Başı (Eğimli Oval - sol altta)
    const headCenter = Offset(-10, 16);
    final headRect = Rect.fromCenter(center: headCenter, width: 28, height: 20);
    final headRRect = RRect.fromRectAndRadius(headRect, const Radius.elliptical(14, 10));

    // Sap ve Bayrak Yolu
    notePath.addRRect(headRRect);
    
    // Sap (Stem) - Düzgün dikey gövde
    final stemPath = Path();
    stemPath.moveTo(0, 15);
    stemPath.lineTo(0, -28);
    stemPath.lineTo(7, -28);
    stemPath.lineTo(7, 15);
    stemPath.close();
    notePath.addPath(stemPath, Offset.zero);

    // Bayrak (Flag) - Zarif kıvrımlı flama
    final flagPath = Path();
    flagPath.moveTo(7, -28);
    flagPath.cubicTo(18, -25, 26, -14, 25, 4);
    flagPath.cubicTo(23, -2, 17, -9, 7, -12);
    flagPath.close();
    notePath.addPath(flagPath, Offset.zero);

    // Nota Arka Aurası (Derin Neon Parlaması)
    final noteGlowPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawPath(notePath, noteGlowPaint);

    // Nota Ana Dolgusu (Gradient Cam / Metalik Neon)
    final noteFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Colors.white.withValues(alpha: 0.95),
          themeColor.withValues(alpha: 0.9),
          themeColor,
          themeColor.withValues(alpha: 0.7),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(const Rect.fromLTWH(-30, -35, 60, 60));
    canvas.drawPath(notePath, noteFillPaint);

    // Nota İç Cam Yansıması (Glass Highlight Çizgisi)
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.75);

    final highlightPath = Path();
    highlightPath.moveTo(2, 10);
    highlightPath.lineTo(2, -26);
    highlightPath.cubicTo(10, -24, 18, -16, 20, -2);
    canvas.drawPath(highlightPath, highlightPaint);

    // Nota Başındaki Cam Işık Parıltısı
    final glintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(const Offset(-13, 13), 3.5, glintPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SiberLogoPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.themeColor != themeColor;
  }
}
