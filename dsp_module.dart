import 'siber_module.dart';
import 'siber_command.dart';
import 'lib/main.dart'; // SİBER BASS/EQ İÇİN
import 'lib/services/audio_engine.dart'; // 🖥️ MASAÜSTÜ EQ MOTORU İÇİN

class DspModule extends SiberModule {
  @override
  String get name => 'DSP_Frekans_Lobları';

  @override
  List<String> get supportedActions =>
      ['bass_boost_on', 'bass_boost_off', 'eq_on', 'eq_off'];

  @override
  Future<void> initModule() async {
    print(
        '🎛️ DSP Lobu: Evrensel (PC + Mobil) Frekans Bükücü motorlar emre amade.');
  }

  @override
  Future<bool> execute(SiberCommand command) async {
    switch (command.action) {
      case 'bass_boost_on':
        // 🖥️ SİBER HAMLE: PC VE MOBİL ORTAK BASS MOTORU
        AudioEngine.applyPreset('Bas Boost');
        AudioEngine.syncHardware();
        return true;

      case 'bass_boost_off':
        AudioEngine.applyPreset('Normal');
        AudioEngine.syncHardware();
        return true;

      case 'eq_on':
        AudioEngine.applyPreset('Savaş Modu');
        AudioEngine.syncHardware();
        return true;

      case 'eq_off':
        AudioEngine.applyPreset('Normal');
        AudioEngine.syncHardware();
        return true;
    }
    return false;
  }

  @override
  Future<void> sleepModule() async {}
}
