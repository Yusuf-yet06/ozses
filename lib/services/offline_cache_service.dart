import 'package:universal_io/io.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
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

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 10),
    sendTimeout: const Duration(seconds: 30),
  ));
  static const String _cachePrefsKey = 'siber_offline_cache_metadata';

  // Bellekteki liste (Anlık hızlı erişim için)
  List<SongModel> _cachedSongs = [];
  
  // Aktif indirmeleri UI tarafında göstermek için (videoId -> progress)
  final ValueNotifier<Map<String, double>> downloadProgress = ValueNotifier({});

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
    if (isCached(videoId) || downloadProgress.value.containsKey(videoId)) return;

    downloadProgress.value = {...downloadProgress.value, videoId: 0.0};

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
          // Android'de proxy_will_handle_it çalışmaz, YoutubeExplode ile gerçek URL al
          if (streamUrl == 'proxy_will_handle_it') {
            try {
              print('🔄 SİBER İNDİRME: YoutubeExplode ile URL alınıyor... videoId=$videoId');
              var yt = YoutubeExplode();
              var ytClients = [YoutubeApiClient.androidVr, YoutubeApiClient.androidSdkless, YoutubeApiClient.android, YoutubeApiClient.tv];
              var manifest = await yt.videos.streamsClient.getManifest(videoId, ytClients: ytClients).timeout(const Duration(seconds: 20));
              var audioStreamList = manifest.audioOnly.where((s) => s.container.name == 'mp4' || s.audioCodec.contains('mp4a')).toList();
              if (audioStreamList.isEmpty) {
                // mp4a yoksa tüm audio'dan en yüksek bitrate'i al
                audioStreamList = manifest.audioOnly.toList();
              }
              var ytStreamInfo = audioStreamList.isNotEmpty 
                  ? audioStreamList.reduce((a, b) => a.bitrate.bitsPerSecond > b.bitrate.bitsPerSecond ? a : b) 
                  : manifest.audioOnly.withHighestBitrate();
                  
              print('✅ SİBER İNDİRME: URL alındı, boyut=${ytStreamInfo.size}, codec=${ytStreamInfo.audioCodec}');
              
              // YoutubeExplode'un kendi stream'ini kullanarak indir (Dio yerine)
              print('📥 SİBER İNDİRME: YoutubeExplode stream ile indiriliyor... -> $filePath');
              var stream = yt.videos.streamsClient.get(ytStreamInfo);
              var file = File(filePath);
              var fileStream = file.openWrite();
              
              int totalBytes = ytStreamInfo.size.totalBytes;
              int receivedBytes = 0;
              
              await for (var data in stream) {
                receivedBytes += data.length;
                fileStream.add(data);
                
                final progress = totalBytes > 0 ? (receivedBytes / totalBytes) : 0.0;
                downloadProgress.value = {...downloadProgress.value, videoId: progress};

                if (onProgress != null) {
                  onProgress(receivedBytes, totalBytes);
                }
              }
              
              await fileStream.flush();
              await fileStream.close();
              yt.close();
              
              if (receivedBytes > 0 && totalBytes > 0 && receivedBytes < totalBytes) {
                throw Exception('İndirme yarım kaldı (Bağlantı koptu). Eksik veri: $receivedBytes / $totalBytes');
              }
              
              

            } catch (e) {
              print('⚠️ SİBER İNDİRME: YoutubeExplode Hata, Vercel deneniyor...: $e');
              
              var file = File(filePath);
              if (await file.exists()) {
                await file.delete();
              }
              
              try {
                final vercelRes = await http.get(
                  Uri.parse('https://ozses-832f9y4py-ozses.vercel.app/stream?id=$videoId'),
                ).timeout(const Duration(seconds: 20));
                
                if (vercelRes.statusCode == 200) {
                  final data = jsonDecode(vercelRes.body);
                  if (data['stream_url'] != null) {
                    streamUrl = data['stream_url'].toString();
                    print('✅ SİBER İNDİRME: Vercel URL alındı: $streamUrl');
                    Dio dio = Dio();
                    await dio.download(
                      streamUrl,
                      filePath,
                      onReceiveProgress: (received, total) {
                        if (total != -1 && onProgress != null) {
                          onProgress(received, total);
                        }
                      },
                    );
                  } else {
                    throw Exception("Vercel stream_url bulunamadı");
                  }
                } else {
                  throw Exception("Vercel API hatası: ${vercelRes.statusCode}");
                }
              } catch (vercelEx) {
                print('❌ SİBER İNDİRME Vercel de Başarısız: $vercelEx');
                throw Exception('YoutubeExplode ve Vercel indirme hatası: $e | $vercelEx');
              }
            }
          } else {
            print('📥 SİBER İNDİRME: Dio ile indiriliyor... -> $filePath');
            await _dio.download(
              streamUrl,
              filePath,
              onReceiveProgress: (received, total) {
                if (total != -1 && onProgress != null) {
                  onProgress(received, total);
                }
              },
            );
          }
  
          final downloadedFile = File(filePath);
          final fileSize = await downloadedFile.exists() ? await downloadedFile.length() : 0;
          print('✅ SİBER İNDİRME: Dosya indirildi! Boyut=$fileSize bytes');
          
          // Boyut kontrolü (beklenen boyuttan çok mu küçük veya hiç yok mu)
          if (fileSize < 100000) {
             if (await downloadedFile.exists()) await downloadedFile.delete();
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
      
      // 🎯 SİBER HAMLE: İndirilen şarkıyı otomatik olarak global kütüphaneye de ekle
      await addToGlobalLibrary(newSong);
      
    } catch (e) {
      print('Offline Cache Download Error: $e');
      rethrow;
    } finally {
      final updated = Map<String, double>.from(downloadProgress.value);
      updated.remove(videoId);
      downloadProgress.value = updated;
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
