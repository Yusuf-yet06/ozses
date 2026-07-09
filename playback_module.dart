import 'siber_module.dart';
import 'siber_command.dart';
import 'lib/main.dart'; // audioHandler ana motoru için

class PlaybackModule extends SiberModule {
  @override
  String get name => 'Oynatma_Motoru_Lobu';

  @override
  List<String> get supportedActions =>
      ['play', 'pause', 'next', 'previous', 'stop'];

  @override
  Future<void> initModule() async {}

  @override
  Future<bool> execute(SiberCommand command) async {
    switch (command.action) {
      case 'play':
        await audioHandler.play();
        return true;
      case 'pause':
        await audioHandler.pause();
        return true;
      case 'next':
        await audioHandler.skipToNext();
        return true;
      case 'previous':
        await audioHandler.skipToPrevious();
        return true;
      case 'stop':
        await audioHandler.stop();
        return true;
    }
    return false;
  }

  @override
  Future<void> sleepModule() async {}
}
