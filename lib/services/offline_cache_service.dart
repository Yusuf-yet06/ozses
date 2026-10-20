import 'package:universal_io/io.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../core/platform/siber_platform.dart';
import '../services/ytdlp_service.dart';
import '../utils/song_media_utils.dart';

class OfflineCacheService {
  static final OfflineCacheService _instance = OfflineCacheService._internal();
  factory OfflineCacheService() => _instance;
  OfflineCacheService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(minutes: 3),
    sendTimeout: const Duration(seconds: 20),
  ));
  static const String _cachePrefsKey = 'siber_offline_cache_metadata';

  List<SongModel> _cachedSongs = [];
  final ValueNotifier<Map<String, double>> downloadProgress = ValueNotifier({});
  final ValueNotifier<Map<String, String>> downloadTitles = ValueNotifier({});
  final ValueNotifier<int> cacheChangeNotifier = ValueNotifier(0);
  final StreamController<String> _downloadCompletedController = StreamController<String>.broadcast();
  Stream<String> get onDownloadCompleted => _downloadCompletedController.stream;

  // IPTAL MEKANIZMASI
  final Map<String, CancelToken> _activeCancelTokens = {};
  final Map<String, Process> _activeProcesses = {};
  final Map<String, http.Client> _activeHttpClients = {};
  final Map<String, bool> _cancelFlags = {};

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_cachePrefsKey) ?? [];
    _cachedSongs.clear();
    for (var raw in rawList) {
      try {
        final Map<String, dynamic> data = json.decode(raw);
        final song = SongModel.fromJson(data);
        if (kIsWeb) {
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

  static Future<String> getCacheDirPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/siber_offline_cache';
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }

  Future<String> get _cacheDirPath async => getCacheDirPath();

  Future<void> _saveMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = _cachedSongs.map((s) => json.encode(s.toJson())).toList();
    await prefs.setStringList(_cachePrefsKey, rawList);
  }

  bool isCached(String videoId) {
    return _cachedSongs.any((s) => s.videoId == videoId);
  }

  // INDIRME IPTAL ET
  Future<void> cancelDownload(String videoId) async {
    print('SiberIptal: $videoId indirmesi durduruluyor...');
    _cancelFlags[videoId] = true;
    final cancelToken = _activeCancelTokens[videoId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('Kullanici tarafindan iptal edildi');
    }
    final client = _activeHttpClients[videoId];
    if (client != null) {
      try { client.close(); } catch (_) {}
    }
    final process = _activeProcesses[videoId];
    if (process != null) {
      try { process.kill(); } catch (_) {}
    }
    final updatedProgress = Map<String, double>.from(downloadProgress.value);
    updatedProgress.remove(videoId);
    downloadProgress.value = updatedProgress;
    final updatedTitles = Map<String, String>.from(downloadTitles.value);
    updatedTitles.remove(videoId);
    downloadTitles.value = updatedTitles;
    try {
      final cacheDir = await _cacheDirPath;
      final partialFile = File('$cacheDir/$videoId.m4a');
      if (await partialFile.exists()) await partialFile.delete();
    } catch (_) {}
    _activeCancelTokens.remove(videoId);
    _activeProcesses.remove(videoId);
    _activeHttpClients.remove(videoId);
    _cancelFlags.remove(videoId);
  }

  // 🛡️ SİBER KOPMAYA KARŞI KALKAN: Range Destekli Kaldığı Yerden Devam Eden Akış İndirici
  Future<bool> _downloadUrlWithResume({
    required String url,
    required File targetFile,
    required String videoId,
    Function(int received, int total)? onProgress,
    int maxRetries = 5,
  }) async {
    int retryCount = 0;
    int totalBytes = 0;

    while (retryCount < maxRetries) {
      if (_cancelFlags[videoId] == true) {
        throw Exception('Iptal');
      }

      int existingBytes = 0;
      if (await targetFile.exists()) {
        existingBytes = await targetFile.length();
      }

      final client = http.Client();
      _activeHttpClients[videoId] = client;

      try {
        final request = http.Request('GET', Uri.parse(url));

        final isVisionOS = url.contains('VISIONOS') || url.contains('c=VISIONOS');
        if (isVisionOS) {
          request.headers['User-Agent'] =
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15';
        } else {
          request.headers['User-Agent'] =
              'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';
        }
        request.headers['Accept'] = '*/*';
        request.headers['Referer'] = 'https://www.youtube.com/';
        request.headers['Accept-Encoding'] = 'identity';

        if (existingBytes > 0) {
          request.headers['Range'] = 'bytes=$existingBytes-';
        }

        final response = await client.send(request).timeout(const Duration(seconds: 25));

        // 416 Range Not Satisfiable: means requested range is beyond end of file (already finished!)
        if (response.statusCode == 416 && existingBytes > 20000) {
          client.close();
          _activeHttpClients.remove(videoId);
          return true;
        }

        // 403 or 410: Stream URL expired or signature rejected
        if (response.statusCode == 403 || response.statusCode == 410) {
          client.close();
          _activeHttpClients.remove(videoId);
          print('⚠️ Stream URL yetkisi reddedildi (HTTP ${response.statusCode})');
          return false;
        }

        if (response.statusCode != 200 && response.statusCode != 206) {
          client.close();
          _activeHttpClients.remove(videoId);
          print('⚠️ HTTP Hata: ${response.statusCode}');
          retryCount++;
          await Future.delayed(const Duration(milliseconds: 1200));
          continue;
        }

        final isAppend = response.statusCode == 206 && existingBytes > 0;
        if (!isAppend && existingBytes > 0) {
          existingBytes = 0;
        }

        if (totalBytes == 0 || !isAppend) {
          totalBytes = (response.contentLength ?? 0) + existingBytes;
        }

        final sink = targetFile.openWrite(mode: isAppend ? FileMode.append : FileMode.write);
        int receivedBytes = existingBytes;

        try {
          await for (final chunk in response.stream) {
            if (_cancelFlags[videoId] == true) {
              await sink.flush();
              await sink.close();
              client.close();
              _activeHttpClients.remove(videoId);
              throw Exception('Iptal');
            }

            sink.add(chunk);
            receivedBytes += chunk.length;

            if (totalBytes > 0) {
              final progress = (receivedBytes / totalBytes).clamp(0.01, 1.0);
              downloadProgress.value = {...downloadProgress.value, videoId: progress};
              if (onProgress != null) onProgress(receivedBytes, totalBytes);
            }
          }

          await sink.flush();
          await sink.close();
          client.close();
          _activeHttpClients.remove(videoId);

          final finalLength = await targetFile.length();
          if (finalLength > 20000 &&
              (totalBytes == 0 || finalLength >= totalBytes || (totalBytes - finalLength).abs() < 4096)) {
            return true;
          } else {
            print('⚠️ Bağlantı kapandı ($finalLength / $totalBytes bayt indi). Kaldığı yerden devam ediliyor...');
            retryCount++;
            await Future.delayed(const Duration(milliseconds: 1000));
          }
        } catch (streamErr) {
          try {
            await sink.flush();
            await sink.close();
          } catch (_) {}
          client.close();
          _activeHttpClients.remove(videoId);
          if (_cancelFlags[videoId] == true || streamErr.toString().contains('Iptal')) {
            throw Exception('Iptal');
          }
          print('⚠️ Stream kesildi ($streamErr), kaldığı yerden devam edilecek...');
          retryCount++;
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      } catch (reqErr) {
        client.close();
        _activeHttpClients.remove(videoId);
        if (_cancelFlags[videoId] == true || reqErr.toString().contains('Iptal')) {
          throw Exception('Iptal');
        }
        print('⚠️ İstek hatası: $reqErr, tekrar deneniyor...');
        retryCount++;
        await Future.delayed(const Duration(milliseconds: 1200));
      }
    }

    final finalCheck = await targetFile.exists() ? await targetFile.length() : 0;
    return finalCheck > 30000;
  }

  Future<void> downloadStream(
    String videoId,
    String title,
    String artist, {
    Function(int received, int total)? onProgress,
  }) async {
    if (videoId.isEmpty) return;
    if (isCached(videoId)) { return; }
    if (downloadProgress.value.containsKey(videoId)) { return; }

    downloadProgress.value = {...downloadProgress.value, videoId: 0.01};
    downloadTitles.value = {...downloadTitles.value, videoId: title};
    _cancelFlags[videoId] = false;

    final cacheDir = await _cacheDirPath;
    final filePath = '$cacheDir/$videoId.m4a';
    final targetFile = File(filePath);
    bool downloadSuccess = false;

    try {
      // 1. STRATEJI: Windows yt-dlp (Masaüstünde en hızlı ve stabil)
      if (!kIsWeb && Platform.isWindows) {
        try {
          final exePath = await YtDlpService().getExecutablePath();
          if (File(exePath).existsSync()) {
            final process = await Process.start(exePath, [
              '-f', 'ba[ext=m4a]/ba/b',
              '--no-playlist',
              '-N', '4',
              '--newline',
              '--no-warnings',
              '--no-check-certificate',
              '-o', filePath,
              'https://www.youtube.com/watch?v=$videoId',
            ]);
            _activeProcesses[videoId] = process;
            final percentRegex = RegExp(r'\[download\]\s+([\d\.]+)%');
            process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
              if (_cancelFlags[videoId] == true) return;
              final match = percentRegex.firstMatch(line);
              if (match != null) {
                final pctVal = double.tryParse(match.group(1) ?? '0') ?? 0.0;
                final pf = (pctVal / 100.0).clamp(0.01, 1.0);
                downloadProgress.value = {...downloadProgress.value, videoId: pf};
                if (onProgress != null) onProgress((pf * 1000).toInt(), 1000);
              }
            });
            final exitCode = await process.exitCode.timeout(const Duration(seconds: 90));
            _activeProcesses.remove(videoId);
            if (_cancelFlags[videoId] == true) throw Exception('Iptal');
            if (exitCode == 0 && await targetFile.exists() && await targetFile.length() > 20000) {
              downloadSuccess = true;
            }
          }
        } catch (ytDlpEx) {
          _activeProcesses.remove(videoId);
          if (_cancelFlags[videoId] == true) throw Exception('Iptal');
        }
      }

      // 2. STRATEJI (MOBİLDE EN HIZLI): SiberPlatform (VisionOS Yerel Çözücü - 1-2 Saniye) + Range Resume
      if (!downloadSuccess && !kIsWeb) {
        if (_cancelFlags[videoId] == true) throw Exception('Iptal');
        try {
          print('📱 SiberPlatform (VisionOS) Akışı Alınıyor: $videoId');
          final res = await SiberPlatform.instance.getStreamUrl(videoId);
          if (res['status'] == 'basarili' && res['stream_url'] != null) {
            final streamUrl = res['stream_url'].toString();
            if (streamUrl.startsWith('http')) {
              downloadSuccess = await _downloadUrlWithResume(
                url: streamUrl,
                targetFile: targetFile,
                videoId: videoId,
                onProgress: onProgress,
              );
            }
          }
        } catch (e) {
          if (_cancelFlags[videoId] == true) throw Exception('Iptal');
          print('⚠️ SiberPlatform Stream İndirme Hatası: $e');
        }
      }

      // 3. STRATEJI: VPS Karargah Stream Check (167.172.190.129)
      if (!downloadSuccess && !kIsWeb) {
        if (_cancelFlags[videoId] == true) throw Exception('Iptal');
        try {
          print('📡 VPS Karargah Akış Deneniyor: $videoId');
          final encodedId = Uri.encodeComponent(videoId);
          final vpsRes = await http.get(
            Uri.parse('http://167.172.190.129:8080/api/stream_check/$encodedId?apikey=siber_secret_key_v7'),
          ).timeout(const Duration(seconds: 15));
          if (vpsRes.statusCode == 200) {
            final data = jsonDecode(vpsRes.body);
            if (data['status'] == 'ok' && data['url'] != null) {
              final vpsStreamUrl = data['url'].toString();
              if (vpsStreamUrl.startsWith('http')) {
                downloadSuccess = await _downloadUrlWithResume(
                  url: vpsStreamUrl,
                  targetFile: targetFile,
                  videoId: videoId,
                  onProgress: onProgress,
                );
              }
            }
          }
        } catch (e) {
          if (_cancelFlags[videoId] == true) throw Exception('Iptal');
          print('⚠️ VPS Stream İndirme Hatası: $e');
        }
      }

      // 4. STRATEJI: Vercel Backend
      if (!downloadSuccess && !kIsWeb) {
        if (_cancelFlags[videoId] == true) throw Exception('Iptal');
        try {
          print('🚀 Vercel Backend Akış Deneniyor: $videoId');
          final vercelRes = await http.get(
            Uri.parse('https://ozses-api.vercel.app/api/stream?id=$videoId'),
          ).timeout(const Duration(seconds: 10));
          if (vercelRes.statusCode == 200) {
            final data = jsonDecode(vercelRes.body);
            if (data['stream_url'] != null) {
              final vercelUrl = data['stream_url'].toString();
              if (vercelUrl.startsWith('http')) {
                downloadSuccess = await _downloadUrlWithResume(
                  url: vercelUrl,
                  targetFile: targetFile,
                  videoId: videoId,
                  onProgress: onProgress,
                );
              }
            }
          }
        } catch (e) {
          if (_cancelFlags[videoId] == true) throw Exception('Iptal');
          print('⚠️ Vercel İndirme Hatası: $e');
        }
      }

      // 5. STRATEJI: Piped API
      if (!downloadSuccess && !kIsWeb) {
        if (_cancelFlags[videoId] == true) throw Exception('Iptal');
        const pipedInstances = [
          'https://pipedapi.kavin.rocks',
          'https://api.piped.yt',
          'https://piped-api.codeberg.org',
          'https://pipedapi.moomoo.me',
        ];
        String? pipedAudioUrl;
        for (final baseUrl in pipedInstances) {
          if (_cancelFlags[videoId] == true) break;
          try {
            final res = await http.get(
              Uri.parse('$baseUrl/streams/$videoId'),
              headers: {'Accept': 'application/json'},
            ).timeout(const Duration(seconds: 8));
            if (res.statusCode == 200) {
              final data = jsonDecode(res.body);
              final audioStreams = data['audioStreams'] as List<dynamic>?;
              if (audioStreams != null && audioStreams.isNotEmpty) {
                final m4aStreams = audioStreams.where((s) {
                  final mime = s['mimeType']?.toString() ?? '';
                  return mime.contains('mp4') || mime.contains('m4a') || mime.contains('mp4a');
                }).toList();
                final bestList = m4aStreams.isNotEmpty ? m4aStreams : audioStreams;
                bestList.sort((a, b) => (b['bitrate'] as int? ?? 0).compareTo(a['bitrate'] as int? ?? 0));
                final urlRaw = bestList.first['url']?.toString() ?? '';
                if (urlRaw.startsWith('http')) {
                  pipedAudioUrl = urlRaw;
                  break;
                }
              }
            }
          } catch (_) { continue; }
        }
        if (pipedAudioUrl != null && _cancelFlags[videoId] != true) {
          downloadSuccess = await _downloadUrlWithResume(
            url: pipedAudioUrl,
            targetFile: targetFile,
            videoId: videoId,
            onProgress: onProgress,
          );
        }
      }

      // 6. STRATEJI: YoutubeExplode (Doğrudan Akış Çekici)
      if (!downloadSuccess) {
        if (_cancelFlags[videoId] == true) throw Exception('Iptal');
        final yt = YoutubeExplode();
        try {
          final ytClients = [
            YoutubeApiClient.androidVr,
            YoutubeApiClient.ios,
            YoutubeApiClient.androidSdkless,
            YoutubeApiClient.safari,
            YoutubeApiClient.android
          ];
          final manifest = await yt.videos.streamsClient.getManifest(videoId, ytClients: ytClients).timeout(const Duration(seconds: 15));
          List<StreamInfo> audioStreams = manifest.audioOnly.where((s) => s.container.name == 'mp4' || s.audioCodec.contains('mp4a')).toList();
          if (audioStreams.isEmpty) audioStreams = manifest.audioOnly.toList();
          if (audioStreams.isEmpty) audioStreams = manifest.muxed.toList();
          if (audioStreams.isNotEmpty) {
            final ytStreamInfo = audioStreams.reduce((a, b) => a.bitrate.bitsPerSecond > b.bitrate.bitsPerSecond ? a : b);
            final stream = yt.videos.streamsClient.get(ytStreamInfo);
            final fileSink = targetFile.openWrite();
            final totalBytes = ytStreamInfo.size.totalBytes;
            int receivedBytes = 0;
            int lastProgressBytes = 0;
            DateTime lastProgressTime = DateTime.now();
            await for (final chunk in stream) {
              if (_cancelFlags[videoId] == true) {
                await fileSink.close();
                throw Exception('Iptal');
              }
              receivedBytes += chunk.length;
              fileSink.add(chunk);
              final progress = totalBytes > 0 ? (receivedBytes / totalBytes) : 0.0;
              downloadProgress.value = {...downloadProgress.value, videoId: progress.clamp(0.01, 1.0)};
              if (onProgress != null) onProgress(receivedBytes, totalBytes);
              if (receivedBytes - lastProgressBytes > 51200) {
                lastProgressBytes = receivedBytes;
                lastProgressTime = DateTime.now();
              } else if (DateTime.now().difference(lastProgressTime).inSeconds > 30) {
                await fileSink.close();
                throw Exception('Stall');
              }
            }
            await fileSink.flush();
            await fileSink.close();
            if (_cancelFlags[videoId] == true) throw Exception('Iptal');
            if (await targetFile.exists() && await targetFile.length() > 20000) {
              downloadSuccess = true;
            }
          }
        } catch (ytEx) {
          if (_cancelFlags[videoId] == true) { yt.close(); throw Exception('Iptal'); }
        } finally {
          yt.close();
        }
      }

      if (!downloadSuccess || !await targetFile.exists() || await targetFile.length() < 20000) {
        if (await targetFile.exists()) { try { await targetFile.delete(); } catch (_) {} }
        throw Exception('Dosya indirilemedi veya boyutu cok kucuk.');
      }

      // 🎯 SİBER ÇEVRİMDISI KORUMASI: Kapak fotoğrafını da yerel diske mühürle (0 kota & çevrimdışı garantisi)
      final coverFile = File('$cacheDir/$videoId.jpg');
      try {
        final imgRes = await http.get(Uri.parse('https://i.ytimg.com/vi/$videoId/hqdefault.jpg')).timeout(const Duration(seconds: 5));
        if (imgRes.statusCode == 200) {
          await coverFile.writeAsBytes(imgRes.bodyBytes);
        }
      } catch (_) {}

      final newSong = SongModel(
        name: title, path: filePath, duration: 0, title: title,
        artist: artist, videoId: videoId, artUrl: 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg',
      );
      _cachedSongs.removeWhere((s) => s.videoId == videoId || s.path == filePath);
      _cachedSongs.insert(0, newSong);
      await _saveMetadata();
      await addToGlobalLibrary(newSong);
      cacheChangeNotifier.value++;
      _downloadCompletedController.add(videoId);

    } catch (e) {
      if (!e.toString().contains('Iptal')) {
        print('Offline Cache Download Error: $e');
        rethrow;
      }
    } finally {
      _cancelFlags.remove(videoId);
      _activeCancelTokens.remove(videoId);
      _activeProcesses.remove(videoId);
      _activeHttpClients.remove(videoId);
      final updated = Map<String, double>.from(downloadProgress.value);
      updated.remove(videoId);
      downloadProgress.value = updated;
      final updatedTitles = Map<String, String>.from(downloadTitles.value);
      updatedTitles.remove(videoId);
      downloadTitles.value = updatedTitles;
    }
  }

  Future<void> removeCachedSong(String videoId) async {
    final index = _cachedSongs.indexWhere((s) => s.videoId == videoId);
    if (index != -1) {
      final song = _cachedSongs[index];
      if (!kIsWeb) {
        try {
          final file = File(song.path ?? '');
          if (await file.exists()) { await file.delete(); }
          final cacheDir = await _cacheDirPath;
          final thumb = File('$cacheDir/$videoId.jpg');
          if (await thumb.exists()) { await thumb.delete(); }
        } catch (e) {}
      }
      _cachedSongs.removeAt(index);
      await _saveMetadata();
      cacheChangeNotifier.value++;
    }
  }

  Future<void> exportToArchive(String videoId) async {
    final song = _cachedSongs.firstWhere((s) => s.videoId == videoId, orElse: () => SongModel(path: '', name: ''));
    if (song.path == null || song.path!.isEmpty) return;
    final globalSongs = await loadGlobalLibrarySongs();
    if (!globalSongs.any((s) => s.path == song.path)) {
      globalSongs.add(song);
      await saveGlobalLibrarySongs(globalSongs);
      cacheChangeNotifier.value++;
    }
  }
}
