import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SiberBackupService {
  static const String _extension = 'siber';

  // 🎯 SİBER PROFİLİ DIŞA AKTAR (BACKUP)
  static Future<String?> exportProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      Map<String, dynamic> backupData = {};
      
      for (String key in keys) {
        // İlgili Siber Verilerini Topla
        backupData[key] = prefs.get(key);
      }

      // JSON'a dönüştür
      final String jsonString = jsonEncode(backupData);

      String? outputFile;
      
      if (Platform.isWindows) {
        outputFile = await FilePicker.saveFile(
          dialogTitle: 'Siber Profili Nereye Kaydedelim?',
          fileName: 'profile_backup.$_extension',
          type: FileType.custom,
          allowedExtensions: [_extension],
        );
      } else {
        // Android/iOS için klasör seçimi
        String? selectedDirectory = await FilePicker.getDirectoryPath(
          dialogTitle: 'Yedekleme Klasörünü Seçin'
        );
        if (selectedDirectory != null) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          outputFile = '$selectedDirectory/profile_backup_$timestamp.$_extension';
        }
      }

      if (outputFile == null) return null; // Kullanıcı iptal etti

      final File file = File(outputFile);
      await file.writeAsString(jsonString);

      return outputFile;
    } catch (e) {
      print('SİBER YEDEKLEME HATASI: $e');
      return null;
    }
  }

  // 🎯 SİBER PROFİLİ İÇE AKTAR (RESTORE)
  static Future<bool> importProfile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        dialogTitle: 'Siber Yedek Dosyasını Seçin',
        type: FileType.custom,
        allowedExtensions: [_extension],
      );

      if (result == null || result.files.single.path == null) return false;

      final File file = File(result.files.single.path!);
      final String jsonString = await file.readAsString();
      
      Map<String, dynamic> backupData = jsonDecode(jsonString);
      final prefs = await SharedPreferences.getInstance();

      // Eski verilerin üzerine yaz
      for (String key in backupData.keys) {
        var value = backupData[key];
        if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is String) {
          await prefs.setString(key, value);
        } else if (value is List) {
          await prefs.setStringList(key, List<String>.from(value));
        }
      }

      return true; // Başarılı
    } catch (e) {
      print('SİBER GERİ YÜKLEME HATASI: $e');
      return false;
    }
  }
}
