import 'dart:convert';
import 'package:http/http.dart' as http;
import 'siber_platform.dart';

SiberPlatform getPlatform() => WebPlatform();

// Web ortamında yerel sunucu (localhost) çalışmaz.
// Bunun yerine bulut üzerine (Render, Heroku vb.) kurduğumuz Siber Karargah Backend API'sine çağrı yaparız.
const String _PROXY_BASE = 'https://ozses-1.onrender.com';

class WebPlatform implements SiberPlatform {
  @override
  bool get supportsHardwareDSP => false;

  @override
  Future<Map<String, dynamic>> fetchKesfet({String? pageToken}) async {
    print('--- SIBER KESFET RADARI BASLATIYOR (yt-dlp proxy) ---');
    try {
      final response = await http
          .get(Uri.parse('$_PROXY_BASE/search?q=hit+sarkilar'))
          .timeout(const Duration(seconds: 60));
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
          .get(Uri.parse('$_PROXY_BASE/search?q=$encodedQuery'))
          .timeout(const Duration(seconds: 60));
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
