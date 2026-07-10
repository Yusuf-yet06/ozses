import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io'; // 🎯 SİBER KALKAN: Platform Algılayıcı
import 'package:flutter/foundation.dart'; // 🎯 SİBER KALKAN: Web kontrolü
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🚀 SİBER KALKAN: Token için eklendi
import 'storage_service.dart';
import 'ytdlp_service.dart';
import '../core/platform/siber_platform.dart';
import 'package:permission_handler/permission_handler.dart';

class OzsesBridge {
  static final OzsesBridge _instance = OzsesBridge._internal();
  factory OzsesBridge() => _instance;
  OzsesBridge._internal();

final List<String> invidiousInstances = [
    'https://inv.bp.projectsegfau.lt',
    'https://invidious.perennialte.ch',
    'https://invidious.jing.rocks',
    'https://invidious.privacydev.net'
  ];
  // Üniversite interneti gelince bu adres üzerinden Victus'un beynine bağlanacağız
  static const String serverUrl = 'http://127.0.0.1:5000/control';

  Future<void> syncWithBrain(bool isAuto, double sensitivity) async {
    // 1. Veriyi paketle (JSON Formatı)
    Map<String, dynamic> data = {
      'is_autonomous': isAuto,
      'value': sensitivity.toInt(),
    };

    String jsonPacket = jsonEncode(data);

    // 2. Çevrimdışı Log (Şimdilik terminale yazar)
    print('--- ÖZSES KÖPRÜSÜ ÇALIŞIYOR ---');
    print('Paket Hazırlandı: $jsonPacket');

    /* ÜNİ İNTERNETİ GELİNCE AKTİF EDİLECEK KISIM:
       var response = await http.post(Uri.parse(serverUrl), body: jsonPacket);
    */
  }

