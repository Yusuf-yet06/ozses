import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:typed_data';

import 'package:ozses_v7/widgets/mini_eq_visualizer.dart'; // Kapak resmi (byte array) için

class BottomPlayerBar extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    // 🛡️ SİBER KALKAN: Çizim Motoru (Slider) için Güvenli Matematik
    double maxVal = duration.inSeconds.toDouble();
    if (maxVal <= 0.0 || maxVal.isNaN) maxVal = 1.0;

    double currentVal = position.inSeconds.toDouble();
    if (currentVal.isNaN || currentVal.isInfinite) currentVal = 0.0;
    currentVal = currentVal.clamp(0.0, maxVal);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        border: Border(
            top: BorderSide(color: themeColor.withValues(alpha: 0.5), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize
            .min, // 🎯 SİBER KALKAN: İçerik ne kadarsa o kadar uzasın, taşma yapmasın!
        children: [
          // 📡 ŞARKI İSMİ BURADA MÜHÜRLENİYOR
          GestureDetector(
            onTap: () {
              if (_isSheetOpen) {
                print('🛡️ SİBER KALKAN: Çift tıklama engellendi! Ekran zaten açık.');
                return;
              }
              _isSheetOpen = true;
              onExpand();
              // 1.5 saniye sonra kilidi aç (BottomSheet'in kapanması veya yüklenmesi için yeterli)
              Future.delayed(const Duration(milliseconds: 1500), () {
                _isSheetOpen = false;
              });
            }, // 🎯 Çubuğa tıklayınca tam ekrana geç
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                // 🎯 SİBER HAMLE: Otonom Dönen Neon CD Kapağı
                RotatingCDCover(
                  isPlaying: isPlaying,
                  themeColor: themeColor,
                  coverBytes: coverBytes,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        songName == 'Müzik Seçilmedi'
                            ? 'Siber Bağlantı Bekleniyor...'
                            : isBuffering
                                ? 'Yükleniyor: $songName...' // 🎯 Şarkı hazır olana kadar bilgi ver
                                : songName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        artistName,
                        style: TextStyle(
                            color: themeColor.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                    onPressed: onShowQueue,
                    icon: const Icon(Icons.queue_music,
                        color: Colors.cyanAccent, size: 20)),
                IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close,
                        color: Colors.white54, size: 18)),
              ],
            ),
          ),
          Slider(
            activeColor: themeColor,
            inactiveColor: Colors.white24,
            max: maxVal,
            value: currentVal,
            onChanged: onSeek,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                  icon: Icon(Icons.shuffle,
                      color: isShuffle ? themeColor : Colors.white54),
                  onPressed: onShuffleToggle),
              IconButton(
                  icon: const Icon(Icons.skip_previous, color: Colors.white),
                  onPressed: onPrevious),
              CircleAvatar(
                backgroundColor: themeColor,
                child: isBuffering
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    : IconButton(
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.black),
                        onPressed: onPlayPause),
              ),
              IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white),
                  onPressed: onNext),
              IconButton(
                icon: Icon(repeatMode == 1 ? Icons.repeat_one : Icons.repeat,
                    color: repeatMode > 0 ? themeColor : Colors.white54),
                onPressed: onRepeatToggle,
              ),
            ],
          ),
        ],
      ),
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
        setState(() {
          _dynamicColor = generator.dominantColor?.color ?? widget.themeColor;
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
              color: (_dynamicColor ?? widget.themeColor), width: widget.size > 100 ? 3.0 : 1.5),
          boxShadow: [
            BoxShadow(
              color: (_dynamicColor ?? widget.themeColor).withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.music_note,
                color: (_dynamicColor ?? widget.themeColor).withValues(alpha: 0.4),
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
                    color: (_dynamicColor ?? widget.themeColor).withValues(alpha: 0.5), width: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
