import 'siber_module.dart';
import 'siber_command.dart';
import 'lib/services/history_service.dart';

class MemoryModule extends SiberModule {
  @override
  String get name => "Siber_Hafiza_Lobu";

  @override
  List<String> get supportedActions => ['clear_history'];

  @override
  Future<void> initModule() async {}

  @override
  Future<bool> execute(SiberCommand command) async {
    if (command.action == 'clear_history') {
      await HistoryService.clearHistory();
      return true;
    }
    return false;
  }

  @override
  Future<void> sleepModule() async {}
}
