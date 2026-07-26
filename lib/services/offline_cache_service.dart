import 'package:universal_io/io.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../core/platform/siber_platform.dart';
import '../services/services.dart'; // OzsesBridge for proxyPort
import '../utils/song_media_utils.dart'; // loadGlobalLibrarySongs, saveGlobalLibrarySongs

class OfflineCacheService {
  static final OfflineCacheService _instance = OfflineCacheService._internal();
  factory OfflineCacheService() => _instance;
  OfflineCacheService._internal();

  final Dio _dio = Dio();
  static const String _cachePrefsKey = 'siber_offline_cache_metadata';

  // Bellekteki liste (Anlık hızlı erişim için)
  List<SongModel> _cachedSongs = [];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_cachePrefsKey) ?? [];
    
    _cachedSongs.clear();
    for (var raw in rawList) {
      try {
        final Map<String, dynamic> data = json.decode(raw);
        final song = SongModel.fromJson(data);
        
        if (kIsWeb) {
          // Web ortamında dosyalar fiziksel olarak tutulmaz (IndexedDB vs kullanılır).
          // Şimdilik sadece belleğe (Archive mode) alıyoruz.
          _cachedSongs.add(song);
        } else {
          if (File(song.path ?? '').existsSync()) {
            if (File(song.path!).lengthSync() > 1024) {
              _cachedSongs.add(song);
            } else {
              try { File(song.path!).deleteSync(); } catch (_) {}
            }
          }
        }
      } catch (e) {
        print('OfflineCacheService init error: $e');
      }
    }
  }

  List<SongModel> get cachedSongs => _cachedSongs;

  Future<String> get _cacheDirPath async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/siber_offline_cache';
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }

  Future<void> _saveMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = _cachedSongs.map((s) => json.encode(s.toJson())).toList();
    await prefs.setStringList(_cachePrefsKey, rawList);
  }

  bool isCached(String videoId) {
    return _cachedSongs.any((s) => s.videoId == videoId);
  }

  Future<void> downloadStream(String videoId, String title, String artist, {Function(int, int)? onProgress}) async {
    if (isCached(videoId)) return;

    try {
      var res = await SiberPlatform.instance.getStreamUrl(videoId);
      if (res['status'] != 'basarili' || res['stream_url'] == null) {
        throw Exception("Stream URL bulunamadı");
      }
      
      String streamUrl = res['stream_url'];
      final cacheDir = await _cacheDirPath;
      String filePath = '$cacheDir/$videoId.m4a';
      
      if (kIsWeb) {
        // Web'de dosyaya yazmak yerine stream_url'i doğrudan kullanacağız
        filePath = streamUrl; 
      } else {
        if (res['is_file'] == true) {
          File(streamUrl).copySync(filePath);
        } else {
          if (streamUrl == 'proxy_will_handle_it') {
            streamUrl = 'http://127.0.0.1:${OzsesBridge.proxyPort}/$videoId';
          }
          await _dio.download(
            streamUrl,
            filePath,
            onReceiveProgress: (received, total) {
              if (total != -1 && onProgress != null) {
                onProgress(received, total);
              }
            },
          );
  
          final downloadedFile = File(filePath);
          if (await downloadedFile.exists() && await downloadedFile.length() < 100000) {
             await downloadedFile.delete();
             throw Exception('İndirilen dosya çok küçük veya bozuk.');
          }
        }
      }

      // İndirme başarılı, listeye ekle
      final newSong = SongModel(
        name: title,
        path: filePath,
        duration: 0,
        title: title,
        artist: artist,
        videoId: videoId,
      );
      
      _cachedSongs.insert(0, newSong);
      await _saveMetadata();
      
    } catch (e) {
      print('Offline Cache Download Error: $e');
      rethrow;
    }
  }

  Future<void> removeCachedSong(String videoId) async {
    final index = _cachedSongs.indexWhere((s) => s.videoId == videoId);
    if (index != -1) {
      final song = _cachedSongs[index];
      if (!kIsWeb) {
        try {
          final file = File(song.path ?? '');
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {}
      }
      _cachedSongs.removeAt(index);
      await _saveMetadata();
    }
  }

  // 🎯 SİBER HAMLE: Kütüphaneye (Arşive) Aktar!
  Future<void> exportToArchive(String videoId) async {
    final song = _cachedSongs.firstWhere((s) => s.videoId == videoId, orElse: () => SongModel(path: '', name: ''));
    if (song.path == null || song.path!.isEmpty) return;

    final globalSongs = await loadGlobalLibrarySongs();
    
    // Zaten ekli mi kontrolü
    if (!globalSongs.any((s) => s.path == song.path)) {
      globalSongs.add(song);
      await saveGlobalLibrarySongs(globalSongs);
    }
  }
}
