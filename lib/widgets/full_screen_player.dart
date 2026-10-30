import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'dart:ui' as ui;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';
import '../services/id3_service.dart';
import '../services/lyrics_service.dart';
import '../widgets/bottom_player_bar.dart';
import '../services/services.dart'; // 🎯 SİBER KÖPRÜ
import '../services/subscription_manager.dart';
import '../utils/song_media_utils.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart'; // 🎯 Dosya okuma/yazma için gerekli mühür
import 'package:flutter/services.dart'; // 🎯 Pano (Clipboard) İşlemleri İçin
import 'siber_ekolayzer_sheet.dart';
import 'sleep_timer_sheet.dart';
import 'siber_uyku_sheet.dart';
import 'siber_kuyruk_sheet.dart';
import 'siber_istatistik_sheet.dart';
import 'interactive_vinyl_disc.dart';

class LyricLine {
  final Duration time;
  final String text;
  LyricLine(this.time, this.text);
}

class FullScreenPlayer extends StatefulWidget {
  final Color themeColor;
  final bool Function(String) checkIsFavorite;
  final Function(String) onToggleFavorite;
  final Function(String) onAddToPlaylist;
  final Function(String) onDelete;
  final Function(String, bool) onAddQueue;
  final Function(String, String)? onDownloadStart;

