import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'siber_platform.dart';

SiberPlatform getPlatform() => WebPlatform();

// Web ortamında yerel sunucu (localhost) çalışmaz.
// Bunun yerine bulut üzerine (Render, Heroku vb.) kurduğumuz Siber Karargah// Vercel Üzerindeki Yeni Limitsiz ve Ücretsiz Proxy Ağı
const String _PROXY_BASE = 'https://ozses-832f9y4py-ozses.vercel.app';

class WebPlatform implements SiberPlatform {
  @override
  bool get supportsHardwareDSP => false;

  static final YoutubeExplode _yt = YoutubeExplode();

  @override
  Future<Map<String, dynamic>> fetchKesfet({String? pageToken}) async {
    print('--- ÖZSES KEŞFET RADARI BAŞLATILIYOR (WEB SİBER PROXY) ---');
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
    final encodedQuery = Uri.encodeComponent(query);
    
    // 1. ZIRH: Bizim Render Proxy (Kendi Sunucun - CORS Güncellemesi Gerektirir)
    try {
      final response = await http
          .get(Uri.parse('$_PROXY_BASE/search?q=$encodedQuery'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawOneriler = data['oneriler'] as List<dynamic>? ?? [];
        var items = [];
        for (var video in rawOneriler) {
          items.add({
            'id': video['id'] ?? video['videoId'],
            'title': video['title'],
            'channel': video['channel'] ?? video['artist'],
            'thumbnail': video['thumbnail'],
          });
        }
        if (items.isNotEmpty) {
           return {'status': 'basarili', 'oneriler': items, 'nextPageToken': data['nextPageToken'] ?? ''};
        }
      }
    } catch (e) {
      print('Siber Kesfet Proxy Hatasi (Web): $e');
    }

    // 2. ZIRH: Invidious API Fallback (CORS Destekler)
    print('🔄 SİBER KALKAN: Invidious Keşfet Fallback Devrede (Web)...');
    final List<String> invidiousInstances = [
      'https://inv.bp.projectsegfau.lt',
      'https://invidious.perennialte.ch',
      'https://invidious.jing.rocks',
      'https://invidious.privacydev.net'
    ];
    for (var instance in invidiousInstances) {
      try {
        final res = await http.get(Uri.parse('$instance/api/v1/search?q=$encodedQuery')).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as List<dynamic>;
          var results = [];
          for (var video in data.take(15)) {
            if (video['type'] == 'video') {
              results.add({
                'id': video['videoId'],
                'title': video['title'],
                'channel': video['author'],
                'thumbnail': video['videoThumbnails']?[0]?['url'] ?? '',
              });
            }
          }
          if (results.isNotEmpty) {
             return {'status': 'basarili', 'oneriler': results, 'nextPageToken': ''};
          }
        }
      } catch (_) {}
    }

    // 3. ZIRH: Piped API Fallback
    print('🔄 SİBER KALKAN: Piped Keşfet Fallback Devrede (Web)...');
    final List<String> pipedInstances = [
      'https://pipedapi.kavin.rocks',
      'https://pipedapi.moomoo.me',
      'https://api.piped.projectsegfau.lt'
    ];
    for (var instance in pipedInstances) {
      try {
        final res = await http.get(Uri.parse('$instance/search?q=$encodedQuery&filter=music_songs')).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final pipedItems = data['items'] as List<dynamic>;
          var results = [];
          for (var video in pipedItems.take(15)) {
            results.add({
              'id': video['url'].toString().replaceAll('/watch?v=', ''),
              'title': video['title'],
              'channel': video['uploaderName'],
              'thumbnail': video['thumbnail'],
            });
          }
          if (results.isNotEmpty) {
             return {'status': 'basarili', 'oneriler': results, 'nextPageToken': data['nextpage'] ?? ''};
          }
        }
      } catch (_) {}
    }

