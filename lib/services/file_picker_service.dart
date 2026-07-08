import 'package:file_picker/file_picker.dart';

class FilePickerService {
  // 🚀 SİBER HAMLE: Android 11+ kısıtlamalarını aşmak için klasör yerine doğrudan ÇOKLU DOSYA seçtiriyoruz!
  static Future<List<String>?> pickMusicFiles() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.audio,
        dialogTitle: "Siber Arşive Eklenecek Müzikleri Seçin (Tümünü Seç Yapabilirsiniz)",
      );
      
      if (result != null) {
        // null olmayan geçerli yolları filtrele ve döndür
        return result.paths.where((path) => path != null).cast<String>().toList();
      }
      return null;
    } catch (e) {
      print("Siber Hata: Dosya seçici servisi çöktü -> $e");
      return null;
    }
  }
}
