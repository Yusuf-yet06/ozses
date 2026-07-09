import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:async';

class MiniEqVisualizer extends StatefulWidget {
  final Color themeColor;
  final bool isPlaying;

  const MiniEqVisualizer({
    super.key,
    required this.themeColor,
    required this.isPlaying,
  });

  @override
  State<MiniEqVisualizer> createState() => _MiniEqVisualizerState();
}

class _MiniEqVisualizerState extends State<MiniEqVisualizer> {
  Timer? _timer;
  final int _barCount = 4;
  late List<double> _barHeights;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _barHeights = List.generate(_barCount, (index) => 2.0);
    if (widget.isPlaying) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (mounted) {
        setState(() {
          _barHeights = List.generate(_barCount, (index) {
            return 4.0 + _random.nextDouble() * 18.0;
          });
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _barHeights = List.generate(_barCount, (index) => 2.0);
      });
    }
  }

  @override
  void didUpdateWidget(MiniEqVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startTimer();
      } else {
        _stopTimer();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(_barCount, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutBack, // SİBER HAMLE: Daha 3D ve elastik zıplama
          width: 4.5,
          height: _barHeights[index],
          margin: const EdgeInsets.symmetric(horizontal: 2.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                widget.themeColor.withValues(alpha: 0.5),
                widget.themeColor,
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                  color: widget.themeColor.withValues(alpha: 0.9), blurRadius: 8, spreadRadius: 1),
              BoxShadow(
                  color: Colors.white.withValues(alpha: 0.5), blurRadius: 4),
            ],
          ),
        );
      }),
    );
  }
}
