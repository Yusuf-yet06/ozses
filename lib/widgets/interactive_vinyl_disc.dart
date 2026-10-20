import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:palette_generator/palette_generator.dart';

enum _VinylGestureMode { unknown, scrub, swipeUp, swipeDown, swipeLeft, swipeRight }

/// 📀 SİBER DJ PLAK: Tam İnteraktif Dokunmatik Pikap Widget'ı
/// - 🔄 Dairesel Döndürme: DJ Sarması (İleri/Geri Seek + Haptik + HUD)
/// - ⬆️ Yukarı Kaydırma: Şarkı Sözleri / Karaoke
/// - ⬇️ Aşağı Kaydırma: Çalma Kuyruğu / Şarkı Listesi
/// - ⬅️ Sola Kaydırma: Sonraki Şarkı
/// - ➡️ Sağa Kaydırma: Önceki Şarkı
/// - ⏱️ Basılı Tutma: 33 / 45 / 78 RPM Hız & Vibe Seçici (Slowed / Nightcore)
/// - 🎯 Tek Dokunma: Oynat / Duraklat
class InteractiveVinylDisc extends StatefulWidget {
  final bool isPlaying;
  final Color themeColor;
  final Uint8List? coverBytes;
  final double size;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onTap;
  final Future<void> Function(Duration targetPosition)? onSeek;
  final Duration currentPosition;
  final Duration totalDuration;
  final double playbackSpeed;
  final ValueChanged<double>? onSpeedChanged;

  const InteractiveVinylDisc({
    super.key,
    required this.isPlaying,
    required this.themeColor,
    this.coverBytes,
    this.size = 280.0,
    this.onSwipeUp,
    this.onSwipeDown,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onTap,
    this.onSeek,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.playbackSpeed = 1.0,
    this.onSpeedChanged,
  });

  @override
  State<InteractiveVinylDisc> createState() => _InteractiveVinylDiscState();
}

