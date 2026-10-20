import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'siber_platform.dart';
import '../../services/ytdlp_service.dart';

class _WindowsStreamCacheEntry {
  final Map<String, dynamic> data;
  final DateTime expiresAt;
  _WindowsStreamCacheEntry(this.data, this.expiresAt);
  bool get isValid => DateTime.now().isBefore(expiresAt);
}

class WindowsPlatform implements SiberPlatform {
  @override
  bool get supportsHardwareDSP => false;

  @override
  void preWarm(String videoId) {}

  final YoutubeExplode _yt = YoutubeExplode();
  final _AsyncMutex _ytMutex = _AsyncMutex();

  // ⚡ SİBER JET RAM ÖNBELLEĞİ: Çözülen akış URL'lerini bellekte tutar (0 ms yanıt)
  static final Map<String, _WindowsStreamCacheEntry> _streamCache = {};

  @override
  Future<Map<String, dynamic>> fetchKesfet({String? pageToken}) async {
    print('--- ÖZSES KEŞFET RADARI BAŞLATILIYOR (Masaüstü) ---');
    try {
      final List<String> popQueries = [
        'en çok dinlenen popüler türkçe şarkılar',
        'yeni çıkan hit şarkılar',
        'trend türkçe pop şarkılar',
        'popüler rap şarkıları türkçe',
        'viral şarkılar türkiye',
        'trend arabesk remix',
        'akustik hit parçalar',
        'spotify top 50 türkiye'
      ];
      popQueries.shuffle();
      String query = popQueries.first;
      var searchResults = await _yt.search.search(query).timeout(const Duration(seconds: 15));
      var items = [];
      for (var video in searchResults.take(15)) {
        items.add({
          'id': video.id.value,
          'title': video.title,
          'channel': video.author,
          'thumbnail': video.thumbnails.highResUrl,
        });
      }
      if (items.isNotEmpty) {
        return {'status': 'basarili', 'oneriler': items, 'nextPageToken': ''};
      }
      return {'status': 'hata', 'oneriler': [], 'nextPageToken': ''};
    } catch (e) {
      print('🚀 Siber Yerel Keşfet Hatası (Masaüstü): $e');
      print('🔄 SİBER KALKAN: Piped Keşfet Fallback Devrede...');
      final List<String> pipedInstances = [
                'https://pipedapi.kavin.rocks',
        'https://api.piped.projectsegfau.lt',
        'https://pipedapi.smnz.de'
      ];
      for (var instance in pipedInstances) {
        try {
          final res = await http.get(Uri.parse('$instance/search?q=popüler+türkçe+şarkılar&filter=all')).timeout(const Duration(seconds: 10));
          if (res.statusCode == 200) {
             try {
               final data = jsonDecode(res.body);
               var items = [];
             for (var item in data['items']) {
               if (item['type'] == 'stream') {
                 items.add({
                    'id': item['url'].replaceAll('/watch?v=', ''),
                    'title': item['title'],
                    'channel': item['uploaderName'],
                    'thumbnail': item['thumbnail']
                 });
                 if (items.length >= 15) break;
               }
             }
             if (items.isNotEmpty) {
               return {'status': 'basarili', 'oneriler': items, 'nextPageToken': ''};
             }
             } catch (decodeEx) { print('JSON Parse error'); }
          }
        } catch (ex) {
          print('⚠️ Piped Keşfet Hatası ($instance): $ex');
        }
      }
    }
    return {'status': 'hata', 'oneriler': [], 'nextPageToken': ''};
  }

