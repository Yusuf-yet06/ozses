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

  return match?.group(1);
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
  if (song.artUrl != null && song.artUrl!.isNotEmpty) {
    return safeParseUri(song.artUrl);
  }
  final vid = song.videoId ?? extractVideoIdFromPath(song.path);
  if (vid != null && vid.isNotEmpty) {
    return Uri.parse('https://i.ytimg.com/vi/$vid/hqdefault.jpg');
  }
  return null;
}

Uri? artUriForMediaId(String id, {String? videoId, Uri? existing}) {
  if (existing != null) return existing;
  final vid = videoId ?? extractVideoIdFromPath(id);
  if (vid != null && vid.isNotEmpty) {
    return Uri.parse('https://i.ytimg.com/vi/$vid/hqdefault.jpg');
  }
  return null;
}

String safeSongTitle(SongModel song) {
  String n = song.title?.trim().isNotEmpty == true
      ? song.title!.trim()
      : (song.name ?? '').trim();
  if (n.isEmpty || n == 'Bilinmeyen Müzik') {
    final path = song.path ?? '';
    if (path.isNotEmpty && path != 'bilinmeyen_yol') {
      n = path.split('/').last.split('\\').last;
      n = n.replaceAll(RegExp(r'^ozses_muhur_', caseSensitive: false), '');
      n = n.replaceAll(
          RegExp(r'\.(mp3|m4a|wav|flac|aac|ogg)$', caseSensitive: false), '');
    } else {
      n = 'Bilinmeyen Müzik';
    }
  }
  return n;
}

MediaItem songToMediaItem(SongModel song) {
  final path = song.path ?? 'bilinmeyen_yol';
  final extras = <String, dynamic>{};
  final vid = song.videoId ?? extractVideoIdFromPath(path);
  if (vid != null) extras['videoId'] = vid;

  return MediaItem(
    id: path,
    album: 'ÖZSES Arşivi',
    title: safeSongTitle(song),
    artist: song.artist?.trim().isNotEmpty == true ? song.artist! : 'Victus V7',
    artUri: artUriForSong(song),
    extras: extras.isEmpty ? null : extras,
  );
}

List<MediaItem> songsToMediaItems(List<SongModel> songs) {
  return songs
      .where((s) => isPlayableSongPath(s.path))
      .map(songToMediaItem)
      .toList();
}

String cleanLyricsTitle(String title) {
  return title
      .replaceAll(RegExp(r'^ozses_muhur_', caseSensitive: false), '')
      .replaceAll(
          RegExp(r'\.(mp3|wav|flac|m4a|aac|ogg|opus)$', caseSensitive: false),
          '')
      .trim();
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
    'videoId': song.videoId ?? extractVideoIdFromPath(song.path),
    'artUrl': song.artUrl ?? artUriForSong(song)?.toString(),
  });
}
