import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../utils/song_media_utils.dart';

/// Her bir söz satırının zamanı ve metni
class LyricLine {
  final Duration time;
  final String text;
  const LyricLine(this.time, this.text);
}

/// Çözülen söz sonucu ve meta verileri
class LyricsResult {
  final String rawText;
  final List<LyricLine> lines;
  final bool isSynced;
  final String source; // 'youtube_cc', 'lrclib_exact', 'lrclib_search', 'local_cache', 'lyrics_ovh'
  final bool isRemixFallback;

  const LyricsResult({
    required this.rawText,
    required this.lines,
    required this.isSynced,
    required this.source,
    this.isRemixFallback = false,
  });
}

/// 🎯 ÖZSES 4 Kademeli Sıfır Gecikmeli & Doğrulamalı Şarkı Sözü Motoru
class LyricsService {
  // 🧠 0-ms UI yanıtı için RAM Önbelleği
  static final Map<String, LyricsResult> _memoryCache = {};

  // 🛡️ Tekrarlı ve çakışan istekleri engelleyen kalkan (In-Flight Request Deduplication)
  static final Map<String, Future<LyricsResult?>> _inFlight = {};

  /// RAM önbelleğini temizler
  static void clearMemoryCache() {
    _memoryCache.clear();
  }

  /// 🚀 Görünmez Arka Plan Avcısı (Speculative Pre-loader)
  /// Şarkı başladığı an arka planda sessizce sözü RAM'e çeker.
  static void preloadLyrics(
    String songPath,
    String rawTitle,
    String rawArtist, {
    Duration? duration,
    String? videoId,
  }) {
    if (songPath.isEmpty || songPath == 'bilinmeyen_yol') return;
    if (_memoryCache.containsKey(songPath)) return;

    fetchLyrics(
      songPath,
      rawTitle,
      rawArtist,
      duration: duration,
      videoId: videoId,
    ).catchError((_) => null);
  }

  /// Şarkı sözünü çok kademeli hibrit boru hattından çeker
  static Future<LyricsResult?> fetchLyrics(
    String songPath,
    String rawTitle,
    String rawArtist, {
    Duration? duration,
    String? videoId,
    bool forceRefresh = false,
  }) async {
    if (songPath.isEmpty || songPath == 'bilinmeyen_yol') return null;

    // 1. RAM Önbelleği Kontrolü (0 ms)
    if (!forceRefresh && _memoryCache.containsKey(songPath)) {
      return _memoryCache[songPath];
    }

    // 2. Devam Eden İstek Varsa Ona Tutun
    if (_inFlight.containsKey(songPath)) {
      return await _inFlight[songPath];
    }

    final future = _executeFetchPipeline(
      songPath,
      rawTitle,
      rawArtist,
      duration: duration,
      videoId: videoId,
    );
    _inFlight[songPath] = future;

    try {
      final result = await future;
      if (result != null) {
        _memoryCache[songPath] = result;
      }
      return result;
    } finally {
      _inFlight.remove(songPath);
    }
  }

