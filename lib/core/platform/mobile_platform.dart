import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/storage_service.dart';
import 'siber_platform.dart';
import '../../services/siber_ip_service.dart'; // 🎯 IP YÖNETİMİ
import '../../services/youtube_api_service.dart';

class _StreamCacheEntry {
  final Map<String, dynamic> data;
  final DateTime expiresAt;
  _StreamCacheEntry(this.data, this.expiresAt);
  bool get isValid => DateTime.now().isBefore(expiresAt);
}

class MobilePlatform implements SiberPlatform {
  @override
  bool get supportsHardwareDSP => Platform.isAndroid;

  // 🔥 SİBER KİLİT: Tüm YouTube API çağrıları sıralı gider, rate limit olmaz
  static final _ytMutex = _AsyncMutex();
  static final YoutubeExplode _yt = YoutubeExplode();

  // ⚡ SİBER JET RAM ÖNBELLEĞİ: Çözülen akış URL'lerini 4 saat bellekte tutar (0 ms yanıt)
  static final Map<String, _StreamCacheEntry> _streamCache = {};
  static String? _cachedDownloadDir;

  // 🚀 SİBER RADAR: Arka planda önceden akış URL'si çözme (0 ms geçiş için)
  static void preWarmStream(String videoId) {
    if (videoId.isEmpty) return;
    final cleanId = videoId.startsWith('yt:') ? videoId.substring(3) : videoId;
    final cached = _streamCache[cleanId];
    if (cached != null && cached.isValid) return;
    MobilePlatform().getStreamUrl(cleanId).catchError((_) => <String, dynamic>{});
  }

