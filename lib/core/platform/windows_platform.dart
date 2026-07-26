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
      return await _ytMutex.run(() async {
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
        for (var video in searchResults) {
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
      });
    } catch (e) {
      print('🚀 Siber Yerel Keşfet Hatası (Masaüstü): $e');
      print('🔄 SİBER KALKAN: Piped Keşfet Fallback Devrede...');
      final List<String> pipedInstances = [
        'https://pipedapi.kavin.rocks',
        'https://pipedapi.moomoo.me',
        'https://api.piped.projectsegfau.lt'
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

  @override
  Future<Map<String, dynamic>> getStreamUrl(String videoId) async {
    try {
      // SİBER KALKAN: Native yt-dlp ile Windows üzerinde akış çöz
      String exePath = await YtDlpService().getExecutablePath();
      var process = await Process.run(exePath, [
        '-g', 
        '-f', 'bestaudio[ext=m4a]/bestaudio', 
        'https://www.youtube.com/watch?v=$videoId'
      ]);
      
      if (process.exitCode == 0 && process.stdout.toString().trim().isNotEmpty) {
        return {'status': 'basarili', 'stream_url': process.stdout.toString().trim()};
      } else {
        print('yt-dlp akış alma hatası: ${process.stderr}');
        
        // Fallback: YoutubeExplode
        var manifest = await _yt.videos.streamsClient.getManifest(videoId).timeout(const Duration(seconds: 10));
        var audioStreams = manifest.audioOnly.where((s) => s.container.name == 'mp4' || s.container.name == 'm4a');
        if (audioStreams.isEmpty) audioStreams = manifest.audioOnly;
        var streamInfo = audioStreams.withHighestBitrate();
        return {'status': 'basarili', 'stream_url': streamInfo.url.toString()};
      }
    } catch (e) {
        print('Windows Desktop Stream URL Hatası: $e');
        print('⚠️ YoutubeExplode da patladı! Piped Fallback devrede...');
        final List<String> pipedInstances = [
          'https://pipedapi.kavin.rocks',
          'https://pipedapi.moomoo.me',
          'https://api.piped.projectsegfau.lt'
        ];
        for (var instance in pipedInstances) {
          try {
            final pipedRes = await http.get(Uri.parse('$instance/streams/$videoId')).timeout(const Duration(seconds: 10));
            if (pipedRes.statusCode == 200) {
              final data = jsonDecode(pipedRes.body);
              if (data['audioStreams'] != null && data['audioStreams'].isNotEmpty) {
                String bestUrl = data['audioStreams'][0]['url'];
                return {'status': 'basarili', 'stream_url': bestUrl};
              }
            }
          } catch (ex) {
            print('⚠️ Piped Stream Hatası ($instance): $ex');
          }
        }
        return {'status': 'hata', 'mesaj': e.toString()};
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
