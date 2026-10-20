import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 🌐 3D SİBER TEL KAFES IZGARASI (CYBER WIREFRAME GRID)
/// Synthwave / Cyberpunk tarzı perspektifli ufuk ızgarası.
class CyberWireframeGrid extends StatelessWidget {
  final double height;
  final Color gridColor;

  const CyberWireframeGrid({
    super.key,
    this.height = 140.0,
    this.gridColor = const Color(0xFF00FFE0),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _WireframeGridPainter(gridColor: gridColor),
      ),
    );
  }
}

class _WireframeGridPainter extends CustomPainter {
  final Color gridColor;

  _WireframeGridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = gridColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final horizonY = h * 0.15;
    final vanishingPoint = Offset(w / 2, -h * 0.2);

    // Yatay ufuk çizgileri (Derinlik arttıkça sıklaşan çizgiler)
    const int hLines = 9;
    for (int i = 1; i <= hLines; i++) {
      final t = math.pow(i / hLines, 2.2).toDouble();
      final y = horizonY + (h - horizonY) * t;

      final alpha = (0.05 + 0.3 * (i / hLines)).clamp(0.0, 0.4);
      paint.color = gridColor.withValues(alpha: alpha);

      // Çizgiyi hafif kavisli çizerek 3D zemin hissi verelim
      final path = Path();
      path.moveTo(0, y + 4 * (1 - t));
      path.quadraticBezierTo(w / 2, y - 6 * (1 - t), w, y + 4 * (1 - t));
      canvas.drawPath(path, paint);
    }

    // Ufuktan kullanıcıya doğru saçılan perspektif çizgileri (Dikey ışınlar)
    const int vLines = 14;
    for (int i = 0; i <= vLines; i++) {
      final bottomX = (w / vLines) * i;
      final path = Path();
      path.moveTo(vanishingPoint.dx + (bottomX - vanishingPoint.dx) * 0.25, horizonY);
      path.lineTo(bottomX, h);
      canvas.drawPath(path, paint);
    }

    // Üstte hafif siber gezegen halkası (Wireframe ring/oval)
    final planetPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final ovalRect = Rect.fromCenter(
      center: Offset(w * 0.42, h * 0.45),
      width: w * 0.65,
      height: h * 0.55,
    );
    canvas.save();
    canvas.translate(w * 0.42, h * 0.45);
    canvas.rotate(-0.35);
    canvas.translate(-w * 0.42, -h * 0.45);
    canvas.drawOval(ovalRect, planetPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WireframeGridPainter oldDelegate) =>
      oldDelegate.gridColor != gridColor;
}
