import 'dart:convert';
import 'package:http/http.dart' as http;
import 'siber_platform.dart';

SiberPlatform getPlatform() => WebPlatform();

// CORS SORUNUNU KOKTEN COZEN MIMARI (yt-dlp powered):
// Tarayici dis API-lere degil, kendi localhost proxy-sine (siber_proxy.py) cagri yapar.
// siber_proxy.py yt-dlp kullanarak CORS olmadan YouTube-a erisir.
const String _PROXY_BASE = 'http://localhost:8081/api/proxy';

class WebPlatform implements SiberPlatform {
  @override
  bool get supportsHardwareDSP => false;

  @override
  Future<Map<String, dynamic>> fetchKesfet({String? pageToken}) async {
    print('--- SIBER KESFET RADARI BASLATIYOR (yt-dlp proxy) ---');
    try {
      final response = await http
          .get(Uri.parse('/kesfet'))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'basarili',
          'oneriler': data['oneriler'] ?? [],
          'nextPageToken': data['nextPageToken'] ?? '',
        };
      }
    } catch (e) {
      print('Siber Kesfet Proxy Hatasi: ');
    }
    throw Exception('Proxy sunucusuna baglanamadi. siber_proxy.py calisıyor mu?');
  }

  @override
  Future<List<dynamic>> searchMusic(String query, {int limit = 15, int page = 1}) async {
    final encodedQuery = Uri.encodeComponent(query);
    try {
      final response = await http
          .get(Uri.parse('/search?q='))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['oneriler'] as List<dynamic>? ?? [];
        return items.take(limit).toList();
      }
    } catch (e) {
      print('Siber Arama Proxy Hatasi: ');
    }
    throw Exception('Arama basarisiz');
  }

  @override
  Future<List<String>> getSearchSuggestions(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    try {
      final response = await http
          .get(Uri.parse('/suggest?q=$encodedQuery'))
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
      final response = await http
          .get(Uri.parse('/stream?id='))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Siber Stream Proxy Hatasi: ');
    }
    throw Exception('Stream URL alinamadi');
  }

  @override
  Future<String> getDownloadPath() async => '';

  @override
  Future<List<String>> scanMusicFolders() async => [];
}
