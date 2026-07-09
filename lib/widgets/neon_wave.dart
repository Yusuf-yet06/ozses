import 'package:flutter/material.dart';
import 'dart:math' as math;

class NeonWaveBackground extends StatefulWidget {
  final bool isPlaying;
  const NeonWaveBackground({super.key, required this.isPlaying});

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
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: WavePainter(
            progress: _controller.value,
            isPlaying: widget.isPlaying,
            color: Colors.deepPurpleAccent.withValues(alpha: 0.3),
          ),
          child: Container(),
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final Color color;

  WavePainter(
      {required this.progress, required this.isPlaying, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10); // Neon Efekti

    final path = Path();
    final double amplitude =
        isPlaying ? 50.0 : 10.0; // Müzik çalıyorsa dalga büyür
    final double wavelength = size.width / 1.5;

    path.moveTo(0, size.height * 0.7);

    for (double x = 0; x <= size.width; x++) {
      double y = size.height * 0.7 +
          math.sin((x / wavelength) + (progress * 2 * math.pi)) * amplitude;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    // İkinci bir ters dalga (Daha derin siber görünüm için)
    final paint2 = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.75);
    for (double x = 0; x <= size.width; x++) {
      double y = size.height * 0.75 +
          math.cos((x / wavelength) + (progress * 2 * math.pi)) *
              (amplitude * 0.8);
      path2.lineTo(x, y);
    }
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
