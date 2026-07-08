import 'dart:async';
import 'siber_module.dart';
import 'siber_command.dart';

// Özellik Lobları (Modüller)
import 'playback_module.dart';
import 'dsp_module.dart';
import 'ai_network_module.dart';
import 'memory_module.dart';
import 'vibe_module.dart';
import 'system_module.dart'; // 🎯 YENİ LOB İÇERİ ALINDI

class SiberBeyin {
  // 🎯 SİBER MÜHÜR (Singleton): Sistemde beynin sadece tek bir kopyası yaşar!
  static final SiberBeyin _instance = SiberBeyin._internal();
  factory SiberBeyin() => _instance;
  SiberBeyin._internal();

  final Map<String, SiberModule> _modules = {};
  final StreamController<SiberCommand> _commandStream =
      StreamController<SiberCommand>.broadcast();

  bool _isAwake = false;
  Stream<SiberCommand> get commandStream => _commandStream.stream;

  // 🛡️ JAPON TEMELİ (AÇIK KAPI): Yeni bir özelliği beyne anında fişler
  void plugModule(SiberModule module) {
    if (_modules.containsKey(module.name)) return;
    _modules[module.name] = module;
    print("🔌 SİBER BAĞLANTI: ${module.name} beyne mühürlendi.");
  }

  // Sistemi Ateşle
  Future<void> wakeUp() async {
    if (_isAwake) return;
    print("\n🧠 Siber Beyin Uyanıyor... Japon temeli atılıyor.");

    // Saydığın 5 Temel Özelliği Otonom Fişliyoruz
    plugModule(PlaybackModule());
    plugModule(DspModule());
    plugModule(AiNetworkModule());
    plugModule(MemoryModule());
    plugModule(VibeModule());
    plugModule(SystemModule()); // 🎯 YENİ LOB BEYNE FİŞLENDİ

    // Hepsini ateşle (Biri çökse bile diğeri çalışır - SİBER İZOLATÖR)
    for (var module in _modules.values) {
      try {
        await module.initModule();
      } catch (e) {
        print(
            "❌ SİBER İZOLATÖR DEVREDE: ${module.name} başlatılamadı ama sistem çökmedi -> $e");
      }
    }
    _isAwake = true;
    print("✅ SİBER BEYİN AKTİF: Tüm loblar devrede, emre amadeyiz!\n");
  }

  // ⚡ Gelen Emri Loblara Dağıt (Merkezi Karar)
  Future<bool> processCommand(SiberCommand command) async {
    print("⚡ BEYİN İŞLİYOR: ${command.action}");
    _commandStream.add(command); // UI dinlemek isterse diye akışa at

    bool isHandled = false;
    for (var module in _modules.values) {
      // Eğer bu modül bu emri tanıyorsa veya her şeyi (*) kabul ediyorsa
      if (module.supportedActions.contains(command.action) ||
          module.supportedActions.contains('*')) {
        try {
          bool result = await module.execute(command);
          if (result) isHandled = true;
        } catch (e) {
          print(
              "🛑 SİBER İZOLATÖR: ${module.name} modülü '${command.action}' emrinde hata verdi (Uygulama Kurtarıldı) -> $e");
        }
      }
    }
    return isHandled;
  }
}