  static Future<LyricsResult?> _executeFetchPipeline(
    String songPath,
    String rawTitle,
    String rawArtist, {
    Duration? duration,
    String? videoId,
  }) async {
    // 0. Kademe: Yerel Dosya Önbelleği (.lrc dosyası varsa)
    final localLyrics = await _getLocalLyrics(songPath);
    if (localLyrics != null && localLyrics.trim().isNotEmpty) {
      final lines = parseLrcContent(localLyrics);
      final isSynced = lines.length > 1 && lines.last.time > Duration.zero;
      return LyricsResult(
        rawText: localLyrics,
        lines: lines,
        isSynced: isSynced,
        source: 'local_cache',
      );
    }

    final effectiveVideoId = videoId ??
        (songPath.startsWith('yt:') ? songPath.substring(3) : extractVideoIdFromPath(songPath));

    // 1. Kademe: YouTube Native Altyazısı (0 ms Zaman Kayması, %100 Birebir Eşleşme, Sıfır Sansür)
    if (effectiveVideoId != null && effectiveVideoId.isNotEmpty) {
      try {
        final yt = YoutubeExplode();
        final manifest = await yt.videos.closedCaptions
            .getManifest(effectiveVideoId)
            .timeout(const Duration(seconds: 4));

        if (manifest.tracks.isNotEmpty) {
          final trackInfo = manifest.tracks.firstWhere(
            (t) => t.language.code == 'tr' || t.language.code == 'tr-TR',
            orElse: () => manifest.tracks.firstWhere(
              (t) => t.language.code == 'en' || t.language.code == 'en-US',
              orElse: () => manifest.tracks.first,
            ),
          );

          final track = await yt.videos.closedCaptions
              .get(trackInfo)
              .timeout(const Duration(seconds: 4));
          final lrcBuffer = StringBuffer();
          for (final caption in track.captions) {
            final start = caption.offset;
            final min = start.inMinutes.toString().padLeft(2, '0');
            final sec = (start.inSeconds % 60).toString().padLeft(2, '0');
            final ms = (start.inMilliseconds % 1000)
                .toString()
                .padLeft(3, '0')
                .substring(0, 2);
            lrcBuffer.writeln(
                '[$min:$sec.$ms] ${caption.text.replaceAll('\n', ' ').trim()}');
          }
          yt.close();

          final lrcStr = lrcBuffer.toString().trim();
          if (lrcStr.isNotEmpty) {
            final parsed = parseLrcContent(lrcStr);
            if (parsed.isNotEmpty) {
              final res = LyricsResult(
                rawText: lrcStr,
                lines: parsed,
                isSynced: true,
                source: 'youtube_cc',
              );
              _maybeSaveLocalLyrics(songPath, lrcStr);
              return res;
            }
          }
        } else {
          yt.close();
        }
      } catch (_) {}
    }

    final info = extractCleanLyricsInfo(rawTitle, rawArtist);
    final cleanTitle = info.title;
    final cleanArtist = info.artist;
    final coreTitle = info.coreTitle;
    final fullQuery = info.fullQuery;
    final isRemix = info.isRemix;

    // 2. Kademe: LRCLIB /api/get (Süre ve Tam Eşleşme ile Doğrulama)
    if (cleanArtist.isNotEmpty && cleanTitle.isNotEmpty) {
      try {
        final durParam = (duration != null && duration.inSeconds > 0)
            ? '&duration=${duration.inSeconds}'
            : '';
        final uri = Uri.parse(
          'https://lrclib.net/api/get?artist_name=${Uri.encodeComponent(cleanArtist)}&track_name=${Uri.encodeComponent(cleanTitle)}$durParam',
        );
        final res = await http.get(uri, headers: {
          'User-Agent': 'Ozses/7.0.0 (https://ozses.app)'
        }).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final data = json.decode(utf8.decode(res.bodyBytes));
          final candidate = pickBestLrcCandidate(
            dataList: [data],
            targetArtist: cleanArtist,
            targetTitle: cleanTitle,
            targetDuration: duration,
            isTargetRemix: isRemix,
          );
          if (candidate != null) {
            final parsed = parseLrcContent(candidate.lyrics);
            final resObj = LyricsResult(
              rawText: candidate.lyrics,
              lines: parsed,
              isSynced: candidate.isSynced,
              source: 'lrclib_exact',
              isRemixFallback: candidate.isOriginalFallback,
            );
            _maybeSaveLocalLyrics(songPath, candidate.lyrics);
            return resObj;
          }
        }
      } catch (_) {}
    }

