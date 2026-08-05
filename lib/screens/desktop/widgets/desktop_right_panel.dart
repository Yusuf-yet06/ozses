import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../../../services/siber_theme_service.dart';
import '../../../main.dart'; // audioHandler için
import 'desktop_karaoke_lyrics.dart';

class DesktopRightPanel extends StatefulWidget {
  final VoidCallback onClose;
  final bool isDetached;
  final VoidCallback? onToggleDetach;

  const DesktopRightPanel({
    super.key, 
    required this.onClose,
    this.isDetached = false,
    this.onToggleDetach,
  });

  @override
  State<DesktopRightPanel> createState() => _DesktopRightPanelState();
}

class _DesktopRightPanelState extends State<DesktopRightPanel> {
  bool _showLyrics = true;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: SiberThemeService.instance.currentThemeColor,
      builder: (context, themeColor, child) {
        return Container(
          width: 320,
          margin: widget.isDetached ? EdgeInsets.zero : const EdgeInsets.only(top: 16, right: 16, bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: themeColor.withValues(alpha: widget.isDetached ? 0.3 : 0.1),
              width: 1.5,
            ),
            boxShadow: [
              if (widget.isDetached)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 15),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: const Color(0xFF0A0C10).withValues(alpha: 0.75), // Biraz koyu şeffaf zemin
                child: Column(
                  children: [
                    // 1. Üst Bar: Sürükleme (varsa), Ayır, Kapat
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        border: Border(
                          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (widget.isDetached)
                            const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Icon(Icons.drag_indicator_rounded, color: Colors.white54, size: 20),
                            ),
                          const Expanded(
                            child: Text(
                              'Müzik Akışı & Sözler',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (widget.onToggleDetach != null)
                            IconButton(
                              icon: Icon(
                                widget.isDetached ? Icons.push_pin_rounded : Icons.open_in_new_rounded,
                                color: Colors.white70,
                                size: 18,
                              ),
                              onPressed: widget.onToggleDetach,
                              tooltip: widget.isDetached ? 'Sabitle (Dock)' : 'Pencereyi Ayır (Undock)',
                            ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                            onPressed: widget.onClose,
                            tooltip: 'Kapat',
                          ),
                        ],
                      ),
                    ),

                // 2. Sekmeler (Sözler | Sıradaki)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _showLyrics = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _showLyrics ? themeColor.withValues(alpha: 0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'Sözler',
                                  style: TextStyle(
                                    color: _showLyrics ? themeColor : Colors.white60,
                                    fontWeight: _showLyrics ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _showLyrics = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !_showLyrics ? themeColor.withValues(alpha: 0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'Sıradaki',
                                  style: TextStyle(
                                    color: !_showLyrics ? themeColor : Colors.white60,
                                    fontWeight: !_showLyrics ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. İçerik (Sözler veya Sıradaki)
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _showLyrics ? _buildLyricsView(themeColor) : _buildQueueView(themeColor),
                  ),
                  ),
                ],
              ), // Column
            ), // Container (Glassmorphism bg)
          ), // BackdropFilter
        ), // ClipRRect
      );
    },
    );
  }

  Widget _buildLyricsView(Color themeColor) {
    return DesktopKaraokeLyrics(themeColor: themeColor);
  }

  Widget _buildQueueView(Color themeColor) {
    return StreamBuilder<List<MediaItem>>(
      key: const ValueKey('queue'),
      stream: audioHandler.queue,
      builder: (context, snapshot) {
        final queue = snapshot.data ?? [];
        if (queue.isEmpty) {
          return const Center(child: Text('Sıra boş', style: TextStyle(color: Colors.white54)));
        }

        return StreamBuilder<MediaItem?>(
          stream: audioHandler.mediaItem,
          builder: (context, mediaSnapshot) {
            final currentItem = mediaSnapshot.data;

            return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: queue.length,
              itemBuilder: (context, index) {
                final item = queue[index];
                final isPlaying = item.id == currentItem?.id;

                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.artUri != null
                        ? Image.network(item.artUri!.toString(), width: 40, height: 40, fit: BoxFit.cover)
                        : Container(width: 40, height: 40, color: Colors.grey[800]),
                  ),
                  title: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isPlaying ? themeColor : Colors.white,
                      fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    item.artist ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  trailing: isPlaying
                      ? Icon(Icons.equalizer, color: themeColor, size: 16)
                      : const SizedBox.shrink(),
                  onTap: () {
                    audioHandler.skipToQueueItem(index);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
