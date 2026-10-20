import 'package:shared_preferences/shared_preferences.dart';

class SiberIPService {
  static const String _ipKey = 'siber_master_node_ip';
  
  // Varsayılan IP (Eğer ayarlanmamışsa emülatör IP'sini veya localhost'u kullanır)
  static Future<String> getMasterIP() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ipKey) ?? '10.0.2.2';
  }

  static Future<void> setMasterIP(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ipKey, ip.trim());
  }
}