  // 🛡️ SİBER KALKAN: Güvenlik Jetonu (Token) Üretici
  Future<Map<String, String>> _getAuthHeaders() async {
    Map<String, String> headers = {'Content-Type': 'application/json'};
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final idToken = await user.getIdToken();
        if (idToken != null) {
          headers['Authorization'] = 'Bearer $idToken';
        }
      } catch (e) {
        print('🛡️ Siber Mühür Alınamadı: $e');
      }
    }
    return headers;
  }

  // 🚀 SİBER HAMLE: Ağ Gecikme Toleransı (Retry Policy)
  Future<T> _withRetry<T>(Future<T> Function() action, {int retries = 3}) async {
    for (int i = 0; i < retries; i++) {
      try {
        return await action();
      } catch (e) {
        if (i == retries - 1) rethrow;
        print('🚀 Siber Ağ Tekrar Deneniyor (${i + 1}/$retries): $e');
        await Future.delayed(Duration(seconds: 2 * (i + 1))); // Exponential backoff
      }
    }
    throw Exception('Max retries reached');
  }

  // 🎯 SİBER HAMLE: Keşfet Frekanslarını Yakalama Modülü
  // 🚀 SİBER HAMLE: Tam Otonom Keşfet Frekansları (Dart Native)
  Future<Map<String, dynamic>> fetchKesfet({String? pageToken}) async {
    try {
      return await _withRetry(() async {
        return await SiberPlatform.instance.fetchKesfet(pageToken: pageToken);
      });
    } catch (e) {
      print('Siber Keşfet Hatası: $e');
    }
    return {};
  }

  // 🎯 SİBER HAMLE: Otonom Arama Motoru (YouTube Music Klonu İçin)
  // 🎯 SİBER HAMLE: Otonom Arama Motoru (YouTube Explode Native)
  Future<List<dynamic>> searchMusic(String query, {int limit = 15, int page = 1}) async {
    try {
      return await _withRetry(() async {
        return await SiberPlatform.instance.searchMusic(query, limit: limit, page: page);
      });
    } catch (e) {
      print('Siber Arama Hatası: $e');
    }
    return [];
  }

  // 🎯 SİBER HAMLE: Otonom Radyo Motoru (YouTube Music Up Next)
  Future<List<dynamic>> getRadio(String videoId) async {
    try {
      print('📻 Siber Radyo İstek Gönderiliyor: $videoId');
      final response = await http.get(
        Uri.parse('https://ozses.onrender.com/radio?id=$videoId'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'basarili' && data['oneriler'] != null) {
          return data['oneriler'] as List<dynamic>;
        }
      }
      print('⚠️ Siber Radyo Yanıt Hatası: ${response.statusCode}');
    } catch (e) {
      print('Siber Radyo Hatası: $e');
    }
    return [];
  }

  static final Map<String, String> _downloadStatuses = {};
  static final Map<String, String?> _downloadPaths = {};
  static final Map<String, Map<String, dynamic>> _downloadMbInfos = {};

  static HttpServer? _proxyServer;
  static int _proxyPort = 0;
  static int get proxyPort => _proxyPort;

  static final Map<String, String> _streamUrlCache = {};
  static final Map<String, Completer<String>> _pendingResolutions = {};

  static Future<void> initProxy() async {
    if (_proxyServer != null) return;
    _proxyServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _proxyPort = _proxyServer!.port;
    print('🎯 Siber Yerel Proxy Başlatıldı: Port $_proxyPort');
    
    _proxyServer!.listen((HttpRequest request) async {
      try {
        String videoId = request.uri.pathSegments.last;
        String targetUrl;

        // 🔥 KADE 1: Önbellekte var mı?
        if (_streamUrlCache.containsKey(videoId)) {
          targetUrl = _streamUrlCache[videoId]!;
        
        // 🔥 KADEME 2: Şu an başka bir istek aynı video için çözüm yapıyor mu?
        // Eğer öyleyse, o tamamlanana kadar bekle (rate limit önleme kilidi)
        } else if (_pendingResolutions.containsKey(videoId)) {
          print('⏳ Proxy: $videoId için çözüm bekleniyor...');
          targetUrl = await _pendingResolutions[videoId]!.future;
        
        // 🔥 KADEME 3: İlk istek - YoutubeExplode çağrısı yap ve kilitle
        } else {
          final completer = Completer<String>();
          _pendingResolutions[videoId] = completer;
          
          try {
            print('🎯 Proxy: SiberPlatform ile akış çözülüyor -> $videoId');
            String resolved;
            var res = await SiberPlatform.instance.getStreamUrl(videoId);
            if (res['status'] == 'basarili' && res['stream_url'] != null) {
              resolved = res['stream_url'];
            } else {
              throw Exception("Akış URL'si alınamadı: ${res['mesaj']}");
            }
            
            _streamUrlCache[videoId] = resolved;
            if (_streamUrlCache.length > 30) {
              _streamUrlCache.remove(_streamUrlCache.keys.first);
            }
            completer.complete(resolved);
            targetUrl = resolved;
            print('✅ Proxy çözüm tamamlandı: $videoId');
          } catch (e) {
            completer.completeError(e);
            _pendingResolutions.remove(videoId);
            rethrow;
          }
          _pendingResolutions.remove(videoId);
        }

        // 🚀 SİBER HAMLE: HttpClient ile 403 yediğimiz için ve YoutubeExplode 
        // 403 döndüren kırık linkler verdiği için ilk olarak KENDİ SİBER KARARGAHIMIZI (Render) deniyoruz!
        try {
          var yt = YoutubeExplode();
          Uri? finalStreamUrl;
          bool usedYoutubeExplode = false;
          dynamic ytStreamInfo;
          bool isRenderStream = false;
          
          try {
            print('🚀 İlk Hedef: Kendi Sunucumuz (Render Backend) kontrol ediliyor...');
            final renderUrl = Uri.parse('https://ozses.onrender.com/stream?id=$videoId');
            
            // Ping atıp sunucunun 502 (Uyuyan sunucu) veya 500 (Hata) dönüp dönmediğine bakıyoruz
            final pingResponse = await http.get(renderUrl).timeout(const Duration(seconds: 40));
            
            if (pingResponse.statusCode == 200 || pingResponse.statusCode == 206) {
              finalStreamUrl = renderUrl;
              isRenderStream = true;
              print('✅ Kendi Sunucumuz (Render) Kullanılıyor: $finalStreamUrl');
            } else {
              print('⚠️ Render Sunucusu Hata Döndürdü (Kod: ${pingResponse.statusCode}), YoutubeExplode denenecek...');
              throw Exception('Render HTTP ${pingResponse.statusCode}');
            }
          } catch (e) {
            print('⚠️ Render Sunucusu Yanıt Vermedi veya Hatalı: $e');
            
            try {
              var manifest = await yt.videos.streamsClient.getManifest(videoId);
              var audioStreamList = manifest.audioOnly.where((s) => s.container.name == 'mp4' || s.audioCodec.contains('mp4a')).toList();
              ytStreamInfo = audioStreamList.isNotEmpty ? audioStreamList.reduce((a, b) => a.bitrate.bitsPerSecond > b.bitrate.bitsPerSecond ? a : b) : manifest.audioOnly.withHighestBitrate();
              finalStreamUrl = ytStreamInfo.url;
              usedYoutubeExplode = true;
            } catch (ytEx) {
              print('⚠️ YoutubeExplode Hatası: $ytEx');
            }
          }
          
          if (finalStreamUrl == null || (!isRenderStream && !usedYoutubeExplode)) {
            print('🔄 SİBER KALKAN: Piped Yedek (Fallback) Devrede...');
            
            final List<String> pipedInstances = [
              'https://pipedapi.kavin.rocks',
              'https://pipedapi.moomoo.me',
              'https://pipedapi.syncpundit.io',
              'https://api.piped.projectsegfau.lt',
              'https://pipedapi.smnz.de'
            ];
            
            for (var instance in pipedInstances) {
              try {
                final response = await http.get(Uri.parse('$instance/streams/$videoId')).timeout(const Duration(seconds: 12));
                if (response.statusCode == 200) {
                  final data = jsonDecode(response.body);
                  if (data['audioStreams'] != null && (data['audioStreams'] as List).isNotEmpty) {
                    var audioStreams = data['audioStreams'] as List;
                    var bestStream = audioStreams.firstWhere(
                      (s) => s['format'] == 'M4A',
                      orElse: () => audioStreams.first,
                    );
                    finalStreamUrl = Uri.parse(bestStream['url'].toString());
                    print('✅ Piped Fallback Başarılı: $instance');
                    break;
                  }
                }
              } catch (e) {
                print('⚠️ Piped Sunucusu Hatası ($instance): $e');
              }
            }
          }
          
          if (finalStreamUrl == null) {
            print('⚠️ Tüm Piped sunucuları başarısız! INVIDIOUS API Devrede...');
            
            final List<String> invidiousInstances = [
              'https://inv.tux.pizza',
              'https://invidious.asir.dev',
              'https://invidious.io.lol',
              'https://invidious.slipfox.xyz',
              'https://inv.bp.projectsegfau.lt'
            ];
            
            for (var instance in invidiousInstances) {
              try {
                final response = await http.get(Uri.parse('$instance/api/v1/videos/$videoId')).timeout(const Duration(seconds: 10));
                if (response.statusCode == 200) {
                  final data = jsonDecode(response.body);
                  if (data['formatStreams'] != null && (data['formatStreams'] as List).isNotEmpty) {
                    var formatStreams = data['formatStreams'] as List;
                    var bestAudio = formatStreams.firstWhere(
                      (s) => s['type'] != null && s['type'].toString().contains('audio'),
                      orElse: () => formatStreams.first,
                    );
                    finalStreamUrl = Uri.parse(bestAudio['url'].toString());
                    print('✅ Invidious Fallback Başarılı: $instance');
                    break;
                  }
                }
              } catch (e) {
                print('⚠️ Invidious Sunucusu Hatası ($instance): $e');
              }
            }
          }
          
          if (finalStreamUrl == null) {
            print('⚠️ Tüm Invidious sunucuları başarısız! COBALT API Devrede...');
            
            final List<String> cobaltInstances = [
              'https://co.wuk.sh',
              'https://cobalt.q0.o.aurora.tech',
              'https://cobalt.kwiatekmateusz.pl',
              'https://cobalt.siren.party',
              'https://api.cobalt.tools'
            ];

            for (var instance in cobaltInstances) {
              try {
                // Cobalt V7 veya V8 uyumluluğu için önce V8 (kök URL) deniyoruz
                final cobaltResponse = await http.post(
                  Uri.parse(instance == 'https://co.wuk.sh' ? '$instance/api/json' : '$instance/'),
                  headers: {
                    'Accept': 'application/json',
                    'Content-Type': 'application/json',
                    'Origin': instance,
                    'Referer': '$instance/',
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
                  },
                  body: jsonEncode({
                    'url': 'https://www.youtube.com/watch?v=$videoId',
                    'aFormat': 'mp3',
                    'isAudioOnly': true,
                    'downloadMode': 'audio'
                  }),
                ).timeout(const Duration(seconds: 12));
                
                if (cobaltResponse.statusCode == 200) {
                  final data = jsonDecode(cobaltResponse.body);
                  if (data['url'] != null) {
                    finalStreamUrl = Uri.parse(data['url'].toString());
                    print('✅ Cobalt Fallback Başarılı: $finalStreamUrl ($instance)');
                    break; // Başarılıysa döngüden çık
                  }
                } else {
                  print('⚠️ Cobalt API ($instance) Hata: ${cobaltResponse.body}');
                }
              } catch (e) {
                print('⚠️ Cobalt Sunucusu Hatası ($instance): $e');
              }
            }
          }

          if (finalStreamUrl == null) {
            print('⚠️ Cobalt başarısız! KENDİ SİBER KARARGAHIMIZ (RENDER BACKEND) DEVREDE...');
            try {
              // Kendi Render sunucumuz
              final renderUrl = Uri.parse('https://ozses.onrender.com/stream?id=$videoId');
              // Sadece HEAD isteği atarak URL'nin çalışıp çalışmadığını kontrol edebiliriz
              // Ama Render direkt stream döndürdüğü için streamUrl olarak kaydediyoruz.
              finalStreamUrl = renderUrl;
              print('✅ Kendi Sunucumuz (Render) Fallback Başarılı: $finalStreamUrl');
            } catch (e) {
              print('⚠️ Kendi Sunucumuz Hatası: $e');
            }
          }
          
          if (finalStreamUrl == null) {
            throw Exception('Tüm akış motorları (YoutubeExplode + Piped + Invidious + Cobalt + Render) çöktü!');
          }
          
          Stream<List<int>> dataStream;
          
          // 🎯 SİBER KALKAN: Range Header (Parçalı İndirme) Desteği
          var client = http.Client();
          var streamRequest = http.Request('GET', finalStreamUrl!);

          var rangeHeader = request.headers.value('range');
          if (rangeHeader != null) {
            streamRequest.headers['range'] = rangeHeader;
            print('🎯 Proxy: ExoPlayer Parçalı İstek Attı: $rangeHeader');
          }

          var streamResponse = await client.send(streamRequest);
          dataStream = streamResponse.stream;

          request.response.statusCode = streamResponse.statusCode;
          streamResponse.headers.forEach((key, value) {
            if (key.toLowerCase() != 'transfer-encoding') {
              request.response.headers.set(key, value);
            }
          });
          // 🚀 ÇİFT ÇEKİRDEK (Dual-Core): Depoya kaydet
          IOSink? fileSink;
          try {
             String storagePath = await StorageService.getOzsesDownloadPath();
             String permanentPath = '$storagePath/ozses_offline_$videoId.mp4';
             var file = File(permanentPath);
             fileSink = file.openWrite();
          } catch (_) {}
          
          dataStream.listen((data) {
             try { request.response.add(data); } catch (_) {}
             try { fileSink?.add(data); } catch (_) {}
          }, onDone: () async {
             try { await request.response.close(); } catch (_) {}
             try { await fileSink?.close(); } catch (_) {}
             yt.close();
             print('✅ Proxy Akışı (ve Kaydı) Tamamlandı: $videoId');
          }, onError: (e) { print('❌ Akış Hatası (dataStream.listen): ');
             try { request.response.close(); } catch (_) {}
             try { fileSink?.close(); } catch (_) {}
             yt.close();
          });
        } catch (ytError) {
          print('❌ Proxy YoutubeExplode Akış Hatası: $ytError');
          rethrow;
        }

      } catch (e) {
        print('❌ Proxy Hatası: $e');
        try {
          request.response.statusCode = HttpStatus.internalServerError;
          await request.response.close();
        } catch (_) {}
      }
    });
  }


  Future<Map<String, dynamic>> getStreamUrl(String videoId) async {
    try {
      return await SiberPlatform.instance.getStreamUrl(videoId);
    } catch (e) {
      print('Siber Akış Çözme Hatası: $e');
      return {'status': 'hata', 'mesaj': e.toString()};
    }
  }

  // 🎯 SİBER HAMLE: Autocomplete Arama Önerileri
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      return await SiberPlatform.instance.getSearchSuggestions(query);
    } catch (e) {
      print('Siber Arama Önerisi Hatası: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> downloadMusic(String videoId, String title) async {
    _downloadStatuses[videoId] = 'indiriliyor';
    _downloadMbInfos[videoId] = {
      'downloaded_mb': '0.00',
      'total_mb': '?',
      'percent': 'Hazırlanıyor...'
    };
    
    Future.microtask(() async {
      try {
        String musicDirPath = await StorageService.getOzsesDownloadPath();
        String safeTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
        
        if (!kIsWeb && Platform.isWindows) {
          // 🚀 SİBER KALKAN: yt-dlp ile Windows üzerinde indirme
          String exePath = await YtDlpService().getExecutablePath();
          String outputTemplate = '$musicDirPath\\$safeTitle.%(ext)s';
          
          var process = await Process.start(exePath, [
            '-f', 'bestaudio[ext=m4a]/bestaudio',
            '-o', outputTemplate,
            'https://www.youtube.com/watch?v=$videoId'
          ]);

          process.stdout.transform(utf8.decoder).listen((data) {
            if (data.contains('[download]') && data.contains('%')) {
              try {
                final percentMatch = RegExp(r'(\d+\.\d+)%').firstMatch(data);
                String percent = percentMatch != null ? percentMatch.group(1)! : '?';
                
                final sizeMatch = RegExp(r'of[~ ]*(\d+\.\d+)([a-zA-Z]+)').firstMatch(data);
                String totalMb = '?';
                if (sizeMatch != null) {
                   double size = double.tryParse(sizeMatch.group(1)!) ?? 0;
                   if (sizeMatch.group(2)!.toLowerCase().contains('k')) {
                      totalMb = (size / 1024).toStringAsFixed(2);
                   } else if (sizeMatch.group(2)!.toLowerCase().contains('g')) {
                      totalMb = (size * 1024).toStringAsFixed(2);
                   } else {
                      totalMb = size.toStringAsFixed(2);
                   }
                }
                
                _downloadMbInfos[videoId] = {
                  'downloaded_mb': '...',
                  'total_mb': totalMb,
                  'percent': '%$percent'
                };
              } catch (e) {
                // Ayrıştırma hatası, devam et
              }
            }
          });

          var exitCode = await process.exitCode;
          if (exitCode == 0) {
            // İndirilen dosyanın tam adını bul (m4a veya webm olabilir)
            File downloadedFile = File('$musicDirPath\\$safeTitle.m4a');
            if (!await downloadedFile.exists()) {
               downloadedFile = File('$musicDirPath\\$safeTitle.webm');
            }
            
            _downloadPaths[videoId] = downloadedFile.path;
            _downloadStatuses[videoId] = 'basarili';
            _downloadMbInfos.remove(videoId);
            print('🚀 İndirme Tamamlandı: ${downloadedFile.path}');
          } else {
            _downloadStatuses[videoId] = 'hata';
            print('❌ yt-dlp indirme hatası, exit code: $exitCode');
          }
          return;
        }

        // 🎯 SİBER HAMLE: Artık YoutubeExplode yerine kendi sağlamlaştırdığımız getStreamUrl'yi kullanıyoruz
        final streamInfo = await getStreamUrl(videoId);
        if (streamInfo['status'] != 'basarili' || streamInfo['stream_url'] == null) {
          _downloadStatuses[videoId] = 'hata';
          print("❌ Siber İndirme Hatası: Akış URL'si alınamadı!");
          return;
        }
        
        String targetUrl = streamInfo['stream_url'];
        String ext = 'm4a'; // Piped ve YT genellikle m4a döndürür
        
        String filePath = '$musicDirPath/$safeTitle.$ext';
        if (!kIsWeb && Platform.isWindows) {
          filePath = '$musicDirPath\\$safeTitle.$ext';
        }
        
        // 🎯 SİBER KALKAN: İndirme Öncesi İzin Kontrolü (Android)
        if (!kIsWeb && Platform.isAndroid) {
          var status = await Permission.storage.status;
          if (!status.isGranted) await Permission.storage.request();
          
          var manageStatus = await Permission.manageExternalStorage.status;
          if (!manageStatus.isGranted) await Permission.manageExternalStorage.request();
        }
        
        File file = File(filePath);
        if (!await file.parent.exists()) {
           await file.parent.create(recursive: true);
        }
        var fileStream = file.openWrite();
        
        // 🎯 Yerleşik HTTP İstemcisi ile Stream (Akış) İndirme
        final request = http.Request('GET', Uri.parse(targetUrl));
        // Bazı sunucular User-Agent ister
        request.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';
        request.headers['Referer'] = 'https://www.youtube.com/';
        final response = await http.Client().send(request).timeout(const Duration(seconds: 15));
        
        if (response.statusCode != 200 && response.statusCode != 206) {
           _downloadStatuses[videoId] = 'hata';
           print('❌ İndirme Sunucu Hatası: ${response.statusCode}');
           _downloadMbInfos[videoId] = {'percent': 'Hata: ${response.statusCode}'};
           return;
        }

        int totalBytes = response.contentLength ?? 0;
        int downloadedBytes = 0;
        
        await response.stream.map((chunk) {
          downloadedBytes += chunk.length;
          
          if (totalBytes > 0) {
            double progress = downloadedBytes / totalBytes;
            _downloadStatuses[videoId] = 'indiriliyor';
            _downloadMbInfos[videoId] = {
              'downloaded_mb': (downloadedBytes / (1024 * 1024)).toStringAsFixed(2),
              'total_mb': (totalBytes / (1024 * 1024)).toStringAsFixed(2),
              'percent': '${(progress * 100).toStringAsFixed(0)}%'
            };
          } else {
            _downloadStatuses[videoId] = 'indiriliyor';
            _downloadMbInfos[videoId] = {
              'downloaded_mb': (downloadedBytes / (1024 * 1024)).toStringAsFixed(2),
              'total_mb': '?',
              'percent': 'İniyor...'
            };
          }
          return chunk;
        }).pipe(fileStream);
        
        _downloadPaths[videoId] = filePath;
        _downloadStatuses[videoId] = 'basarili';
        _downloadMbInfos.remove(videoId);
        print('✅ İndirme Tamamlandı: $filePath');
      } catch (e) {
        print('❌ Siber İndirme Hatası: $e');
        _downloadStatuses[videoId] = 'hata';
        _downloadMbInfos[videoId] = {'percent': 'Hata: ${e.toString().split('\n')[0]}'};
      }
    });

    return {'status': 'basladi'};
  }

  // 🎯 SİBER HAMLE: İndirme Durumu Sorgulayıcı (NATIVE)
  Future<Map<String, dynamic>> getDownloadStatus(String videoId) async {
    String status = _downloadStatuses[videoId] ?? 'bilinmiyor';
    String? filePath = _downloadPaths[videoId];
    Map<String, dynamic> mbInfo = _downloadMbInfos[videoId] ?? {};
    
    return {
      'status': status, 
      'file_path': filePath,
      'percent': mbInfo['percent'],
      'downloaded_mb': mbInfo['downloaded_mb'],
      'total_mb': mbInfo['total_mb']
    };
  }

  // 🎯 SİBER HAMLE: Derin Ağ ve Yapay Zeka Söz Çıkarıcı
  // 🎯 SİBER HAMLE: Tam Otonom Youtube Altyazı Sökücü (Native Söz Motoru)
  Future<String?> getSiberLyrics(String videoId, String query) async {
    try {
      return await _withRetry(() async {
        var yt = YoutubeExplode();
        var manifest = await yt.videos.closedCaptions.getManifest(videoId);
        
        if (manifest.tracks.isNotEmpty) {
          var trackInfo = manifest.tracks.firstWhere(
              (t) => t.language.code == 'tr' || t.language.code == 'en',
              orElse: () => manifest.tracks.first);
              
          var track = await yt.videos.closedCaptions.get(trackInfo);
          
          StringBuffer lrcBuffer = StringBuffer();
          for (var caption in track.captions) {
            var start = caption.offset;
            var min = start.inMinutes.toString().padLeft(2, '0');
            var sec = (start.inSeconds % 60).toString().padLeft(2, '0');
            var ms = (start.inMilliseconds % 1000).toString().padLeft(3, '0').substring(0, 2);
            lrcBuffer.writeln('[$min:$sec.$ms] ${caption.text.replaceAll('\\n', ' ')}');
          }
          yt.close();
          
          String lrcStr = lrcBuffer.toString();
          if (lrcStr.isNotEmpty) return lrcStr;
        }
        yt.close();
        return null;
      });
    } catch (e) {
      print('🛑 Siber YouTube Lirik Hatası: $e');
    }
    return null;
  }

  // 🎯 SİBER HAMLE: Profil Doğrulama Kodu Gönder
  Future<Map<String, dynamic>> sendSiberCode(String email) async {
    String url = 'http://127.0.0.1:8000/siber-kod-gonder';
    if (!kIsWeb && Platform.isAndroid) {
      url = 'http://10.0.2.2:8000/siber-kod-gonder';
    }
    try {
      var response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {}
    return {'status': 'hata', 'mesaj': 'Bağlantı koptu'};
  }

  // 🎯 SİBER HAMLE: Kodu Doğrula ve Kayıt Ol
  Future<Map<String, dynamic>> verifyAndRegister(
      String email, String username, String password, String code) async {
    String url = 'http://127.0.0.1:8000/siber-dogrula-kayit';
    if (!kIsWeb && Platform.isAndroid) {
      url = 'http://10.0.2.2:8000/siber-dogrula-kayit';
    }
    try {
      var response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'username': username,
              'password': password,
              'code': code
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {}
    return {'status': 'hata', 'mesaj': 'Bağlantı koptu'};
  }
}

// 🎯 SİBER HAMLE: Isolate (Arka plan işçisi) için ana işlemciden bağımsız dönüştürücü
Map<String, dynamic> _decodeAndParseJsonMap(Uint8List bytes) {
  return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
}
