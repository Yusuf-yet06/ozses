import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:typed_data';

import 'package:ozses_v7/widgets/mini_eq_visualizer.dart'; // Kapak resmi (byte array) için

class BottomPlayerBar extends StatefulWidget {
  final String songName;
  final String artistName;
  final Uint8List? coverBytes;
  final Color themeColor;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isBuffering; // 🎯 SİBER HAMLE: Otonom Yükleme Durumu
  final bool isShuffle;
  final int repeatMode;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final Function(double) onSeek;
  final VoidCallback onShuffleToggle;
  final VoidCallback onRepeatToggle;
  final VoidCallback onShowQueue;
  final VoidCallback onExpand; // 🎯 SİBER HAMLE: Tam ekrana geçiş tetiği
  final VoidCallback onClose;

  // 🪟 GROG İLHAMLI YÜZEN MİNİ PLAK & BUKALEMUN RENK DURUMLARI
  static final ValueNotifier<bool> isFloatingMiniMode = ValueNotifier<bool>(false);
  static final ValueNotifier<Offset?> floatingOffset = ValueNotifier<Offset?>(null);
  static final ValueNotifier<Color?> chameleonColor = ValueNotifier<Color?>(null);

  const BottomPlayerBar({
    super.key,
    required this.songName,
    required this.artistName,
    required this.coverBytes,
    required this.themeColor,
    required this.position,
    required this.duration,
    required this.isPlaying,
    this.isBuffering = false, // 🎯 SİBER HAMLE: Varsayılan olarak kapalı
    required this.isShuffle,
    required this.repeatMode,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onSeek,
    required this.onShuffleToggle,
    required this.onRepeatToggle,
    required this.onShowQueue,
    required this.onExpand,
    required this.onClose,
    required bool isFavorite,
    required Future<void> Function() onFavoriteToggle,
    required MiniEqVisualizer trailingAccessory,
  });

  // 🛡️ SİBER KALKAN: Çift Tıklama ve Çoklu Ekran Koruyucu (Uygulama geneli)
  static bool _isSheetOpen = false;

  static Color ensureReadableNeon(Color raw) {
    final hsl = HSLColor.fromColor(raw);
    if (raw.computeLuminance() < 0.18) {
      return hsl
          .withLightness((hsl.lightness + 0.35).clamp(0.45, 0.75))
          .withSaturation((hsl.saturation + 0.2).clamp(0.55, 1.0))
          .toColor();
    }
    return raw;
  }

  @override
  State<BottomPlayerBar> createState() => _BottomPlayerBarState();
}

class _BottomPlayerBarState extends State<BottomPlayerBar> {
  Color? _dynamicColor;

  @override
  void initState() {
    super.initState();
    _updateChameleonPalette();
  }

