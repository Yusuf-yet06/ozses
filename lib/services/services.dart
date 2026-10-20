import 'spotify_service.dart';
import 'youtube_api_service.dart';
import '../utils/search_utils.dart';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'dart:io'; // ÄŸÅ¸ÂÂ¯ SÃ„Â°BER KALKAN: Platform AlgÃ„Â±layÃ„Â±cÃ„Â±
import 'dart:convert';
import 'package:flutter/foundation.dart'; // ÄŸÅ¸ÂÂ¯ SÃ„Â°BER KALKAN: Web kontrolÃƒÂ¼
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ÄŸÅ¸Å¡â‚¬ SÃ„Â°BER KALKAN: Token iÃƒÂ§in eklendi
import 'storage_service.dart';
import 'ytdlp_service.dart';
import '../core/platform/siber_platform.dart';
import 'package:permission_handler/permission_handler.dart';
import 'siber_ip_service.dart'; // ÄŸÅ¸ÂÂ¯ IP YÃƒâ€“NETÃ„Â°MÃ„Â°
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
  // ÃƒÅ“niversite interneti gelince bu adres ÃƒÂ¼zerinden Victus'un beynine baÃ„Å¸lanacaÃ„Å¸Ã„Â±z
  static const String serverUrl = 'http://127.0.0.1:5000/control';

  Future<void> syncWithBrain(bool isAuto, double sensitivity) async {
    // 1. Veriyi paketle (JSON FormatÃ„Â±)
    Map<String, dynamic> data = {
      'is_autonomous': isAuto,
      'value': sensitivity.toInt(),
    };

    String jsonPacket = jsonEncode(data);

    // 2. Ãƒâ€¡evrimdÃ„Â±Ã…Å¸Ã„Â± Log (Ã…Âimdilik terminale yazar)
    print('--- Ãƒâ€“ZSES KÃƒâ€“PRÃƒÅ“SÃƒÅ“ Ãƒâ€¡ALIÃ…ÂIYOR ---');
    print('Paket HazÃ„Â±rlandÃ„Â±: $jsonPacket');

    /* ÃƒÅ“NÃ„Â° Ã„Â°NTERNETÃ„Â° GELÃ„Â°NCE AKTÃ„Â°F EDÃ„Â°LECEK KISIM:
       var response = await http.post(Uri.parse(serverUrl), body: jsonPacket);
    */
  }

  // ÄŸÅ¸â€ºÂ¡Ã¯Â¸Â SÃ„Â°BER KALKAN: GÃƒÂ¼venlik Jetonu (Token) ÃƒÅ“retici
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
        print('ÄŸÅ¸â€ºÂ¡Ã¯Â¸Â Siber MÃƒÂ¼hÃƒÂ¼r AlÃ„Â±namadÃ„Â±: $e');
      }
    }
    return headers;
  }

  // ÄŸÅ¸Å¡â‚¬ SÃ„Â°BER HAMLE: AÃ„Å¸ Gecikme ToleransÃ„Â± (Retry Policy)
  Future<T> _withRetry<T>(Future<T> Function() action, {int retries = 3}) async {
    for (int i = 0; i < retries; i++) {
      try {
        return await action();
      } catch (e) {
        if (i == retries - 1) rethrow;
        print('ÄŸÅ¸Å¡â‚¬ Siber AÃ„Å¸ Tekrar Deneniyor (${i + 1}/$retries): $e');
        await Future.delayed(Duration(seconds: 2 * (i + 1))); // Exponential backoff
      }
    }
    throw Exception('Max retries reached');
  }

  // 🚀 SİBER HAMLE: Tam Otonom Keşfet Frekansları (Spotify Native)
  Future<Map<String, dynamic>> fetchKesfet({String? pageToken}) async {
    // 🌐 Web ortamında Spotify CORS engeline takılmamak için doğrudan SiberPlatform (YouTube API) kullan
    if (kIsWeb) {
      return await SiberPlatform.instance.fetchKesfet(pageToken: pageToken);
    }
    try {
      final items = await SpotifyService.instance.getTop50Turkey();
      if (items.isEmpty) {
        throw Exception('Spotify Keşfet listesi boş döndü, yedek motora geçiliyor.');
      }
      return {
        'status': 'basarili',
        'oneriler': items,
        'nextPageToken': '',
      };
    } catch (e) {
      print('Siber Keşfet Hatası (Spotify): $e');
      // Fallback if Spotify fails
      return await _withRetry(() async {
        return await SiberPlatform.instance.fetchKesfet(pageToken: pageToken);
      });
    }
  }

  // 🚀 Otonom Arama Motoru (Türkçe/Karakter Toleranslı & Spotify Destekli)
  Future<List<dynamic>> searchMusic(String query, {int limit = 15, int page = 1, bool onlyMusic = true}) async {
    try {
      if (query.trim().isEmpty) return [];
      
      // 🌐 Web ortamında Spotify CORS engeline takılmamak için doğrudan SiberPlatform kullan
      if (kIsWeb) {
        return await SiberPlatform.instance.searchMusic(query, limit: limit, page: page, onlyMusic: onlyMusic);
      }
      
      // Genel arama (Podcast/Video) seçildiyse Spotify'ı tamamen atla, doğrudan YT'ye git!
      if (!onlyMusic) {
        print('🌍 Radar: Genel arama modu aktif, Spotify es geçiliyor...');
        return await SiberPlatform.instance.searchMusic(query, onlyMusic: false);
      }

      // 🎯 TÜRKÇE & BÜYÜK/KÜÇÜK HARF UYUMLU ARAMA SORGUSU
      final trCleanQuery = SearchUtils.toTurkishLower(query)
          .replaceAll('2026', '')
          .replaceAll('hit', '')
          .replaceAll('şarkıları', '')
          .replaceAll('popüler albüm', 'pop')
          .replaceAll('türkçe', '')
          .trim();

      String targetQuery = trCleanQuery.isNotEmpty ? trCleanQuery : query.trim();

      print('🔍 [SPOTIFY] Aranıyor: $targetQuery');
      var items = await SpotifyService.instance.searchTracks(targetQuery);
      
      // Eğer Türkçe harfle bulunamazsa, normalize edilmiş varyantı dene (Örn: "isik" <-> "ışık")
      if (items.isEmpty) {
        final normQuery = SearchUtils.normalizeForSearch(targetQuery);
        if (normQuery != targetQuery && normQuery.isNotEmpty) {
          print('🔍 [SPOTIFY - TOLERANS DENEMESİ] Aranıyor: $normQuery');
          items = await SpotifyService.instance.searchTracks(normQuery);
        }
      }

      if (items.isEmpty) {
        // Fallback: YouTube aramasına gönder
        return await SiberPlatform.instance.searchMusic(query, onlyMusic: onlyMusic);
      }
      return items;
    } catch (e) {
      print('Arama Hatası (Spotify): $e');
      return await SiberPlatform.instance.searchMusic(query, onlyMusic: onlyMusic);
    }
  }

  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      final cleanQ = SearchUtils.toTurkishLower(query);
      var items = await SpotifyService.instance.searchTracks(cleanQ);

      if (items.isEmpty) {
        final normQ = SearchUtils.normalizeForSearch(query);
        if (normQ != cleanQ && normQ.isNotEmpty) {
          items = await SpotifyService.instance.searchTracks(normQ);
        }
      }

      if (items.isNotEmpty) {
        return items.map((e) {
          final t = (e['title'] ?? '').toString();
          final c = (e['channel'] ?? '').toString();
          return (c.isNotEmpty && c != 'Bilinmeyen' && c != 'Victus V7')
              ? '$c - $t'
              : t;
        }).where((s) => s.isNotEmpty).take(6).toList();
      }
    } catch (e) {
      // Fallback
    }
    return await SiberPlatform.instance.getSearchSuggestions(query);
  }

  Future<List<dynamic>> getRadio(
    String videoId, {
    String? title,
    String? artist,
    String? genre,
  }) async {
    final List<dynamic> results = [];
    final Set<String> seenIds = {videoId};

    // 🛡️ SİBER FİLTRE: İki şarkı başlığının aynı parçanın farklı yüklemeleri olup olmadığını anlar
    bool isDuplicateTrack(String t1, String t2) {
      String clean(String s) => s
          .toLowerCase()
          .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '')
          .replaceAll(RegExp(r'[^a-z0-9ğüşıöç\s]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final c1 = clean(t1);
      final c2 = clean(t2);
      if (c1.isEmpty || c2.isEmpty) return false;
      if (c1 == c2) return true;
      if (c1.contains(c2) || c2.contains(c1)) {
        final words1 = c1.split(' ').where((w) => w.length > 2).toSet();
        final words2 = c2.split(' ').where((w) => w.length > 2).toSet();
        if (words1.isNotEmpty && words2.isNotEmpty) {
          final common = words1.intersection(words2);
          if (common.length >= 2 || common.length == words1.length || common.length == words2.length) {
            return true;
          }
        }
      }
      return false;
    }

    // 1. ZIRH: Resmi YouTube API ile Hızlı & İlgili Şarkı Arama (200ms)
    try {
      String searchQuery = '';
      if (artist != null && artist.isNotEmpty && artist != 'Victus V7' && artist != 'Bilinmeyen') {
        searchQuery = '$artist mix';
      } else if (title != null && title.isNotEmpty && title != 'Bilinmeyen') {
        searchQuery = '$title radyo';
      } else if (genre != null && genre.isNotEmpty) {
        searchQuery = '$genre şarkılar';
      }

      if (searchQuery.isNotEmpty) {
        print('📻 Siber Otonom Radyo (YouTube API): $searchQuery');
        final apiResults = await YoutubeApiService.searchMusic(searchQuery, onlyMusic: true);
        for (var item in apiResults) {
          final id = item['videoId'];
          final t = item['title'] ?? '';
          if (id != null && !seenIds.contains(id)) {
            if (title != null && isDuplicateTrack(title, t)) {
              continue; // Aynı şarkının farklı kanallardaki kopyasını atla!
            }
            seenIds.add(id);
            results.add({
              'id': id,
              'title': t,
              'channel': item['channel'] ?? 'ÖZSES Müzik',
              'thumbnail': item['thumbnail'] ?? '',
            });
          }
        }
        if (results.length >= 8) {
          print('✅ YouTube API Radyo: ${results.length} benzersiz ilgili şarkı bulundu');
          return results.take(15).toList();
        }
      }
    } catch (e) {
      print('⚠️ YouTube API Radyo Arama Hatası: $e');
    }

    // 2. ZIRH: Eğer VPS ayaktaysa (en fazla 2 sn bekle, asla 15 sn askıda kalmaz)
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final res = await http.get(
          Uri.parse('$_vpsBase/api/radio/$videoId?apikey=$_vpsApiKey'),
        ).timeout(const Duration(milliseconds: 2000));
        
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          if (data['status'] == 'basarili' && data['oneriler'] != null) {
            final List<dynamic> items = (data['oneriler'] as List).take(15).toList();
            for (var item in items) {
              final id = item['id'];
              final t = item['title'] ?? '';
              if (id != null && !seenIds.contains(id)) {
                if (title != null && isDuplicateTrack(title, t)) continue;
                seenIds.add(id);
                results.add(item);
              }
            }
            if (results.length >= 5) {
              return results.take(15).toList();
            }
          }
        }
      } catch (_) {}
    }

    // 3. ZIRH: YoutubeExplode (Yerel Yedek - 4 sn timeout)
    try {
      print('📻 Siber Radyo (Yerel Explode): $videoId');
      var yt = YoutubeExplode();
      var v = await yt.videos.get(videoId).timeout(const Duration(seconds: 4));
      var related = await yt.videos.getRelatedVideos(v).timeout(const Duration(seconds: 4));
      if (related != null) {
        for (var video in related) {
          final id = video.id.value;
          final t = video.title;
          if (!seenIds.contains(id)) {
            if (title != null && isDuplicateTrack(title, t)) continue;
            seenIds.add(id);
            results.add({
              'id': id,
              'title': t,
              'channel': video.author,
              'thumbnail': video.thumbnails.highResUrl,
            });
          }
        }
      }
      yt.close();
      if (results.isNotEmpty) {
        return results.take(15).toList();
      }
    } catch (e) {
      print('❌ YoutubeExplode Radyo Hatası: $e');
    }

    return results;
  }

  static final Map<String, String> _downloadStatuses = {};
  static final Map<String, String?> _downloadPaths = {};
  static final Map<String, Map<String, dynamic>> _downloadMbInfos = {};

  static HttpServer? _proxyServer;
  static int _proxyPort = 0;
  static int get proxyPort => _proxyPort;

  static final Map<String, String> _streamUrlCache = {};
  static void cacheStreamUrl(String videoId, String url) {
    _streamUrlCache[videoId] = url;
    if (_streamUrlCache.length > 30) {
      _streamUrlCache.remove(_streamUrlCache.keys.first);
    }
  }
  static final Map<String, Completer<String>> _pendingResolutions = {};

  static Future<void> initProxy() async {
    if (_proxyServer != null) return;
    _proxyServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _proxyPort = _proxyServer!.port;
    print('ÄŸÅ¸ÂÂ¯ Siber Yerel Proxy BaÃ…Å¸latÃ„Â±ldÃ„Â±: Port $_proxyPort');
    
    _proxyServer!.listen((HttpRequest request) async {
      try {
        String videoId = request.uri.pathSegments.last;
        String targetUrl;

        // ÄŸÅ¸â€Â¥ KADE 1: Ãƒâ€“nbellekte var mÃ„Â±?
        if (_streamUrlCache.containsKey(videoId)) {
          targetUrl = _streamUrlCache[videoId]!;
        
        // ÄŸÅ¸â€Â¥ KADEME 2: Ã…Âu an baÃ…Å¸ka bir istek aynÃ„Â± video iÃƒÂ§in ÃƒÂ§ÃƒÂ¶zÃƒÂ¼m yapÃ„Â±yor mu?
        // EÃ„Å¸er ÃƒÂ¶yleyse, o tamamlanana kadar bekle (rate limit ÃƒÂ¶nleme kilidi)
        } else if (_pendingResolutions.containsKey(videoId)) {
          print('Ã¢ÂÂ³ Proxy: $videoId iÃƒÂ§in ÃƒÂ§ÃƒÂ¶zÃƒÂ¼m bekleniyor...');
          targetUrl = await _pendingResolutions[videoId]!.future;
        
        // ÄŸÅ¸â€Â¥ KADEME 3: Ã„Â°lk istek - YoutubeExplode ÃƒÂ§aÃ„Å¸rÃ„Â±sÃ„Â± yap ve kilitle
        } else {
          final completer = Completer<String>();
          _pendingResolutions[videoId] = completer;
          
          try {
            print('ÄŸÅ¸ÂÂ¯ Proxy: SiberPlatform ile akÃ„Â±Ã…Å¸ ÃƒÂ§ÃƒÂ¶zÃƒÂ¼lÃƒÂ¼yor -> $videoId');
            String resolved;
            var res = await SiberPlatform.instance.getStreamUrl(videoId);
            if (res['status'] == 'basarili' && res['stream_url'] != null) {
              resolved = res['stream_url'];
            } else {
              throw Exception("AkÃ„Â±Ã…Å¸ URL'si alÃ„Â±namadÃ„Â±: ${res['mesaj']}");
            }
            
            _streamUrlCache[videoId] = resolved;
            if (_streamUrlCache.length > 30) {
              _streamUrlCache.remove(_streamUrlCache.keys.first);
            }
            completer.complete(resolved);
            targetUrl = resolved;
            print('Ã¢Å“â€¦ Proxy ÃƒÂ§ÃƒÂ¶zÃƒÂ¼m tamamlandÃ„Â±: $videoId');
          } catch (e) {
            completer.completeError(e);
            _pendingResolutions.remove(videoId);
            rethrow;
          }
          _pendingResolutions.remove(videoId);
        }

        // ÄŸÅ¸Å¡â‚¬ SÃ„Â°BER HAMLE: SadeleÃ…Å¸tirilmiÃ…Å¸ Proxy AkÃ„Â±Ã…Å¸ Motoru V4
        // URL zaten ÃƒÂ§ÃƒÂ¶zÃƒÂ¼lmÃƒÂ¼Ã…Å¸ ve cache'lenmiÃ…Å¸. Proxy sadece fetch + 403 retry yapÃ„Â±yor.
        try {
          var client = http.Client();
          var rangeHeader = request.headers.value('range');
          http.StreamedResponse? streamResponse;

          Future<http.StreamedResponse?> tryFetchStream(Uri url) async {
             try {
                var streamRequest = http.Request('GET', url);
                streamRequest.headers['User-Agent'] = 'com.google.ios.youtube/19.28.1 (iPhone16,2; U; CPU iOS 17_5_1 like Mac OS X;)';
                streamRequest.headers['Accept'] = '*/*';
                streamRequest.headers['Connection'] = 'keep-alive';
                streamRequest.headers['Accept-Encoding'] = 'identity';
                 
                if (rangeHeader != null) {
                    streamRequest.headers['Range'] = rangeHeader;
                  } else {
                    streamRequest.headers['Range'] = 'bytes=0-';
                }
                  var resp = await client.send(streamRequest).timeout(const Duration(seconds: 7));
                if (resp.statusCode == 200 || resp.statusCode == 206) {
                   return resp;
                } else {
                   print('Ã¢Å¡Â Ã¯Â¸Â Sunucu ${resp.statusCode} dÃƒÂ¶ndÃƒÂ¼rdÃƒÂ¼: $url');
                }
             } catch (e) {
                print('Ã¢Å¡Â Ã¯Â¸Â AkÃ„Â±Ã…Å¸ isteÃ„Å¸i baÃ…Å¸arÃ„Â±sÃ„Â±z: $e');
             }
             return null;
          }

          // ÄŸÅ¸ÂÂ¯ 1. ADIM: Ãƒâ€“nbellekteki URL ile doÃ„Å¸rudan baÃ„Å¸lan
          if (targetUrl.isNotEmpty) {
             print('ÄŸÅ¸ÂÂ¯ Proxy: Ãƒâ€“nbellekteki URL deneniyor...');
             streamResponse = await tryFetchStream(Uri.parse(targetUrl));
             if (streamResponse != null) {
                 print('Ã¢Å“â€¦ Proxy: Ãƒâ€“nbellekteki URL baÃ…Å¸arÃ„Â±yla baÃ…Å¸landÃ„Â±!');
             }
          }


            // ğŸŽ¯ 3. ADIM: YoutubeExplode Android Music
            if (streamResponse == null) {
              print('ğŸŽ¯ Proxy: YoutubeExplode AndroidMusic deneniyor...');
              var yt = YoutubeExplode();
              try {
                  var manifest = await yt.videos.streamsClient
                      .getManifest(videoId, ytClients: [YoutubeApiClient.androidMusic, YoutubeApiClient.ios, YoutubeApiClient.androidVr, YoutubeApiClient.tv])
                      .timeout(const Duration(seconds: 5));
                  var audioStreamList = manifest.audioOnly
                      .where((s) => s.container.name == 'mp4' || s.audioCodec.contains('mp4a'))
                      .toList();
                  if (audioStreamList.isEmpty) {
                      
                      if (Platform.isWindows) {
                          print('âš ï¸ Proxy: Windows iÃ§in uyumlu mp4a bulunamadÄ±, sessizliÄŸi Ã¶nlemek iÃ§in Piped API\'ye devrediliyor!');
                          throw Exception('Windows uyumlu MP4 yok');
                      } else {
                          audioStreamList = manifest.audioOnly.toList();
                      }
                  }
                  if (audioStreamList.isNotEmpty) {
                      
                      var ytStreamInfo = audioStreamList.reduce((a, b) => a.bitrate.bitsPerSecond > b.bitrate.bitsPerSecond ? a : b);
                      
                      streamResponse = await tryFetchStream(ytStreamInfo.url);
                      if (streamResponse != null) {
                        _streamUrlCache[videoId] = ytStreamInfo.url.toString();
                        print('âœ… Proxy: YoutubeExplode AndroidMusic baÅŸarÄ±lÄ±!');
                      }
                  }
              } catch (e) {
                  print('âš ï¸ Proxy YoutubeExplode hatasÄ±: $e');
              }
              yt.close();
            }


            // ğŸ¯ 4. ADIM: GÃ¼Ã§lÃ¼ Piped API YedeÄŸi (HTTP 302 YÃ¶nlendirmesi)
            if (streamResponse == null) {
              print('ğŸ¯ Proxy: TÃ¼m yÃ¶ntemler tÃ¼kendi, son Ã§are PIPED API YÃ¶nlendirmesi deneniyor...');
              bool pipedSuccess = false;
                  final pipedInstances = [
                    'https://pipedapi.kavin.rocks',
                    'https://pipedapi.smnz.de',
                    'https://pipedapi.lunar.icu'
                  ];
                  for (var instance in pipedInstances) {
                    if (pipedSuccess) break;
                    try {
                      final res = await http.get(Uri.parse('$instance/streams/$videoId')).timeout(const Duration(seconds: 4));
                      if (res.statusCode == 200) {
                        final data = jsonDecode(res.body);
                        final audioStreams = data['audioStreams'] as List<dynamic>? ?? [];
                        if (audioStreams.isNotEmpty) {
                          var safeStream = audioStreams.firstWhere(
                              (s) => s['mimeType'] != null && s['mimeType'].toString().contains('mp4'),
                              orElse: () => audioStreams.first);
                          Uri pipedUrl = Uri.parse(safeStream['url'].toString());
                          print('âœ… Proxy: Piped API baÅŸarÄ±lÄ± ($instance)! OynatÄ±cÄ± 302 Redirect ile yÃ¶nlendiriliyor: $pipedUrl');
                          
                          request.response.statusCode = 302;
                          request.response.headers.set('Location', pipedUrl.toString());
                          await request.response.close();
                          pipedSuccess = true;
                          return;
                        }
                      }
                    } catch (e) {
                      print('âš ï¸ Piped YÃ¶nlendirme HatasÄ± ($instance): $e');
                    }
                  }
                  
                  // Invidious Fallback!
                  if (!pipedSuccess) {
                    final invidiousInstances = ['inv.tux.pizza', 'invidious.nerdvpn.de', 'invidious.lunar.icu'];
                    for (var instance in invidiousInstances) {
                      try {
                        final invRes = await http.get(Uri.parse('https://$instance/api/v1/videos/$videoId')).timeout(const Duration(seconds: 4));
                        if (invRes.statusCode == 200) {
                          final data = jsonDecode(invRes.body);
                          final adaptiveFormats = data['adaptiveFormats'] as List<dynamic>? ?? [];
                          var audioStreams = adaptiveFormats.where((s) => s['type'] != null && s['type'].toString().contains('audio')).toList();
                          if (audioStreams.isNotEmpty) {
                            var preferredStream = audioStreams.firstWhere(
                              (s) => s['type'] != null && s['type'].toString().contains('mp4'),
                              orElse: () => audioStreams.first
                            );
                            Uri invUrl = Uri.parse(preferredStream['url'].toString());
                            print('âœ… Proxy: Invidious baÅŸarÄ±lÄ± ($instance)! OynatÄ±cÄ± 302 Redirect ile yÃ¶nlendiriliyor: $invUrl');
                            request.response.statusCode = 302;
                            request.response.headers.set('Location', invUrl.toString());
                            await request.response.close();
                            return;
                          }
                        }
                      } catch (e) {
                        print('âš ï¸ Invidious YÃ¶nlendirme HatasÄ± ($instance): $e');
                      }
                    }
                  }
            }
          if (streamResponse == null) {
             print('Ã¢ÂÅ’ HATA: TÃƒÂ¼m akÃ„Â±Ã…Å¸ motorlarÃ„Â± ÃƒÂ§ÃƒÂ¶ktÃƒÂ¼!');
             try { request.response.statusCode = 500; await request.response.close(); } catch (_) {}
             return;
          }
          

            // ğŸ¯ SÄ°BER HAMLE: Dart Ã¼zerinden veri akÄ±tmak (Piping) Windows'ta Media Foundation'Ä± Ã§Ã¶kertiyordu!
            // Bunun yerine, bulduÄŸumuz URL'nin Ã§alÄ±ÅŸtÄ±ÄŸÄ±nÄ± doÄŸruladÄ±ktan sonra oynatÄ±cÄ±ya HTTP 302 Redirect atÄ±yoruz!
            String finalStreamUrl = streamResponse.request!.url.toString();
            
            print('âœ… Proxy: YÃ¶nlendirme URLsi hazÄ±r! OynatÄ±cÄ±ya 302 Redirect atÄ±lÄ±yor...');
            try {
              request.response.statusCode = 302;
              request.response.headers.set('Location', finalStreamUrl);
              await request.response.close();
            } catch (e) {
              print('âš ï¸  Proxy Redirect HatasÄ±: $e');
            }
            
            // Veriyi tÃ¼ketmemiz lazÄ±m yoksa bellek sÄ±zdÄ±rÄ±r.
            try {
              streamResponse.stream.listen((_) {}).cancel();
            } catch (_) {}
        } catch (ytError) {
          print('Ã¢Â Å’ Proxy AkÃ„Â±Ã…Å¸ HatasÃ„Â±: $ytError');
          rethrow;
        }

      } catch (e) {
        print('Ã¢Â Å’ Proxy HatasÃ„Â±: $e');
        try {
          request.response.statusCode = HttpStatus.internalServerError;
          await request.response.close();
        } catch (_) {}
      }
    });
  }


  // 🔥 VPS Karargah endpoint'i
  static const String _vpsBase = 'http://167.172.190.129:8080';
  static const String _vpsApiKey = 'siber_secret_key_v7';

  // 🚀 SİBER RADAR: Arka planda sessizce akış URL'si çöz ve RAM'e al (0 ms geçiş)
  void preWarm(String videoId) {
    if (videoId.isEmpty) return;
    final cleanId = videoId.startsWith('yt:') ? videoId.substring(3) : videoId;
    SiberPlatform.instance.preWarm(cleanId);
    getStreamUrl(cleanId).catchError((_) => <String, dynamic>{});
  }

  Future<Map<String, dynamic>> getStreamUrl(String videoId) async {
    // 🌐 Web ve 🖥️ PC'de SiberPlatform'u kullan
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      try {
        return await SiberPlatform.instance.getStreamUrl(videoId);
      } catch (e) {
        print('❌ Stream Hatası: $e');
        return {'status': 'hata', 'mesaj': e.toString()};
      }
    }
    
    // 📱 Mobilde Hibrid (Giydirme) Mimari
    try {
      final encodedId = Uri.encodeComponent(videoId);
      
      // 1. ÖNCÜ BİRLİK (HIZ - VisionOS Yerel Çözücü)
      try {
        final SiberPlatform siber = SiberPlatform.instance;
        final res = await siber.getStreamUrl(videoId);
        if (res['status'] == 'basarili' && res['stream_url'] != null) {
          print('✅ ÖNCÜ BİRLİK (VisionOS) Şarkıyı 2 saniyede çözdü!');
          return res;
        }
      } catch (e) {
        print('❌ ÖNCÜ BİRLİK BAŞARISIZ: $e. AĞIR TANK (VPS) ÇAĞRILIYOR!');
      }

      // 2. AĞIR TANK (KALICILIK - VPS Webshare Proxies)
      final checkUrl = '$_vpsBase/api/stream_check/$encodedId?apikey=$_vpsApiKey';
      print('📡 AĞIR TANK (VPS) Devreye Girdi (10-15s sürebilir)...');
      
      // VPS timeout 25 saniyeye çıkarıldı çünkü proxy'lerin cevap vermesi 12-15 sn sürüyor.
      final response = await http.get(Uri.parse(checkUrl)).timeout(const Duration(seconds: 25));
      
      if (response.statusCode == 200) {
         final data = jsonDecode(response.body);
         if (data['status'] == 'ok') {
            final vpsUrl = data['url'];
            print('📡 VPS Stream ONAYLANDI: $vpsUrl');
            return {
              'status': 'basarili',
              'stream_url': vpsUrl,
              'is_file': false,
            };
         }
      }
      
      print('⚠️ VPS Stream Bulamadı! (HTTP ${response.statusCode}). Yerel otonom motora (Piped) geçiliyor...');
      throw Exception("VPS sesi çözemedi");
    } catch (e) {
      print('❌ VPS yönlendirme hatası: $e');
      // 🛡️ Acil durum: Yerel otonom çözücüye düş
      try {
        print('🔄 YEREL OTONOM MOTOR (SiberPlatform) BAŞLATILIYOR -> $videoId');
        return await SiberPlatform.instance.getStreamUrl(videoId);
      } catch (e2) {
        return {'status': 'hata', 'mesaj': e2.toString()};
      }
    }
  }


  Future<Map<String, dynamic>> downloadMusic(String videoId, String title) async {
    _downloadStatuses[videoId] = 'indiriliyor';
    _downloadMbInfos[videoId] = {
      'downloaded_mb': '0.00',
      'total_mb': '?',
      'percent': 'HazÃ„Â±rlanÃ„Â±yor...'
    };
    
    Future.microtask(() async {
      try {
        String musicDirPath = await StorageService.getOzsesDownloadPath();
        String safeTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
        
        if (!kIsWeb && Platform.isWindows) {
          // ÄŸÅ¸Å¡â‚¬ SÃ„Â°BER KALKAN: yt-dlp ile Windows ÃƒÂ¼zerinde indirme
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
                // AyrÃ„Â±Ã…Å¸tÃ„Â±rma hatasÃ„Â±, devam et
              }
            }
          });

          var exitCode = await process.exitCode;
          if (exitCode == 0) {
            // Ã„Â°ndirilen dosyanÃ„Â±n tam adÃ„Â±nÃ„Â± bul (m4a veya webm olabilir)
            File downloadedFile = File('$musicDirPath\\$safeTitle.m4a');
            if (!await downloadedFile.exists()) {
               downloadedFile = File('$musicDirPath\\$safeTitle.webm');
            }
            
            _downloadPaths[videoId] = downloadedFile.path;
            _downloadStatuses[videoId] = 'basarili';
            _downloadMbInfos.remove(videoId);
            print('ÄŸÅ¸Å¡â‚¬ Ã„Â°ndirme TamamlandÃ„Â±: ${downloadedFile.path}');
          } else {
            _downloadStatuses[videoId] = 'hata';
            print('Ã¢ÂÅ’ yt-dlp indirme hatasÃ„Â±, exit code: $exitCode');
          }
          return;
        }

        // ÄŸÅ¸ÂÂ¯ SÃ„Â°BER HAMLE: Android Ã„Â°ndirme Ã„Â°ÃƒÂ§in DoÃ„Å¸rudan YoutubeExplode ile GerÃƒÂ§ek URL Ãƒâ€¡ÃƒÂ¶zÃƒÂ¼mÃƒÂ¼
        String targetUrl;
        if (!kIsWeb && Platform.isAndroid) {
          // Android'de proxy ÃƒÂ§alÃ„Â±Ã…Å¸maz, doÃ„Å¸rudan YoutubeExplode ile URL al
          try {
            var yt = YoutubeExplode();
            var ytClients = [YoutubeApiClient.androidVr, YoutubeApiClient.androidSdkless, YoutubeApiClient.android, YoutubeApiClient.tv];
            var manifest = await yt.videos.streamsClient.getManifest(videoId, ytClients: ytClients).timeout(const Duration(seconds: 15));
            var audioStreamList = manifest.audioOnly.where((s) => s.container.name == 'mp4' || s.audioCodec.contains('mp4a')).toList();
            var ytStreamInfo = audioStreamList.isNotEmpty 
                ? audioStreamList.reduce((a, b) => a.bitrate.bitsPerSecond > b.bitrate.bitsPerSecond ? a : b) 
                : manifest.audioOnly.withHighestBitrate();
            targetUrl = ytStreamInfo.url.toString();
            yt.close();
            print('Ã¢Å“â€¦ Android Ã„Â°ndirme: YoutubeExplode ile gerÃƒÂ§ek URL alÃ„Â±ndÃ„Â±!');
          } catch (e) {
            print('Ã¢ÂÅ’ YoutubeExplode Ã„Â°ndirme URL HatasÃ„Â±: $e');
            _downloadStatuses[videoId] = 'hata';
            _downloadMbInfos[videoId] = {'percent': 'Hata: URL alÃ„Â±namadÃ„Â±'};
            return;
          }
        } else {
          final streamInfo = await getStreamUrl(videoId);
          if (streamInfo['status'] != 'basarili' || streamInfo['stream_url'] == null) {
            _downloadStatuses[videoId] = 'hata';
            print("Ã¢ÂÅ’ Siber Ã„Â°ndirme HatasÃ„Â±: AkÃ„Â±Ã…Å¸ URL'si alÃ„Â±namadÃ„Â±!");
            return;
          }
          targetUrl = streamInfo['stream_url'];
          if (targetUrl == 'proxy_will_handle_it') {
             targetUrl = 'http://127.0.0.1:${OzsesBridge.proxyPort}/$videoId';
          }
        }

        String ext = 'm4a'; // Piped ve YT genellikle m4a dÃƒÂ¶ndÃƒÂ¼rÃƒÂ¼r
        
        String filePath = '$musicDirPath/$safeTitle.$ext';
        if (!kIsWeb && Platform.isWindows) {
          filePath = '$musicDirPath\\$safeTitle.$ext';
        }
        
        // ÄŸÅ¸ÂÂ¯ SÃ„Â°BER KALKAN: Ã„Â°ndirme Ãƒâ€“ncesi Ã„Â°zin KontrolÃƒÂ¼ (Android)
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

        int totalBytes = 0;
        int downloadedBytes = 0;
        bool isDone = false;
        int retryCount = 0;

        while (!isDone && retryCount < 5) {
          try {
            final request = http.Request('GET', Uri.parse(targetUrl));
            request.headers['User-Agent'] = 'com.google.ios.youtube/19.28.1 (iPhone16,2; U; CPU iOS 17_5_1 like Mac OS X;)';
            request.headers['Referer'] = 'https://www.youtube.com/';
            
            if (downloadedBytes > 0) {
              request.headers['Range'] = 'bytes=$downloadedBytes-';
            }
            
            final response = await http.Client().send(request).timeout(const Duration(seconds: 15));
            
            if (response.statusCode != 200 && response.statusCode != 206) {
               if (downloadedBytes > 0 && response.statusCode == 416) {
                 isDone = true; // Bitti say
                 break;
               }
               _downloadStatuses[videoId] = 'hata';
               _downloadMbInfos[videoId] = {'percent': 'Hata: ${response.statusCode}'};
               return;
            }

            if (totalBytes == 0) {
              totalBytes = (response.contentLength ?? 0) + downloadedBytes;
            }
            
            var fileStream = file.openWrite(mode: downloadedBytes > 0 ? FileMode.append : FileMode.write);
            
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
                  'percent': 'Ã„Â°niyor...'
                };
              }
              return chunk;
            }).pipe(fileStream);
            
            await fileStream.close();

            if (totalBytes > 0 && downloadedBytes >= totalBytes) {
              isDone = true;
            } else if (totalBytes == 0) {
              // Boyut bilinmiyorsa stream bitince tamamlandÃ„Â± sayarÃ„Â±z
              isDone = true;
            } else {
              // BaÃ„Å¸lantÃ„Â± koptu, tekrar denenecek
              print('Ã¢Å¡Â Ã¯Â¸Â Ã„Â°ndirme koptu ($downloadedBytes / $totalBytes), tekrar deneniyor...');
              retryCount++;
              await Future.delayed(const Duration(seconds: 2));
            }
          } catch (e) {
            print('Ã¢Å¡Â Ã¯Â¸Â Ã„Â°ndirme aÃ„Å¸ hatasÃ„Â±: $e');
            retryCount++;
            await Future.delayed(const Duration(seconds: 2));
          }
        }
        
        if (!isDone) {
          throw Exception("BaÃ„Å¸lantÃ„Â± ÃƒÂ§ok fazla kez koptu.");
        }

        _downloadPaths[videoId] = filePath;
        _downloadStatuses[videoId] = 'basarili';
        _downloadMbInfos.remove(videoId);
        print('Ã¢Å“â€¦ Ã„Â°ndirme TamamlandÃ„Â±: $filePath');
      } catch (e) {
        print('Ã¢ÂÅ’ Siber Ã„Â°ndirme HatasÃ„Â±: $e');
        _downloadStatuses[videoId] = 'hata';
        _downloadMbInfos[videoId] = {'percent': 'Hata: ${e.toString().split('\n')[0]}'};
      }
    });

    return {'status': 'basladi'};
  }

  // ÄŸÅ¸ÂÂ¯ SÃ„Â°BER HAMLE: Ã„Â°ndirme Durumu SorgulayÃ„Â±cÃ„Â± (NATIVE)
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

  // ÄŸÅ¸ÂÂ¯ SÃ„Â°BER HAMLE: Derin AÃ„Å¸ ve Yapay Zeka SÃƒÂ¶z Ãƒâ€¡Ã„Â±karÃ„Â±cÃ„Â±
  // ÄŸÅ¸ÂÂ¯ SÃ„Â°BER HAMLE: Tam Otonom Youtube AltyazÃ„Â± SÃƒÂ¶kÃƒÂ¼cÃƒÂ¼ (Native SÃƒÂ¶z Motoru)
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
      print('ÄŸÅ¸â€ºâ€˜ Siber YouTube Lirik HatasÃ„Â±: $e');
    }
    return null;
  }

  // ÄŸÅ¸ÂÂ¯ SÃ„Â°BER HAMLE: Profil DoÃ„Å¸rulama Kodu GÃƒÂ¶nder
  Future<Map<String, dynamic>> sendSiberCode(String email) async {
    String url = 'http://127.0.0.1:8000/siber-kod-gonder';
    if (!kIsWeb && Platform.isAndroid) {
      String ip = await SiberIPService.getMasterIP();
      url = 'http://$ip:8000/siber-kod-gonder';
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
    return {'status': 'hata', 'mesaj': 'BaÃ„Å¸lantÃ„Â± koptu'};
  }

  // ÄŸÅ¸ÂÂ¯ SÃ„Â°BER HAMLE: Kodu DoÃ„Å¸rula ve KayÃ„Â±t Ol
  Future<Map<String, dynamic>> verifyAndRegister(
      String email, String username, String password, String code) async {
    String url = 'http://127.0.0.1:8000/siber-dogrula-kayit';
    if (!kIsWeb && Platform.isAndroid) {
      String ip = await SiberIPService.getMasterIP();
      url = 'http://$ip:8000/siber-dogrula-kayit';
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
    return {'status': 'hata', 'mesaj': 'BaÃ„Å¸lantÃ„Â± koptu'};
  }
}

// ÄŸÅ¸ÂÂ¯ SÃ„Â°BER HAMLE: Isolate (Arka plan iÃ…Å¸ÃƒÂ§isi) iÃƒÂ§in ana iÃ…Å¸lemciden baÃ„Å¸Ã„Â±msÃ„Â±z dÃƒÂ¶nÃƒÂ¼Ã…Å¸tÃƒÂ¼rÃƒÂ¼cÃƒÂ¼
Map<String, dynamic> _decodeAndParseJsonMap(Uint8List bytes) {
  return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
}



