import '../constants/anayasa.dart';

class MasterGuard {
  // Kullanıcının yetkisini kontrol et (Şimdilik manuel, sonra Firebase olacak)
  static bool verifyUser(String deviceId, String role) {
    if (role == "ADMIN") {
      print("✅ Erişim Onaylandı: İmparator Hoş Geldiniz.");
      return true;
    } else {
      // Yetkisiz girişte Labyrinth'i sessizce aktif et
      OzsesAnayasa.labyrinthModu = true;
      print("⚠️ Şüpheli Giriş Denemesi! Honeypot Aktif Edildi.");
      return false;
    }
  }
}