  @override
  void didUpdateWidget(BottomPlayerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.coverBytes != oldWidget.coverBytes) {
      _updateChameleonPalette();
    }
  }

  Future<void> _updateChameleonPalette() async {
    if (widget.coverBytes == null) {
      if (mounted) {
        setState(() => _dynamicColor = null);
      }
      BottomPlayerBar.chameleonColor.value = null;
      return;
    }
    try {
      final generator = await PaletteGenerator.fromImageProvider(
        MemoryImage(widget.coverBytes!),
        maximumColorCount: 6,
      );
      final raw = generator.vibrantColor?.color ??
          generator.lightVibrantColor?.color ??
          generator.dominantColor?.color;
      if (raw != null && mounted) {
        final readable = BottomPlayerBar.ensureReadableNeon(raw);
        setState(() => _dynamicColor = readable);
        BottomPlayerBar.chameleonColor.value = readable;
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _dynamicColor ?? widget.themeColor;

    // 🛡️ SİBER KALKAN: Çizim Motoru (Slider) için Güvenli Matematik
    double maxVal = widget.duration.inSeconds.toDouble();
    if (maxVal <= 0.0 || maxVal.isNaN) maxVal = 1.0;

    double currentVal = widget.position.inSeconds.toDouble();
    if (currentVal.isNaN || currentVal.isInfinite) currentVal = 0.0;
    currentVal = currentVal.clamp(0.0, maxVal);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        border: Border(
            top: BorderSide(color: activeColor.withValues(alpha: 0.5), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize
            .min, // 🎯 SİBER KALKAN: İçerik ne kadarsa o kadar uzasın, taşma yapmasın!
        children: [
          // 📡 ŞARKI İSMİ BURADA MÜHÜRLENİYOR
          GestureDetector(
            onTap: () {
              if (BottomPlayerBar._isSheetOpen) {
                print('🛡️ SİBER KALKAN: Çift tıklama engellendi! Ekran zaten açık.');
                return;
              }
              BottomPlayerBar._isSheetOpen = true;
              widget.onExpand();
              // 1.5 saniye sonra kilidi aç (BottomSheet'in kapanması veya yüklenmesi için yeterli)
              Future.delayed(const Duration(milliseconds: 1500), () {
                BottomPlayerBar._isSheetOpen = false;
              });
            }, // 🎯 Çubuğa tıklayınca tam ekrana geç
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                // 🎯 SİBER HAMLE: Otonom Dönen Neon CD Kapağı
                RotatingCDCover(
                  isPlaying: widget.isPlaying,
                  themeColor: activeColor,
                  coverBytes: widget.coverBytes,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.songName == 'Müzik Seçilmedi'
                            ? 'Müzik Bekleniyor...'
                            : widget.isBuffering
                                ? 'Yükleniyor: ${widget.songName}...' // 🎯 Şarkı hazır olana kadar bilgi ver
                                : widget.songName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.artistName,
                        style: TextStyle(
                            color: activeColor.withValues(alpha: 0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // 🪟 YÜZEN MİNİ PLAK MODUNA GEÇİŞ BUTONU
                IconButton(
                  onPressed: () {
                    BottomPlayerBar.isFloatingMiniMode.value = true;
                  },
                  tooltip: 'Yüzen Mini Plak Modu',
                  icon: Icon(Icons.disc_full_rounded, color: activeColor, size: 20),
                ),
                IconButton(
                    onPressed: widget.onShowQueue,
                    icon: const Icon(Icons.queue_music,
                        color: Colors.cyanAccent, size: 20)),
                IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close,
                        color: Colors.white54, size: 18)),
              ],
            ),
          ),
          Slider(
            activeColor: activeColor,
            inactiveColor: Colors.white24,
            max: maxVal,
            value: currentVal,
            onChanged: widget.onSeek,
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                    icon: Icon(Icons.shuffle,
                        color: widget.isShuffle ? activeColor : Colors.white54),
                    onPressed: widget.onShuffleToggle),
                IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white),
                    onPressed: widget.onPrevious),
                CircleAvatar(
                  backgroundColor: activeColor,
                  child: widget.isBuffering
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      : IconButton(
                          icon: Icon(widget.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.black),
                          onPressed: widget.onPlayPause),
                ),
                IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    onPressed: widget.onNext),
                IconButton(
                  icon: Icon(widget.repeatMode == 1 ? Icons.repeat_one : Icons.repeat,
                      color: widget.repeatMode > 0 ? activeColor : Colors.white54),
                  onPressed: widget.onRepeatToggle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 🪟 GROG İLHAMLI SÜRÜKLENEBİLİR YÜZEN MİNİ PLAK (FLOATING MINI VINYL)
class FloatingMiniVinyl extends StatelessWidget {
  final String songName;
  final Uint8List? coverBytes;
  final Color themeColor;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onExpandFullScreen;

  const FloatingMiniVinyl({
    super.key,
    required this.songName,
    required this.coverBytes,
    required this.themeColor,
    required this.position,
    required this.duration,
    required this.isPlaying,
    this.isBuffering = false,
    required this.onPlayPause,
    required this.onNext,
    required this.onExpandFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final defaultPos = Offset(screen.width - 170, screen.height - 230);

    return ValueListenableBuilder<Offset?>(
      valueListenable: BottomPlayerBar.floatingOffset,
      builder: (context, savedOffset, _) {
        final currentOffset = savedOffset ?? defaultPos;
        final clampedX = currentOffset.dx.clamp(8.0, (screen.width - 158.0).clamp(8.0, double.infinity));
        final clampedY = currentOffset.dy.clamp(40.0, (screen.height - 130.0).clamp(40.0, double.infinity));

        return Positioned(
          left: clampedX,
          top: clampedY,
          child: ValueListenableBuilder<Color?>(
            valueListenable: BottomPlayerBar.chameleonColor,
            builder: (context, chamColor, _) {
              final activeColor = chamColor ?? themeColor;
              final maxSec = duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0;
              final progress = (position.inSeconds.toDouble() / maxSec).clamp(0.0, 1.0);

              return GestureDetector(
                onPanUpdate: (details) {
                  final next = Offset(clampedX + details.delta.dx, clampedY + details.delta.dy);
                  BottomPlayerBar.floatingOffset.value = next;
                },
                onPanEnd: (_) {
                  // Parmak bırakılınca en yakın kenara (sol/sağ) mıknatıs gibi yapış
                  final cur = BottomPlayerBar.floatingOffset.value ?? currentOffset;
                  final snapLeft = cur.dx < (screen.width / 2 - 40);
                  final targetX = snapLeft ? 12.0 : (screen.width - 162.0).clamp(12.0, double.infinity);
                  BottomPlayerBar.floatingOffset.value = Offset(targetX, cur.dy.clamp(50.0, screen.height - 130.0));
                },
                onTap: onPlayPause,
                onDoubleTap: onExpandFullScreen,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF09090B).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: activeColor.withValues(alpha: 0.8), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.35),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dönen Plak + Çevresel İlerleme Halkası
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              value: isBuffering ? null : progress,
                              strokeWidth: 2.5,
                              color: activeColor,
                              backgroundColor: Colors.white12,
                            ),
                          ),
                          RotatingCDCover(
                            isPlaying: isPlaying,
                            themeColor: activeColor,
                            coverBytes: coverBytes,
                            size: 40,
                          ),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: activeColor,
                              size: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      // Hızlı Sonraki Şarkı Butonu
                      InkWell(
                        onTap: onNext,
                        borderRadius: BorderRadius.circular(16),
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(Icons.skip_next_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                      // Tam Çubuğa Geri Dön Butonu
                      InkWell(
                        onTap: () {
                          BottomPlayerBar.isFloatingMiniMode.value = false;
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(Icons.open_in_full_rounded, color: activeColor, size: 17),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// 🎯 SİBER KALKAN: Otonom Dönen Neon CD Widget'ı
class RotatingCDCover extends StatefulWidget {
  final bool isPlaying;
  final Color themeColor;
  final Uint8List? coverBytes; // 🛡️ SİBER HAMLE: Gerçek albüm resmi verisi
  final double size; // 🎯 SİBER HAMLE: CD boyutu dinamik oldu

  const RotatingCDCover({
    super.key,
    required this.isPlaying,
    required this.themeColor,
    this.coverBytes,
    this.size = 44.0, // Varsayılan ufak çubuk boyutu
  });

  @override
  State<RotatingCDCover> createState() => _RotatingCDCoverState();
}

class _RotatingCDCoverState extends State<RotatingCDCover>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Color? _dynamicColor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8), // Plak/CD dönüş hızı
    );
    if (widget.isPlaying) _controller.repeat();
    _updatePalette();
  }

  @override
  void didUpdateWidget(RotatingCDCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Şarkı durursa CD de otonom olarak durur usta!
    if (widget.isPlaying) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
    if (widget.coverBytes != oldWidget.coverBytes) {
      _updatePalette();
    }
  }

  Future<void> _updatePalette() async {
    if (widget.coverBytes == null) return;
    try {
      final PaletteGenerator generator = await PaletteGenerator.fromImageProvider(
        MemoryImage(widget.coverBytes!),
        maximumColorCount: 5,
      );
      if (mounted) {
        final raw = generator.vibrantColor?.color ??
            generator.lightVibrantColor?.color ??
            generator.dominantColor?.color ??
            Theme.of(context).colorScheme.primary;
        setState(() {
          _dynamicColor = BottomPlayerBar.ensureReadableNeon(raw);
        });
      }
    } catch (e) {
      print('Palette Error: $e');
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[900], // İleride Image.memory(...) gelecek
          border: Border.all(
              color: (_dynamicColor ?? Theme.of(context).colorScheme.primary), width: widget.size > 100 ? 3.0 : 1.5),
          boxShadow: [
            BoxShadow(
              color: (_dynamicColor ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.music_note,
                color: (_dynamicColor ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.4),
                size: widget.size * 0.45),

            // 🎯 SİBER HAMLE: Gerçek Kapak Resmi
            if (widget.coverBytes != null)
              ClipOval(
                child: Image.memory(
                  widget.coverBytes!,
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.cover,
                  // 🛡️ Çökmeyi engellemek için hata yönetimi
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),

            // 🎯 CD'nin ortasındaki delik efekti
            Container(
              width: widget.size * 0.27,
              height: widget.size * 0.27,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(
                    color: (_dynamicColor ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.5), width: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
