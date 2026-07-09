import 'dart:convert';
import 'package:http/http.dart' as http;

// 🎯 SİBER HAMLE: Şarkı sözlerini otonom arayıp getiren ağ ajanı
class LyricsService {
  static Future<String?> fetchLyrics(String title, String artist) async {
    try {
      // Arama hatalarını önlemek için .mp3 uzantılarını temizle
      String safeArtist =
          (artist.toLowerCase().contains('victus') || artist.isEmpty)
              ? ''
              : artist;
      String safeTitle = title
          .replaceAll(RegExp(r'\.mp3|\.wav|\.m4a', caseSensitive: false), '')
          .trim();

      final url =
          'https://lrclib.net/api/get?track_name=${Uri.encodeComponent(safeTitle)}&artist_name=${Uri.encodeComponent(safeArtist)}';

      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null) {
          return data['syncedLyrics'] ?? data['plainLyrics'];
        }
      } else if (response.statusCode == 404) {
        // Sadece başlık ile aramayı dene (Artist yanlış girilmiş olabilir)
        final fallbackUrl =
            'https://lrclib.net/api/search?q=${Uri.encodeComponent(safeTitle)}';
        final fbResponse = await http
            .get(Uri.parse(fallbackUrl))
            .timeout(const Duration(seconds: 10));
        if (fbResponse.statusCode == 200) {
          final fbData = json.decode(fbResponse.body) as List;
          if (fbData.isNotEmpty) {
            return fbData[0]['syncedLyrics'] ?? fbData[0]['plainLyrics'];
          }
        }
      }
    } catch (e) {
      print('Siber Hata: Şarkı sözü okunamadı -> $e');
    }
    return null;
  }
}
