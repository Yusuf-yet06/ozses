import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../../../services/siber_theme_service.dart';
import '../../../main.dart'; // To access audioHandler
import 'elegant_visualizer.dart';

class DesktopCinematicView extends StatefulWidget {
  final MediaItem mediaItem;
  final VoidCallback onMinimize;

  const DesktopCinematicView({
    super.key,
    required this.mediaItem,
    required this.onMinimize,
  });

  @override
  State<DesktopCinematicView> createState() => _DesktopCinematicViewState();
}

class _DesktopCinematicViewState extends State<DesktopCinematicView> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final artUri = widget.mediaItem.artUri?.toString();
    final hasImage = artUri != null && artUri.isNotEmpty;

    return ValueListenableBuilder<Color>(
      valueListenable: SiberThemeService.instance.currentThemeColor,
      builder: (context, themeColor, child) {
        return Stack(
          children: [
            // 1. Nebula/Arkaplan Efekti (Bulanık Kapak Fotoğrafı)
            Positioned.fill(
              child: hasImage
                  ? Image.network(
                      artUri,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: const Color(0xFF0F111A)),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [themeColor.withValues(alpha: 0.3), const Color(0xFF0D0E15)],
                          radius: 1.5,
                        ),
                      ),
                    ),
            ),
            
            // Cam efekti (Buzlucam) maskelemesi
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ),

            // 2. Ortada Dönen Plak (Vinyl) ve Ses Dalgaları (Visualizer)
            Center(
              child: StreamBuilder<PlaybackState>(
                stream: audioHandler.playbackState,
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing ?? false;
                  return ElegantVisualizer(
                    themeColor: themeColor,
                    isPlaying: playing,
                    child: AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationController.value * 2 * 3.14159,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 350,
                        height: 350,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                          boxShadow: [
                            BoxShadow(
                              color: themeColor.withValues(alpha: 0.5),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 1. Kapak Resmi (Tam Boyut)
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: hasImage
                                      ? NetworkImage(artUri)
                                      : const AssetImage('assets/images/logo.jpg') as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            // 2. Plak Yivleri ve Siyah Transparan Efekt (Kapağın üstüne biner)
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.25), // Resmin üstüne hafif karanlık
                                border: Border.all(color: Colors.black.withValues(alpha: 0.5), width: 6),
                              ),
                            ),
                            Container(
                              width: 330,
                              height: 330,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
                              ),
                            ),
                            Container(
                              width: 310,
                              height: 310,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.03), width: 2),
                              ),
                            ),
                            Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
                              ),
                            ),
                            // 3. Merkez Deliği (Ortası)
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0D0E15),
                                border: Border.all(color: Colors.black, width: 4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),


            // 3. Üst Bar (Küçültme Tuşu ve Şarkı Bilgisi)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 36),
                    onPressed: widget.onMinimize,
                    tooltip: 'Küçült',
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.mediaItem.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.mediaItem.artist ?? 'Bilinmeyen Sanatçı',
                          style: TextStyle(
                            color: themeColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