  const FullScreenPlayer({
    super.key,
    required this.themeColor,
    required this.checkIsFavorite,
    required this.onToggleFavorite,
    required this.onAddToPlaylist,
    required this.onDelete,
    required this.onAddQueue,
    this.onDownloadStart,
  });

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> {
  String _songPath = '';
  String _songName = 'Bağlanıyor...';
  String _artistName = '';
  Uint8List? _coverBytes;
  Color? _dynamicColor;

  bool _showLyrics = false;
  bool _isFetchingLyrics = false;
  String _lyricsText = '';
  String _currentProcessedId =
      ''; // 🎯 Titremeyi (Flicker) engelleyen kimlik mührü
  List<LyricLine> _parsedLyrics = [];
  List<GlobalKey> _lyricKeys = [];
  final ScrollController _lyricsScrollController = ScrollController();
  int _lastActiveIndex = -1;
  StreamSubscription? _mediaSub;
  bool _isAutoScrollLocked = true;
  int _lyricsOffsetMs = 0;

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
              _songPath = item.id;
              _songName = item.title;
              _artistName = item.artist ?? 'Victus V7';
              _coverBytes =
                  null; // 🛡️ Yalnızca şarkı DEĞİŞTİĞİNDE resmi sıfırla!
              _lyricsText = '';
              _parsedLyrics.clear();
              _lyricKeys.clear();
              _showLyrics = false;
              _lastActiveIndex = -1;
              _lyricsOffsetMs = 0;
            });
          }
          _loadCoverForMediaItem(item);
        }
      }
    });
  }

  void _loadCoverForMediaItem(MediaItem item) {
    final vid = item.extras?['videoId']?.toString() ?? extractVideoIdFromPath(item.id);
    final uri = artUriForMediaId(
      item.id,
      videoId: vid,
      existing: item.artUri,
    );

    // 1. Önce yerel hafızadan (ID3 / M4A / Çevrimdışı Kapak) kontrol et! (0ms gecikme & kota koruması)
    ID3Service.getCoverBytesForSong(item.id, videoId: vid, artUrl: item.artUri?.toString()).then((bytes) {
      if (bytes != null && mounted && _currentProcessedId == item.id) {
        setState(() => _coverBytes = bytes);
        _updatePalette();
        return;
      }

      // 2. Yerelde yoksa ve internet URL'si varsa çek ve yerel belleğe mühürle
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        http.get(uri).then((response) {
          if (response.statusCode == 200 &&
              mounted &&
              _currentProcessedId == item.id) {
            setState(() => _coverBytes = response.bodyBytes);
            _updatePalette();
            if (vid != null && vid.isNotEmpty) {
              ID3Service.cacheCoverBytes(vid, response.bodyBytes);
            }
          }
        }).catchError((_) {
          _extractFallbackTags(item.id);
        });
        return;
      }

      _extractFallbackTags(item.id);
    }).catchError((_) {
      _extractFallbackTags(item.id);
    });
  }

  void _extractFallbackTags(String filePath) {
    if (filePath.startsWith('downloading:') || filePath == 'bilinmeyen_yol') {
      return;
    }

    ID3Service.extractTags(filePath).then((tags) {
      if (!mounted || _currentProcessedId != filePath) return;
      setState(() {
        final b = ID3Service.getCoverBytes(tags);
        if (b != null) {
          _coverBytes = b;
          _updatePalette();
        }
        final extractedArtist = tags['Artist'];
        if (extractedArtist != null &&
            extractedArtist.toString().trim().isNotEmpty) {
          _artistName = extractedArtist;
        }
        final extractedTitle = tags['Title'];
        if (extractedTitle != null &&
            extractedTitle.toString().trim().isNotEmpty) {
          _songName = extractedTitle;
        }
      });
    });
  }

  Future<void> _updatePalette() async {
    if (_coverBytes == null) return;
    try {
      final PaletteGenerator generator = await PaletteGenerator.fromImageProvider(
        MemoryImage(_coverBytes!),
        maximumColorCount: 5,
      );
      if (mounted) {
        setState(() {
          final rawColor = generator.vibrantColor?.color ??
              generator.lightVibrantColor?.color ??
              generator.dominantColor?.color ??
              (_dynamicColor ?? widget.themeColor);
          final hsl = HSLColor.fromColor(rawColor);
          _dynamicColor = rawColor.computeLuminance() < 0.18
              ? hsl.withLightness((hsl.lightness + 0.35).clamp(0.45, 0.75)).withSaturation((hsl.saturation + 0.2).clamp(0.5, 1.0)).toColor()
              : rawColor;
        });
      }
    } catch (e) {
      print('Palette Error: $e');
    }
  }
  
  // 🎯 SİBER HAMLE: Söz Kayıt (Cache) Motoru
  Future<String?> _getLocalLyrics(String songPath) async {
    if (!canPersistLyrics(songPath)) return null;
    try {
      final file = File(songPath.replaceAll(RegExp(r'\.[^.]+$'), '.lrc'));
      if (await file.exists()) {
        print('✅ Siber Mühür: Sözler yerel kayıttan (cache) otonom yüklendi!');
        return await file.readAsString();
      }
    } catch (e) {}
    return null;
  }

  void _changeLyricsOffset(int deltaMs) {
    setState(() {
      _lyricsOffsetMs += deltaMs;
    });
    LyricsService.saveLyricsOffset(_songPath, _lyricsOffsetMs);
  }

  void _resetLyricsOffset() {
    setState(() {
      _lyricsOffsetMs = 0;
    });
    LyricsService.saveLyricsOffset(_songPath, 0);
  }

  void _scrollToActiveIndex(int activeIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_lyricsScrollController.hasClients) return;
      if (activeIndex >= 0 && activeIndex < _lyricKeys.length) {
        final key = _lyricKeys[activeIndex];
        final itemContext = key.currentContext;
        if (itemContext != null) {
          Scrollable.ensureVisible(
            itemContext,
            alignment: 0.45, // 🎯 Tam göz hizası (Hafifçe ortanın üstü)
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
          );
        } else {
          // 🛡️ SİBER KALKAN: Eğer henüz render edilmemişse yaklaşık konuma sıçra, sonra hizala
          if (_lyricsScrollController.position.hasContentDimensions) {
            final maxExtent = _lyricsScrollController.position.maxScrollExtent;
            final targetOffset = (activeIndex * 55.0 - (_lyricsScrollController.position.viewportDimension / 2)).clamp(0.0, maxExtent);
            _lyricsScrollController.jumpTo(targetOffset);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && key.currentContext != null) {
                Scrollable.ensureVisible(
                  key.currentContext!,
                  alignment: 0.45,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                );
              }
            });
          }
        }
      }
    });
  }

  Future<void> _saveLocalLyrics(String songPath, String lyrics) async {
    if (!canPersistLyrics(songPath) || lyrics.isEmpty) return;
    try {
      final file = File(songPath.replaceAll(RegExp(r'\.[^.]+$'), '.lrc'));
      await file.writeAsString(lyrics);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sözler kaydedilemedi: $e')),
        );
      }
    }
  }

  Future<String?> _fallbackLrcFetch(String title, String artist) async {
    String cleanTitle = cleanLyricsTitle(title);
    String cleanArtist = (artist.toLowerCase() == 'victus v7' ||
            artist.toLowerCase() == 'bilinmeyen')
        ? ''
        : artist.trim();
    // 🎯 SİBER KALKAN: searchQuery zindandan çıkarılıp evrensel hale getirildi!
    String searchQuery =
        cleanArtist.isNotEmpty ? '$cleanArtist $cleanTitle' : cleanTitle;

    try {
      if (cleanArtist.isNotEmpty) {
        final uri = Uri.parse(
            'https://lrclib.net/api/get?artist_name=${Uri.encodeComponent(cleanArtist)}&track_name=${Uri.encodeComponent(cleanTitle)}');
        final res = await http.get(uri, headers: {'User-Agent': 'Ozses/7.0.0'}).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          if (data['syncedLyrics'] != null) return data['syncedLyrics'];
          if (data['plainLyrics'] != null) return data['plainLyrics'];
        }
      }
    } catch (e) {
      print('LRCLIB /get Hatası: $e');
    }

    try {
      final searchUri = Uri.parse(
          'https://lrclib.net/api/search?q=${Uri.encodeComponent(searchQuery)}');
      final searchRes = await http.get(searchUri, headers: {'User-Agent': 'Ozses/7.0.0'}).timeout(const Duration(seconds: 5));
      if (searchRes.statusCode == 200) {
        final List dataList = json.decode(searchRes.body);
        if (dataList.isNotEmpty) {
          for (var track in dataList) {
            if (track['syncedLyrics'] != null) return track['syncedLyrics'];
          }
          if (dataList[0]['plainLyrics'] != null) {
            return dataList[0]['plainLyrics'];
          }
        }
      }
    } catch (e) {
      print('LRCLIB /search Hatası, Siber Yapay Zeka Söz Motoruna (YouTube) Geçiliyor... $e');
    }

    // 🎯 SİBER HAMLE: Lyrics.ovh Yedek Söz Radarı
    try {
      if (cleanArtist.isNotEmpty) {
        final ovhUri = Uri.parse(
            'https://api.lyrics.ovh/v1/${Uri.encodeComponent(cleanArtist)}/${Uri.encodeComponent(cleanTitle)}');
        final ovhRes = await http.get(ovhUri, headers: {'User-Agent': 'Ozses/7.0.0'}).timeout(const Duration(seconds: 5));
        if (ovhRes.statusCode == 200) {
          final ovhData = json.decode(ovhRes.body);
          if (ovhData['lyrics'] != null) return ovhData['lyrics'];
        }
      }
    } catch (e) {}

    // 🤖 SİBER YAPAY ZEKA SÖZ MOTORU (Bulamazsa YouTube'dan Kırar!)
    try {
      final bridge = OzsesBridge();
      final searchRes = await bridge.searchMusic(searchQuery, limit: 1);
      if (searchRes.isNotEmpty) {
        String vId = searchRes[0]['video_id'] ?? searchRes[0]['id'];
        final ytLyrics = await bridge.getSiberLyrics(vId, searchQuery);
        if (ytLyrics != null && ytLyrics.isNotEmpty) return ytLyrics;
      }
    } catch (e) {
      print('Siber YouTube Lirik Sökücü Çöktü: $e');
    }
    return null;
  }

  Future<void> _handleKaraokeToggle() async {
    if (_lyricsText.isEmpty) {
      setState(() {
        _isFetchingLyrics = true;
        _showLyrics = true;
      });

      // 1. Önce Lokalden (Kayıttan) Çek (Sistemi Yorma!)
      // 1. Önce 4-Kademeli Sıfır Gecikmeli RAM & YouTube CC & LRCLIB Motorundan Çek
      String? finalText = await _getLocalLyrics(_songPath);
      try {
        final savedOffset = await LyricsService.getLyricsOffset(_songPath);
        if (mounted) _lyricsOffsetMs = savedOffset;
        final currentDur = audioHandler.mediaItem.value?.duration;
        final res = await LyricsService.fetchLyrics(
          _songPath,
          _songName,
          _artistName,
          duration: currentDur,
        );
        if (res != null && res.rawText.trim().isNotEmpty) {
          finalText = res.rawText;
        }
      } catch (_) {}

      // 2. Bulamazsa Siber Ağdan HIZLICA Çek
      if (finalText == null || finalText.trim().isEmpty) {
        final searchTitle = cleanLyricsTitle(_songName);
        final searchArtist = _artistName.toLowerCase() == 'victus v7' ? '' : _artistName;
        
        finalText = await _fallbackLrcFetch(searchTitle, searchArtist);

        if (finalText != null &&
            finalText.trim().isNotEmpty &&
            canPersistLyrics(_songPath)) {
          await _saveLocalLyrics(_songPath, finalText);
        }
      }
      if (mounted) {
        setState(() {
          _lyricsText = finalText ??
              'Usta, siber ağda bu müzik için mühürlenmiş söz bulunamadı!';
          // 🎯 SİBER HAMLE: Şarkının anlık süresini parse motoruna gönder!
          final currentDuration =
              audioHandler.mediaItem.value?.duration ?? Duration.zero;
          _parseLrc(_lyricsText, currentDuration);
          _isFetchingLyrics = false;
        });
      }
    } else {
      setState(() => _showLyrics = !_showLyrics);
    }
  }

  void _parseLrc(String text, Duration songDuration) {
    _parsedLyrics.clear();
    if (!text.contains('[0')) {
      // 🤖 SİBER OTONOM LİRİK MOTORU (AI SİMÜLASYONU)
      // Eğer sözlerde zaman etiketi yoksa, siber beyin süreyi analiz edip otomatik atama yapar!
      final lines = text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // 🎯 SİBER KALKAN: Eğer şarkı süresi sıfır gelirse (stream vb.) 3.5 dakika (210000 ms) varsay!
      int totalMs = songDuration.inMilliseconds;
      if (totalMs <= 0) totalMs = 210000;

      if (lines.isNotEmpty) {
        final msPerLine = (totalMs * 0.85) ~/ lines.length;
        final startOffset = totalMs * 0.05;
        for (int i = 0; i < lines.length; i++) {
          _parsedLyrics.add(LyricLine(
              Duration(milliseconds: startOffset.toInt() + (i * msPerLine)),
              lines[i]));
        }
      } else {
        _parsedLyrics = lines.map((e) => LyricLine(Duration.zero, e)).toList();
      }
      _lyricKeys = List.generate(_parsedLyrics.length, (_) => GlobalKey());
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
          _parsedLyrics.add(LyricLine(
              Duration(minutes: min, seconds: sec, milliseconds: ms), lText));
        }
      }
    }
    if (_parsedLyrics.isEmpty) {
      _parsedLyrics = text
          .split('\n')
          .map((e) => LyricLine(Duration.zero, e.trim()))
          .where((e) => e.text.isNotEmpty)
          .toList();
    }
    _lyricKeys = List.generate(_parsedLyrics.length, (_) => GlobalKey());
  }

  String _analyzeLineMood(String text) {
    final t = text.toLowerCase();
    if (t.contains('aşk') ||
        t.contains('sev') ||
        t.contains('kalp') ||
        t.contains('yürek') ||
        t.contains('özle') ||
        t.contains('göz')) {
      return 'Romantik / Duygusal';
    }
    if (t.contains('git') ||
        t.contains('ayrı') ||
        t.contains('yalnız') ||
        t.contains('acı') ||
        t.contains('ağla') ||
        t.contains('bırak')) {
      return 'Hüzünlü / Melankolik';
    }
    if (t.contains('para') ||
        t.contains('silah') ||
        t.contains('sokak') ||
        t.contains('kan') ||
        t.contains('vur') ||
        t.contains('kır')) {
      return 'Agresif / Sokak';
    }
    if (t.contains('dans') ||
        t.contains('hadi') ||
        t.contains('zıpla') ||
        t.contains('uç') ||
        t.contains('gece') ||
        t.contains('oyna')) {
      return 'Enerjik / Parti';
    }
    return 'Siber Denge';
  }

  @override
  void dispose() {
    _lyricsScrollController.dispose();
    _mediaSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isFav = widget.checkIsFavorite(_songPath);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Dev Ortam Işığı (Neon Ampul Etkisi)
          if (_coverBytes != null)
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (_dynamicColor ?? widget.themeColor).withValues(alpha: 0.9),
                      (_dynamicColor ?? widget.themeColor).withValues(alpha: 0.4),
                      Colors.black,
                    ],
                  ),
                ),
              ),
            )
          else
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(seconds: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (widget.themeColor).withValues(alpha: 0.6),
                      Colors.black87,
                      Colors.black,
                    ],
                  ),
                ),
              ),
            ),

          // 2. Yüksek Dozajlı Bulanıklık ve Glass Kalkanı
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ).animate(target: _showLyrics ? 1 : 0, onPlay: (controller) => controller.repeat(reverse: true))
           .fade(begin: 0.8, end: 1.0, duration: 2000.ms),

          // 🛠️ SİBER LEHİM: Masaüstü taşmalarını engellemek için ana gövdeyi esnek LayoutBuilder ile sarmaladık
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    // Üst Kapatma Çubuğu
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      key: const ValueKey('top_bar'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: Colors.white, size: 32),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Text('ŞU AN ÇALAN',
                              style: TextStyle(
                                  color: (_dynamicColor ?? widget.themeColor),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2)),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                            color: Colors.black.withOpacity(0.85),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: (_dynamicColor ?? widget.themeColor).withOpacity(0.3), width: 1),
                            ),
                            elevation: 12,
                            onSelected: (value) async {
                              if (value == 'floating_vinyl') {
                                BottomPlayerBar.isFloatingMiniMode.value = true;
                                Navigator.pop(context);
                              } else if (value == 'add_playlist') {
                                widget.onAddToPlaylist(_songPath);
                              } else if (value == 'delete') {
                                widget.onDelete(_songPath);
                              } else if (value == 'play_next') {
                                widget.onAddQueue(_songPath, true);
                              } else if (value == 'add_queue') {
                                widget.onAddQueue(_songPath, false);
                              } else if (value == 'download_song') {
                                if (widget.onDownloadStart != null) {
                                   String videoId = _songPath.replaceFirst('yt:', '');
                                   widget.onDownloadStart!(videoId, _songName);
                                } else {
                                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Siber Ağ: Bu ekrandan indirme yapılamaz!'), backgroundColor: Colors.redAccent));
                                }
                              } else if (value == 'analyze_mood') {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Siber Beyin: "$_songName" analiz ediliyor...'), backgroundColor: (_dynamicColor ?? widget.themeColor)));
                                await Future.delayed(const Duration(seconds: 2));
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yapay Zeka Analizi: Yüksek Frekanslı Enerji Tespit Edildi! 🚀'), backgroundColor: Colors.deepPurpleAccent, duration: Duration(seconds: 4)));
                                }
                              }
                            },
                            itemBuilder: (context) {
                              PopupMenuItem<String> buildItem(String val, IconData icon, String title, {bool isRed = false}) {
                                return PopupMenuItem<String>(
                                  value: val,
                                  child: Row(
                                    children: [
                                      Icon(icon, color: isRed ? Colors.redAccent : (_dynamicColor ?? widget.themeColor), size: 20),
                                      const SizedBox(width: 12),
                                      Text(
                                        title,
                                        style: TextStyle(
                                          color: isRed ? Colors.redAccent : Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              bool isOnline = _songPath.startsWith('yt:');
                              if (isOnline) {
                                return [
                                  buildItem('play_next', Icons.skip_next_rounded, 'Sıradakini Çal'),
                                  buildItem('add_queue', Icons.queue_music_rounded, 'Kuyruğa Ekle'),
                                  buildItem('download_song', Icons.download_rounded, 'Şarkıyı İndir'),
                                  buildItem('floating_vinyl', Icons.disc_full_rounded, 'Yüzen Mini Plak Modu'),
                                  buildItem('analyze_mood', Icons.psychology_rounded, 'Yapay Zeka Analizi'),
                                ];
                              } else {
                                return [
                                  buildItem('play_next', Icons.skip_next_rounded, 'Sıradakini Çal'),
                                  buildItem('add_queue', Icons.queue_music_rounded, 'Kuyruğa Ekle'),
                                  buildItem('floating_vinyl', Icons.disc_full_rounded, 'Yüzen Mini Plak Modu'),
                                  buildItem('add_playlist', Icons.playlist_add_rounded, "Playlist'e Ekle"),
                                  buildItem('delete', Icons.delete_sweep_rounded, 'Sök At (Sil)', isRed: true),
                                ];
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    // 🛠️ SİBER KALKAN: Masaüstü dikey daralmalarında taşmayı önleyen esnek içerik alanı
                    Expanded(
                      child: SingleChildScrollView(
                        physics: _showLyrics
                            ? const NeverScrollableScrollPhysics()
                            : const BouncingScrollPhysics(),
                        child: Container(
                          constraints: BoxConstraints(
                            // Ekran çok daralırsa minimum dikey alan tanı, genişse tam doldur
                            minHeight: constraints.maxHeight - 250,
                            maxHeight: _showLyrics
                                ? constraints.maxHeight - 240
                                : double.infinity,
                          ),
                          child: _showLyrics
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: BackdropFilter(
                                      filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                                        ),
                                        child: _isFetchingLyrics
                                          ? Center(
                                              child: CircularProgressIndicator(
                                                  color: (_dynamicColor ?? widget.themeColor)))
                                          : StreamBuilder<Duration>(
                                              stream: AudioService.position,
                                              builder: (context, snapshot) {
                                                final rawPos = snapshot.data ??
                                                    Duration.zero;
                                                final effectiveMs = (rawPos.inMilliseconds - _lyricsOffsetMs).clamp(0, 99999999);
                                                final pos = Duration(milliseconds: effectiveMs);
                                                int activeIndex = -1;
                                                bool isSynced =
                                                    _parsedLyrics.length > 1 &&
                                                        _parsedLyrics
                                                                .last.time >
                                                            Duration.zero;

                                                if (isSynced) {
                                                  for (int i = 0;
                                                      i < _parsedLyrics.length;
                                                      i++) {
                                                    if (_parsedLyrics[i].time >
                                                        pos) {
                                                      break;
                                                    }
                                                    activeIndex = i;
                                                  }

                                                  // 🛠️ SİBER OPERASYON: Sabitleyici modu açıksa otomatik kaydır, serbest moddaysa kullanıcının kaydırmasına izin ver
                                                  if (activeIndex != -1 &&
                                                      activeIndex !=
                                                          _lastActiveIndex) {
                                                    if (_isAutoScrollLocked) {
                                                      _scrollToActiveIndex(activeIndex);
                                                    }
                                                    _lastActiveIndex =
                                                        activeIndex;
                                                  }
                                                }

                                                return Column(
                                                  children: [
                                                    // ⏱️ Kalibrasyon, Sabitleyici & Çeviri Kontrol Paneli
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0, left: 8.0, right: 8.0),
                                                      child: Wrap(
                                                        alignment: WrapAlignment.center,
                                                        crossAxisAlignment: WrapCrossAlignment.center,
                                                        spacing: 6,
                                                        runSpacing: 6,
                                                        children: [
                                                          // 1. Senkron Ofset Ayar Çubuğu (Varsa)
                                                          if (isSynced)
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                              decoration: BoxDecoration(
                                                                color: Colors.black.withValues(alpha: 0.4),
                                                                borderRadius: BorderRadius.circular(14),
                                                                border: Border.all(
                                                                  color: (_dynamicColor ?? widget.themeColor).withValues(alpha: 0.35),
                                                                  width: 1,
                                                                ),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  InkWell(
                                                                    onTap: () => _changeLyricsOffset(-500),
                                                                    borderRadius: BorderRadius.circular(8),
                                                                    child: const Padding(
                                                                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                                      child: Text('-0.5s', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(width: 3),
                                                                  InkWell(
                                                                    onTap: _resetLyricsOffset,
                                                                    borderRadius: BorderRadius.circular(8),
                                                                    child: Padding(
                                                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                                      child: Text(
                                                                        _lyricsOffsetMs == 0 ? 'Senkron' : 's',
                                                                        style: TextStyle(
                                                                          color: (_dynamicColor ?? widget.themeColor),
                                                                          fontSize: 10,
                                                                          fontWeight: FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(width: 3),
                                                                  InkWell(
                                                                    onTap: () => _changeLyricsOffset(500),
                                                                    borderRadius: BorderRadius.circular(8),
                                                                    child: const Padding(
                                                                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                                      child: Text('+0.5s', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),

                                                          // 2. 📌 Sabitleyici / Serbest Mod Butonu
                                                          InkWell(
                                                            onTap: () {
                                                              setState(() {
                                                                _isAutoScrollLocked = !_isAutoScrollLocked;
                                                              });
                                                              if (_isAutoScrollLocked && activeIndex >= 0) {
                                                                _scrollToActiveIndex(activeIndex);
                                                              }
                                                            },
                                                            borderRadius: BorderRadius.circular(14),
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                              decoration: BoxDecoration(
                                                                color: _isAutoScrollLocked
                                                                    ? (_dynamicColor ?? widget.themeColor).withValues(alpha: 0.25)
                                                                    : Colors.black.withValues(alpha: 0.4),
                                                                borderRadius: BorderRadius.circular(14),
                                                                border: Border.all(
                                                                  color: _isAutoScrollLocked
                                                                      ? (_dynamicColor ?? widget.themeColor).withValues(alpha: 0.7)
                                                                      : Colors.white24,
                                                                  width: 1,
                                                                ),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  Icon(
                                                                    _isAutoScrollLocked ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                                                                    color: _isAutoScrollLocked ? (_dynamicColor ?? widget.themeColor) : Colors.white60,
                                                                    size: 12,
                                                                  ),
                                                                  const SizedBox(width: 4),
                                                                  Text(
                                                                    _isAutoScrollLocked ? 'Sabit' : 'Serbest',
                                                                    style: TextStyle(
                                                                      color: _isAutoScrollLocked ? Colors.white : Colors.white70,
                                                                      fontSize: 10,
                                                                      fontWeight: FontWeight.bold,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),

                                                          // 3. 🌐 Türkçe Çeviri Butonu (Sistem döşenmemiş, şık UI butonu)
                                                          InkWell(
                                                            onTap: () {
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                const SnackBar(
                                                                  content: Text('🌐 Türkçe Çeviri Motoru V8 ile aktif edilecek.'),
                                                                  backgroundColor: Colors.deepPurple,
                                                                  duration: Duration(seconds: 2),
                                                                ),
                                                              );
                                                            },
                                                            borderRadius: BorderRadius.circular(14),
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                              decoration: BoxDecoration(
                                                                color: Colors.black.withValues(alpha: 0.4),
                                                                borderRadius: BorderRadius.circular(14),
                                                                border: Border.all(
                                                                  color: Colors.white24,
                                                                  width: 1,
                                                                ),
                                                              ),
                                                              child: const Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  Icon(
                                                                    Icons.translate_rounded,
                                                                    color: Colors.cyanAccent,
                                                                    size: 12,
                                                                  ),
                                                                  SizedBox(width: 4),
                                                                  Text(
                                                                    'Türkçe Çeviri',
                                                                    style: TextStyle(
                                                                      color: Colors.white,
                                                                      fontSize: 10,
                                                                      fontWeight: FontWeight.bold,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    if (isSynced &&
                                                        activeIndex >= 0 &&
                                                        activeIndex <
                                                            _parsedLyrics
                                                                .length)
                                                      Container(
                                                        margin: const EdgeInsets
                                                            .only(
                                                            top: 15, bottom: 5),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 16,
                                                                vertical: 8),
                                                        decoration: BoxDecoration(
                                                            color: (_dynamicColor ?? widget.themeColor)
                                                                .withValues(alpha: 
                                                                    0.15),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                            border: Border.all(
                                                                color: (_dynamicColor ?? widget.themeColor)
                                                                    .withValues(alpha: 
                                                                        0.8),
                                                                width: 1.5),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                  color: (_dynamicColor ?? widget.themeColor)
                                                                      .withValues(alpha: 
                                                                          0.4),
                                                                  blurRadius:
                                                                      12,
                                                                  spreadRadius:
                                                                      1),
                                                            ]),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                                Icons
                                                                    .psychology,
                                                                color: (_dynamicColor ?? widget.themeColor),
                                                                size: 16),
                                                            const SizedBox(
                                                                width: 8),
                                                            Text(
                                                                'SİBER ANALİZ: ${_analyzeLineMood(_parsedLyrics[activeIndex].text)}',
                                                                style: TextStyle(
                                                                    color: (_dynamicColor ?? widget.themeColor),
                                                                    fontSize:
                                                                        11,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    letterSpacing:
                                                                        1.2)),
                                                          ],
                                                        ),
                                                      ),
                                                    Expanded(
                                                      child: MediaQuery(
                                                        data: MediaQuery.of(context).copyWith(
                                                          textScaler: MediaQuery.of(context).textScaler.clamp(
                                                            minScaleFactor: 0.85,
                                                            maxScaleFactor: 1.10,
                                                          ),
                                                        ),
                                                        child: ListView.builder(
                                                          controller:
                                                              _lyricsScrollController,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 24,
                                                                  horizontal: 16),
                                                          itemCount: _parsedLyrics
                                                              .length,
                                                          itemBuilder:
                                                              (context, index) {
                                                            final line =
                                                                _parsedLyrics[
                                                                    index];
                                                            final isActive =
                                                                isSynced
                                                                    ? (index ==
                                                                        activeIndex)
                                                                    : false;
                                                            final key = (index < _lyricKeys.length)
                                                                ? _lyricKeys[index]
                                                                : null;

                                                            return InkWell(
                                                              key: key,
                                                              borderRadius: BorderRadius.circular(15),
                                                              splashColor: (_dynamicColor ?? widget.themeColor).withValues(alpha: 0.25),
                                                              highlightColor: (_dynamicColor ?? widget.themeColor).withValues(alpha: 0.1),
                                                              onTap: () {
                                                                if (isSynced) {
                                                                  audioHandler.seek(line.time);
                                                                  HapticFeedback.selectionClick();
                                                                  _scrollToActiveIndex(index);
                                                                }
                                                              },
                                                              child: AnimatedContainer(
                                                                duration:
                                                                    const Duration(
                                                                        milliseconds:
                                                                            250),
                                                                margin:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            4),
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                        vertical:
                                                                            isActive
                                                                                ? 10
                                                                                : 6,
                                                                        horizontal:
                                                                            12),
                                                                decoration: isActive
                                                                    ? BoxDecoration(
                                                                        color: (_dynamicColor ?? widget.themeColor)
                                                                            .withValues(alpha: 
                                                                                0.2),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                                15),
                                                                        border: Border.all(
                                                                            color: (_dynamicColor ?? widget.themeColor)
                                                                                .withValues(alpha: 
                                                                                    0.8),
                                                                            width:
                                                                                1),
                                                                      )
                                                                    : null,
                                                                child: isActive ? (SubscriptionManager().canUseAdvancedKaraoke() ? Text(
                                                                  line.text,
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  maxLines: 4,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  style: TextStyle(
                                                                    color: Colors.white,
                                                                    fontSize: 22,
                                                                    fontWeight: FontWeight.w800,
                                                                    shadows: [
                                                                      Shadow(
                                                                          color: (_dynamicColor ?? widget.themeColor),
                                                                          blurRadius: 10),
                                                                      Shadow(
                                                                          color: (_dynamicColor ?? widget.themeColor),
                                                                          blurRadius: 20)
                                                                    ],
                                                                  ),
                                                                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                                                                 .shimmer(duration: 1500.ms, color: (_dynamicColor ?? widget.themeColor).withValues(alpha: 0.5))
                                                                 .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.03, 1.03), duration: 800.ms)
                                                                : Text(
                                                                  line.text,
                                                                  textAlign: TextAlign.center,
                                                                  maxLines: 4,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  style: TextStyle(
                                                                    color: (_dynamicColor ?? widget.themeColor),
                                                                    fontSize: 21,
                                                                    fontWeight: FontWeight.w800,
                                                                  ),
                                                                ))
                                                                : Text(
                                                                  line.text,
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  maxLines: 4,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  style: const TextStyle(
                                                                    color: Colors.white54,
                                                                    fontSize: 15,
                                                                    fontWeight: FontWeight.w600,
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                  ).animate().fadeIn()
                              : Center(
                                  child: StreamBuilder<PlaybackState>(
                                      stream: audioHandler.playbackState,
                                      builder: (context, snapshot) {
                                        final playbackState = snapshot.data;
                                        final isPlaying =
                                            playbackState?.playing ?? false;
                                        final currentSpeed =
                                            playbackState?.speed ?? 1.0;
                                        final currentPos =
                                            playbackState?.position ?? Duration.zero;
                                        final totalDur = audioHandler.mediaItem.value?.duration ?? Duration.zero;

                                        // 🛠️ SİBER REHİS: Masaüstü dikey alanına göre CD boyutunu koruma altına aldık
                                        double calculatedSize =
                                            constraints.maxHeight * 0.45;
                                        if (calculatedSize > 320) {
                                          calculatedSize = 320;
                                        }
                                        if (calculatedSize < 180) {
                                          calculatedSize = 180;
                                        }

                                        return InteractiveVinylDisc(
                                          isPlaying: isPlaying,
                                          themeColor: (_dynamicColor ?? widget.themeColor),
                                          coverBytes: _coverBytes,
                                          size: calculatedSize,
                                          playbackSpeed: currentSpeed,
                                          currentPosition: currentPos,
                                          totalDuration: totalDur,
                                          onSwipeUp: _handleKaraokeToggle,
                                          onSwipeDown: () {
                                            showModalBottomSheet(
                                              context: context,
                                              backgroundColor: Colors.transparent,
                                              isScrollControlled: true,
                                              builder: (context) => SiberKuyrukSheet(
                                                themeColor: (_dynamicColor ?? widget.themeColor),
                                              ),
                                            );
                                          },
                                          onSwipeLeft: () {
                                            audioHandler.skipToNext();
                                          },
                                          onSwipeRight: () {
                                            audioHandler.skipToPrevious();
                                          },
                                          onTap: () {
                                            if (isPlaying) {
                                              audioHandler.pause();
                                            } else {
                                              audioHandler.play();
                                            }
                                          },
                                          onSeek: (target) async {
                                            await audioHandler.seek(target);
                                          },
                                          onSpeedChanged: (speed) async {
                                            await audioHandler.setSpeed(speed);
                                          },
                                        );
                                      }),
                                ),
                        ),
                      ),
                    ),

                    // 🎤 ŞARKICI VE ŞARKI İSMİ BARBAROS PANELİ
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _songName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _artistName,
                                  style: TextStyle(
                                      color: (_dynamicColor ?? widget.themeColor).withValues(alpha: 0.8),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.redAccent : Colors.white,
                                size: 30),
                            onPressed: () {
                              widget.onToggleFavorite(_songPath);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),

                    // 🎯 SİBER AKSİYON ÇUBUĞU (EQ, KARAOKE, ZAMANLAYICI)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // EKOLAYZER BUTONU
                          IconButton(
                          icon: Icon(Icons.equalizer, color: (_dynamicColor ?? widget.themeColor), size: 30),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) => SiberEkolayzerSheet(themeColor: (_dynamicColor ?? widget.themeColor)),
                            );
                          },
                        ),
                        const SizedBox(width: 15),

                        // KARAOKE BUTONU
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: (_dynamicColor ?? widget.themeColor).withValues(alpha: 0.8),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: (_dynamicColor ?? widget.themeColor).withValues(alpha: 0.3),
                                  blurRadius: 10),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
                                },
                                child: ElevatedButton.icon(
                                  key: ValueKey<bool>(_showLyrics),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _showLyrics ? Colors.redAccent.withValues(alpha: 0.2) : (_dynamicColor ?? widget.themeColor).withValues(alpha: 0.1),
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  icon: Icon(_showLyrics ? Icons.close : Icons.mic_external_on, color: Colors.white),
                                  label: Text(_showLyrics ? "KARAOKE'DEN ÇIK" : 'SİBER KARAOKE',
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  onPressed: _handleKaraokeToggle,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 🌙 GELİŞMİŞ UYKU ZAMANLAYICI BUTONU
                        IconButton(
                          icon: Icon(Icons.bedtime_rounded, color: (_dynamicColor ?? widget.themeColor), size: 28),
                          tooltip: 'Uyku Zamanlayıcı',
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) => SiberUykuSheet(themeColor: (_dynamicColor ?? widget.themeColor)),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        // 🎵 KUYRUK BUTONU
                        IconButton(
                          icon: Icon(Icons.queue_music_rounded, color: (_dynamicColor ?? widget.themeColor), size: 28),
                          tooltip: 'Çalma Kuyruğu',
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) => SiberKuyrukSheet(themeColor: (_dynamicColor ?? widget.themeColor)),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        // 📊 İSTATİSTİK BUTONU
                        IconButton(
                          icon: Icon(Icons.bar_chart_rounded, color: (_dynamicColor ?? widget.themeColor), size: 28),
                          tooltip: 'Dinleme İstatistikleri',
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) => SiberIstatistikSheet(themeColor: (_dynamicColor ?? widget.themeColor)),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        // 💬 SİBER PAYLAŞ BUTONU
                        IconButton(
                          icon: Icon(Icons.share_rounded, color: (_dynamicColor ?? widget.themeColor), size: 28),
                          tooltip: 'Paylaş',
                          onPressed: () {
                            Share.share('🎧 Şu an dinliyorum: $_songName - $_artistName\nÖZSES Müzik ile keşfettim!');
                          },
                        ),
                      ],
                    ),
                    ),

                // 🎛️ MÜZİK KONTROL PANELİ VE SLIDER
                    StreamBuilder<Duration>(
                      stream: AudioService.position,
                      key: const ValueKey('controls_panel'),
                      builder: (context, positionSnapshot) {
                        return StreamBuilder<PlaybackState>(
                          stream: audioHandler.playbackState,
                          builder: (context, stateSnapshot) {
                            final pos = positionSnapshot.data ?? Duration.zero;
                            final state = stateSnapshot.data;
                            final isPlaying = state?.playing ?? false;
                            final isBuffering = state?.processingState == AudioProcessingState.buffering || state?.processingState == AudioProcessingState.loading;

                            return StreamBuilder<MediaItem?>(
                              stream: audioHandler.mediaItem,
                              builder: (context, mediaSnapshot) {
                                final dur = mediaSnapshot.data?.duration ??
                                    Duration.zero;
                                double maxVal = dur.inSeconds.toDouble();
                                if (maxVal <= 0.0) maxVal = 1.0;
                                double currentVal =
                                    pos.inSeconds.toDouble().clamp(0.0, maxVal);

                                return Padding(
                                  padding: const EdgeInsets.only(
                                      left: 20, right: 20, bottom: 15, top: 5),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Slider(
                                        activeColor: (_dynamicColor ?? widget.themeColor),
                                        inactiveColor: Colors.white24,
                                        max: maxVal,
                                        value: currentVal,
                                        onChanged: (v) => audioHandler
                                            .seek(Duration(seconds: v.toInt())),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                                "${(pos.inMinutes).toString().padLeft(2, '0')}:${(pos.inSeconds % 60).toString().padLeft(2, '0')}",
                                                style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 11)),
                                            Text(
                                                "${(dur.inMinutes).toString().padLeft(2, '0')}:${(dur.inSeconds % 60).toString().padLeft(2, '0')}",
                                                style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          IconButton(
                                              icon: Icon(Icons.shuffle,
                                                  color: state?.shuffleMode ==
                                                          AudioServiceShuffleMode
                                                              .all
                                                      ? (_dynamicColor ?? widget.themeColor)
                                                      : Colors.white54,
                                                  size: 26),
                                              onPressed: () => audioHandler
                                                  .setShuffleMode(state
                                                              ?.shuffleMode ==
                                                          AudioServiceShuffleMode
                                                              .all
                                                      ? AudioServiceShuffleMode
                                                          .none
                                                      : AudioServiceShuffleMode
                                                          .all)),
                                          IconButton(
                                              icon: const Icon(
                                                  Icons.skip_previous,
                                                  color: Colors.white,
                                                  size: 36),
                                              onPressed: () => audioHandler
                                                  .skipToPrevious()),
                                          Container(
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: (_dynamicColor ?? widget.themeColor),
                                                boxShadow: [
                                                  BoxShadow(
                                                      color: (_dynamicColor ?? widget.themeColor)
                                                          .withValues(alpha: 0.5),
                                                      blurRadius: 15)
                                                ]),
                                            child: isBuffering
                                                ? const Padding(
                                                    padding: EdgeInsets.all(12.0),
                                                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                                                  )
                                                : IconButton(
                                                    icon: Icon(
                                                        isPlaying
                                                            ? Icons.pause
                                                            : Icons.play_arrow,
                                                        color: Colors.black,
                                                        size: 40),
                                                    onPressed: () => isPlaying
                                                        ? audioHandler.pause()
                                                        : audioHandler.play()),
                                          ),
                                          IconButton(
                                              icon: const Icon(Icons.skip_next,
                                                  color: Colors.white,
                                                  size: 36),
                                              onPressed: () =>
                                                  audioHandler.skipToNext()),
                                          IconButton(
                                              icon: Icon(
                                                  state?.repeatMode ==
                                                          AudioServiceRepeatMode
                                                              .one
                                                      ? Icons.repeat_one
                                                      : Icons.repeat,
                                                  color: state?.repeatMode !=
                                                          AudioServiceRepeatMode
                                                              .none
                                                      ? (_dynamicColor ?? widget.themeColor)
                                                      : Colors.white54,
                                                  size: 26),
                                              onPressed: () {
                                                final current =
                                                    state?.repeatMode;
                                                if (current ==
                                                    AudioServiceRepeatMode
                                                        .none) {
                                                  audioHandler.setRepeatMode(
                                                      AudioServiceRepeatMode
                                                          .all);
                                                } else if (current ==
                                                    AudioServiceRepeatMode
                                                        .all) {
                                                  audioHandler.setRepeatMode(
                                                      AudioServiceRepeatMode
                                                          .one);
                                                } else {
                                                  audioHandler.setRepeatMode(
                                                      AudioServiceRepeatMode
                                                          .none);
                                                }
                                              }),
                                        ],
                                      ),

                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
