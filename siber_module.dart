import 'siber_command.dart';

/// 🎯 JAPON TEMELİ (SİBER LOB ARAYÜZÜ)
/// Beyne eklenecek her yeni özellik (DSP, Çalar, AI, Görsel) bu kalıptan türemelidir.
abstract class SiberModule {
  // Modülün siber adı
  String get name;

  // Bu lobun anlayabileceği emirlerin (action) listesi
  List<String> get supportedActions;

  // Lob beyne takıldığında otonom çalışacak hazırlık motoru
  Future<void> initModule();

  // Beyinden gelen emri icra eden asıl tetikleyici
  Future<bool> execute(SiberCommand command);

  // Uyku moduna geçiş
  Future<void> sleepModule();
}
