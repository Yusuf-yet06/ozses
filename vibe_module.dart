import 'siber_module.dart';
import 'siber_command.dart';
import 'lib/services/audio_engine.dart';

class VibeModule extends SiberModule {
  @override
  String get name => "Ruh_Hali_Gorsel_Lobu";

  @override
  List<String> get supportedActions => ['toggle_visuals'];

  @override
  Future<void> initModule() async {}

  @override
  Future<bool> execute(SiberCommand command) async {
    if (command.action == 'toggle_visuals') {
      AudioEngine.visualEffectsEnabled = !AudioEngine.visualEffectsEnabled;
      return true;
    }
    return false;
  }

  @override
  Future<void> sleepModule() async {}
}
