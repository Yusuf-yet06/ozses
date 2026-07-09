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
    print('--- ÖZSES KEŞFET RADARI BAŞLATILIYOR (RENDER BACKEND) ---');
    final List<String> discoveryTerms = [
      'türkçe pop en çok dinlenenler official audio',
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
      final response = await http.get(
        Uri.parse('https://ozses.onrender.com/search?q=${Uri.encodeComponent(query)}')
      ).timeout(const Duration(seconds: 45)); // Render uyanması (cold start) için 45 sn
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'basarili' && data['oneriler'] != null) {
          return {'status': 'basarili', 'oneriler': data['oneriler'], 'nextPageToken': ''};
        }
      }
    } catch (e) {
      print('❌ Siber Backend Keşfet Hatası: $e');
    }
    return {'status': 'hata', 'oneriler': [], 'nextPageToken': ''};
  }

  @override
  Future<List<dynamic>> searchMusic(String query, {int limit = 15, int page = 1}) async {
    print('--- SİBER ARAMA BAŞLATILIYOR (RENDER BACKEND) ---');
    try {
      final response = await http.get(
        Uri.parse('https://ozses.onrender.com/search?q=${Uri.encodeComponent(query)}')
      ).timeout(const Duration(seconds: 45)); // Render uyanması (cold start) için 45 sn
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'basarili' && data['oneriler'] != null) {
          return data['oneriler'];
        }
      }
    } catch (e) {
      print('❌ Siber Backend Arama Hatası: $e');
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

    // SİBER HIZLANDIRICI: Eğer kalıcı dosya yoksa, vakit kaybetmeden direkt proxy'e devret!
    // Piped ve Cobalt sunucularını beklemek 3-8 saniye gecikme yaratıyordu.
    // Artık Proxy (services.dart) içerisinde YoutubeExplode ile saniyesinde çekip çalıyoruz.
    return {'status': 'basarili', 'stream_url': 'proxy_will_handle_it', 'is_file': false};
    
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
