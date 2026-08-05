import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'siber_platform.dart';
import '../../services/ytdlp_service.dart';

class WindowsPlatform implements SiberPlatform {
  @override
  bool get supportsHardwareDSP => false;

  final YoutubeExplode _yt = YoutubeExplode();
  final _AsyncMutex _ytMutex = _AsyncMutex();

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
          }
        } catch (ex) {
          print('⚠️ Piped Keşfet Hatası ($instance): $ex');
        }
      }
    }
    return {'status': 'hata', 'oneriler': [], 'nextPageToken': ''};
  }

  @override
  Future<List<dynamic>> searchMusic(String query, {int limit = 15, int page = 1}) async {
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
        'https://pipedapi.moomoo.me',
        'https://api.piped.projectsegfau.lt'
      ];
      
      for (var instance in pipedInstances) {
        try {
          print('🎯 Deneniyor: $instance');
          final res = await http.get(Uri.parse('$instance/search?q=${Uri.encodeComponent(query)}&filter=all')).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200) {
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
      final res = await http.get(Uri.parse(url), headers: {'Range': 'bytes=0-1024', 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200 || res.statusCode == 206) {
        final contentType = res.headers['content-type']?.toLowerCase() ?? '';
        if (contentType.contains('audio') || contentType.contains('video') || contentType.contains('application/octet-stream')) {
          if (res.bodyBytes.length > 100) return true;
        }
      }
    } catch (_) {}
    return false;
  }

  @override
  Future<Map<String, dynamic>> getStreamUrl(String videoId) async {
    print('🎯 SİBER ÇÖZÜCÜ (Masaüstü): Eşzamanlı yarış başlıyor -> $videoId');
    
    List<Future<Map<String, dynamic>>> resolvers = [];

    // 1. YoutubeExplode (Yerel)
    resolvers.add(() async {
      try {
        var ytClients = [YoutubeApiClient.ios, YoutubeApiClient.androidVr, YoutubeApiClient.androidSdkless, YoutubeApiClient.tv];
        var manifest = await _yt.videos.streamsClient.getManifest(videoId, ytClients: ytClients).timeout(const Duration(seconds: 15));
        var audioStreamList = manifest.audioOnly.where((s) => s.container.name == 'mp4' || s.audioCodec.contains('mp4a')).toList();
        if (audioStreamList.isEmpty) {
          audioStreamList = manifest.audioOnly.toList();
        }
        var ytStreamInfo = audioStreamList.isNotEmpty
            ? audioStreamList.reduce((a, b) => a.bitrate.bitsPerSecond > b.bitrate.bitsPerSecond ? a : b)
            : manifest.audioOnly.withHighestBitrate();
        final finalUrl = ytStreamInfo.url.toString();
        if (!(await _isValidStream(finalUrl))) throw Exception('Invalid Stream');
        print('✅ SİBER YARIŞ KAZANANI (Masaüstü): YoutubeExplode');
        return {'status': 'basarili', 'stream_url': finalUrl, 'is_file': false};
      } catch (e) {
        throw Exception('YoutubeExplode başarısız');
      }
    }());

    // 2. yt-dlp (Harici İşlem)
    resolvers.add(() async {
      try {
        String exePath = await YtDlpService().getExecutablePath();
        var process = await Process.run(exePath, [
          '-g', 
          '-f', 'bestaudio[ext=m4a]/bestaudio', 
          'https://www.youtube.com/watch?v=$videoId'
        ]).timeout(const Duration(seconds: 30));
        
        if (process.exitCode == 0 && process.stdout.toString().trim().isNotEmpty) {
          print('✅ SİBER YARIŞ KAZANANI (Masaüstü): yt-dlp');
          return {'status': 'basarili', 'stream_url': process.stdout.toString().trim(), 'is_file': false};
        }
        throw Exception('yt-dlp başarısız');
      } catch (_) {
        throw Exception('yt-dlp başarısız');
      }
    }());

    // 3. Piped API
    final pipedInstances = [
      'https://pipedapi.kavin.rocks', 
      'https://api.piped.projectsegfau.lt',
      'https://pipedapi.smnz.de'
    ];
    for (var instance in pipedInstances) {
      resolvers.add(() async {
        try {
          final pipedRes = await http.get(Uri.parse('$instance/streams/$videoId')).timeout(const Duration(seconds: 15));
          if (pipedRes.statusCode == 200) {
             final data = jsonDecode(pipedRes.body);
             final audioStreams = data['audioStreams'] as List<dynamic>? ?? [];
             if (audioStreams.isNotEmpty) {
               final finalUrl = audioStreams.first['url'].toString();
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

    // 4. Vercel Backend
    resolvers.add(() async {
      try {
        final vercelRes = await http.get(Uri.parse('https://ozses-832f9y4py-ozses.vercel.app/stream?id=$videoId')).timeout(const Duration(seconds: 15));
         if (vercelRes.statusCode == 200) {
           final data = jsonDecode(vercelRes.body);
           if (data['stream_url'] != null) {
             final finalUrl = data['stream_url'].toString();
             if (await _isValidStream(finalUrl)) {
               print('✅ SİBER YARIŞ KAZANANI (Masaüstü): Vercel Backend');
               return {'status': 'basarili', 'stream_url': finalUrl, 'is_file': false};
             }
           }
         }
       } catch (_) {}
       throw Exception('Vercel başarısız');
     }());

    // 4.5 Cobalt API (Güçlü Yedek)
    resolvers.add(() async {
      try {
        final cobaltRes = await http.post(
          Uri.parse('https://api.cobalt.tools/api/json'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'url': 'https://www.youtube.com/watch?v=$videoId',
            'isAudioOnly': true,
            'aFormat': 'mp3'
          }),
        ).timeout(const Duration(seconds: 15));
        
         if (cobaltRes.statusCode == 200) {
           final data = jsonDecode(cobaltRes.body);
           if (data['url'] != null) {
             final finalUrl = data['url'].toString();
             if (await _isValidStream(finalUrl)) {
               print('✅ SİBER YARIŞ KAZANANI (Masaüstü): Cobalt API');
               return {'status': 'basarili', 'stream_url': finalUrl, 'is_file': false};
             }
           }
         }
       } catch (_) {}
       throw Exception('Cobalt başarısız');
     }());

    // 5. Invidious API
    final invidiousInstances = ['vid.puffyan.us', 'invidious.jing.rocks'];
    for (var instance in invidiousInstances) {
      resolvers.add(() async {
        try {
          final invRes = await http.get(Uri.parse('https://$instance/api/v1/videos/$videoId')).timeout(const Duration(seconds: 15));
          if (invRes.statusCode == 200) {
            final data = jsonDecode(invRes.body);
             final streams = data['formatStreams'] as List<dynamic>? ?? [];
             for (var s in streams) {
               if (s['type'] != null && s['type'].toString().contains('audio')) {
                 final finalUrl = s['url'].toString();
                 if (await _isValidStream(finalUrl)) {
                   print('✅ SİBER YARIŞ KAZANANI (Masaüstü): Invidious ($instance)');
                   return {'status': 'basarili', 'stream_url': finalUrl, 'is_file': false};
                 }
               }
             }
           }
         } catch (_) {}
         throw Exception('Invidious başarısız');
       }());
    }

    try {
      return await firstSuccessful(resolvers);
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
