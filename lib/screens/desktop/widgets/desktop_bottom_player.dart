import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'dart:ui';
import '../../../main.dart'; // audioHandler için
import '../../../services/siber_theme_service.dart';
import '../../../services/offline_cache_service.dart';

class DesktopBottomPlayer extends StatefulWidget {
  final bool isCinematicMode;
  final bool isRightPanelOpen;
  final VoidCallback onToggleCinematicMode;
  final VoidCallback onToggleRightPanel;

  const DesktopBottomPlayer({
    super.key,
    this.isCinematicMode = false,
    this.isRightPanelOpen = false,
    required this.onToggleCinematicMode,
    required this.onToggleRightPanel,
  });

  @override
  State<DesktopBottomPlayer> createState() => _DesktopBottomPlayerState();
}

class _DesktopBottomPlayerState extends State<DesktopBottomPlayer> {
  double _volume = 1.0;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: SiberThemeService.instance.currentThemeColor,
      builder: (context, themeColor, child) {
        return Container(
          margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65), // Çok daha premium cam efekti
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: themeColor.withValues(alpha: 0.4), 
                    width: 1.5
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.25),
                      offset: const Offset(0, 10),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // En üstte interaktif ve ince Progress Bar
                    Positioned(
                      top: -8, 
                      left: 12,
                      right: 12,
                      height: 20, 
                      child: StreamBuilder<Duration>(
                        stream: AudioService.position,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          final duration = audioHandler.mediaItem.value?.duration ?? Duration.zero;
                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 3, 
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0, pressedElevation: 8), 
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10), 
                                activeTrackColor: themeColor,
                                inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
                                thumbColor: themeColor,
                                trackShape: const RectangularSliderTrackShape(),
                              ),
                              child: Slider(
                                value: duration.inMilliseconds > 0 
                                  ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0) 
                                  : 0.0,
                                onChanged: (val) {
                                  final seekPos = duration * val;
                                  audioHandler.seek(seekPos);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  
                  // Alt İçerik
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      children: [
                        // Sol: Albüm Kapak, Parça İsmi, Sanatçı
                        Expanded(
                          flex: 3,
                          child: StreamBuilder<MediaItem?>(
                            stream: audioHandler.mediaItem,
                            builder: (context, snapshot) {
                              final item = snapshot.data;
                              if (item == null) return const SizedBox.shrink();
                              return Row(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(12),
                                      image: item.artUri != null
                                          ? DecorationImage(
                                              image: NetworkImage(item.artUri.toString()),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                                      ],
                                    ),
                                    child: item.artUri == null
                                        ? Icon(Icons.music_note_rounded, color: themeColor.withValues(alpha: 0.5), size: 30)
                                        : null,
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          item.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item.artist ?? 'Bilinmeyen Sanatçı',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.5),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        
                        // Orta: Oynatma Kontrolleri
                        Expanded(
                          flex: 4,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.shuffle_rounded, color: Colors.white54, size: 22),
                                onPressed: () {},
                                hoverColor: Colors.white10,
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 32),
                                onPressed: () => audioHandler.skipToPrevious(),
                                hoverColor: Colors.white10,
                              ),
                              const SizedBox(width: 16),
                              StreamBuilder<PlaybackState>(
                                stream: audioHandler.playbackState,
                                builder: (context, snapshot) {
                                  final state = snapshot.data;
                                  final playing = state?.playing ?? false;
                                  return InkWell(
                                    onTap: () {
                                      if (playing) {
                                        audioHandler.pause();
                                      } else {
                                        audioHandler.play();
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(40),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            blurRadius: 12,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        color: Colors.black,
                                        size: 34,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 32),
                                onPressed: () => audioHandler.skipToNext(),
                                hoverColor: Colors.white10,
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.repeat_rounded, color: Colors.white54, size: 22),
                                onPressed: () {},
                                hoverColor: Colors.white10,
                              ),
                            ],
                          ),
                        ),
                        
                        // Sağ: Süre, İndirme, Ses ve Mod Geçişleri
                        Expanded(
                          flex: 3,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                              StreamBuilder<Duration>(
                                stream: AudioService.position,
                                builder: (context, snapshot) {
                                  final position = snapshot.data ?? Duration.zero;
                                  final duration = audioHandler.mediaItem.value?.duration ?? Duration.zero;
                                  return Text(
                                    '${_formatDuration(position)} / ${_formatDuration(duration)}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7), 
                                      fontSize: 12,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              
                              // İndir / Çevrimdışı Dinle Butonu
                              StreamBuilder<MediaItem?>(
                                stream: audioHandler.mediaItem,
                                builder: (context, snapshot) {
                                  final item = snapshot.data;
                                  if (item == null) return const SizedBox.shrink();
                                  
                                  final isCached = OfflineCacheService().isCached(item.id);
                                  
                                  return IconButton(
                                    icon: Icon(
                                      isCached ? Icons.download_done_rounded : Icons.download_rounded,
                                      color: isCached ? themeColor : Colors.white70,
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      if (!isCached) {
                                        final vidId = item.id.startsWith('yt:') ? item.id.substring(3) : item.id;
                                        OfflineCacheService().downloadStream(
                                          vidId,
                                          item.title,
                                          item.artist ?? 'Bilinmeyen',
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Şarkı arşive indiriliyor...'),
                                            backgroundColor: themeColor,
                                            behavior: SnackBarBehavior.floating,
                                          )
                                        );
                                      }
                                    },
                                    tooltip: isCached ? 'İndirildi' : 'İndir / Çevrimdışı Dinle',
                                  );
                                },
                              ),
                              
                              // Ses Seviyesi Kontrolü
                              const SizedBox(width: 8),
                              Icon(
                                _volume == 0 ? Icons.volume_off_rounded : (_volume < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded), 
                                color: Colors.white70, 
                                size: 20
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 80,
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5, pressedElevation: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                    activeTrackColor: themeColor,
                                    inactiveTrackColor: Colors.white10,
                                    thumbColor: Colors.white,
                                    trackShape: const RectangularSliderTrackShape(),
                                  ),
                                  child: Slider(
                                    value: _volume, 
                                    onChanged: (val) {
                                      setState(() {
                                        _volume = val;
                                      });
                                      audioHandler.customAction('setVolume', {'volume': val});
                                    },
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 16),
                              Container(width: 1, height: 24, color: Colors.white10),
                              const SizedBox(width: 16),

                              // Sağ Panel (Sözler/Liste) Butonu
                              IconButton(
                                icon: Icon(
                                  Icons.queue_music_rounded,
                                  color: widget.isRightPanelOpen ? themeColor : Colors.white70,
                                  size: 22,
                                ),
                                onPressed: widget.onToggleRightPanel,
                                tooltip: 'Sıradakiler & Sözler',
                              ),

                              // Sinematik Mod Butonu
                              IconButton(
                                icon: Icon(
                                  widget.isCinematicMode ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                                  color: widget.isCinematicMode ? themeColor : Colors.white70,
                                  size: 22,
                                ),
                                onPressed: widget.onToggleCinematicMode,
                                tooltip: widget.isCinematicMode ? 'Keşfete Dön' : 'Sinematik Moda Geç',
                              ),
                            ],
                          ),
                        ), // FittedBox
                        ), // Expanded(flex: 3)
                      ],
                    ),
                  ),
                ],
              ), // Stack
            ), // Container (inner)
          ), // BackdropFilter
        ), // ClipRRect
      ); // Container (outer, return)
      },
    );
  }
}
