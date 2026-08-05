import 'dart:math' as math;
import 'package:flutter/material.dart';

class ElegantVisualizer extends StatefulWidget {
  final Widget child; // The central element (e.g. the album disk)
  final Color themeColor;
  final bool isPlaying;

  const ElegantVisualizer({
    super.key,
    required this.child,
    required this.themeColor,
    this.isPlaying = true,
  });

  @override
  State<ElegantVisualizer> createState() => _ElegantVisualizerState();
}

class _ElegantVisualizerState extends State<ElegantVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _tickerController;
  
  final List<_Wave> _waves = [];
  final math.Random _random = math.Random();
  
  // Beat generation state
  double _timeSinceLastBeat = 0;
  double _nextBeatInterval = 0.468; // ~128 BPM base
  
  // Central disk bounce state
  double _diskScale = 1.0;
  double _diskVelocity = 0.0;
  final double _springStiffness = 150.0;
  final double _springDamping = 10.0;

  @override
  void initState() {
    super.initState();
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(days: 365), // Sonsuz döngü için
    )..addListener(_onTick);

    if (widget.isPlaying) {
      _tickerController.forward();
    }
  }

  @override
  void didUpdateWidget(ElegantVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _tickerController.forward();
      } else {
        _tickerController.stop();
        _waves.clear();
      }
    }
  }

  void _onTick() {
    if (!mounted) return;
    
    // FPS bağımsız zaman hesaplaması için yaklaşık delta time (16ms = 60fps)
    double dt = 0.016; 
    
    // Beat (Vuruş) Simülasyonu
    _timeSinceLastBeat += dt;
    if (_timeSinceLastBeat >= _nextBeatInterval) {
      _timeSinceLastBeat = 0;
      
      // Dinamik Ritim: Çapı, hızı ve opaklığı farklı dalgalar üret
      // NCS (NoCopyrightSounds) tarzı: Bazen çok güçlü, bazen zayıf vuruşlar
      double intensity = _random.nextDouble(); // 0.0 ile 1.0 arası
      
      if (intensity > 0.2) { // Çok zayıf vuruşları yoksay (senkop efekti)
        bool isHeavyBeat = intensity > 0.8;
        
        _waves.add(_Wave(
          maxScale: isHeavyBeat ? 1.6 + (_random.nextDouble() * 0.2) : 1.3 + (_random.nextDouble() * 0.2),
          speed: isHeavyBeat ? 0.8 + (_random.nextDouble() * 0.4) : 0.5 + (_random.nextDouble() * 0.3),
          thickness: isHeavyBeat ? 4.0 + (_random.nextDouble() * 3.0) : 1.0 + (_random.nextDouble() * 2.0),
          maxOpacity: isHeavyBeat ? 0.8 : 0.4,
        ));
        
        // Merkeze vurma (Bounce) efekti
        _diskVelocity += isHeavyBeat ? 2.5 : 1.0;
      }
      
      // Bir sonraki vuruş süresini rastgele belirle (EDM ritmine uygun)
      // Yaklaşık 128 BPM (468ms) baz alınarak 1/4, 1/2 veya tam vuruş aralıkları
      List<double> intervals = [0.234, 0.468, 0.468, 0.936];
      _nextBeatInterval = intervals[_random.nextInt(intervals.length)] + (_random.nextDouble() * 0.05);
    }
    
    // Dalgaları güncelle ve bitenleri temizle
    for (var i = _waves.length - 1; i >= 0; i--) {
      _waves[i].progress += dt * _waves[i].speed;
      if (_waves[i].progress >= 1.0) {
        _waves.removeAt(i);
      }
    }
    
    // Merkez diskin fizik motoru (Spring physics)
    double force = -_springStiffness * (_diskScale - 1.0) - _springDamping * _diskVelocity;
    _diskVelocity += force * dt;
    _diskScale += _diskVelocity * dt;
    
    setState(() {}); // Ekranı yenile
  }

  @override
  void dispose() {
    _tickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Dalgalar
        ..._waves.map((wave) {
          // Dalganın büyüme eğrisi (dışarı doğru patlama)
          double scale = 1.0 + (wave.maxScale - 1.0) * Curves.easeOutCirc.transform(wave.progress);
          
          // Dalganın kaybolma eğrisi
          double opacity = wave.maxOpacity * (1.0 - Curves.easeIn.transform(wave.progress));

          return Transform.scale(
            scale: scale,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.themeColor.withValues(alpha: opacity),
                  width: wave.thickness,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.themeColor.withValues(alpha: opacity * 0.5),
                    blurRadius: 15 * wave.progress,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          );
        }),
        
        // Merkezdeki Albüm Diski (Vuruşlarla esner)
        Transform.scale(
          scale: widget.isPlaying ? _diskScale : 1.0,
          child: widget.child,
        ),
      ],
    );
  }
}

class _Wave {
  double progress = 0.0;
  final double maxScale;
  final double speed;
  final double thickness;
  final double maxOpacity;

  _Wave({
    required this.maxScale,
    required this.speed,
    required this.thickness,
    required this.maxOpacity,
  });
}
