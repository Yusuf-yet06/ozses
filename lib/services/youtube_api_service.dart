import 'dart:convert';
import 'package:http/http.dart' as http;

/// 🎯 SİBER HAMLE: Genel Keşfet (YouTube) İstihbarat Motoru
class YoutubeApiService {
  // ⚠️ KÜTÜPHANEDE ALACAĞIN API KEY'İ BURAYA MÜHÜRLEYECEĞİZ
  static const String _apiKey = "AIzaSyDk3JK5TviRsxTNYMTz8j3TKeHA6y8G3QU";
  static const String _baseUrl = "https://www.googleapis.com/youtube/v3";

  // 🎯 YouTube üzerinde siber arama yapan otonom radar
  static Future<List<Map<String, dynamic>>> searchMusic(String query) async {
    // Eğer API Key henüz girilmediyse motoru korumaya al
    if (_apiKey == "API_KEY_BEKLENIYOR") {
      print("🛡️ SİBER KALKAN: API Key eksik. YouTube radarı bekleme modunda.");
      return [];
    }

    try {
      // Sadece müzikleri bulması için 'official audio' takısı ekliyoruz
      final uri = Uri.parse(
          "$_baseUrl/search?part=snippet&q=${Uri.encodeComponent('$query official audio')}&type=video&maxResults=15&key=$_apiKey");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List items = data['items'] ?? [];

        return items
            .map((item) => {
                  'videoId': item['id']['videoId'],
                  'title': item['snippet']['title'],
                  'channel': item['snippet']['channelTitle'],
                  'thumbnail': item['snippet']['thumbnails']['high']['url']
                })
            .toList();
      }
    } catch (e) {
      print("❌ Siber YouTube Hata: $e");
    }
    return [];
  }
}
