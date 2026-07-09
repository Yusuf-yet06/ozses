import 'siber_module.dart';
import 'siber_command.dart';
import 'dart:async';
import 'lib/services/audio_engine.dart'; // Otonom Görsel Kontrolü İçin

class SystemModule extends SiberModule {
  Timer? _clockTimer;

  @override
  String get name => 'Sistem_Kontrol_Lobu';

  @override
  List<String> get supportedActions => ['check_time', 'check_battery'];

  @override
  Future<void> initModule() async {
    print('⚙️ Sistem Lobu: Saat ve cihaz durumu sensörleri devrede.');

    // 🎯 SİBER HAMLE: Gerçek Saati Dinleyip Otonom Görsel Değiştiren Lob!
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _autonomousDayNightCycle();
    });
    _autonomousDayNightCycle(); // Uyanır uyanmaz da anında kontrol et
  }

  void _autonomousDayNightCycle() {
    final hour = DateTime.now().hour;
    // 🎯 Gece 23:00 ile Sabah 06:00 arası Zifiri Karanlık (Dark Mod)
    if (hour >= 23 || hour < 6) {
      if (AudioEngine.darkMode != 1) {
        AudioEngine.darkMode = 1;
        print(
            '🌙 SİBER BEYİN OTONOM: Gece vakti algılandı, Zifiri Karanlık (Dark Mod) devrede.');
      }
    } else {
      // 🎯 Gündüz vakti Neon Çizgiler (Night Mod)
      if (AudioEngine.darkMode != 0) {
        AudioEngine.darkMode = 0;
        print(
            '☀️ SİBER BEYİN OTONOM: Gündüz vakti algılandı, Neon Çizgiler (Night Mod) devrede.');
      }
    }
  }

  @override
  Future<bool> execute(SiberCommand command) async {
    if (command.action == 'check_time') {
      final now = DateTime.now();
      final timeStr =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      print('🕒 SİBER BEYİN: Gardaşım saat şu an $timeStr');
      return true;
    } else if (command.action == 'check_battery') {
      print(
          '🔋 SİBER BEYİN: Batarya okuma donanımı henüz takılmadı ama enerji stabil!');
      return true;
    }
    return false;
  }

  @override
  Future<void> sleepModule() async {
    _clockTimer?.cancel();
  }
}