class _InteractiveVinylDiscState extends State<InteractiveVinylDisc>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  Color? _dynamicColor;

  // 🎯 GESTURE / SCRUB MOTORU
  _VinylGestureMode _gestureMode = _VinylGestureMode.unknown;
  Offset? _panStartPos;
  DateTime? _panStartTime;
  double _lastAngle = 0.0;
  double _manualRotationOffset = 0.0;
  double _accumulatedSeekSeconds = 0.0;
  int _lastHapticTick = 0;

  // 🪟 HUD GERİ BİLDİRİM
  bool _showHud = false;
  String _hudTitle = '';
  String _hudSubtitle = '';
  IconData _hudIcon = Icons.refresh_rounded;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: _calculateRotationDuration(widget.playbackSpeed),
    );

    if (widget.isPlaying) {
      _rotationController.repeat();
    }

    _extractPalette();
  }

  @override
  void didUpdateWidget(InteractiveVinylDisc oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.playbackSpeed != oldWidget.playbackSpeed) {
      final wasAnimating = _rotationController.isAnimating;
      _rotationController.duration = _calculateRotationDuration(widget.playbackSpeed);
      if (wasAnimating && widget.isPlaying) {
        _rotationController.repeat();
      }
    }

    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        if (!_rotationController.isAnimating) {
          _rotationController.repeat();
        }
      } else {
        _rotationController.stop();
      }
    }

    if (widget.coverBytes != oldWidget.coverBytes) {
      _extractPalette();
    }
  }

  Duration _calculateRotationDuration(double speed) {
    final effectiveSpeed = speed <= 0.1 ? 1.0 : speed;
    final baseSeconds = 8.0 / effectiveSpeed;
    return Duration(milliseconds: (baseSeconds * 1000).round().clamp(1000, 20000));
  }

  Future<void> _extractPalette() async {
    if (widget.coverBytes == null || widget.coverBytes!.isEmpty) return;
    try {
      final PaletteGenerator generator = await PaletteGenerator.fromImageProvider(
        MemoryImage(widget.coverBytes!),
        maximumColorCount: 5,
      );
      if (mounted) {
        setState(() {
          _dynamicColor = generator.dominantColor?.color ?? widget.themeColor;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Color get _activeColor => _dynamicColor ?? widget.themeColor;

  // 🎯 GESTURE ALGILAMA & DISAMBIGUATION
  void _handlePanStart(DragStartDetails details) {
    _panStartPos = details.localPosition;
    _panStartTime = DateTime.now();
    _gestureMode = _VinylGestureMode.unknown;
    _accumulatedSeekSeconds = 0.0;
    _lastHapticTick = 0;

    final center = Offset(widget.size / 2, widget.size / 2);
    final touch = details.localPosition;
    _lastAngle = math.atan2(touch.dy - center.dy, touch.dx - center.dx);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_panStartPos == null) return;

    final center = Offset(widget.size / 2, widget.size / 2);
    final touch = details.localPosition;
    final currentAngle = math.atan2(touch.dy - center.dy, touch.dx - center.dx);

    final dx = touch.dx - _panStartPos!.dx;
    final dy = touch.dy - _panStartPos!.dy;
    final dist = math.sqrt(dx * dx + dy * dy);

    // 🎯 Henüz yön belirlenmediyse
    if (_gestureMode == _VinylGestureMode.unknown) {
      if (dist < 15.0) return; // Ufak titremeleri yok say

      // Doğrusal kaydırma (Swipe) algılama: En az 30px ve baskın yön
      if (dist >= 30.0) {
        if (dx.abs() > dy.abs() * 1.25) {
          // Belirgin yatay hareket -> Şarkı Değiştirme
          _gestureMode = dx < 0 ? _VinylGestureMode.swipeLeft : _VinylGestureMode.swipeRight;
          HapticFeedback.lightImpact();
          setState(() {
            _showHud = true;
            _hudTitle = dx < 0 ? '⏭️ Sıradaki Şarkı' : '⏮️ Önceki Şarkı';
            _hudSubtitle = dx < 0 ? 'Parçayı atlamak için bırak' : 'Önceki parçaya dönmek için bırak';
            _hudIcon = dx < 0 ? Icons.skip_next_rounded : Icons.skip_previous_rounded;
          });
          return;
        } else if (dy.abs() > dx.abs() * 1.25) {
          // Belirgin dikey hareket -> Sözler veya Kuyruk
          _gestureMode = dy < 0 ? _VinylGestureMode.swipeUp : _VinylGestureMode.swipeDown;
          HapticFeedback.lightImpact();
          setState(() {
            _showHud = true;
            _hudTitle = dy < 0 ? '🎤 Şarkı Sözleri' : '📜 Çalma Kuyruğu';
            _hudSubtitle = dy < 0 ? 'Sözleri açmak için bırak' : 'Kuyruğu açmak için bırak';
            _hudIcon = dy < 0 ? Icons.lyrics_rounded : Icons.queue_music_rounded;
          });
          return;
        }
      }

      // Eğer 35px geçmesine rağmen düz çizgi değilse ve açı dönüyorsa -> Dairesel DJ Sarması (Scrub)
      if (dist >= 35.0) {
        _gestureMode = _VinylGestureMode.scrub;
        _rotationController.stop(); // Plak elin kontrolüne geçer
        _lastAngle = currentAngle;
      }
    }

    // 🔄 SCRUB (DJ SARMASI) MODU
    if (_gestureMode == _VinylGestureMode.scrub) {
      var dTheta = currentAngle - _lastAngle;
      // [-pi, pi] sınırına sar
      if (dTheta > math.pi) dTheta -= 2 * math.pi;
      if (dTheta < -math.pi) dTheta += 2 * math.pi;

      _lastAngle = currentAngle;
      _manualRotationOffset += dTheta / (2 * math.pi);

      // 1 tam tur = 30 saniye sarma
      final seekDelta = (dTheta / (2 * math.pi)) * 30.0;
      _accumulatedSeekSeconds += seekDelta;

      // Haptik Çıt-Çıt (Her 5 saniyede bir hafif titreşim)
      final currentTick = (_accumulatedSeekSeconds / 5.0).floor();
      if (currentTick != _lastHapticTick) {
        _lastHapticTick = currentTick;
        HapticFeedback.selectionClick();
      }

      final totalSec = widget.totalDuration.inSeconds > 0 ? widget.totalDuration.inSeconds : 3600;
      final rawSec = widget.currentPosition.inSeconds + _accumulatedSeekSeconds.round();
      final targetSec = rawSec.clamp(0, totalSec);
      final targetPos = Duration(seconds: targetSec);

      setState(() {
        _showHud = true;
        final isForward = _accumulatedSeekSeconds >= 0;
        final sign = isForward ? '+' : '';
        _hudTitle = '$sign${_accumulatedSeekSeconds.round()}s';
        _hudSubtitle = '${_formatDuration(targetPos)} / ${_formatDuration(widget.totalDuration)}';
        _hudIcon = isForward ? Icons.fast_forward_rounded : Icons.fast_rewind_rounded;
      });
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    // Eğer henüz mod kilitlenmediyse hızlı savurma (flick) kontrolü
    if (_gestureMode == _VinylGestureMode.unknown && _panStartPos != null) {
      final vx = details.velocity.pixelsPerSecond.dx;
      final vy = details.velocity.pixelsPerSecond.dy;
      if (vx.abs() > 250 && vx.abs() > vy.abs() * 1.2) {
        _gestureMode = vx < 0 ? _VinylGestureMode.swipeLeft : _VinylGestureMode.swipeRight;
      } else if (vy.abs() > 250 && vy.abs() > vx.abs() * 1.2) {
        _gestureMode = vy < 0 ? _VinylGestureMode.swipeUp : _VinylGestureMode.swipeDown;
      }
    }

    if (_gestureMode == _VinylGestureMode.scrub) {
      final targetSeconds = widget.currentPosition.inSeconds + _accumulatedSeekSeconds.round();
      final clampedSeconds = targetSeconds.clamp(0, widget.totalDuration.inSeconds > 0 ? widget.totalDuration.inSeconds : 3600);
      final targetDuration = Duration(seconds: clampedSeconds);

      HapticFeedback.mediumImpact();
      widget.onSeek?.call(targetDuration);

      if (widget.isPlaying) {
        _rotationController.repeat();
      }

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _showHud = false;
          });
        }
      });
    } else if (_gestureMode == _VinylGestureMode.swipeUp) {
      _triggerSwipeAction('🎤 Şarkı Sözleri', Icons.lyrics_rounded, widget.onSwipeUp);
    } else if (_gestureMode == _VinylGestureMode.swipeDown) {
      _triggerSwipeAction('📜 Çalma Kuyruğu', Icons.queue_music_rounded, widget.onSwipeDown);
    } else if (_gestureMode == _VinylGestureMode.swipeLeft) {
      _triggerSwipeAction('⏭️ Sıradaki Şarkı', Icons.skip_next_rounded, widget.onSwipeLeft);
    } else if (_gestureMode == _VinylGestureMode.swipeRight) {
      _triggerSwipeAction('⏮️ Önceki Şarkı', Icons.skip_previous_rounded, widget.onSwipeRight);
    } else {
      // Bilinmeyen veya ufak hareket
      setState(() {
        _showHud = false;
      });
      if (widget.isPlaying && !_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    }

    _panStartPos = null;
    _panStartTime = null;
    _gestureMode = _VinylGestureMode.unknown;
  }

  void _triggerSwipeAction(String title, IconData icon, VoidCallback? action) {
    HapticFeedback.mediumImpact();
    setState(() {
      _showHud = true;
      _hudTitle = title;
      _hudSubtitle = '';
      _hudIcon = icon;
    });

    action?.call();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showHud = false;
        });
      }
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ⏱️ PİKAP HIZ MODU MENÜSÜ (33 / 45 / 78 RPM)
  void _showRPMSelectorModal() {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141419),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: _activeColor.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _activeColor.withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.album_rounded, color: _activeColor, size: 28),
                  const SizedBox(width: 10),
                  const Text(
                    'PİKAP HIZI & VİBE AYARI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Plak devrini ve müzik hızını canlı modüle et',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              ),
              const SizedBox(height: 22),

              _buildRPMOption(
                title: '33 RPM (Standart)',
                subtitle: '1.0x • Orijinal Stüdyo Akışı',
                speed: 1.0,
                icon: Icons.music_note_rounded,
                badge: 'DOĞAL',
              ),
              const SizedBox(height: 10),
              _buildRPMOption(
                title: '33 RPM Lo-Fi / Slowed',
                subtitle: '0.85x • Gece Modu, Derin Bas & Chill',
                speed: 0.85,
                icon: Icons.nightlight_round,
                badge: 'SLOWED',
              ),
              const SizedBox(height: 10),
              _buildRPMOption(
                title: '45 RPM Nightcore',
                subtitle: '1.25x • Yüksek Enerji & Hızlı Tempo',
                speed: 1.25,
                icon: Icons.bolt_rounded,
                badge: 'SPEED UP',
              ),
              const SizedBox(height: 10),
              _buildRPMOption(
                title: '78 RPM Turbo',
                subtitle: '1.50x • Ultra Hızlı Podcast & Tempo',
                speed: 1.5,
                icon: Icons.rocket_launch_rounded,
                badge: 'TURBO',
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRPMOption({
    required String title,
    required String subtitle,
    required double speed,
    required IconData icon,
    required String badge,
  }) {
    final isSelected = (widget.playbackSpeed - speed).abs() < 0.05;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.pop(context);
        HapticFeedback.mediumImpact();
        widget.onSpeedChanged?.call(speed);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? _activeColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _activeColor : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? _activeColor : Colors.white10,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.black : Colors.white70, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? _activeColor : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? _activeColor.withValues(alpha: 0.25) : Colors.white12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: isSelected ? _activeColor : Colors.white60,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: _activeColor, size: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double discSize = widget.size;
    final double labelSize = discSize * 0.44;
    final double centerHoleSize = discSize * 0.12;

    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onTap: widget.onTap,
      onLongPress: _showRPMSelectorModal,
      child: Center(
        child: SizedBox(
          width: discSize,
          height: discSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 📀 1. DÖNEN PLAK GÖVDESİ (ROTATING VINYL BODY)
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  final double angle = (_rotationController.value + _manualRotationOffset) * 2 * math.pi;
                  return Transform.rotate(
                    angle: angle,
                    child: child,
                  );
                },
                child: Container(
                  width: discSize,
                  height: discSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0D0D10),
                    border: Border.all(
                      color: _activeColor.withValues(alpha: 0.65),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _activeColor.withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 🎚️ Konsantrik Plak Çizgileri (Vinyl Grooves)
                      CustomPaint(
                        size: Size(discSize, discSize),
                        painter: _VinylGroovesPainter(
                          color: Colors.white.withValues(alpha: 0.05),
                          grooveCount: 8,
                          labelRadius: labelSize / 2,
                        ),
                      ),

                      // ✨ Plak Işık Yansıması (Anisotropic Sheen Effect)
                      CustomPaint(
                        size: Size(discSize, discSize),
                        painter: _VinylSheenPainter(),
                      ),

                      // 🏷️ ORTA ALBÜM KAPAĞI / ETİKET (CENTER LABEL)
                      Container(
                        width: labelSize,
                        height: labelSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _activeColor,
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.8),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (widget.coverBytes != null && widget.coverBytes!.isNotEmpty)
                              ClipOval(
                                child: Image.memory(
                                  widget.coverBytes!,
                                  width: labelSize,
                                  height: labelSize,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildFallbackLabel(),
                                ),
                              )
                            else
                              _buildFallbackLabel(),

                            // 🎵 İnce Parlama Kaplaması
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.25),
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.4),
                                  ],
                                ),
                              ),
                            ),

                            // 🕳️ MERKEZ PİKAP MİL DELİĞİ (SPINDLE HOLE)
                            Container(
                              width: centerHoleSize,
                              height: centerHoleSize,
                              decoration: BoxDecoration(
                                color: const Color(0xFF09090C),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white38,
                                  width: 1.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black,
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 🏷️ HIZ ROZETİ (RPM BADGE - Plak üzerinde sabit)
              Positioned(
                top: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _activeColor.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _activeColor.withValues(alpha: 0.2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    _formatSpeedBadge(widget.playbackSpeed),
                    style: TextStyle(
                      color: _activeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),

              // 🧭 4 YÖN MİNİK İPUCU OKLARI (Çok hafif, şeffaf cyber dokunuş)
              const Positioned(
                top: 4,
                child: Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white24, size: 18),
              ),
              const Positioned(
                bottom: 4,
                child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white24, size: 18),
              ),
              const Positioned(
                left: 4,
                child: Icon(Icons.keyboard_arrow_left_rounded, color: Colors.white24, size: 18),
              ),
              const Positioned(
                right: 4,
                child: Icon(Icons.keyboard_arrow_right_rounded, color: Colors.white24, size: 18),
              ),

              // 🪟 2. İNTERAKTİF HUD GÖSTERGESİ (OVERLAY HUD)
              if (_showHud)
                Container(
                  width: discSize * 0.72,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101015).withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _activeColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _activeColor.withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_hudIcon, color: _activeColor, size: 32),
                      const SizedBox(height: 6),
                      Text(
                        _hudTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (_hudSubtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _hudSubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ).animate().scale(duration: 150.ms, curve: Curves.easeOutBack),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackLabel() {
    return Container(
      color: const Color(0xFF1B1B22),
      child: Center(
        child: Icon(
          Icons.album_rounded,
          color: _activeColor.withValues(alpha: 0.5),
          size: 48,
        ),
      ),
    );
  }

  String _formatSpeedBadge(double speed) {
    if ((speed - 1.0).abs() < 0.05) return '33 RPM';
    if ((speed - 0.85).abs() < 0.05) return '33 RPM (SLOWED)';
    if ((speed - 1.25).abs() < 0.05) return '45 RPM';
    if ((speed - 1.5).abs() < 0.05) return '78 RPM';
    return '${speed.toStringAsFixed(2)}x';
  }
}

// 🎨 PLAK ÇİZGİLERİ ÇİZİCİSİ (CONCENTRIC GROOVES)
class _VinylGroovesPainter extends CustomPainter {
  final Color color;
  final int grooveCount;
  final double labelRadius;

  _VinylGroovesPainter({
    required this.color,
    required this.grooveCount,
    required this.labelRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = (size.width / 2) - 4;
    final step = (outerRadius - labelRadius) / (grooveCount + 1);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= grooveCount; i++) {
      final r = labelRadius + (i * step);
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VinylGroovesPainter oldDelegate) => false;
}

// ✨ PLAK IŞIK YANSIMASI (ANISOTROPIC SHEEN)
class _VinylSheenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = Offset(size.width / 2, size.height / 2);

    final gradient = SweepGradient(
      center: Alignment.center,
      colors: [
        Colors.transparent,
        Colors.white.withValues(alpha: 0.07),
        Colors.transparent,
        Colors.white.withValues(alpha: 0.07),
        Colors.transparent,
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..blendMode = BlendMode.screen;

    canvas.drawCircle(center, size.width / 2 - 3, paint);
  }

  @override
  bool shouldRepaint(covariant _VinylSheenPainter oldDelegate) => false;
}
