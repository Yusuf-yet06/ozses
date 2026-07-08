import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'siber_platform.dart';

class MobilePlatform implements SiberPlatform {
  @override
  bool get supportsHardwareDSP => Platform.isAndroid;

  // 🔥 SİBER KİLİT: Tüm YouTube API çağrıları sıralı gider, rate limit olmaz
  static final _ytMutex = _AsyncMutex();
  static final YoutubeExplode _yt = YoutubeExplode();

  @override
  Future<Map<String, dynamic>> fetchKesfet({String? pageToken}) async {
    print("--- ÖZSES KEŞFET RADARI BAŞLATILIYOR (MOBİL) ---");
    return await _ytMutex.run(() async {
      final List<String> discoveryTerms = [
        "türkçe pop en çok dinlenenler official audio",
        "haftanın trend şarkıları",
        "yeni çıkan şarkılar 2026",
        "hit şarkılar karışık Türkçe",
        "viral türkçe şarkılar",
        "arabesk rap en çok dinlenenler",
        "akustik performans Türkçe",
      ];
      discoveryTerms.shuffle();
      String query = discoveryTerms.first;
      
      try {
        var searchResults = await _yt.search.search(query).timeout(const Duration(seconds: 8));
        var items = [];
        for (var video in searchResults.take(15)) {
          items.add({
            "id": video.id.value,
            "title": video.title,
            "channel": video.author,
            "thumbnail": video.thumbnails.highResUrl,
            "duration": video.duration?.inSeconds ?? 0,
          });
        }
        return {"status": "basarili", "oneriler": items, "nextPageToken": ""};
      } catch (e) {
        print("❌ YoutubeExplode Arama Hatası: $e");
        final List<String> pipedInstances = [
          'https://pipedapi.kavin.rocks',
          'https://api.piped.privacydev.net',
          'https://piped-api.lunar.icu',
          'https://piped-api.garudalinux.org',
          'https://pipedapi.adminforge.de',
        ];
        
        try {
          final futures = pipedInstances.map((instance) async {
            final response = await http.get(Uri.parse('$instance/search?q=${Uri.encodeComponent(query)}&filter=music_songs')).timeout(const Duration(seconds: 3));
            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              if (data['items'] != null) {
                var pipedItems = [];
                for (var item in (data['items'] as List).take(15)) {
                  if (item['type'] == 'stream') {
                    pipedItems.add({
                      "id": item['url'].toString().replaceAll('/watch?v=', ''),
                      "title": item['title'],
                      "channel": item['uploaderName'],
                      "thumbnail": item['thumbnail'],
                      "duration": item['duration'] ?? 0,
                    });
                  }
                }
                return pipedItems;
              }
            }
            throw Exception("Piped Hata");
          });

          final bestItems = await Future.any(futures);
          return {"status": "basarili", "oneriler": bestItems, "nextPageToken": ""};
        } catch (e) {
          print("❌ Tüm Piped sunucuları çöktü: $e");
        }
        return {"status": "hata", "oneriler": [], "nextPageToken": ""};
      }
    });
  }

  @override
  Future<List<dynamic>> searchMusic(String query, {int limit = 15, int page = 1}) async {
    print("--- SİBER ARAMA BAŞLATILIYOR (MOBİL) ---");
    return await _ytMutex.run(() async {
      try {
        var searchResults = await _yt.search.search(query + " official audio").timeout(const Duration(seconds: 8));
        var items = [];
        for (var video in searchResults.take(limit)) {
          items.add({
            "id": video.id.value,
            "title": video.title,
            "channel": video.author,
            "thumbnail": video.thumbnails.highResUrl,
            "duration": video.duration?.inSeconds ?? 0,
          });
        }
        return items;
      } catch (e) {
        print("❌ YoutubeExplode Arama Hatası: $e");
        final List<String> pipedInstances = [
          'https://api.piped.private.coffee',
          'https://pipedapi.kavin.rocks',
          'https://api.piped.privacydev.net',
          'https://piped-api.lunar.icu',
          'https://piped-api.garudalinux.org',
          'https://pipedapi.adminforge.de',
          'https://pipedapi.smnz.de',
          'https://piped-api.moomoo.me',
          'https://api.piped.projectsegfau.lt',
          'https://pipedapi.tokhmi.xyz',
          'https://pipedapi.r4fo.com'
        ];
        
        try {
          final futures = pipedInstances.map((instance) async {
            final response = await http.get(Uri.parse('$instance/search?q=${Uri.encodeComponent(query + " official audio")}&filter=music_songs')).timeout(const Duration(seconds: 3));
            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              if (data['items'] != null) {
                var pipedItems = [];
                for (var item in (data['items'] as List).take(limit)) {
                  if (item['type'] == 'stream') {
                    pipedItems.add({
                      "id": item['url'].toString().replaceAll('/watch?v=', ''),
                      "title": item['title'],
                      "channel": item['uploaderName'],
                      "thumbnail": item['thumbnail'],
                      "duration": item['duration'] ?? 0,
                    });
                  }
                }
                return pipedItems;
              }
            }
            throw Exception("Piped Hata");
          });

          return await Future.any(futures);
        } catch (e) {
          print("❌ Tüm Piped sunucuları çöktü: $e");
        }
        return [];
      }
    });
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
      print("Siber Proxy Suggestion Hatası: $e");
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> getStreamUrl(String videoId) async {
    print("🎯 SİBER HAMLE: YoutubeExplode Native Byte Akışı Başlatılıyor...");
    
    // 🎯 1. KADEME: Mutex ile tek sıralı YoutubeExplode çağrısı (rate limit engeli)
    try {
      // Manifest alımı mutex ile (rate limit önleme)
      final manifest = await _ytMutex.run(() =>
        _yt.videos.streamsClient.getManifest(videoId).timeout(const Duration(seconds: 8))
      );
      
      var audioStreamList = manifest.audioOnly.where(
        (s) => s.container.name == 'mp4' || s.audioCodec.contains('mp4a')
      ).toList();
      var streamInfo = audioStreamList.isNotEmpty 
          ? audioStreamList.reduce((a, b) => a.bitrate.bitsPerSecond > b.bitrate.bitsPerSecond ? a : b)
          : manifest.audioOnly.withHighestBitrate();
      
      return {"status": "basarili", "stream_url": streamInfo.url.toString(), "is_file": false};
      
    } catch (e) {
      print("❌ YoutubeExplode Native Hatası: $e");
    }
    
    // 🎯 2. KADEME: Cobalt API (Youtube rate limit ve Piped çökmesine karşı en güçlü alternatif)
    print("🎯 Cobalt API deneniyor...");
    final List<String> cobaltInstances = [
      'https://api.cobalt.tools/api/json',
      'https://co.wuk.sh/api/json',
      'https://cobalt.qoid.us/api/json'
    ];

    try {
      final futures = cobaltInstances.map((instance) async {
        final response = await http.post(
          Uri.parse(instance),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "url": "https://www.youtube.com/watch?v=$videoId",
            "isAudioOnly": true,
            "aFormat": "mp3", // m4a veya mp3
            "isNoTTWatermark": true,
          }),
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'redirect' || data['status'] == 'stream') {
            return data['url'].toString();
          }
        }
        throw Exception("Cobalt stream bulunamadı");
      });

      final bestUrl = await firstSuccessful(futures);
      return {"status": "basarili", "stream_url": bestUrl, "is_file": false};
    } catch (e) {
      print("❌ Cobalt API de çöktü: $e");
    }

    // 🎯 3. KADEME: Piped API (sadece DNS engeli yoksa)
    print("🎯 Piped API deneniyor...");
    final List<String> pipedInstances = [
      'https://api.piped.private.coffee',
      'https://pipedapi.kavin.rocks',
      'https://api.piped.privacydev.net',
      'https://piped-api.lunar.icu',
      'https://piped-api.garudalinux.org',
      'https://pipedapi.adminforge.de',
      'https://pipedapi.smnz.de',
      'https://piped-api.moomoo.me',
      'https://api.piped.projectsegfau.lt',
      'https://pipedapi.tokhmi.xyz',
      'https://pipedapi.r4fo.com'
    ];

    try {
      // Bütün Piped sunucularına aynı anda istek at, ilk cevap vereni al
      final futures = pipedInstances.map((instance) async {
        final String apiUrl = "$instance/streams/$videoId";
        final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['audioStreams'] != null && (data['audioStreams'] as List).isNotEmpty) {
            var audioStreams = data['audioStreams'] as List;
            var bestStream = audioStreams.firstWhere(
              (s) => s['format'] == 'M4A',
              orElse: () => audioStreams.first,
            );
            return bestStream['url'].toString();
          } else if (data['videoStreams'] != null && (data['videoStreams'] as List).isNotEmpty) {
            var videoStreams = data['videoStreams'] as List;
            try {
              var bestStream = videoStreams.firstWhere(
                (s) => s['videoOnly'] == false && s['format'] == 'MPEG_4'
              );
              return bestStream['url'].toString();
            } catch (e) {
              try {
                var backupStream = videoStreams.firstWhere((s) => s['videoOnly'] == false);
                return backupStream['url'].toString();
              } catch (e) {
                // Ignore if all are videoOnly
              }
            }
          }
        }
        throw Exception("Stream bulunamadı");
      });

      final bestUrl = await firstSuccessful(futures);
      return {"status": "basarili", "stream_url": bestUrl, "is_file": false};
    } catch (e) {
      print("❌ Tüm Piped sunucuları çöktü veya zaman aşımı: $e");
    }

    // 🎯 4. KADEME: Siber PC Proxy (Kuzen'in Özel Ağı)
    print("🎯 Siber Proxy deneniyor...");
    final List<String> localIps = [
      '192.168.1.121',
      '192.168.1.15',
      '10.0.2.2' // Emulator
    ];

    try {
      final futures = localIps.map((ip) async {
        final response = await http.get(Uri.parse('http://$ip:8081/api/proxy/stream?id=$videoId')).timeout(const Duration(seconds: 2));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'basarili' && data['stream_url'] != null) {
            return data['stream_url'].toString();
          }
        }
        throw Exception("Proxy'den stream alınamadı");
      });
      final bestUrl = await firstSuccessful(futures);
      return {"status": "basarili", "stream_url": bestUrl, "is_file": false};
    } catch (e) {
      print("❌ Siber Proxy de çöktü: $e");
    }

    return {"status": "hata", "stream_url": null};
  }

  @override
  Future<String> getDownloadPath() async {
    if (Platform.isAndroid) {
      // 🎯 SİBER KALKAN: Güvenli İndirme Yolu (Android Scoped Storage)
      return '/storage/emulated/0/Download';
    } else if (Platform.isIOS) {
      return '';
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
    _last = next.whenComplete(() => Future.delayed(const Duration(milliseconds: 1000))).catchError((_) {});
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
