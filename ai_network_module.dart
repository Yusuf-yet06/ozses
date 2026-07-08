import 'siber_module.dart';
import 'siber_command.dart';
import 'siber_beyin.dart';

class AiNetworkModule extends SiberModule {
  @override
  String get name => "Yapay_Zeka_Siber_Ag_Lobu";

  @override
  List<String> get supportedActions => ['analyze_text_command'];

  @override
  Future<void> initModule() async {
    print(
        "🌐 AI Ağı: Python devreden çıkarıldı, %100 Dart (İç) Yapay Zeka devrede!");
  }

  @override
  Future<bool> execute(SiberCommand command) async {
    if (command.action == 'analyze_text_command') {
      final text = command.data['text']?.toString().toLowerCase() ?? '';
      if (text.isEmpty) return false;

      String karar = 'beklemede';

      // 🎯 SİBER HAMLE: İçsel Dart YZ Algoritması (Eklentisiz, saf hız!)
      if (text.contains('çal') ||
          text.contains('başlat') ||
          text.contains('devam')) {
        karar = 'play';
      } else if (text.contains('durdur') ||
          text.contains('bekle') ||
          text.contains('sus')) {
        karar = 'pause';
      }

      if (text.contains('bas') || text.contains('bass')) {
        if (text.contains('kökle') ||
            text.contains('aç') ||
            text.contains('arttır') ||
            text.contains('yükselt')) {
          karar = 'bass_boost_on';
        } else if (text.contains('kapat') || text.contains('kıs')) {
          karar = 'bass_boost_off';
        }
      }

      if (text.contains('ekolayzır') ||
          text.contains('eq') ||
          text.contains('frekans')) {
        if (text.contains('aç') || text.contains('başlat')) {
          karar = 'eq_on';
        } else if (text.contains('kapat') || text.contains('durdur')) {
          karar = 'eq_off';
        }
      }

      // 🎯 SİBER HAMLE: Sistem Durumu Algılayıcı (Saat/Şarj)
      if (text.contains('saat') || text.contains('zaman')) {
        karar = 'check_time';
      } else if (text.contains('şarj') ||
          text.contains('batarya') ||
          text.contains('pil')) {
        karar = 'check_battery';
      }

      if (karar != 'beklemede') {
        print("🧠 İÇSEL SİBER BEYİN KARARI: $karar");
        SiberBeyin()
            .processCommand(SiberCommand(action: karar, source: 'ai_network'));
        return true;
      }
    }
    return false;
  }

  @override
  Future<void> sleepModule() async {}
}