  @override
  Future<List<dynamic>> searchMusic(String query, {int limit = 15, int page = 1, bool onlyMusic = true}) async {
    print('--- SİBER ARAMA BAŞLATILIYOR (Masaüstü) ---');
    try {
      return await _ytMutex.run(() async {
        var searchResults = await _yt.search.search(query).timeout(const Duration(seconds: 15));
        var items = [];
        for (var video in searchResults.take(limit)) {
          items.add({
            'id': video.id.value,
            'title': video.title,
            'channel': video.author,
            'thumbnail': video.thumbnails.highResUrl,
          });
        }
        return items;
      });
    } catch (e) {
      print('Siber Arama Hatası: $e');
      print('🔄 SİBER KALKAN: Piped Arama Fallback Devrede (Masaüstü)...');
      final List<String> pipedInstances = [
                'https://pipedapi.kavin.rocks',
        'https://pipedapi.smnz.de',
        'https://pipedapi.adminforge.de',
        'https://api.piped.projectsegfau.lt'
      ];
      
      for (var instance in pipedInstances) {
        try {
          print('🎯 Deneniyor: $instance');
          final res = await http.get(Uri.parse('$instance/search?q=${Uri.encodeComponent(query)}&filter=all')).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200) {
             try {
               final data = jsonDecode(res.body);
               var items = [];
             for (var item in data['items']) {
               if (item['type'] == 'stream') {
                 items.add({
                    'id': item['url'].replaceAll('/watch?v=', ''),
                    'title': item['title'],
                    'channel': item['uploaderName'],
                    'thumbnail': item['thumbnail']
                 });
               }
             }
             if (items.isNotEmpty) {
               print('✅ Piped Arama Başarılı ($instance)');
               return items;
             }
             } catch (decodeEx) { print('JSON Parse error'); }
          }
        } catch (ex) {
          print('⚠️ Piped Arama Hatası ($instance): $ex');
        }
      }
    }
    return [];
  }

  @override
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/proxy/suggest?q=$query')).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['oneriler'] != null) {
          return List<String>.from(decoded['oneriler']);
        }
      }
    } catch (e) {
      print('Windows Proxy Suggestion Hatası: $e');
    }
    return [];
  }

  Future<bool> _isValidStream(String url) async {
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {'Range': 'bytes=0-1024', 'Accept': '*/*'},
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 || res.statusCode == 206) {
        final contentType = res.headers['content-type']?.toLowerCase() ?? '';

        // 🛡️ SİBER KALKAN: Windows Media Foundation (just_audio_windows) native olarak WebM/Opus desteklemez!
        if (contentType.contains('webm') || contentType.contains('opus')) {
          print('⚠️ SİBER KALKAN: Uyumsuz WebM/Opus formatı tespit edildi ($url)');
          return false;
        }

        if (contentType.contains('audio') || contentType.contains('video') || contentType.contains('application/octet-stream')) {
          if (res.bodyBytes.length > 50) return true;
        }
      }
    } catch (_) {}
    return false;
  }

  @override
  Future<Map<String, dynamic>> getStreamUrl(String videoId) async {
    String finalVideoId = videoId;
    if (videoId.startsWith('spotify:')) {
      final query = videoId.substring(8);
      print('🔍 [SPOTIFY MAPPING - PC] YouTube üzerinde aranıyor: $query');
      try {
        var searchResults = await _yt.search.search(query).timeout(const Duration(seconds: 8));
        if (searchResults.isNotEmpty) {
          finalVideoId = searchResults.first.id.value;
          print('✅ [SPOTIFY MAPPING - PC] Eşleşme bulundu: $finalVideoId');
        }
      } catch (e) {
        print('⚠️ Spotify arama hatası: $e');
      }
    }

    print('🎯 SİBER ÇÖZÜCÜ (Masaüstü): Hızlı yarış başlıyor -> $finalVideoId');

    // ⚡ 0. JET MOTORU: Hızlı RAM Önbelleği (0 ms gecikme)
    final cached = _streamCache[finalVideoId];
    if (cached != null && cached.isValid) {
      print('⚡ [JET MOTORU - PC] $finalVideoId akış URL\'si RAM önbellekten 0 ms ile alındı!');
      return cached.data;
    }

    List<Future<Map<String, dynamic>>> resolvers = [];

    // 1. YoutubeExplode (Çoklu İstemci + Muxed MP4 Desteği)
    resolvers.add(() async {
      try {
        var ytClients = [
          YoutubeApiClient.androidVr,
          YoutubeApiClient.ios,
          YoutubeApiClient.androidSdkless,
          YoutubeApiClient.safari,
        ];
        var manifest = await _yt.videos.streamsClient.getManifest(finalVideoId, ytClients: ytClients).timeout(const Duration(seconds: 6));
        List<StreamInfo> audioStreamList = manifest.audioOnly
            .where((s) => s.container.name == 'mp4' || s.audioCodec.contains('mp4a'))
            .toList();
        
        // 🛡️ SİBER KALKAN: Nadir parçalarda sadece muxed mp4 olabilir!
        if (audioStreamList.isEmpty) {
          audioStreamList = manifest.muxed
              .where((s) => s.container.name == 'mp4')
              .toList();
        }

        if (audioStreamList.isNotEmpty) {
          var ytStreamInfo = audioStreamList.reduce((a, b) => a.bitrate.bitsPerSecond > b.bitrate.bitsPerSecond ? a : b);
          final finalUrl = ytStreamInfo.url.toString();
          print('✅ SİBER YARIŞ KAZANANI (Masaüstü): YoutubeExplode (Hızlı)');
          return {'status': 'basarili', 'stream_url': finalUrl, 'is_file': false};
        }
      } catch (_) {}
      throw Exception('YoutubeExplode başarısız');
    }());

    // 2. yt-dlp (VisionOS Kamuflajı + Genişletilmiş Zaman Aşımı)
    resolvers.add(() async {
      try {
        String exePath = await YtDlpService().getExecutablePath();
        var process = await Process.run(exePath, [
          '-g',
          '--no-playlist',
          '-f', 'ba[ext=m4a]/ba[ext=mp4]/b[ext=mp4]/ba',
          '--no-check-certificate',
          '--no-warnings',
          '--extractor-args', 'youtube:player_client=visionos,android_vr,ios,web',
          'https://www.youtube.com/watch?v=$finalVideoId',
        ]).timeout(const Duration(seconds: 14));

        if (process.exitCode == 0 && process.stdout.toString().trim().isNotEmpty) {
          final lines = process.stdout.toString().trim().split('\n');
          final finalUrl = lines.firstWhere((l) => l.trim().startsWith('http'), orElse: () => '').trim();
          if (finalUrl.isNotEmpty) {
            print('✅ SİBER YARIŞ KAZANANI (Masaüstü): yt-dlp');
            return {'status': 'basarili', 'stream_url': finalUrl, 'is_file': false};
          }
        }
      } catch (_) {}
      throw Exception('yt-dlp başarısız');
    }());

    // 3. Vercel Backend Fallback
    resolvers.add(() async {
      try {
        final res = await http.get(Uri.parse('https://ozses-api.vercel.app/api/stream?id=$finalVideoId')).timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['stream_url'] != null && data['stream_url'].toString().startsWith('http')) {
            print('✅ SİBER YARIŞ KAZANANI (Masaüstü): Vercel Backend');
            return {'status': 'basarili', 'stream_url': data['stream_url'].toString(), 'is_file': false};
          }
        }
      } catch (_) {}
      throw Exception('Vercel başarısız');
    }());

    // 4. Güncel Piped API Yedekleri
    final pipedInstances = [
      'https://pipedapi.leptons.xyz',
      'https://pipedapi.nosebs.ru',
      'https://pipedapi.smnz.de',
      'https://api.piped.yt',
    ];
    for (var instance in pipedInstances) {
      resolvers.add(() async {
        try {
          final pipedRes = await http.get(Uri.parse('$instance/streams/$finalVideoId')).timeout(const Duration(seconds: 5));
          if (pipedRes.statusCode == 200) {
            final data = jsonDecode(pipedRes.body);
            final audioStreams = data['audioStreams'] as List<dynamic>? ?? [];
            if (audioStreams.isNotEmpty) {
              var preferredStream = audioStreams.firstWhere(
                (s) => s['mimeType'] != null && (s['mimeType'].toString().contains('mp4a') || s['mimeType'].toString().contains('mp4')),
                orElse: () => audioStreams.first,
              );
              final finalUrl = preferredStream['url'].toString();
              if (await _isValidStream(finalUrl)) {
                print('✅ SİBER YARIŞ KAZANANI (Masaüstü): Piped ($instance)');
                return {'status': 'basarili', 'stream_url': finalUrl, 'is_file': false};
              }
            }
          }
        } catch (_) {}
        throw Exception('Piped başarısız');
      }());
    }

    // 5. VPS Audio Relay (Son Çare)
    resolvers.add(() async {
      try {
        final relayUrl = 'http://167.172.190.129:8080/stream/$videoId';
        final check = await http.head(Uri.parse(relayUrl)).timeout(const Duration(seconds: 4));
        if (check.statusCode == 200 || check.statusCode == 206 || check.statusCode == 302) {
          print('✅ SİBER YARIŞ KAZANANI (Masaüstü): VPS Audio Relay');
          return {'status': 'basarili', 'stream_url': relayUrl, 'is_file': false};
        }
      } catch (_) {}
      throw Exception('VPS Relay başarısız');
    }());

    try {
      final winner = await firstSuccessful(resolvers);
      if (winner['status'] == 'basarili' && winner['stream_url'] != null) {
        _streamCache[finalVideoId] = _WindowsStreamCacheEntry(winner, DateTime.now().add(const Duration(hours: 4)));
      }
      return winner;
    } catch (e) {
      print('🛑 SİBER ÇÖZÜCÜ (Masaüstü): TÜM MOTORLAR ÇÖKTÜ! HİÇBİR URL BULUNAMADI.');
      return {'status': 'hata', 'mesaj': 'Tüm akış motorları çöktü'};
    }
  }

  @override
  Future<String> getDownloadPath() async {
    String userHome = Platform.environment['USERPROFILE'] ?? '';
    return '$userHome\\Music\\OzsesDownloads';
  }

  @override
  Future<List<String>> scanMusicFolders() async {
    String userHome = Platform.environment['USERPROFILE'] ?? '';
    List<Directory> targetDirs = [
      Directory('$userHome\\Music'),
      Directory('$userHome\\Downloads')
    ];

    List<String> foundFiles = [];
    for (var dir in targetDirs) {
      if (dir.existsSync()) {
        try {
          var files = dir.listSync(recursive: true, followLinks: false);
          for (var file in files) {
            if (file is File && (file.path.endsWith('.mp3') || file.path.endsWith('.m4a'))) {
              foundFiles.add(file.path);
            }
          }
        } catch (e) {
          print('Dizin tarama yetki hatası (atlandı): $dir');
        }
      }
    }
    return foundFiles;
  }
}

class _AsyncMutex {
  Future<void> _last = Future.value();

  Future<T> run<T>(Future<T> Function() fn) {
    final next = _last.then((_) => fn());
    _last = next.whenComplete(() => Future.delayed(const Duration(milliseconds: 1000))).then((_) => null).catchError((_) => null);
    return next;
  }
}

Future<T> firstSuccessful<T>(Iterable<Future<T>> futures) {
  final completer = Completer<T>();
  int remaining = futures.length;
  List<Object> errors = [];
  if (remaining == 0) return Future.error('No futures provided');
  for (var future in futures) {
    future.then((value) {
      if (!completer.isCompleted) completer.complete(value);
    }).catchError((error) {
      errors.add(error);
      remaining--;
      if (remaining == 0 && !completer.isCompleted) {
        completer.completeError(Exception('All futures failed'));
      }
    });
  }
  return completer.future;
}
