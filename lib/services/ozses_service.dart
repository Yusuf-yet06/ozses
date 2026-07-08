import 'dart:convert';
import 'package:http/http.dart' as http;

class OzsesService {
  // FastAPI sunucusunun adresi
  final String baseUrl = 'http://127.0.0.1:8000';

  Future<Map<String, dynamic>?> fetchLiveData() async {
    try {
      // Python beyninden anlık nabız ve frekans verisini çekiyoruz
      final response = await http.get(Uri.parse('$baseUrl/live_data'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // Python motoru kapalıysa veya hata verdiyse sessizce null dön
      return null;
    }
    return null;
  }

  Future<void> updateBrainSettings(
    bool isAutonomous,
    double threshold, {
    String? subMode,
  }) async {
    try {
      // Flutter'dan Python'a ayar mühürlüyoruz
      await http.post(
        Uri.parse('$baseUrl/settings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'isAutonomous': isAutonomous,
          'threshold': threshold,
          'subMode': subMode,
        }),
      );
      print("Siber Komut: Ayarlar Python'a mühürlendi!");
    } catch (e) {
      print("SİBER HATA: Python'a komut iletilemedi. $e");
    }
  }
}
