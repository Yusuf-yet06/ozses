import 'dart:convert';
import 'dart:io'; // 🎯 SİBER HAMLE: Gerçek dosya ve işletim sistemi motoru içeri alındı
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_service/audio_service.dart';
import '../models/song_model.dart';

/// Oynatılabilir yol kontrolü — downloading: placeholder'ları eler.
bool isPlayableSongPath(String? path) {
  if (path == null || path.isEmpty || path == 'bilinmeyen_yol') return false;
  if (path.startsWith('downloading:')) return false;
  return true; 
}

String? extractVideoIdFromPath(String? path) {
  if (path == null) return null;
  if (path.startsWith('yt:')) return path.substring(3);

  // 🎯 SİBER KALKAN: Windows veya Android fark etmeksizin ismi dosya yolundan güvenle koparır
  final lastSegment = path.split('/').last.split('\\').last;
  final match = RegExp(r'ozses_muhur_([^.]+)', caseSensitive: false)
      .firstMatch(lastSegment);
  if (match != null) return match.group(1);

  // 🎯 Çevrimdışı önbellek formatı (<videoId>.m4a) için 11 karakterli YouTube ID yakalayıcı
  final baseName = lastSegment.replaceAll(RegExp(r'\.[^.]+$'), '');
  if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(baseName)) {
    return baseName;
  }

  return null;
}

Uri? safeParseUri(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  String cleanUrl = url.trim();
  if (cleanUrl.startsWith('//')) {
    cleanUrl = 'https:$cleanUrl';
  } else if (!cleanUrl.startsWith('http')) {
    return null;
  }
  return Uri.tryParse(cleanUrl);
}

Uri? artUriForSong(SongModel song) {
  final vid = song.videoId ?? extractVideoIdFromPath(song.path);
  if (vid != null && vid.isNotEmpty) {
    return Uri.parse('https://i.ytimg.com/vi/$vid/hqdefault.jpg');
  }
  if (song.artUrl != null && song.artUrl!.isNotEmpty) {
    return safeParseUri(song.artUrl);
  }
  return null;
}

Uri? artUriForMediaId(String id, {String? videoId, Uri? existing}) {
  final vid = videoId ?? extractVideoIdFromPath(id);
  if (vid != null && vid.isNotEmpty) {
    return Uri.parse('https://i.ytimg.com/vi/$vid/hqdefault.jpg');
  }
  return existing;
}

String safeSongTitle(SongModel song) {
  String n = song.title?.trim().isNotEmpty == true
      ? song.title!.trim()
      : (song.name ?? '').trim();
  if (n.isEmpty || n == 'Bilinmeyen Müzik' || n.toLowerCase() == 'null' || n.toLowerCase() == 'unknown') {
    final path = song.path ?? '';
    if (path.isNotEmpty && path != 'bilinmeyen_yol') {
      n = path.split('/').last.split('\\').last;
      n = n.replaceAll(RegExp(r'^ozses_muhur_', caseSensitive: false), '');
      n = n.replaceAll(
          RegExp(r'\.(mp3|m4a|wav|flac|aac|ogg|opus|webm)$', caseSensitive: false), '');
    } else {
      n = 'Bilinmeyen Müzik';
    }
  }
  if (n.toLowerCase() == 'null' || n.trim().isEmpty) {
    n = 'ÖZSES Müzik';
  }
  return n;
}

MediaItem songToMediaItem(SongModel song) {
  final path = song.path ?? 'bilinmeyen_yol';
  final extras = <String, dynamic>{};
  final vid = song.videoId ?? extractVideoIdFromPath(path);
  if (vid != null) extras['videoId'] = vid;

  final rawArtist = song.artist?.trim();
  final safeArtist = (rawArtist != null &&
          rawArtist.isNotEmpty &&
          rawArtist.toLowerCase() != 'null' &&
          rawArtist.toLowerCase() != 'unknown')
      ? rawArtist
      : 'Victus V7';

  final dur = (song.duration != null && song.duration! > 0)
      ? Duration(seconds: song.duration!)
      : null;

  return MediaItem(
    id: path,
    album: 'ÖZSES Arşivi',
    title: safeSongTitle(song),
    artist: safeArtist,
    artUri: artUriForSong(song),
    duration: dur,
    extras: extras.isEmpty ? null : extras,
  );
}

List<MediaItem> songsToMediaItems(List<SongModel> songs) {
  return songs
      .where((s) => isPlayableSongPath(s.path))
      .map(songToMediaItem)
      .toList();
}

class CleanLyricsInfo {
  final String artist;
  final String title;
  final String coreTitle;
  final String fullQuery;
  final bool isRemix;