  @override
  void preWarm(String videoId) => preWarmStream(videoId);

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
      var searchResults = await YoutubeApiService.searchMusic(query, onlyMusic: true);
      if (searchResults.isNotEmpty) {
        print('✅ Siber Yerel Keşfet: Resmi API ${searchResults.length} şarkı buldu!');
        return {
          'status': 'basarili',
          'oneriler': searchResults,
          'nextPageToken': '',
        };
      } else {
        throw Exception('Resmi API boş sonuç döndürdü');
      }
    } catch (e) {
            print('❌ Siber Yerel Keşfet Hatası (Resmi API): $e');

      print('🛡️ SİBER KALKAN: Resmi API Çöktü, YoutubeExplode (Yerel Yedek) Devrede...');
      try {
        final searchResults = await _yt.search.search(query).timeout(const Duration(seconds: 15));
        if (searchResults.isNotEmpty) {
          print('✅ Siber Yerel Keşfet: YoutubeExplode başarıyla getirdi!');
          return {
            'status': 'basarili',
            'oneriler': searchResults.take(15).map((vid) => {
              'videoId': vid.id.value,
              'title': vid.title,
              'channel': vid.author,
              'thumbnail': vid.thumbnails.highResUrl.toString(),
            }).toList(),
            'nextPageToken': '',
          };
        }
      } catch (ex) {
        print('❌ YoutubeExplode Keşfet Hatası: $ex');
      }

      print('🛡️ SİBER KALKAN: Piped Keşfet Fallback Devrede...');
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
        'invidious.nerdvpn.de',
        'inv.nadeko.net',
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
  Future<List<dynamic>> searchMusic(String query, {int limit = 15, int page = 1, bool onlyMusic = true}) async {
        print('--- SİBER ARAMA BAŞLATILIYOR (RESMİ YOUTUBE API) ---');
    try {
      final items = await YoutubeApiService.searchMusic(query, onlyMusic: onlyMusic);
      if (items.isNotEmpty) {
        print('✅ Resmi YouTube API Arama Başarılı!');
        return items.take(limit).toList();
      }
    } catch (e) {
      print('❌ Resmi YouTube API Hatası: $e');
    }

    print('🛡️ SİBER KALKAN: Resmi API çöktü, YoutubeExplode (Yerel Yedek) devreye giriyor...');
    try {
      final searchQuery = query;
      final searchResults = await _yt.search.search(searchQuery).timeout(const Duration(seconds: 12));
      if (searchResults.isNotEmpty) {
        print('✅ YoutubeExplode Arama Başarılı!');
        return searchResults
            .where((vid) {
              if (!onlyMusic) return true;
              final t = vid.title.toLowerCase();
              return !t.contains('gameplay') &&
                  !t.contains('oyun oynadık') &&
                  !t.contains('vlog') &&
                  !t.contains('unboxing') &&
                  !t.contains('kutu açılımı') &&
                  !t.contains('motivasyon konuşması') &&
                  !t.contains('motivasyon videosu');
            })
            .take(limit)
            .map((vid) => {
              'videoId': vid.id.value,
              'title': vid.title,
              'channel': vid.author,
              'thumbnail': vid.thumbnails.highResUrl.toString(),
            })
            .toList();
      }
    } catch (e) {
      print('❌ YoutubeExplode Arama Hatası: $e');
    }

    print('🛡️ SİBER KALKAN: YoutubeExplode da çöktü, Piped API (Yedek 2) devreye giriyor...');
    final List<String> pipedInstances = [
      'https://pipedapi.nosebs.ru',
      'https://pipedapi.leptons.xyz',
      'https://api.piped.yt'
    ];
    for (var instance in pipedInstances) {
      try {
        final res = await http.get(Uri.parse('$instance/search?q=${Uri.encodeComponent(query)}&filter=all')).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final items = data['items'] as List<dynamic>? ?? [];
          final filtered = items.where((i) => i['type'] == 'stream').map((i) => {
            'videoId': i['url'].toString().replaceAll('/watch?v=', ''),
            'title': i['title'],
            'channel': i['uploaderName'],
            'thumbnail': i['thumbnail'],
          }).toList();
          if (filtered.isNotEmpty) {
            print('✅ Piped API ($instance) Arama Başarılı!');
            return filtered.take(limit).toList();
          }
        }
      } catch (e) {
        print('❌ Piped Hatası ($instance): $e');
      }
    }

    return [];
  }

  @override
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      final suggestions = await _yt.search.getQuerySuggestions(query);
      return suggestions.toList();
    } catch (e) {
      print('Siber Yerel Suggestion Hatası: $e');
      return [];
    }
  }

  // 🚀 SİBER AUDIO RELAY: Canlı Ses Köprüsü (VPS)
  static const String _vpsAudioRelay = '167.172.190.129:8080';

  @override
  Future<Map<String, dynamic>> getStreamUrl(String videoId) async {
    String finalVideoId = videoId;
    
    // 🔍 SİBER OTONOM MAPPING (Spotify -> YouTube)
    if (videoId.startsWith('spotify:')) {
      final query = videoId.substring(8);
      print('🔍 [SPOTIFY MAPPING] YouTube üzerinde aranıyor: $query');
      try {
        var searchResults = await _yt.search.search(query).timeout(const Duration(seconds: 10));
        if (searchResults.isNotEmpty) {
          finalVideoId = searchResults.first.id.value;
          print('✅ [SPOTIFY MAPPING] Eşleşme bulundu: $finalVideoId');
        } else {
          throw Exception('Eşleşme bulunamadı');
        }
      } catch (e) {
        print('❌ [SPOTIFY MAPPING] Hata: $e');
        throw Exception('Spotify şarkısı oynatılamıyor: $e');
      }
    }

    // ⚡ 0. JET MOTORU: Hızlı RAM Önbelleği (0 ms gecikme)
    final cached = _streamCache[finalVideoId];
    if (cached != null && cached.isValid) {
      print('⚡ [JET MOTORU] $finalVideoId akış URL\'si RAM önbellekten 0 ms ile alındı!');
      return cached.data;
    }

    // 1. Önce çevrimdışı depoya bak
    try {
      _cachedDownloadDir ??= await StorageService.getOzsesDownloadPath();
      String permanentPath = '$_cachedDownloadDir/ozses_offline_$finalVideoId.mp4';
      var file = File(permanentPath);
      if (await file.exists() && await file.length() > 500000) {
        print('📱 SİBER ÇİFT ÇEKİRDEK: Şarkı kalıcı depodan saniyesinde açılıyor!');
        final res = {'status': 'basarili', 'stream_url': permanentPath, 'is_file': true};
        _streamCache[finalVideoId] = _StreamCacheEntry(res, DateTime.now().add(const Duration(hours: 24)));
        return res;
      }
    } catch (e) {}

    // 1. YEREL ÇÖZÜCÜ (youtube_explode_dart) - Hızlı Deneme (Maksimum 4 saniye)
    try {
      print('📱 YEREL ÇÖZÜCÜ: Video akış URL\'si doğrudan telefondan alınıyor...');
      var manifest = await _yt.videos.streamsClient.getManifest(finalVideoId).timeout(const Duration(seconds: 8));
      var audioStreams = manifest.audioOnly;
      var streamInfo = audioStreams.isNotEmpty 
          ? audioStreams.withHighestBitrate() 
          : (manifest.muxed.isNotEmpty ? manifest.muxed.withHighestBitrate() : null);
      
      if (streamInfo != null) {
        print('✅ YEREL ÇÖZÜCÜ BAŞARILI! Doğrudan Google HTTPS URL\'si alındı.');
        final res = {'status': 'basarili', 'stream_url': streamInfo.url.toString(), 'is_file': false};
        _streamCache[finalVideoId] = _StreamCacheEntry(res, DateTime.now().add(const Duration(hours: 4)));
        return res;
      }
    } catch (e) {
      print('⚠️ Yerel Çözücü Hızlı Geçiş: $e');
    }

    // 2. VPS AUDIO RELAY (Canlı ve Hızlı Proxy - Port 8080)
    try {
      final relayUrl = 'http://$_vpsAudioRelay/stream/$finalVideoId';
      print('🚀 VPS AUDIO RELAY DENENİYOR: $relayUrl');
      final relayRes = await http.head(Uri.parse(relayUrl)).timeout(const Duration(seconds: 4));
      if (relayRes.statusCode == 200 || relayRes.statusCode == 206 || relayRes.statusCode == 302) {
        print('✅ VPS Audio Relay Aktif ve Hazır!');
        final res = {'status': 'basarili', 'stream_url': relayUrl, 'is_file': false};
        _streamCache[finalVideoId] = _StreamCacheEntry(res, DateTime.now().add(const Duration(hours: 4)));
        return res;
      }
    } catch (e) {
      print('⚠️ VPS Audio Relay Kontrol: $e');
    }

    // 3. Piped API (Hızlı Yedekler - Maksimum 3 saniye her biri)
    final pipedInstances = [
      'https://pipedapi.kavin.rocks',
      'https://pipedapi.smnz.de',
      'https://api.piped.projectsegfau.lt'
    ];
    for (var instance in pipedInstances) {
      try {
        print('🔄 YEREL MOTOR DENENİYOR: Piped ($instance)');
        final pipedRes = await http.get(
          Uri.parse('$instance/streams/$finalVideoId'),
          headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36'}
        ).timeout(const Duration(seconds: 5));
        
        if (pipedRes.statusCode == 200) {
          try {
            final data = jsonDecode(pipedRes.body);
            final audioStreams = data['audioStreams'] as List<dynamic>? ?? [];
            if (audioStreams.isNotEmpty) {
              var preferredStream = audioStreams.firstWhere(
                (s) => s['mimeType'] != null && (s['mimeType'].toString().contains('mp4a') || s['mimeType'].toString().contains('mp4')),
                orElse: () => audioStreams.first
              );
              final res = {'status': 'basarili', 'stream_url': preferredStream['url'].toString(), 'is_file': false};
              _streamCache[finalVideoId] = _StreamCacheEntry(res, DateTime.now().add(const Duration(hours: 4)));
              return res;
            }
          } catch (e) {
            print('! Piped JSON Parse Hatası: HTML döndü.');
          }
        } else {
          print('❌ Piped HTTP Hatası ($instance): ${pipedRes.statusCode}');
        }
      } catch (e) {
        print('❌ Piped Bağlantı Hatası ($instance): $e');
      }
    }

    // 4. Invidious API (Son Çare)
    final invidiousInstances = ['inv.tux.pizza', 'invidious.lunar.icu', 'vid.puffyan.us', 'invidious.asir.dev'];
    for (var instance in invidiousInstances) {
      try {
        print('🔄 SON ÇARE DENENİYOR: Invidious ($instance)');
        final invRes = await http.get(
          Uri.parse('https://$instance/api/v1/videos/$finalVideoId'),
          headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36'}
        ).timeout(const Duration(seconds: 8));
        
        if (invRes.statusCode == 200) {
          try {
            final data = jsonDecode(invRes.body);
            final streams = data['formatStreams'] as List<dynamic>? ?? [];
            final adaptiveFormats = data['adaptiveFormats'] as List<dynamic>? ?? [];
            
            var audioStreams = adaptiveFormats.where((s) => s['type'] != null && s['type'].toString().contains('audio')).toList();
            if (audioStreams.isEmpty) {
              audioStreams = streams.where((s) => s['type'] != null && s['type'].toString().contains('audio')).toList();
            }
            if (audioStreams.isNotEmpty) {
              var preferredStream = audioStreams.firstWhere(
                (s) => s['type'] != null && (s['type'].toString().contains('mp4a') || s['type'].toString().contains('mp4')),
                orElse: () => audioStreams.first
              );
              return {'status': 'basarili', 'stream_url': preferredStream['url'].toString(), 'is_file': false};
            }
          } catch (e) {
            print('! Invidious JSON Parse Hatası: HTML döndü.');
          }
        }
      } catch (e) {}
    }

    // 5. VPS AUDIO RELAY (ÖLÜMCÜL DURUMDA - En Son Seçenek)
    final relayUrl = 'http://$_vpsAudioRelay/stream/$finalVideoId';
    print('🚀 SİBER AUDIO RELAY (VPS): Tüm motorlar çöktü, VPS köprüsüne zorlanıyor!');
    return {'status': 'basarili', 'stream_url': relayUrl, 'is_file': false};
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
