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
import '../utils/song_media_utils.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart'; // 🎯 Dosya okuma/yazma için gerekli mühür
import 'package:flutter/services.dart'; // 🎯 Pano (Clipboard) İşlemleri İçin
import 'siber_ekolayzer_sheet.dart';
import 'sleep_timer_sheet.dart';
import 'siber_uyku_sheet.dart';
import 'siber_kuyruk_sheet.dart';
import 'siber_istatistik_sheet.dart';

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
  final ScrollController _lyricsScrollController = ScrollController();
  int _lastActiveIndex = -1;
  StreamSubscription? _mediaSub;

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
              _showLyrics = false;
            });
          }
          _loadCoverForMediaItem(item);
        }
      }
    });
  }

  void _loadCoverForMediaItem(MediaItem item) {
    final uri = artUriForMediaId(
      item.id,
      videoId: item.extras?['videoId']?.toString(),
      existing: item.artUri,
    );

    if (uri != null) {
      http.get(uri).then((response) {
        if (response.statusCode == 200 &&
            mounted &&
            _currentProcessedId == item.id) {
          setState(() => _coverBytes = response.bodyBytes);
          _updatePalette();
        }
      }).catchError((_) {});
      return;
    }

    if (item.id.startsWith('downloading:') || item.id == 'bilinmeyen_yol') {
      return;
    }

    ID3Service.extractTags(item.id).then((tags) {
      if (!mounted || _currentProcessedId != item.id) return;
      setState(() {
        _coverBytes = ID3Service.getCoverBytes(tags);
        _updatePalette();
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
          _dynamicColor = generator.dominantColor?.color ?? (_dynamicColor ?? widget.themeColor);
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
      String? finalText = await _getLocalLyrics(_songPath);

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
                            icon: const Icon(Icons.more_vert,
                                color: Colors.white),
                            color: Colors.grey[900],
                            onSelected: (value) async {
                              if (value == 'add_playlist') {
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
                              } else if (value == 'share_song') {
                                final String text = 'Şu an dinliyorum: $_songName - $_artistName\n(Victus V7 IMPERIUM Siber Ağı)';
                                await Clipboard.setData(ClipboardData(text: text));
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Siber Ağ: Pano Bağlantısı Sağlandı (Paylaşıma Hazır)'), backgroundColor: Colors.greenAccent));
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
                              bool isOnline = _songPath.startsWith('yt:');
                              if (isOnline) {
                                return [
                                  const PopupMenuItem(
                                      value: 'play_next',
                                      child: Text('Sıradakini Çal',
                                          style: TextStyle(color: Colors.white))),
                                  const PopupMenuItem(
                                      value: 'add_queue',
                                      child: Text('Kuyruğa Ekle',
                                          style: TextStyle(color: Colors.white))),
                                  const PopupMenuItem(
                                      value: 'download_song',
                                      child: Text('Şarkıyı İndir',
                                          style: TextStyle(color: Colors.white))),
                                  const PopupMenuItem(
                                      value: 'analyze_mood',
                                      child: Text('Yapay Zeka Ruh Hali Analizi',
                                          style: TextStyle(color: Colors.white))),
                                  const PopupMenuItem(
                                      value: 'share_song',
                                      child: Text('Paylaş',
                                          style: TextStyle(color: Colors.white))),
                                ];
                              } else {
                                return [
                                  const PopupMenuItem(
                                      value: 'play_next',
                                      child: Text('Sıradakini Çal',
                                          style: TextStyle(color: Colors.white))),
                                  const PopupMenuItem(
                                      value: 'add_queue',
                                      child: Text('Kuyruğa Ekle',
                                          style: TextStyle(color: Colors.white))),
                                  const PopupMenuItem(
                                      value: 'add_playlist',
                                      child: Text("Playlist'e Ekle",
                                          style: TextStyle(color: Colors.white))),
                                  const PopupMenuItem(
                                      value: 'share_song',
                                      child: Text('Paylaş',
                                          style: TextStyle(color: Colors.white))),
                                  const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Sök At (Sil)',
                                          style: TextStyle(color: Colors.redAccent))),
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
                                                final pos = snapshot.data ??
                                                    Duration.zero;
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

                                                  // 🛠️ SİBER OPERASYON: Kaydırma taşması ve kilitlenmesi jilet gibi sıfırlandı
                                                  if (activeIndex != -1 &&
                                                      activeIndex !=
                                                          _lastActiveIndex) {
                                                    WidgetsBinding.instance
                                                        .addPostFrameCallback(
                                                            (_) {
                                                      if (_lyricsScrollController
                                                              .hasClients &&
                                                          activeIndex <
                                                              _parsedLyrics
                                                                  .length) {
                                                        const double
                                                            itemExtent = 54.0;
                                                        double viewportHeight =
                                                            _lyricsScrollController
                                                                .position
                                                                .viewportDimension;
                                                        double targetOffset =
                                                            (activeIndex *
                                                                    itemExtent) -
                                                                (viewportHeight /
                                                                    2) +
                                                                (itemExtent /
                                                                    2);

                                                        // Max extent kontrolünü güvenli sınıra aldık
                                                        double maxExtent =
                                                            _lyricsScrollController
                                                                .position
                                                                .maxScrollExtent;
                                                        targetOffset =
                                                            targetOffset.clamp(
                                                                0.0,
                                                                maxExtent > 0
                                                                    ? maxExtent
                                                                    : double
                                                                        .infinity);

                                                        _lyricsScrollController.animateTo(
                                                            targetOffset,
                                                            duration:
                                                                const Duration(
                                                                    milliseconds:
                                                                        400),
                                                            curve: Curves
                                                                .fastOutSlowIn);
                                                      }
                                                    });
                                                    _lastActiveIndex =
                                                        activeIndex;
                                                  }
                                                }

                                                return Column(
                                                  children: [
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
                                                            color: widget
                                                                .themeColor
                                                                .withValues(alpha: 
                                                                    0.15),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                            border: Border.all(
                                                                color: widget
                                                                    .themeColor
                                                                    .withValues(alpha: 
                                                                        0.8),
                                                                width: 1.5),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                  color: widget
                                                                      .themeColor
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
                                                                color: widget
                                                                    .themeColor,
                                                                size: 16),
                                                            const SizedBox(
                                                                width: 8),
                                                            Text(
                                                                'SİBER ANALİZ: ${_analyzeLineMood(_parsedLyrics[activeIndex].text)}',
                                                                style: TextStyle(
                                                                    color: widget
                                                                        .themeColor,
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
                                                      child: ListView.builder(
                                                        controller:
                                                            _lyricsScrollController,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 20,
                                                                horizontal: 20),
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

                                                          return AnimatedContainer(
                                                            duration:
                                                                const Duration(
                                                                    milliseconds:
                                                                        250),
                                                            margin:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        6),
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    vertical:
                                                                        isActive
                                                                            ? 12
                                                                            : 6,
                                                                    horizontal:
                                                                        8),
                                                            decoration: isActive
                                                                ? BoxDecoration(
                                                                    color: widget
                                                                        .themeColor
                                                                        .withValues(alpha: 
                                                                            0.2),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            15),
                                                                    border: Border.all(
                                                                        color: widget
                                                                            .themeColor
                                                                            .withValues(alpha: 
                                                                                0.8),
                                                                        width:
                                                                            1),
                                                                  )
                                                                : null,
                                                            child: isActive ? Text(
                                                              line.text,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 32,
                                                                fontWeight: FontWeight.w900,
                                                                shadows: [
                                                                  Shadow(
                                                                      color: (_dynamicColor ?? widget.themeColor),
                                                                      blurRadius: 15),
                                                                  Shadow(
                                                                      color: (_dynamicColor ?? widget.themeColor),
                                                                      blurRadius: 30)
                                                                ],
                                                              ),
                                                            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                                                             .shimmer(duration: 1500.ms, color: (_dynamicColor ?? widget.themeColor).withValues(alpha: 0.5))
                                                             .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.05, 1.05), duration: 800.ms)
                                                            : Text(
                                                              line.text,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: const TextStyle(
                                                                color: Colors.white54,
                                                                fontSize: 20,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          );
                                                        },
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
                                        final isPlaying =
                                            snapshot.data?.playing ?? false;
                                        // 🛠️ SİBER REHİS: Masaüstü dikey alanına göre CD boyutunu koruma altına aldık
                                        double calculatedSize =
                                            constraints.maxHeight * 0.45;
                                        if (calculatedSize > 320) {
                                          calculatedSize = 320;
                                        }
                                        if (calculatedSize < 180) {
                                          calculatedSize = 180;
                                        }

                                        return RotatingCDCover(
                                          isPlaying: isPlaying,
                                          themeColor: (_dynamicColor ?? widget.themeColor),
                                          coverBytes: _coverBytes,
                                          size: calculatedSize,
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
                    Row(
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
