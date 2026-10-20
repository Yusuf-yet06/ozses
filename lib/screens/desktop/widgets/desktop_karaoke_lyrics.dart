import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../main.dart'; // audioHandler için
import '../../../utils/song_media_utils.dart'; // cleanLyricsTitle vb. için
import '../../../services/services.dart'; // OzsesBridge için
import '../../../services/lyrics_service.dart';

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
  String _currentSongPath = '';
  String _currentSongName = '';
  String _currentArtistName = '';
  final List<DesktopLyricLine> _parsedLyrics = [];
  final ScrollController _lyricsScrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};
  bool _isAutoScrollLocked = true;
  int _lastActiveIndex = -1;
  StreamSubscription? _mediaSub;

  // ⏱️ Siber Senkron & Aday Doğrulama Değişkenleri
  int _lyricsOffsetMs = 0;
  bool _isLrcSynced = false;
  bool _isRemixFallback = false;

  final OzsesBridge bridge = OzsesBridge();

  @override
  void initState() {
    super.initState();
    _mediaSub = audioHandler.mediaItem.listen((item) {
      if (item != null) {
        bool isNewSong = _currentProcessedId != item.id;
        if (isNewSong) {
          _currentProcessedId = item.id;
          _currentSongPath = item.id;
          _currentSongName = item.title;
          _currentArtistName = item.artist ?? 'Bilinmeyen Sanatçı';
          if (mounted) {
            setState(() {
              _lyricsText = '';
              _parsedLyrics.clear();
              _itemKeys.clear();
              _lastActiveIndex = -1;
              _lyricsOffsetMs = 0;
              _isLrcSynced = false;
              _isRemixFallback = false;
            });
            _loadLyricsOffset(item.id);
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
        _currentSongPath = currentItem.id;
        _currentSongName = currentItem.title;
        _currentArtistName = currentItem.artist ?? 'Bilinmeyen Sanatçı';
        _loadLyricsOffset(currentItem.id);
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

  // 🎯 Şarkı Bazlı Senkron Kalibrasyon Metotları
  Future<void> _loadLyricsOffset(String songPath) async {
    final savedOffset = await LyricsService.getLyricsOffset(songPath);
    if (mounted) {
      setState(() {
        _lyricsOffsetMs = savedOffset;
      });
    }
  }

  Future<void> _changeLyricsOffset(int deltaMs) async {
    final newOffset = _lyricsOffsetMs + deltaMs;
    setState(() {
      _lyricsOffsetMs = newOffset;
    });
    await LyricsService.saveLyricsOffset(_currentSongPath, newOffset);
  }

  Future<void> _resetLyricsOffset() async {
    setState(() {
      _lyricsOffsetMs = 0;
    });
    await LyricsService.saveLyricsOffset(_currentSongPath, 0);
  }

  Future<void> _loadLyrics(String songPath, String songName, String artistName, {bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isFetchingLyrics = true;
    });

    try {
      final currentDuration = audioHandler.mediaItem.value?.duration;
      final vId = songPath.startsWith('yt:') ? songPath.substring(3) : null;

      final result = await LyricsService.fetchLyrics(
        songPath,
        songName,
        artistName,
        duration: currentDuration,
        videoId: vId,
        forceRefresh: forceRefresh,
      );

      if (!mounted || _currentProcessedId != songPath) return;

      if (result != null && result.lines.isNotEmpty) {
        setState(() {
          _lyricsText = result.rawText;
          _parsedLyrics.clear();
          for (final l in result.lines) {
            _parsedLyrics.add(DesktopLyricLine(l.time, l.text));
          }
          _isLrcSynced = result.isSynced;
          _isRemixFallback = result.isRemixFallback;
          _isFetchingLyrics = false;
        });
      } else {
        setState(() {
          _lyricsText = 'Şarkı sözü bulunamadı.\n(Alakasız şarkı gösterilmemesi için koruma kalkanı devrede)';
          _parsedLyrics.clear();
          _parsedLyrics.add(DesktopLyricLine(Duration.zero, _lyricsText));
          _isLrcSynced = false;
          _isRemixFallback = false;
          _isFetchingLyrics = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lyricsText = 'Sözler yüklenirken bir ağ hatası oluştu.';
          _parsedLyrics.clear();
          _isFetchingLyrics = false;
        });
      }
    }
  }

  void _parseLrc(String text, Duration totalDuration) {
    _parsedLyrics.clear();
    final regex = RegExp(r'\[(\d{1,2}):(\d{2})\.(\d{2,3})\]');
    bool foundTimeTag = false;

    for (var line in text.split('\n')) {
      final match = regex.firstMatch(line);
      if (match != null) {
        foundTimeTag = true;
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

    _isLrcSynced = foundTimeTag && _parsedLyrics.length > 1;

    // Düz metin sözler: Yapay zamanlama yapma, doğal serbest kaydırma olarak ekle
    if (!_isLrcSynced) {
      final lines = text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && !e.startsWith('[') && !e.endsWith(']'))
          .toList();

      for (var line in lines) {
        _parsedLyrics.add(DesktopLyricLine(Duration.zero, line));
      }
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

  void _scrollToActiveIndex(int activeIndex) {
    if (!_isAutoScrollLocked || activeIndex < 0 || activeIndex >= _parsedLyrics.length) return;
    
    final key = _itemKeys[activeIndex];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        alignment: 0.42, // 🎯 Tam merkez-üstü ideal okuma hizası
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    } else if (_lyricsScrollController.hasClients) {
      final maxExt = _lyricsScrollController.position.maxScrollExtent;
      if (maxExt > 0 && _parsedLyrics.isNotEmpty) {
        final ratio = activeIndex / _parsedLyrics.length;
        final targetOffset = (maxExt * ratio).clamp(0.0, maxExt);
        _lyricsScrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (key?.currentContext != null) {
            Scrollable.ensureVisible(
              key!.currentContext!,
              alignment: 0.42,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    }
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

    bool isSynced = _isLrcSynced && _parsedLyrics.length > 1;

    return StreamBuilder<Duration>(
      stream: AudioService.position,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final effectiveMs = position.inMilliseconds - _lyricsOffsetMs;
        final effectivePos = effectiveMs > 0 ? Duration(milliseconds: effectiveMs) : Duration.zero;
        int activeIndex = -1;
        
        if (isSynced) {
          for (int i = 0; i < _parsedLyrics.length; i++) {
            if (effectivePos >= _parsedLyrics[i].time) {
              activeIndex = i;
            } else {
              break;
            }
          }
        }

        // 🎯 SİBER SABİTLEME DÜZENEĞİ: Sırası gelen sözü kusursuzca ortala
        if (activeIndex != _lastActiveIndex) {
          _lastActiveIndex = activeIndex;
          if (activeIndex >= 0 && activeIndex < _parsedLyrics.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToActiveIndex(activeIndex);
            });
          }
        }

        return Stack(
          children: [
            Column(
              children: [
                // Üst Durum Çubuğu (Analiz & Sabitleme Kontrolü & Senkron Kalibrasyonu)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 4),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (isSynced && activeIndex >= 0 && activeIndex < _parsedLyrics.length)
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: widget.themeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: widget.themeColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.analytics_rounded, color: widget.themeColor, size: 13),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        _analyzeLineMood(_parsedLyrics[activeIndex].text),
                                        style: TextStyle(
                                          color: widget.themeColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(),

                          // ⏱️ SENKRON / ZAMANLAMA AYARI (±0.5s)
                          if (isSynced)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => _changeLyricsOffset(-500),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: const Text('-0.5s', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                InkWell(
                                  onTap: () {
                                    _resetLyricsOffset();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Senkron kalibrasyonu sıfırlandı (±0.0s)'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _lyricsOffsetMs != 0
                                          ? widget.themeColor.withValues(alpha: 0.25)
                                          : Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _lyricsOffsetMs != 0 ? widget.themeColor : Colors.white24,
                                      ),
                                    ),
                                    child: Text(
                                      _lyricsOffsetMs == 0
                                          ? '⚡ Senkron'
                                          : '⚡ ${_lyricsOffsetMs > 0 ? "+" : ""}${(_lyricsOffsetMs / 1000).toStringAsFixed(1)}s',
                                      style: TextStyle(
                                        color: _lyricsOffsetMs != 0 ? Colors.white : Colors.white60,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                InkWell(
                                  onTap: () => _changeLyricsOffset(500),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: const Text('+0.5s', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.notes_rounded, color: Colors.amber, size: 12),
                                  SizedBox(width: 4),
                                  Text('DÜZ METİN', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          
                          // 🎯 Sabitleme Düzeneği Butonu
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isAutoScrollLocked = !_isAutoScrollLocked;
                              });
                              if (_isAutoScrollLocked && activeIndex >= 0) {
                                _scrollToActiveIndex(activeIndex);
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _isAutoScrollLocked
                                    ? widget.themeColor.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _isAutoScrollLocked
                                      ? widget.themeColor.withValues(alpha: 0.5)
                                      : Colors.white12,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isAutoScrollLocked ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                                    color: _isAutoScrollLocked ? widget.themeColor : Colors.white54,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _isAutoScrollLocked ? 'Sabit' : 'Serbest',
                                    style: TextStyle(
                                      color: _isAutoScrollLocked ? Colors.white : Colors.white54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 🔄 Yenile Butonu
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sözler siber ağdan yeniden taranıyor...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                              _loadLyrics(_currentSongPath, _currentSongName, _currentArtistName, forceRefresh: true);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 14),
                            ),
                          ),
                        ],
                      ),

                      if (_isRemixFallback)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.purpleAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              '⚡ Remix Versiyon İçin Orijinal Şarkı Sözleri Eşleştirildi',
                              style: TextStyle(color: Colors.purpleAccent, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    controller: _lyricsScrollController,
                    cacheExtent: 3500,
                    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
                    itemCount: _parsedLyrics.length,
                    itemBuilder: (context, index) {
                      final line = _parsedLyrics[index];
                      final isActive = isSynced ? (index == activeIndex) : false;
                      final itemKey = _itemKeys.putIfAbsent(index, () => GlobalKey());

                      return InkWell(
                        onTap: () {
                          if (isSynced && line.time > Duration.zero) {
                            audioHandler.seek(line.time);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          key: itemKey,
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: EdgeInsets.symmetric(vertical: isActive ? 12 : 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: isActive ? widget.themeColor.withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: isActive 
                                ? Border.all(color: widget.themeColor.withValues(alpha: 0.4), width: 1.5)
                                : Border.all(color: Colors.transparent),
                            boxShadow: [
                              if (isActive)
                                BoxShadow(
                                  color: widget.themeColor.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                            ],
                          ),
                          child: Text(
                            line.text,
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.35),
                              fontSize: isActive ? 18 : 14,
                              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // 🎯 Hızlı Sabitleme Düğmesi (Aşağıda kaybolmayı önleyen acil odak butonu)
            if (isSynced && activeIndex >= 0)
              Positioned(
                bottom: 12,
                right: 16,
                child: AnimatedOpacity(
                  opacity: _isAutoScrollLocked ? 0.7 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isAutoScrollLocked = true;
                      });
                      _scrollToActiveIndex(activeIndex);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: widget.themeColor.withValues(alpha: 0.6)),
                        boxShadow: [
                          BoxShadow(
                            color: widget.themeColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.my_location_rounded, color: widget.themeColor, size: 14),
                          const SizedBox(width: 5),
                          const Text(
                            'Şarkıya Odakla',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
