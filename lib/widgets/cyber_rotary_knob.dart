import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 🎛️ SİBER DÖNER POTANSİYOMETRE (ROTARY KNOB)
/// Parmağın dairesel veya dikey hareketine göre dönen, haptik titreşim veren fütüristik kadran.
class CyberRotaryKnob extends StatefulWidget {
  final double value; // 0.0 ile 1.0 arası
  final ValueChanged<double> onChanged;
  final double size;
  final Color activeColor;
  final String? label;

  const CyberRotaryKnob({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 56.0,
    this.activeColor = const Color(0xFF00FFE0),
    this.label,
  });

  @override
  State<CyberRotaryKnob> createState() => _CyberRotaryKnobState();
}

class _CyberRotaryKnobState extends State<CyberRotaryKnob> {
  double _lastAngle = 0.0;
  int _lastHapticStep = 0;

  void _onPanStart(DragStartDetails details) {
    final center = Offset(widget.size / 2, widget.size / 2);
    _lastAngle = math.atan2(
      details.localPosition.dy - center.dy,
      details.localPosition.dx - center.dx,
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final currentAngle = math.atan2(
      details.localPosition.dy - center.dy,
      details.localPosition.dx - center.dx,
    );

    var delta = currentAngle - _lastAngle;
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;

    _lastAngle = currentAngle;

    // Açı değişimini 0.0 - 1.0 aralığına ölçekle
    final change = delta / (1.5 * math.pi);
    final newValue = (widget.value + change).clamp(0.0, 1.0);

    if ((newValue - widget.value).abs() > 0.005) {
      widget.onChanged(newValue);

      final step = (newValue * 20).floor();
      if (step != _lastHapticStep) {
        _lastHapticStep = step;
        HapticFeedback.selectionClick();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Açı aralığı: -135 derece ile +135 derece arası (270 derecelik klasik potansiyometre)
    final rotationAngle = (-135 + (widget.value * 270)) * (math.pi / 180);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF12141A),
              border: Border.all(
                color: widget.activeColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.activeColor.withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
                const BoxShadow(
                  color: Colors.black,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Kadran arkasındaki ince dairesel ray
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _KnobArcPainter(
                    activeColor: widget.activeColor,
                    value: widget.value,
                  ),
                ),

                // Dönen potansiyometre gövdesi ve ibresi
                Transform.rotate(
                  angle: rotationAngle,
                  child: Container(
                    width: widget.size * 0.72,
                    height: widget.size * 0.72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFF2C303E),
                          Color(0xFF0C0E14),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1.0,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: const EdgeInsets.only(top: 3),
                        width: 3.5,
                        height: widget.size * 0.22,
                        decoration: BoxDecoration(
                          color: widget.activeColor,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: widget.activeColor,
                              blurRadius: 4,
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
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.label!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _KnobArcPainter extends CustomPainter {
  final Color activeColor;
  final double value;

  _KnobArcPainter({required this.activeColor, required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 3;

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    const startAngle = 135 * (math.pi / 180);
    const sweepAngle = 270 * (math.pi / 180);

    // Arka plan yayı
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Aktif değer yayı
    if (value > 0.01) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * value,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _KnobArcPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.activeColor != activeColor;
}
