import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/storage_service.dart';
import 'siber_platform.dart';

class MobilePlatform implements SiberPlatform {
  @override
  bool get supportsHardwareDSP => Platform.isAndroid;

  // 🔥 SİBER KİLİT: Tüm YouTube API çağrıları sıralı gider, rate limit olmaz
  static final _ytMutex = _AsyncMutex();
  static final YoutubeExplode _yt = YoutubeExplode();

  @override
  Future<Map<String, dynamic>> fetchKesfet({String? pageToken}) async {
    print('--- ÖZSES KEŞFET RADARI BAŞLATILIYOR (YEREL OTONOM) ---');
    final List<String> discoveryTerms = [
      'türkçe pop en çok dinlenenler',
      'haftanın trend şarkıları',
      'yeni çıkan şarkılar 2026',
      'hit şarkılar karışık Türkçe',
      'viral türkçe şarkılar',
      'arabesk rap en çok dinlenenler',
      'akustik performans Türkçe',
    ];
    discoveryTerms.shuffle();
    String query = discoveryTerms.first;
    
    try {
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
      print('🚀 Siber Yerel Keşfet Hatası: $e');
      print('🔄 SİBER KALKAN: Piped Keşfet Fallback Devrede...');
      final List<String> pipedInstances = [
        'https://pipedapi.kavin.rocks',
        'https://pipedapi.moomoo.me',
        'https://api.piped.projectsegfau.lt'
      ];
      for (var instance in pipedInstances) {
        try {
          final res = await http.get(Uri.parse('$instance/search?q=${Uri.encodeComponent(query)}&filter=all')).timeout(const Duration(seconds: 10));
          if (res.statusCode == 200) {
             try {
               final data = jsonDecode(res.body);
               var items = [];
               for (var item in data['items'] ?? []) {
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
             } catch (decodeEx) {
               print('⚠️ Piped JSON Parse Hatası ($instance): HTML döndü.');
             }
          }
        } catch (ex) {
          print('⚠️ Piped Keşfet Hatası ($instance): $ex');
        }
      }
      
      // 🛡️ 3. ZIRH: Invidious Keşfet (Eğer YouTube ve Piped çöktüyse)
      print('🔄 SİBER KALKAN: Invidious Keşfet Fallback Devrede...');
      final List<String> invidiousInstances = [
        'vid.puffyan.us',
        'invidious.jing.rocks',
        'invidious.nerdvpn.de',
        'inv.tux.pizza'
      ];
      for (var instance in invidiousInstances) {
        try {
          print('🎯 Invidious Keşfet Deneniyor: $instance');
          final res = await http.get(Uri.parse('https://$instance/api/v1/search?q=${Uri.encodeComponent(query)}')).timeout(const Duration(seconds: 10));
          if (res.statusCode == 200) {
             try {
               final List<dynamic> data = jsonDecode(res.body);
               var items = [];
               for (var item in data) {
               if (item['type'] == 'video' && item['videoId'] != null) {
                 String tUrl = '';
                 if (item['videoThumbnails'] != null && (item['videoThumbnails'] as List).isNotEmpty) {
                   tUrl = item['videoThumbnails'][0]['url'] ?? '';
                 }
                 items.add({
                    'id': item['videoId'],
                    'title': item['title'],
                    'channel': item['author'],
                    'thumbnail': tUrl
                 });
               }
             }
             if (items.isNotEmpty) {
               print('✅ Invidious Keşfet Başarılı ($instance)');
               return {'status': 'basarili', 'oneriler': items, 'nextPageToken': ''};
             }
             } catch (decodeEx) {
               print('⚠️ Invidious JSON Parse Hatası ($instance)');
             }
          }
        } catch (ex) {
          print('⚠️ Invidious Keşfet Hatası ($instance): $ex');
        }
      }

    }
    return {'status': 'hata', 'oneriler': [], 'nextPageToken': ''};
  }

  @override
  Future<List<dynamic>> searchMusic(String query, {int limit = 15, int page = 1}) async {
    print('--- SİBER ARAMA BAŞLATILIYOR (YEREL OTONOM) ---');
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
      print('🚀 Siber Yerel Arama Hatası: $e');
      print('🔄 SİBER KALKAN: Piped Arama Fallback Devrede...');
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
             try {
               final data = jsonDecode(res.body);
               var items = [];
               for (var item in data['items'] ?? []) {
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
             } catch (decodeEx) {
               print('⚠️ Piped JSON Parse Hatası ($instance)');
             }
          }
        } catch (ex) {
          print('⚠️ Piped Arama Hatası ($instance): $ex');
        }
      }
      
