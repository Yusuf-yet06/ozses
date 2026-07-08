import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import '../services/id3_service.dart';
import '../services/audio_analysis_service.dart';

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
    return Stack(
      children: [
        // 1. Dev Ortam Işığı Arka Planı (Neon Ampul Etkisi)
        if (_coverBytes != null)
          Positioned.fill(
            child: StreamBuilder<AudioAnalysisData>(
              stream: AudioAnalysisService.instance.getAnalysisStream(),
              builder: (context, snapshot) {
                // Eğer oynatılmıyorsa 0.6 baz değerde kalır, oynatılıyorsa ritme göre parlar
                double baseScale = 1.0;
                double baseOpacity = 0.6;
                
                if (_isPlaying && snapshot.hasData) {
                  double neonScale = snapshot.data!.neonScale; // 1.0 to 1.5
                  baseOpacity = (0.6 + (neonScale - 1.0)).clamp(0.6, 1.0);
                  baseScale = 1.0 + (neonScale - 1.0) * 0.2;
                }

                return Opacity(
                  opacity: baseOpacity,
                  child: Transform.scale(
                    scale: baseScale,
                    child: Image.memory(
                      _coverBytes!,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          )
        else
          Positioned.fill(
            child: StreamBuilder<AudioAnalysisData>(
              stream: AudioAnalysisService.instance.getAnalysisStream(),
              builder: (context, snapshot) {
                double baseOpacity = 0.6;
                if (_isPlaying && snapshot.hasData) {
                   double neonScale = snapshot.data!.neonScale;
                   baseOpacity = (0.6 + (neonScale - 1.0)).clamp(0.6, 1.0);
                }
                return Opacity(
                  opacity: baseOpacity,
                  child: Container(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                );
              },
            ),
          ),

        // 2. Çok Yüksek Bulanıklık ve Okunabilirlik Kalkanı
        Positioned.fill(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(
              color: Colors.black.withValues(alpha: 0.65), // %65 Siyah kalkan
            ),
          ),
        ),

        // 3. Uygulamanın Geri Kalanı (Rotalar / Ekranlar)
        widget.child,
      ],
    );
  }
}