    // 3. Kademe: LRCLIB /api/search (Aday Puanlama & Baraj Kalkanı)
    if (fullQuery.isNotEmpty) {
      try {
        final searchUri = Uri.parse(
          'https://lrclib.net/api/search?q=${Uri.encodeComponent(fullQuery)}',
        );
        final res = await http.get(searchUri, headers: {
          'User-Agent': 'Ozses/7.0.0 (https://ozses.app)'
        }).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final List dataList = json.decode(utf8.decode(res.bodyBytes));
          final candidate = pickBestLrcCandidate(
            dataList: dataList,
            targetArtist: cleanArtist,
            targetTitle: cleanTitle,
            targetDuration: duration,
            isTargetRemix: isRemix,
          );
          if (candidate != null) {
            final parsed = parseLrcContent(candidate.lyrics);
            final resObj = LyricsResult(
              rawText: candidate.lyrics,
              lines: parsed,
              isSynced: candidate.isSynced,
              source: 'lrclib_search',
              isRemixFallback: candidate.isOriginalFallback,
            );
            _maybeSaveLocalLyrics(songPath, candidate.lyrics);
            return resObj;
          }
        }
      } catch (_) {}
    }

    // 4. Kademe: Remix Koruma & Orijinal Parça Eşleştirme
    if (isRemix && coreTitle.isNotEmpty && coreTitle != cleanTitle) {
      try {
        final origQuery =
            cleanArtist.isNotEmpty ? '$cleanArtist $coreTitle' : coreTitle;
        final searchUri = Uri.parse(
          'https://lrclib.net/api/search?q=${Uri.encodeComponent(origQuery)}',
        );
        final res = await http.get(searchUri, headers: {
          'User-Agent': 'Ozses/7.0.0 (https://ozses.app)'
        }).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final List dataList = json.decode(utf8.decode(res.bodyBytes));
          final candidate = pickBestLrcCandidate(
            dataList: dataList,
            targetArtist: cleanArtist,
            targetTitle: coreTitle,
            targetDuration: duration,
            isTargetRemix: true,
            allowOriginalFallback: true,
          );
          if (candidate != null) {
            final parsed = parseLrcContent(candidate.lyrics);
            final resObj = LyricsResult(
              rawText: candidate.lyrics,
              lines: parsed,
              isSynced: candidate.isSynced,
              source: 'lrclib_remix_fallback',
              isRemixFallback: true,
            );
            _maybeSaveLocalLyrics(songPath, candidate.lyrics);
            return resObj;
          }
        }
      } catch (_) {}
    }

    // 5. Kademe: Lyrics.ovh Düz Metin Kurtarıcı
    if (cleanArtist.isNotEmpty && cleanTitle.isNotEmpty) {
      try {
        final ovhUri = Uri.parse(
          'https://api.lyrics.ovh/v1/${Uri.encodeComponent(cleanArtist)}/${Uri.encodeComponent(cleanTitle)}',
        );
        final ovhRes = await http.get(ovhUri, headers: {
          'User-Agent': 'Ozses/7.0.0 (https://ozses.app)'
        }).timeout(const Duration(seconds: 3));

        if (ovhRes.statusCode == 200) {
          final ovhData = json.decode(utf8.decode(ovhRes.bodyBytes));
          final lText = ovhData['lyrics']?.toString();
          if (lText != null && lText.trim().isNotEmpty) {
            final parsed = parseLrcContent(lText);
            final resObj = LyricsResult(
              rawText: lText,
              lines: parsed,
              isSynced: false,
              source: 'lyrics_ovh',
            );
            _maybeSaveLocalLyrics(songPath, lText);
            return resObj;
          }
        }
      } catch (_) {}
    }

    return null;
  }

  /// .lrc ve düz metinleri parse eder (Tek haneli dakikaları ve çoklu zaman etiketlerini destekler)
  static List<LyricLine> parseLrcContent(String text) {
    final lines = <LyricLine>[];
    final regex = RegExp(r'\[(\d{1,2}):(\d{2})(?:\.(\d{2,3}))?\]');

    for (final rawLine in text.split('\n')) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty) continue;
      // LRC meta verilerini temizle ([ti:..], [ar:..], vb.)
      if (RegExp(r'^\[(ti|ar|al|by|length|offset|re|ve):', caseSensitive: false)
          .hasMatch(trimmed)) {
        continue;
      }

      final matches = regex.allMatches(trimmed);
      if (matches.isNotEmpty) {
        final lastMatch = matches.last;
        final lineText = trimmed.substring(lastMatch.end).trim();

        for (final match in matches) {
          final min = int.parse(match.group(1)!);
          final sec = int.parse(match.group(2)!);
          final msStr = match.group(3);
          int ms = 0;
          if (msStr != null) {
            ms = int.parse(msStr.padRight(3, '0').substring(0, 3));
          }
          lines.add(LyricLine(
            Duration(minutes: min, seconds: sec, milliseconds: ms),
            lineText,
          ));
        }
      }
    }

    lines.sort((a, b) => a.time.compareTo(b.time));

    // Senkron etiketi yoksa düz metin olarak aktar
    if (lines.isEmpty) {
      for (final rawLine in text.split('\n')) {
        final trimmed = rawLine.trim();
        if (trimmed.isNotEmpty && !trimmed.startsWith('[')) {
          lines.add(LyricLine(Duration.zero, trimmed));
        }
      }
    }

    return lines;
  }

  // 🎯 Şarkı bazlı milisaniye ofset hafızası
  static Future<int> getLyricsOffset(String songPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key =
          'lrc_offset_${songPath.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      return prefs.getInt(key) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> saveLyricsOffset(String songPath, int offsetMs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key =
          'lrc_offset_${songPath.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      await prefs.setInt(key, offsetMs);
    } catch (_) {}
  }

  static Future<String?> _getLocalLyrics(String songPath) async {
    if (!canPersistLyrics(songPath)) return null;
    try {
      final file = File(songPath.replaceAll(RegExp(r'\.[^.]+$'), '.lrc'));
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (_) {}
    return null;
  }

  static Future<void> _maybeSaveLocalLyrics(
      String songPath, String lyrics) async {
    if (!canPersistLyrics(songPath) || lyrics.isEmpty) return;
    try {
      final file = File(songPath.replaceAll(RegExp(r'\.[^.]+$'), '.lrc'));
      await file.writeAsString(lyrics);
    } catch (_) {}
  }
}