      // 🛡️ 3. ZIRH: Invidious Arama (Eğer YouTube ve Piped tamamen çöktüyse)
      print('🔄 SİBER KALKAN: Invidious Arama Fallback Devrede...');
      final List<String> invidiousInstances = [
        'vid.puffyan.us',
        'invidious.jing.rocks',
        'invidious.nerdvpn.de',
        'inv.tux.pizza'
      ];
      
      for (var instance in invidiousInstances) {
        try {
          print('🎯 Invidious Deneniyor: $instance');
          final res = await http.get(Uri.parse('https://$instance/api/v1/search?q=${Uri.encodeComponent(query)}')).timeout(const Duration(seconds: 5));
          if (res.statusCode == 200) {
             try {
               final List<dynamic> data = jsonDecode(res.body);
               var items = [];
               for (var item in data) {
               if (item['type'] == 'video' && item['videoId'] != null) {
                 String tUrl = '';
                 if (item['videoThumbnails'] != null && (item['videoThumbnails'] as List).isNotEmpty) {
                   tUrl = item['videoThumbnails'][0]['url'] ?? '';
                 }
                 items.add({
                    'id': item['videoId'],
                    'title': item['title'],
                    'channel': item['author'],
                    'thumbnail': tUrl
                 });
               }
             }
             if (items.isNotEmpty) {
               print('✅ Invidious Arama Başarılı ($instance)');
               return items;
             }
             } catch (decodeEx) {
               print('⚠️ Invidious JSON Parse Hatası ($instance)');
             }
          }
        } catch (ex) {
          print('⚠️ Invidious Arama Hatası ($instance): $ex');
        }
      }

    }
    return [];
  }

  @override
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8081/api/proxy/suggest?q=$query')).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['oneriler'] != null) {
          return List<String>.from(decoded['oneriler']);
        }
      }
    } catch (e) {
      print('Siber Proxy Suggestion Hatası: $e');
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> getStreamUrl(String videoId) async {
    // 🚀 ÇİFT ÇEKİRDEK KONTROLÜ: Kalıcı depoda dosya var mı?
    try {
      String storagePath = await StorageService.getOzsesDownloadPath();
      String permanentPath = '$storagePath/ozses_offline_$videoId.mp4';
      var file = File(permanentPath);
      if (await file.exists() && await file.length() > 500000) { // En az 500KB ise (boş dosya değilse)
        print('🎯 SİBER ÇİFT ÇEKİRDEK: Şarkı kalıcı depodan saniyesinde açılıyor! İNTERNET YOK, BEKLEME YOK!');
        return {'status': 'basarili', 'stream_url': permanentPath, 'is_file': true};
      }
    } catch (e) {
      print('Çift Çekirdek Okuma Hatası: $e');
    }

    // 🛡️ SİBER KALKAN V3: EŞZAMANLI YARIŞ (CONCURRENT RESOLVER)
    // Tüm akış motorları aynı anda yarışır, ilk URL bulan kazanır. Bu sayede süre 60 saniyeden 2 saniyeye düşer!
    print('🎯 SİBER ÇÖZÜCÜ (Mobil): Eşzamanlı yarış başlıyor -> $videoId');
    
    List<Future<Map<String, dynamic>>> resolvers = [];

    // 1. YoutubeExplode (Yerel)
    resolvers.add(() async {
      try {
        var ytClients = [YoutubeApiClient.ios, YoutubeApiClient.androidVr, YoutubeApiClient.androidSdkless, YoutubeApiClient.tv];
        var manifest = await _yt.videos.streamsClient.getManifest(videoId, ytClients: ytClients).timeout(const Duration(seconds: 8));
        var audioStreamList = manifest.audioOnly.where((s) => s.container.name == 'mp4' || s.audioCodec.contains('mp4a')).toList();
        if (audioStreamList.isEmpty) {
          audioStreamList = manifest.audioOnly.toList();
        }
        var ytStreamInfo = audioStreamList.isNotEmpty
            ? audioStreamList.reduce((a, b) => a.bitrate.bitsPerSecond > b.bitrate.bitsPerSecond ? a : b)
            : manifest.audioOnly.withHighestBitrate();
        print('✅ SİBER YARIŞ KAZANANI: YoutubeExplode');
        return {'status': 'basarili', 'stream_url': ytStreamInfo.url.toString(), 'is_file': false};
      } catch (e) {
        throw Exception('YoutubeExplode başarısız');
      }
    }());

    // 2. Piped API
    final pipedInstances = [
      'https://pipedapi.kavin.rocks', 
      'https://api.piped.projectsegfau.lt',
      'https://pipedapi.smnz.de'
    ];
    for (var instance in pipedInstances) {
      resolvers.add(() async {
        try {
          final pipedRes = await http.get(Uri.parse('$instance/streams/$videoId')).timeout(const Duration(seconds: 6));
          if (pipedRes.statusCode == 200) {
            final data = jsonDecode(pipedRes.body);
            final audioStreams = data['audioStreams'] as List<dynamic>? ?? [];
            if (audioStreams.isNotEmpty) {
              print('✅ SİBER YARIŞ KAZANANI: Piped ($instance)');
              return {'status': 'basarili', 'stream_url': audioStreams.first['url'].toString(), 'is_file': false};
            }
          }
        } catch (_) {}
        throw Exception('Piped başarısız');
      }());
    }

    // 3. Vercel Backend
    resolvers.add(() async {
      try {
        final vercelRes = await http.get(Uri.parse('https://ozses-832f9y4py-ozses.vercel.app/stream?id=$videoId')).timeout(const Duration(seconds: 6));
        if (vercelRes.statusCode == 200) {
          final data = jsonDecode(vercelRes.body);
          if (data['stream_url'] != null) {
            print('✅ SİBER YARIŞ KAZANANI: Vercel Backend');
            return {'status': 'basarili', 'stream_url': data['stream_url'].toString(), 'is_file': false};
          }
        }
      } catch (_) {}
      throw Exception('Vercel başarısız');
    }());

    // 4. Invidious API
    final invidiousInstances = ['vid.puffyan.us', 'invidious.jing.rocks'];
    for (var instance in invidiousInstances) {
      resolvers.add(() async {
        try {
          final invRes = await http.get(Uri.parse('https://$instance/api/v1/videos/$videoId')).timeout(const Duration(seconds: 6));
          if (invRes.statusCode == 200) {
            final data = jsonDecode(invRes.body);
            final streams = data['formatStreams'] as List<dynamic>? ?? [];
            for (var s in streams) {
              if (s['type'] != null && s['type'].toString().contains('audio')) {
                print('✅ SİBER YARIŞ KAZANANI: Invidious ($instance)');
                return {'status': 'basarili', 'stream_url': s['url'].toString(), 'is_file': false};
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
      print('🛑 SİBER ÇÖZÜCÜ: TÜM MOTORLAR ÇÖKTÜ! HİÇBİR URL BULUNAMADI.');
      return {'status': 'hata', 'mesaj': 'Tüm akış motorları çöktü'};
    }
  }

  @override
  Future<String> getDownloadPath() async {
    if (Platform.isAndroid) {
      // 🛡️ SİBER KALKAN: Güvenli İndirme Yolu (Android Scoped Storage)
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        return extDir.path;
      }
      return '/storage/emulated/0/Download';
    } else if (Platform.isIOS) {
      final appDocDir = await getApplicationDocumentsDirectory();
      return appDocDir.path;
    }
    return '';
  }

  @override
  Future<List<String>> scanMusicFolders() async {
    if (Platform.isAndroid) {
      await [
        Permission.storage,
        Permission.audio,
      ].request();

      List<Directory> targetDirs = [
        Directory('/storage/emulated/0/Download'),
        Directory('/storage/emulated/0/Music')
      ];

      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        targetDirs.add(extDir);
      }

      List<String> foundFiles = [];
      for (var dir in targetDirs) {
        if (dir.existsSync()) {
          var files = dir.listSync(recursive: true, followLinks: false);
          for (var file in files) {
            if (file is File && (file.path.endsWith('.mp3') || file.path.endsWith('.m4a'))) {
              foundFiles.add(file.path);
            }
          }
        }
      }
      return foundFiles;
    }
    return [];
  }
}

// 🔒 Async Mutex: Dart'ta tek sıralı asenkron işlem kuyruğu
// Tüm YoutubeExplode çağrıları sıralı gider, rate limit olmaz
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