  const CleanLyricsInfo({
    required this.artist,
    required this.title,
    required this.coreTitle,
    required this.fullQuery,
    required this.isRemix,
  });
}

CleanLyricsInfo extractCleanLyricsInfo(String rawTitle, [String? rawArtist]) {
  final lowerRaw = '${rawTitle.toLowerCase()} ${(rawArtist ?? '').toLowerCase()}';
  final isRemix = lowerRaw.contains('remix') ||
      lowerRaw.contains('club mix') ||
      lowerRaw.contains('speed up') ||
      lowerRaw.contains('sped up') ||
      lowerRaw.contains('slowed') ||
      lowerRaw.contains('drill') ||
      lowerRaw.contains('vip mix') ||
      lowerRaw.contains('mashup');

  String clean = rawTitle
      .replaceAll(RegExp(r'^ozses_muhur_', caseSensitive: false), '')
      .replaceAll(
          RegExp(r'\.(mp3|wav|flac|m4a|aac|ogg|opus)$', caseSensitive: false),
          '')
      // Köşeli parantezli etiketleri temizle: [Official Video], [4K], [HD], vb.
      .replaceAll(RegExp(r'\[.*?\]'), '')
      // Parantez içi video/audio/versiyon etiketlerini temizle (remix hariç, remix'i koru)
      .replaceAll(
          RegExp(
              r'\([^)]*?(?:official|music\s*video|video|audio|klip|clip|lyric|söz|remaster|akustik|live|prod\.|feat|ft\.|4k|hd|hq|visualizer|versiyon|version)[^)]*?\)',
              caseSensitive: false),
          '')
      .replaceAll('"', '')
      .replaceAll("'", '')
      .replaceAll('“', '')
      .replaceAll('”', '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  String extractedArtist = '';
  String extractedTitle = clean;

  if (clean.contains(' - ')) {
    final parts = clean.split(' - ');
    if (parts.length >= 2) {
      extractedArtist = parts[0].trim();
      extractedTitle = parts.sublist(1).join(' - ').trim();
    }
  }

  String finalArtist = '';
  if (rawArtist != null &&
      rawArtist.trim().isNotEmpty &&
      !rawArtist.toLowerCase().contains('victus') &&
      !rawArtist.toLowerCase().contains('bilinmeyen')) {
    finalArtist = rawArtist.trim();
  } else {
    finalArtist = extractedArtist;
  }

  extractedTitle = extractedTitle
      .replaceAll(RegExp(r'\s*-\s*$', caseSensitive: false), '')
      .trim();

  final finalTitle = extractedTitle.isNotEmpty ? extractedTitle : clean;

  // Çekirdek başlık: Remix, mix gibi ekleri ayıklar (Orijinal şarkı eşleştirmesi için)
  String coreTitle = finalTitle
      .replaceAll(
          RegExp(r'\b(remix|club\s*mix|speed\s*up|sped\s*up|slowed|drill|vip\s*mix|mashup)\b',
              caseSensitive: false),
          '')
      .replaceAll(RegExp(r'[\(\[\{\}\]\)]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (coreTitle.isEmpty) coreTitle = finalTitle;

  String fullQuery = finalArtist.isNotEmpty ? '$finalArtist $finalTitle' : finalTitle;

  return CleanLyricsInfo(
    artist: finalArtist,
    title: finalTitle,
    coreTitle: coreTitle,
    fullQuery: fullQuery.replaceAll(RegExp(r'\s+'), ' ').trim(),
    isRemix: isRemix,
  );
}

String cleanLyricsTitle(String title) {
  return extractCleanLyricsInfo(title).fullQuery;
}

String normalizeLyricsText(String text) {
  if (text.isEmpty) return '';
  String t = text.toLowerCase();
  t = t.replaceAll(RegExp(r'[\(\[\{].*?[\)\]\}]'), ' ');
  t = t.replaceAll(RegExp(r'[^a-z0-9ğüşıöç\s]'), ' ');
  return t.replaceAll(RegExp(r'\s+'), ' ').trim();
}

double lyricsTokenSimilarity(String s1, String s2) {
  final t1 = normalizeLyricsText(s1).split(' ').where((w) => w.isNotEmpty).toSet();
  final t2 = normalizeLyricsText(s2).split(' ').where((w) => w.isNotEmpty).toSet();
  if (t1.isEmpty || t2.isEmpty) return 0.0;
  final intersection = t1.intersection(t2);
  final union = t1.union(t2);
  return intersection.length / union.length;
}

class LrcCandidateResult {
  final String lyrics;
  final bool isSynced;
  final double score;
  final String trackName;
  final String artistName;
  final double duration;
  final bool isOriginalFallback;

  const LrcCandidateResult({
    required this.lyrics,
    required this.isSynced,
    required this.score,
    required this.trackName,
    required this.artistName,
    required this.duration,
    this.isOriginalFallback = false,
  });
}

LrcCandidateResult? pickBestLrcCandidate({
  required List<dynamic> dataList,
  required String targetArtist,
  required String targetTitle,
  Duration? targetDuration,
  required bool isTargetRemix,
  bool allowOriginalFallback = true,
}) {
  if (dataList.isEmpty) return null;

  final targetSec = (targetDuration != null && targetDuration.inSeconds > 0)
      ? targetDuration.inSeconds.toDouble()
      : 0.0;
  final normTargetArtist = normalizeLyricsText(targetArtist);
  final normTargetTitle = normalizeLyricsText(targetTitle);

  final targetWords = normTargetTitle.split(' ').where((w) => w.isNotEmpty).toList();
  final targetHasMashup = targetWords.any((w) => w == 'x' || w == 'vs' || w == 'mashup');

  double bestScore = -999.0;
  LrcCandidateResult? bestCandidate;

  for (final rawItem in dataList) {
    if (rawItem is! Map) continue;
    final cArtist = rawItem['artistName']?.toString() ?? '';
    final cTitle = rawItem['trackName']?.toString() ?? rawItem['name']?.toString() ?? '';
    final cDur = (rawItem['duration'] as num?)?.toDouble() ?? 0.0;
    final cSynced = rawItem['syncedLyrics']?.toString();
    final cPlain = rawItem['plainLyrics']?.toString();

    final hasSynced = cSynced != null && cSynced.trim().isNotEmpty;
    final hasPlain = cPlain != null && cPlain.trim().isNotEmpty;
    if (!hasSynced && !hasPlain) continue;

    final lyrics = hasSynced ? cSynced : cPlain!;

    final normCArtist = normalizeLyricsText(cArtist);
    final normCTitle = normalizeLyricsText(cTitle);
    final cWords = normCTitle.split(' ').where((w) => w.isNotEmpty).toList();

    // 1. 🛡️ MASHUP KALKANI:
    // Eğer hedef şarkı bir mashup değilse fakat adayda 'x', 'vs', 'mashup' varsa diskalifiye et!
    // (Örn: 'Lvbel C5 - DACIA' ararken 'DACIA X YATIYA' gibi alakasız şarkı birleşmelerini %100 eler!)
    final cHasMashup = cWords.any((w) => w == 'x' || w == 'vs' || w == 'mashup');
    if (!targetHasMashup && cHasMashup) {
      continue;
    }

    // 2. 🛡️ SANATÇI DOĞRULAMASI:
    double artistScore = 0.0;
    if (normTargetArtist.isNotEmpty) {
      if (normTargetArtist.contains(normCArtist) || normCArtist.contains(normTargetArtist)) {
        artistScore = 1.0;
      } else {
        artistScore = lyricsTokenSimilarity(targetArtist, cArtist);
      }
      if (artistScore < 0.25) {
        // Sanatçı uyuşmuyor -> Diskalifiye!
        continue;
      }
    } else {
      artistScore = 0.5;
    }

    // 3. 🛡️ BAŞLIK BENZERLİĞİ:
    double titleScore = lyricsTokenSimilarity(targetTitle, cTitle);
    if (normTargetTitle.contains(normCTitle) || normCTitle.contains(normTargetTitle)) {
      titleScore = titleScore > 0.85 ? titleScore : 0.85;
    }
    if (titleScore < 0.28) {
      // Başlık tamamen alakasız -> Diskalifiye!
      continue;
    }

    // 4. 🛡️ REMIX / ORİJİNAL DENGESİ:
    final cIsRemix = cTitle.toLowerCase().contains('remix') || cArtist.toLowerCase().contains('remix');
    double remixScore = 0.0;
    bool isOrigFallback = false;

    if (isTargetRemix && cIsRemix) {
      remixScore = 0.25;
    } else if (!isTargetRemix && !cIsRemix) {
      remixScore = 0.20;
    } else if (isTargetRemix && !cIsRemix) {
      if (!allowOriginalFallback) continue;
      remixScore = 0.05;
      isOrigFallback = true; // Remix versiyonu için orijinal şarkı sözleri yedeklendi
    } else {
      remixScore = -0.20;
    }

    // 5. ⏱️ SÜRE DOĞRULAMASI (Zamansız Başlamayı Önleme):
    double durScore = 0.0;
    if (targetSec > 0 && cDur > 0) {
      final diff = (targetSec - cDur).abs();
      if (diff <= 4) {
        durScore = 0.40; // Mükemmel süre eşleşmesi
      } else if (diff <= 12) {
        durScore = 0.25;
      } else if (diff <= 25) {
        durScore = 0.10;
      } else if (diff <= 45) {
        durScore = -0.10;
      } else {
        durScore = -0.40; // Ağır ceza: Kısa edit veya kesilmiş versiyon
      }
    }

    // 6. ⚡ SENKRONİZE SÖZ ÖNCELİĞİ:
    final syncedBonus = hasSynced ? 0.25 : 0.0;

    final totalScore = (artistScore * 0.40) + (titleScore * 0.35) + remixScore + durScore + syncedBonus;

    if (totalScore > bestScore) {
      bestScore = totalScore;
      bestCandidate = LrcCandidateResult(
        lyrics: lyrics,
        isSynced: hasSynced,
        score: totalScore,
        trackName: cTitle,
        artistName: cArtist,
        duration: cDur,
        isOriginalFallback: isOrigFallback,
      );
    }
  }

  // 🎯 KORUMA DUVARI: Asgari kalite eşiğini geçemeyen hiçbir aday gösterilmez
  if (bestScore >= 0.45) {
    return bestCandidate;
  }
  return null;
}

bool canPersistLyrics(String songPath) {
  if (songPath.isEmpty || songPath == 'bilinmeyen_yol') return false;
  if (songPath.startsWith('http') ||
      songPath.startsWith('yt:') ||
      songPath.startsWith('downloading:')) {
    return false;
  }
  return File(songPath).existsSync();
}

const _libraryKeyV2 = 'siber_global_library_v2';
const _libraryKeyV1 = 'siber_global_library';

Future<List<SongModel>> loadGlobalLibrarySongs() async {
  final prefs = await SharedPreferences.getInstance();
  final v2 = prefs.getStringList(_libraryKeyV2) ?? [];
  final songs = <SongModel>[];

  for (final raw in v2) {
    final song = _decodeLibraryEntry(raw);
    if (song != null && isPlayableSongPath(song.path)) {
      songs.add(song);
    }
  }

  if (songs.isEmpty) {
    final v1 = prefs.getStringList(_libraryKeyV1) ?? [];
    for (final path in v1) {
      if (!isPlayableSongPath(path)) continue;
      songs.add(SongModel(
        path: path,
        name: path.split('/').last.split('\\').last,
        title: safeSongTitle(SongModel(path: path, name: path)),
        videoId: extractVideoIdFromPath(path),
      ));
    }
    if (songs.isNotEmpty) {
      await saveGlobalLibrarySongs(songs);
    }
  }

  return songs;
}

Future<void> saveGlobalLibrarySongs(List<SongModel> songs) async {
  final prefs = await SharedPreferences.getInstance();
  final encoded = songs
      .where((s) => isPlayableSongPath(s.path))
      .map(_encodeLibraryEntry)
      .toSet()
      .toList();
  await prefs.setStringList(_libraryKeyV2, encoded);
}

Future<void> addToGlobalLibrary(SongModel song) async {
  if (!isPlayableSongPath(song.path)) return;
  final existing = await loadGlobalLibrarySongs();
  existing.removeWhere((s) => s.path == song.path);
  existing.insert(0, song);
  await saveGlobalLibrarySongs(existing);
}

Future<void> removeFromGlobalLibrary(String songPath) async {
  final existing = await loadGlobalLibrarySongs();
  existing.removeWhere((s) => s.path == songPath);
  await saveGlobalLibrarySongs(existing);
  
  try {
    final file = File(songPath);
    if (file.existsSync()) {
      file.deleteSync();
    }
  } catch (e) {
    print('Dosya silme hatası: $e');
  }
}

SongModel? _decodeLibraryEntry(String raw) {
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final path = map['path']?.toString();
    if (path == null || !isPlayableSongPath(path)) return null;
    return SongModel(
      path: path,
      title: map['title']?.toString(),
      name: map['title']?.toString() ?? map['name']?.toString(),
      videoId: map['videoId']?.toString(),
      artUrl: map['artUrl']?.toString(),
      artist: map['artist']?.toString(),
    );
  } catch (_) {
    if (isPlayableSongPath(raw)) {
      return SongModel(
        path: raw,
        name: raw.split('/').last.split('\\').last,
        videoId: extractVideoIdFromPath(raw),
      );
    }
    return null;
  }
}

String _encodeLibraryEntry(SongModel song) {
  return jsonEncode({
    'path': song.path,
    'title': safeSongTitle(song),
    'artist': song.artist,
    'videoId': song.videoId ?? extractVideoIdFromPath(song.path),
    'artUrl': song.artUrl ?? artUriForSong(song)?.toString(),
  });
}