    // ASLA BOŞ DÖNME - OFFLINE MODU TETİKLEMEMEK İÇİN ACİL DURUM ŞARKISI
    return {
      'status': 'basarili',
      'oneriler': [
        {
          'id': 'pEW0fomRqs0',
          'title': 'Siber Kalkan Aktif (Bağlantı Yavaş - Yenile)',
          'channel': 'ÖZSES V7',
          'thumbnail': 'https://i.ytimg.com/vi/pEW0fomRqs0/hqdefault.jpg'
        }
      ],
      'nextPageToken': ''
    };
  }

  @override
  Future<List<dynamic>> searchMusic(String query, {int limit = 15, int page = 1}) async {
    print('--- SİBER ARAMA BAŞLATILIYOR (WEB SİBER PROXY) ---');
    final encodedQuery = Uri.encodeComponent(query);
    
    // 1. ZIRH: Render Proxy (Kendi Sunucun - CORS Güncellemesi Gerektirir)
    try {
      final response = await http
          .get(Uri.parse('$_PROXY_BASE/search?q=$encodedQuery'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawOneriler = data['oneriler'] as List<dynamic>? ?? [];
        var items = [];
        for (var video in rawOneriler.take(limit)) {
          items.add({
            'id': video['id'] ?? video['videoId'],
            'title': video['title'],
            'channel': video['channel'] ?? video['artist'],
            'thumbnail': video['thumbnail'],
          });
        }
        if (items.isNotEmpty) return items;
      }
    } catch (e) {
      print('Siber Arama Proxy Hatasi (Web): $e');
    }

    // 2. ZIRH: Invidious API
    print('🔄 SİBER KALKAN: Invidious Arama Fallback Devrede (Web)...');
    final List<String> invidiousInstances = [
      'https://inv.bp.projectsegfau.lt',
      'https://invidious.perennialte.ch',
      'https://invidious.jing.rocks',
      'https://invidious.privacydev.net'
    ];
    for (var instance in invidiousInstances) {
      try {
        final res = await http.get(Uri.parse('$instance/api/v1/search?q=$encodedQuery')).timeout(const Duration(seconds: 7));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as List<dynamic>;
          var results = [];
          for (var video in data.take(limit)) {
            if (video['type'] == 'video') {
              results.add({
                'id': video['videoId'],
                'title': video['title'],
                'channel': video['author'],
                'thumbnail': video['videoThumbnails']?[0]?['url'] ?? '',
              });
            }
          }
          if (results.isNotEmpty) return results;
        }
      } catch (_) {}
    }

    // 3. ZIRH: Piped API
    print('🔄 SİBER KALKAN: Piped Arama Fallback Devrede (Web)...');
    final List<String> pipedInstances = [
      'https://pipedapi.kavin.rocks',
      'https://pipedapi.smnz.de',
      'https://pipedapi.adminforge.de',
      'https://pipedapi.moomoo.me',
      'https://api.piped.projectsegfau.lt'
    ];
      
    for (var instance in pipedInstances) {
      try {
        final res = await http.get(Uri.parse('$instance/search?q=$encodedQuery&filter=all')).timeout(const Duration(seconds: 7));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          var items = [];
          for (var item in data['items'] ?? []) {
            if (item['type'] == 'stream') {
              items.add({
                'id': item['url'].toString().replaceAll('/watch?v=', ''),
                'title': item['title'],
                'channel': item['uploaderName'],
                'thumbnail': item['thumbnail']
              });
            }
          }
          if (items.isNotEmpty) return items;
        }
      } catch (_) {}
    }

    return [];
  }

  @override
  Future<List<String>> getSearchSuggestions(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    try {
      final response = await http
          .get(Uri.parse('$_PROXY_BASE/suggest?q=$encodedQuery'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['oneriler'] != null) {
          return List<String>.from(data['oneriler']);
        }
      }
    } catch (e) {
      print('Siber Arama Onerisi Proxy Hatasi: $e');
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> getStreamUrl(String videoId) async {
    try {
      // Web ortamı için backend üzerindeki /play endpointini (stream proxy) ver
      // Böylece CORS bypass edilmiş olur.
      return {
        'status': 'basarili',
        'stream_url': '$_PROXY_BASE/play/$videoId'
      };
    } catch (e) {
      print('Siber Stream Proxy Hatasi: $e');
    }
    throw Exception('Stream URL alinamadi');
  }

  @override
  Future<String> getDownloadPath() async => '';

  @override
  Future<List<String>> scanMusicFolders() async => [];
}
