import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:id3/id3.dart';

// 🎯 SİBER HAMLE: MP3 dosyalarının içine sızıp gizli künyeyi (Metadata) ve resmi söken servis!
class ID3Service {
  static Future<Map<String, dynamic>> extractTags(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return {};

      // 🛡️ SİBER KALKAN: Şarkıyı okuyup ID3 verisini söküyoruz
      final bytes = await file.readAsBytes();
      final mp3 = MP3Instance(bytes);

      if (mp3.parseTagsSync()) {
        return mp3.getMetaTags() ?? {};
      }
    } catch (e) {
      print('Siber Hata: ID3 Künyesi Okunamadı -> $e');
    }
    return {};
  }

  static Uint8List? getCoverBytes(Map<String, dynamic> tags) {
    try {
      // 🎯 MP3'ün içindeki APIC (Attached Picture) kodunu çözüyoruz
      if (tags['APIC'] != null && tags['APIC']['base64'] != null) {
        return base64Decode(tags['APIC']['base64']);
      }
      // 🎯 SİBER KALKAN: Bazı eski MP3'ler PIC (ID3v2.2) etiketi kullanır, onu da yakalayalım!
      if (tags['PIC'] != null && tags['PIC']['base64'] != null) {
        return base64Decode(tags['PIC']['base64']);
      }
    } catch (_) {}
    return null;
  }
}
