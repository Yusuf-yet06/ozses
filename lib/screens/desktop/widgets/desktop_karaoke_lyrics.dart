import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../../../main.dart'; // audioHandler için
import '../../../utils/song_media_utils.dart'; // cleanLyricsTitle vb. için
import '../../../services/services.dart'; // OzsesBridge için

// Sadece bu widget için geçici LyricLine (Eğer full_screen_player'da global değilse)
class DesktopLyricLine {
  final Duration time;
  final String text;
  DesktopLyricLine(this.time, this.text);
}

class DesktopKaraokeLyrics extends StatefulWidget {
  final Color themeColor;

  const DesktopKaraokeLyrics({
    super.key,
    required this.themeColor,
  });

  @override
  State<DesktopKaraokeLyrics> createState() => _DesktopKaraokeLyricsState();
}

class _DesktopKaraokeLyricsState extends State<DesktopKaraokeLyrics> {
  bool _isFetchingLyrics = false;
  String _lyricsText = '';
  String _currentProcessedId = '';
  List<DesktopLyricLine> _parsedLyrics = [];
  final ScrollController _lyricsScrollController = ScrollController();
  int _lastActiveIndex = -1;
  StreamSubscription? _mediaSub;

  final OzsesBridge bridge = OzsesBridge();

  @override
  void initState() {
    super.initState();
    _mediaSub = audioHandler.mediaItem.listen((item) {
      if (item != null) {
        bool isNewSong = _currentProcessedId != item.id;
        if (isNewSong) {
          _currentProcessedId = item.id;
          if (mounted) {
            setState(() {
              _lyricsText = '';
              _parsedLyrics.clear();
            });
            _loadLyrics(item.id, item.title, item.artist ?? 'Bilinmeyen Sanatçı');
          }
        }
      }
    });
    
    // İlk açılışta mevcut şarkıyı yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentItem = audioHandler.mediaItem.value;
      if (currentItem != null) {
        _currentProcessedId = currentItem.id;
        _loadLyrics(currentItem.id, currentItem.title, currentItem.artist ?? 'Bilinmeyen Sanatçı');
      }
    });
  }

  @override
  void dispose() {
    _mediaSub?.cancel();
    _lyricsScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLyrics(String songPath, String songName, String artistName) async {
    if (!mounted) return;
    setState(() {
      _isFetchingLyrics = true;
    });

    try {
      final searchTitle = cleanLyricsTitle(songName);
      final searchQuery = '$searchTitle $artistName lyrics';
      final vId = songPath.startsWith('yt:') ? songPath.substring(3) : songPath;

      // 1. YouTube Kül Kalkanı (OzsesBridge) üzerinden getir
      String? finalText = await bridge.getSiberLyrics(vId, searchQuery);
      
      // 2. Eğer YouTube'da yoksa LRCLIB üzerinden dene
      if (finalText == null || finalText.isEmpty) {
        try {
          final url = Uri.parse('https://lrclib.net/api/search?q=${Uri.encodeComponent('$artistName $searchTitle')}');
          final response = await http.get(url).timeout(const Duration(seconds: 4));
          if (response.statusCode == 200) {
            final List<dynamic> dataList = json.decode(response.body);
            if (dataList.isNotEmpty) {
              final track = dataList.firstWhere(
                (item) => item['syncedLyrics'] != null,
                orElse: () => dataList[0],
              );
              if (track['syncedLyrics'] != null) finalText = track['syncedLyrics'];
              else if (track['plainLyrics'] != null) finalText = track['plainLyrics'];
            }
          }
        } catch (e) {
          // lrclib başarısız
        }
      }

      if (mounted) {
        setState(() {
          _lyricsText = finalText ?? "Şarkı sözü bulunamadı.\n(Siber ağda iz bulunmuyor...)";
          final currentDuration = audioHandler.mediaItem.value?.duration ?? const Duration(minutes: 3);
          _parseLrc(_lyricsText, currentDuration);
          _isFetchingLyrics = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lyricsText = "Sözler yüklenirken bir ağ hatası oluştu.";
          _parsedLyrics.clear();
          _isFetchingLyrics = false;
        });
      }
    }
  }

  void _parseLrc(String text, Duration totalDuration) {
    _parsedLyrics.clear();
    bool hasTimeTags = text.contains(RegExp(r'\[\d{2}:\d{2}\.\d{2,3}\]'));
    
    if (!hasTimeTags) {
      final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final totalMs = totalDuration.inMilliseconds;
      if (lines.isNotEmpty && totalMs > 0) {
        final msPerLine = (totalMs * 0.85) ~/ lines.length;
        final startOffset = totalMs * 0.05;
        for (int i = 0; i < lines.length; i++) {
          _parsedLyrics.add(DesktopLyricLine(
              Duration(milliseconds: startOffset.toInt() + (i * msPerLine)),
              lines[i]));
        }
      } else {
        _parsedLyrics = lines.map((e) => DesktopLyricLine(Duration.zero, e)).toList();
      }
      return;
    }

    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\]');
    for (var line in text.split('\n')) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final msStr = match.group(3)!;
        final ms = int.parse(msStr.padRight(3, '0').substring(0, 3));
        final lText = line.substring(match.end).trim();
        if (lText.isNotEmpty) {
          _parsedLyrics.add(DesktopLyricLine(
              Duration(minutes: min, seconds: sec, milliseconds: ms), lText));
        }
      }
    }
    if (_parsedLyrics.isEmpty) {
      _parsedLyrics = text
          .split('\n')
          .map((e) => DesktopLyricLine(Duration.zero, e.trim()))
          .where((e) => e.text.isNotEmpty)
          .toList();
    }
  }

  String _analyzeLineMood(String text) {
    final t = text.toLowerCase();
    if (t.contains('aşk') || t.contains('sev') || t.contains('kalp') || t.contains('yürek') || t.contains('özle') || t.contains('göz')) {
      return 'Romantik / Duygusal';
    }
    if (t.contains('git') || t.contains('ayrı') || t.contains('yalnız') || t.contains('acı') || t.contains('ağla') || t.contains('üz')) {
      return 'Hüzünlü / Melankolik';
    }
    if (t.contains('gece') || t.contains('karanlık') || t.contains('sokak') || t.contains('uyku')) {
      return 'Gece / Karanlık Vibe';
    }
    if (t.contains('para') || t.contains('hızlı') || t.contains('ateş') || t.contains('yak') || t.contains('vur') || t.contains('kır')) {
      return 'Agresif / Hype';
    }
    return 'Standart Ritim';
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetchingLyrics) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(color: widget.themeColor, strokeWidth: 2),
            ),
            const SizedBox(height: 16),
            const Text(
              'Siber Ağda Sözler Aranıyor...',
              style: TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 1.2),
            ),
          ],
        ),
      );
    }

    if (_parsedLyrics.isEmpty) {
      return const Center(child: Text('Şu an bir şey çalmıyor', style: TextStyle(color: Colors.white54)));
    }

    bool isSynced = _lyricsText.contains(RegExp(r'\[\d{2}:\d{2}\.\d{2,3}\]')) || _parsedLyrics.length > 1;

    return StreamBuilder<Duration>(
      stream: AudioService.position,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        int activeIndex = -1;
        
        if (isSynced) {
          for (int i = 0; i < _parsedLyrics.length; i++) {
            if (position >= _parsedLyrics[i].time) {
              activeIndex = i;
            } else {
              break;
            }
          }
        }

        if (activeIndex != _lastActiveIndex) {
          _lastActiveIndex = activeIndex;
          if (activeIndex >= 0 && activeIndex < _parsedLyrics.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_lyricsScrollController.hasClients) {
                const double itemExtent = 48.0;
                double viewportHeight = _lyricsScrollController.position.viewportDimension;
                double targetOffset = (activeIndex * itemExtent) - (viewportHeight / 2) + (itemExtent / 2);
                
                double maxExtent = _lyricsScrollController.position.maxScrollExtent;
                if (targetOffset < 0) targetOffset = 0;
                if (targetOffset > maxExtent) targetOffset = maxExtent;
                
                _lyricsScrollController.animateTo(
                  targetOffset,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                );
              }
            });
          }
        }

        return Column(
          children: [
            if (isSynced && activeIndex >= 0 && activeIndex < _parsedLyrics.length)
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 5),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.themeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.themeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.analytics_rounded, color: widget.themeColor, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'SİBER ANALİZ: ${_analyzeLineMood(_parsedLyrics[activeIndex].text)}',
                      style: TextStyle(
                        color: widget.themeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2
                      )
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _lyricsScrollController,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                itemCount: _parsedLyrics.length,
                itemBuilder: (context, index) {
                  final line = _parsedLyrics[index];
                  final isActive = isSynced ? (index == activeIndex) : false;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: EdgeInsets.symmetric(vertical: isActive ? 12 : 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isActive ? widget.themeColor.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isActive 
                          ? Border.all(color: widget.themeColor.withValues(alpha: 0.3))
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Text(
                      line.text,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
                        fontSize: isActive ? 18 : 14,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
