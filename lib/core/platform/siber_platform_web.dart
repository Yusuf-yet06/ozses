import 'dart:convert';
import 'package:http/http.dart' as http;
import 'siber_platform.dart';
import '../../services/youtube_api_service.dart';

SiberPlatform getPlatform() => WebPlatform();

class WebPlatform implements SiberPlatform {
  @override
  bool get supportsHardwareDSP => false;

  // ⚡ SİBER RAM ÖNBELLEĞİ: 0 ms jet geçiş
  static final Map<String, _StreamCacheEntry> _streamCache = {};

  @override
  Future<Map<String, dynamic>> fetchKesfet({String? pageToken}) async {
    print('--- 🚀 ÖZSES KEŞFET RADARI (WEB GOOGLE YOUTUBE API) ---');
    final List<String> discoveryTerms = [
      'en çok dinlenen türkçe pop şarkılar 2026',
      'haftanın trend türkçe şarkıları',
      'yeni çıkan şarkılar 2026',
      'hit şarkılar karışık Türkçe',
      'viral türkçe şarkılar 2026',
      'türkçe rap en çok dinlenenler',
      'akustik performans Türkçe',
    ];
    discoveryTerms.shuffle();
    final String query = discoveryTerms.first;

    // 1. ZIRH: Google Resmi YouTube API (Işık Hızında & Sıfır CORS & Sıfır Bekleme)
    try {
      final ytResults = await YoutubeApiService.searchMusic(query, onlyMusic: true);
      if (ytResults.isNotEmpty) {
        final items = ytResults.map((video) => {
          'id': video['videoId'],
          'videoId': video['videoId'],
          'title': video['title'],
          'channel': video['channel'],
          'thumbnail': video['thumbnail'],
        }).toList();
        print('✅ [WEB KEŞFET] YouTube API ile ${items.length} trend parça anında yüklendi!');
        return {
          'status': 'basarili',
          'oneriler': items,
          'nextPageToken': '',
        };
      }
    } catch (e) {
      print('❌ Siber Keşfet YouTube API Hatası: $e');
    }

    // 2. ZIRH: Acil durum emniyet subabı
    return {
      'status': 'basarili',
      'oneriler': [
        {
          'id': 'SCZgGVqVsbY',
          'videoId': 'SCZgGVqVsbY',
          'title': 'Tarkan - Dudu',
          'channel': 'Tarkan',
          'thumbnail': 'https://i.ytimg.com/vi/SCZgGVqVsbY/hqdefault.jpg'
        }
      ],
      'nextPageToken': ''
    };
  }

  @override
  Future<List<dynamic>> searchMusic(String query, {int limit = 15, int page = 1, bool onlyMusic = true}) async {
    print('--- 🔍 SİBER ARAMA (WEB GOOGLE YOUTUBE API: $query) ---');
    try {
      final ytResults = await YoutubeApiService.searchMusic(query, onlyMusic: onlyMusic);
      if (ytResults.isNotEmpty) {
        final results = ytResults.take(limit).map((video) => {
          'id': video['videoId'],
          'videoId': video['videoId'],
          'title': video['title'],
          'channel': video['channel'],
          'thumbnail': video['thumbnail'],
        }).toList();
        print('✅ [WEB ARAMA] ${results.length} şarkı 150ms içinde bulundu!');
        return results;
      }
    } catch (e) {
      print('❌ Siber Arama YouTube API Hatası: $e');
    }
    return [];
  }

  @override
  Future<List<String>> getSearchSuggestions(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    try {
      final response = await http
          .get(Uri.parse('https://suggestqueries.google.com/complete/search?client=firefox&ds=yt&q=$encodedQuery'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is List && data.length > 1 && data[1] is List) {
          return List<String>.from(data[1]);
        }
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<Map<String, dynamic>> getStreamUrl(String videoId) async {
    // 0. JET MOTORU: RAM Önbelleği (0 ms)
    final cached = _streamCache[videoId];
    if (cached != null && cached.isValid) {
      print('⚡ [WEB JET MOTORU] $videoId RAM önbellekten anında alındı (0 ms)');
      return cached.data;
    }

    // 1. ZIRH: Bizim Nginx SSL VPS Karargahımız (Anında Başlatma)
    print('🛡️ [WEB HİBRİT] VPS Audio Relay doğrudan akış: $videoId');
    final vpsUrl = 'https://167-172-190-129.nip.io/api/stream/$videoId?apikey=siber_secret_key_v7';
    final result = {
      'status': 'basarili',
      'stream_url': vpsUrl,
      'is_file': false,
    };
    _streamCache[videoId] = _StreamCacheEntry(result, DateTime.now().add(const Duration(hours: 4)));
    return result;
  }

  @override
  Future<String> getDownloadPath() async => '';

  @override
  Future<List<String>> scanMusicFolders() async => [];

  @override
  void preWarm(String videoId) {
    if (videoId.isEmpty) return;
    try {
      final cleanId = videoId.startsWith('yt:') ? videoId.substring(3) : videoId;
      final uri = Uri.parse('https://167-172-190-129.nip.io/api/stream_check/$cleanId?apikey=siber_secret_key_v7');
      http.get(uri).catchError((_) => http.Response('', 500));
    } catch (_) {}
  }
}

class _StreamCacheEntry {
  final Map<String, dynamic> data;
  final DateTime expiresAt;
  _StreamCacheEntry(this.data, this.expiresAt);
  bool get isValid => DateTime.now().isBefore(expiresAt);
}
