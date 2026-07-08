import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:firebase_auth/firebase_auth.dart'; // 🛡️ SİBER KALKAN

class SiberKopru {
  static const String _baseUrl = 'http://127.0.0.1:8000';

  // 🛡️ SİBER KALKAN: Güvenlik Jetonu (Token) Üretici
  static Future<Map<String, String>> _getAuthHeaders() async {
    Map<String, String> headers = {"Content-Type": "application/json"};
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final idToken = await user.getIdToken();
        if (idToken != null) {
          headers['Authorization'] = 'Bearer $idToken';
        }
      } catch (e) {}
    }
    return headers;
  }

  // 🛡️ SİBER KALKAN: Otonom Motor bağlantısı koptuğunda otonom lokal moda geçmek için
  static bool _siberKalkanAktif = false;

  // 🎯 SİBER HAMLE: Otonom Motor beyninin ayakta olup olmadığını kontrol eder
  static Future<bool> beyneBaglan() async {
    try {
      // 🛡️ 2 saniyede dönmezse bekleme, kalkanı aç!
      final response = await http
          .get(Uri.parse('$_baseUrl/'))
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        print("✅ Siber Beyin Yanıt Verdi: ${response.body}");
        _siberKalkanAktif = false;
        return true;
      }
    } catch (e) {
      print(
          "🛡️ SİBER KALKAN DEVREDE: Otonom Motor beyni kapalı. Uygulama lokal moda alındı. $e");
      _siberKalkanAktif = true;
    }
    return false;
  }

  // 🎯 SİBER HAMLE: Sesli veya yazılı komutları metin olarak Ağa atar, AI kararını geri alır
  static Future<String> komutGonder(String komutMetni) async {
    if (_siberKalkanAktif) {
      return "offline_mod"; // Bağlantı zaten yoksa boşuna istek atıp sistemi yorma
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/siber-komut'),
            headers: await _getAuthHeaders(),
            body: jsonEncode({"text": komutMetni}),
          )
          .timeout(const Duration(seconds: 2)); // 🛡️ SİBER İZOLATÖR

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['karar'] ?? "Bilinmiyor";
      }
    } catch (e) {
      print("🛡️ Siber İletişim Koptu (İzolatör Devrede): $e");
      _siberKalkanAktif = true;
      return "offline_mod";
    }
    return "hata";
  }
}
