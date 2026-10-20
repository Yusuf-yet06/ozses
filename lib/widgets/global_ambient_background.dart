import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import '../services/id3_service.dart';
import '../services/audio_analysis_service.dart';
import '../services/siber_theme_service.dart';

class GlobalAmbientBackground extends StatefulWidget {
  final Widget child;

  const GlobalAmbientBackground({super.key, required this.child});

  @override
  State<GlobalAmbientBackground> createState() => _GlobalAmbientBackgroundState();
}

class _GlobalAmbientBackgroundState extends State<GlobalAmbientBackground> {
  Uint8List? _coverBytes;
  String _currentMediaId = '';
  StreamSubscription? _mediaSub;
  StreamSubscription? _playbackSub;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _listenToAudioHandler();
  }

  void _listenToAudioHandler() {
    try {
      _mediaSub = audioHandler.mediaItem.listen((item) async {
        if (item == null || !mounted) return;
        if (item.id == _currentMediaId) return;

        setState(() {
          _currentMediaId = item.id;
          _coverBytes = null; // Yeni şarkı geldi, eski resmi temizle
        });

        _fetchCoverArt(item);
      });

      _playbackSub = audioHandler.playbackState.listen((state) {
        if (!mounted) return;
        final isPlaying = state.playing;
        if (_isPlaying != isPlaying) {
          setState(() {
            _isPlaying = isPlaying;
          });
        }
      });
    } catch (e) {
      debugPrint('GlobalAmbientBackground: audioHandler listener henüz aktif değil: $e');
    }
  }

  Future<void> _fetchCoverArt(MediaItem item) async {
    final artUriStr = item.extras?['artUri'] as String? ?? item.artUri?.toString();

    if (artUriStr != null && artUriStr.startsWith('http')) {
      try {
        final response = await http.get(Uri.parse(artUriStr));
        if (mounted && _currentMediaId == item.id) {
          setState(() {
            _coverBytes = response.bodyBytes;
          });
        }
      } catch (_) {}
      return;
    }

    final tags = await ID3Service.extractTags(item.id);
    if (!mounted || _currentMediaId != item.id) return;

    setState(() {
      _coverBytes = ID3Service.getCoverBytes(tags);
    });
  }

  @override
  void dispose() {
    _mediaSub?.cancel();
    _playbackSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SiberThemeService.instance.isMinimalMode,
      builder: (context, isMinimal, _) {
        if (isMinimal) {
          return Stack(
            children: [
              Positioned.fill(
                child: Container(color: const Color(0xFF101010)),
              ),
              widget.child,
            ],
          );
        }

        return Stack(
          children: [
            // 1. Dev Ortam Işığı Arka Planı (GPU Dostu Hızlı Render & RepaintBoundary Önbelleği)
            if (_coverBytes != null)
              Positioned.fill(
                child: RepaintBoundary(
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Opacity(
                      opacity: 0.45,
                      child: Image.memory(
                        _coverBytes!,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
              )
            else
              Positioned.fill(
                child: Container(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                ),
              ),

            // 2. Koyu Gradyan ve Okunabilirlik Kalkanı (0ms GPU Maliyeti)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.75),
              ),
            ),

            // 3. Uygulamanın Geri Kalanı (Rotalar / Ekranlar)
            widget.child,
          ],
        );
      },
    );
  }
}
