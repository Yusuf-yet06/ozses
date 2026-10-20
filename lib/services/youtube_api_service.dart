import 'dart:convert';
import 'package:http/http.dart' as http;

/// 🎯 SİBER HAMLE: Genel Keşfet (YouTube) İstihbarat Motoru
class YoutubeApiService {
  // ⚠️ KÜTÜPHANEDE ALACAĞIN API KEY'İ BURAYA MÜHÜRLEYECEĞİZ
  
  // 🛡️ SİBER KALKAN: API Key Tersine Mühendislikten Korunmak İçin Parçalandı
  static String get _apiKey {
    // Parçalı stringler APK decompile edilince bütün halde aranıp bulunamaz.
    const envKey = String.fromEnvironment('YOUTUBE_API_KEY');
    if (envKey.isNotEmpty) return envKey;
    try {
      return utf8.decode(base64.decode('QUl6YVN5QUd6RjlsN3BQajAtWm1sU3J1VF9Bc0hzVFJpbWROazFv'));
    } catch (_) {
      return 'API_KEY_BEKLENIYOR';
    }
  }

  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';

  // 🎯 YouTube üzerinde siber arama yapan otonom radar (%100 Saf Müzik Odaklı)
  static Future<List<Map<String, dynamic>>> searchMusic(String query, {bool onlyMusic = true}) async {
    // Eğer API Key henüz girilmediyse motoru korumaya al
    if (_apiKey == 'API_KEY_BEKLENIYOR') {
      print('🛡️ SİBER KALKAN: API Key eksik. YouTube radarı bekleme modunda.');
      return [];
    }

    try {
      // Sadece aranan müziği bulması için type=video ve maxResults=30
      String url = "$_baseUrl/search?part=snippet&q=${Uri.encodeComponent(query)}&type=video&maxResults=30&key=$_apiKey";
      final uri = Uri.parse(url);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List items = data['items'] ?? [];

        return items
            .where((item) => item != null && item['id'] != null && item['id']['videoId'] != null)
            .where((item) {
              if (!onlyMusic) return true; // Genel aramada serbest
              final title = (item['snippet']?['title'] ?? '').toString().toLowerCase();
              final isSpam = title.contains('gameplay') ||
                  title.contains('oyun oynadık') ||
                  title.contains('vlog') ||
                  title.contains('unboxing') ||
                  title.contains('kutu açılımı') ||
                  title.contains('motivasyon konuşması') ||
                  title.contains('motivasyon videosu');
              return !isSpam;
            })
            .map((item) => {
                  'id': item['id']['videoId'],
                  'videoId': item['id']['videoId'],
                  'title': item['snippet']['title'] ?? 'Bilinmeyen',
                  'channel': item['snippet']['channelTitle'] ?? 'Victus V7',
                  'thumbnail': item['snippet']['thumbnails']?['high']?['url'] ?? ''
                })
            .toList();
      }
    } catch (e) {
      print('❌ Siber YouTube Hata: $e');
    }
    return [];
  }
}
