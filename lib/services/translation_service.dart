import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  // SİBER ÇEVİRİ MOTORU (Beta Özellik)
  static Future<String> translateLyrics(String lyrics, {String targetLang = 'tr'}) async {
    try {
      if (lyrics.isEmpty) return lyrics;

      // 4000 karakter sınırını aşmamak için satır satır bölüp öbekler oluşturalım
      List<String> lines = lyrics.split('\n');
      List<String> chunks = [];
      String currentChunk = "";

      for (var line in lines) {
        if ((currentChunk.length + line.length) > 3500) {
          chunks.add(currentChunk);
          currentChunk = line + '\n';
        } else {
          currentChunk += line + '\n';
        }
      }
      if (currentChunk.isNotEmpty) {
        chunks.add(currentChunk);
      }

      String finalTranslation = "";
      for (var chunk in chunks) {
        finalTranslation += await _translateChunk(chunk, targetLang);
      }

      // SİBER HACK: Bazen Google Translate senkronize zaman etiketlerinin yanına fazladan boşluk koyabiliyor
      // Örn: [ 00:10.00 ] -> [00:10.00] olarak düzelt
      finalTranslation = finalTranslation.replaceAllMapped(
        RegExp(r'\[\s*(\d{2}:\d{2}\.\d{2,3})\s*\]'), 
        (match) => '[${match.group(1)}]'
      );

      return finalTranslation.trim();
    } catch (e) {
      print('Siber Çeviri Hatası: $e');
      return "[SİBER ÇEVİRİ AĞ HATASI: Lütfen tekrar deneyin]\n\n" + lyrics; 
    }
  }

  static Future<String> _translateChunk(String text, String targetLang) async {
    final url = Uri.parse('https://translate.googleapis.com/translate_a/single');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client': 'gtx',
          'sl': 'auto',
          'tl': targetLang,
          'dt': 't',
          'q': text,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String translated = '';
        if (data != null && data.isNotEmpty && data[0] != null) {
          for (var i = 0; i < data[0].length; i++) {
            translated += data[0][i][0].toString();
          }
          return translated;
        }
      }
      throw Exception('HTTP Error or invalid JSON format: ${response.statusCode}');
    } catch (e) {
      print('Siber Çeviri Parça Hatası: $e');
      rethrow;
    }
  }
}
