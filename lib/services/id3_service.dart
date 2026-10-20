import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:id3/id3.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/song_media_utils.dart';

// 🎯 SİBER HAMLE: MP3, M4A ve yerel müzik dosyalarının içine sızıp gizli künyeyi ve albüm kapağını söken servis!
class ID3Service {
  static final Map<String, Uint8List?> _memoryCoverCache = {};

  static String normalizeFilePath(String path) {
    String clean = path.trim();
    if (clean.startsWith('file://')) {
      try {
        clean = Uri.parse(clean).toFilePath();
      } catch (_) {
        clean = clean.replaceFirst(RegExp(r'^file://+'), '');
      }
    }
    return clean;
  }

  /// M4A / MP4 dosyasının 'covr' kutusundan resim baytlarını çıkarır
  static Uint8List? extractM4aCover(List<int> bytes) {
    for (int i = 0; i < bytes.length - 16; i++) {
      // 'covr' = 0x63, 0x6F, 0x76, 0x72
      if (bytes[i] == 0x63 &&
          bytes[i + 1] == 0x6F &&
          bytes[i + 2] == 0x76 &&
          bytes[i + 3] == 0x72) {
        int searchLimit = (i + 512 < bytes.length) ? i + 512 : bytes.length - 8;
        for (int j = i + 4; j < searchLimit; j++) {
          // 'data' = 0x64, 0x61, 0x74, 0x61
          if (bytes[j] == 0x64 &&
              bytes[j + 1] == 0x61 &&
              bytes[j + 2] == 0x74 &&
              bytes[j + 3] == 0x61) {
            int dataBoxLen = ((bytes[j - 4] & 0xFF) << 24) |
                             ((bytes[j - 3] & 0xFF) << 16) |
                             ((bytes[j - 2] & 0xFF) << 8) |
                             (bytes[j - 1] & 0xFF);
            int payloadStart = j + 12; // 'data' + 4 flags + 4 locale
            int payloadLen = dataBoxLen - 16;
            if (payloadLen > 0 && payloadStart + payloadLen <= bytes.length) {
              return Uint8List.fromList(bytes.sublist(payloadStart, payloadStart + payloadLen));
            }
          }
        }
      }
    }
    return null;
  }

  /// Dosyanın bulunduğu klasördeki albüm resimlerini (cover.jpg, folder.jpg vb.) arar
  static Future<Uint8List?> _findDirectoryCover(String cleanPath) async {
    try {
      final file = File(cleanPath);
      final parent = file.parent;
      if (!await parent.exists()) return null;

      final pathWithoutExt = cleanPath.replaceAll(RegExp(r'\.[^.]+$'), '');
      final fileNameOnly = file.uri.pathSegments.isNotEmpty
          ? file.uri.pathSegments.last.replaceAll(RegExp(r'\.[^.]+$'), '')
          : '';

      final candidates = [
        '$pathWithoutExt.jpg',
        '$pathWithoutExt.png',
        '$pathWithoutExt.jpeg',
        if (fileNameOnly.isNotEmpty) '${parent.path}/$fileNameOnly.jpg',
        '${parent.path}/cover.jpg',
        '${parent.path}/cover.png',
        '${parent.path}/folder.jpg',
        '${parent.path}/folder.png',
        '${parent.path}/album.jpg',
        '${parent.path}/album.png',
      ];

      for (final candidate in candidates) {
        final imgFile = File(candidate);
        if (await imgFile.exists()) {
          return await imgFile.readAsBytes();
        }
      }
    } catch (_) {}
    return null;
  }

  /// Çevrimdışı kaydedilen videoId küçük resmini arar
  static Future<Uint8List?> _findCacheThumbnail(String? videoId) async {
    if (videoId == null || videoId.isEmpty) return null;
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final thumbFile = File('${docsDir.path}/siber_offline_cache/$videoId.jpg');
      if (await thumbFile.exists()) {
        return await thumbFile.readAsBytes();
      }
    } catch (_) {}
    return null;
  }

  /// Kapak resmini yerel çevrimdışı önbelleğe kaydeder
  static Future<void> cacheCoverBytes(String videoId, Uint8List bytes) async {
    if (videoId.isEmpty) return;
    _memoryCoverCache[videoId] = bytes;
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${docsDir.path}/siber_offline_cache');
      if (!await dir.exists()) await dir.create(recursive: true);
      final file = File('${dir.path}/$videoId.jpg');
      await file.writeAsBytes(bytes);
    } catch (_) {}
  }

  /// Şarkı dosyasından veya yerel depolamadan kapak resmini çözer (En hızlıdan en yavaşa)
  static Future<Uint8List?> getCoverBytesForSong(
    String? filePath, {
    String? videoId,
    String? artUrl,
  }) async {
    if (filePath == null && videoId == null && artUrl == null) return null;

    final key = videoId ?? filePath ?? artUrl!;
    if (_memoryCoverCache.containsKey(key)) {
      return _memoryCoverCache[key];
    }

    // 1. VideoId ile kaydedilmiş yerel küçük resmi kontrol et
    if (videoId != null && videoId.isNotEmpty) {
      final cachedBytes = await _findCacheThumbnail(videoId);
      if (cachedBytes != null) {
        _memoryCoverCache[key] = cachedBytes;
        return cachedBytes;
      }
    }

    // 2. Dosya yolundan çıkarılan videoId ile yerel önbellek resmi kontrolü
    if (filePath != null) {
      final extractedVid = extractVideoIdFromPath(filePath);
      if (extractedVid != null && extractedVid.isNotEmpty) {
        final cachedBytes = await _findCacheThumbnail(extractedVid);
        if (cachedBytes != null) {
          _memoryCoverCache[key] = cachedBytes;
          return cachedBytes;
        }
      }
    }

    // 3. Yerel ses dosyasından etiket ve gömülü görsel taraması
    if (filePath != null &&
        filePath.isNotEmpty &&
        !filePath.startsWith('downloading:') &&
        filePath != 'bilinmeyen_yol') {
      final clean = normalizeFilePath(filePath);
      final file = File(clean);
      if (await file.exists()) {
        final tags = await extractTags(clean);
        final tagBytes = getCoverBytes(tags);
        if (tagBytes != null) {
          _memoryCoverCache[key] = tagBytes;
          return tagBytes;
        }

        // Klasör içi resim arayışı (cover.jpg vb.)
        final dirBytes = await _findDirectoryCover(clean);
        if (dirBytes != null) {
          _memoryCoverCache[key] = dirBytes;
          return dirBytes;
        }
      }
    }

    // 4. artUrl yerel dosya ise
    if (artUrl != null && artUrl.isNotEmpty && !artUrl.startsWith('http')) {
      final artFile = File(normalizeFilePath(artUrl));
      if (await artFile.exists()) {
        final bytes = await artFile.readAsBytes();
        _memoryCoverCache[key] = bytes;
        return bytes;
      }
    }

    _memoryCoverCache[key] = null;
    return null;
  }

  static Future<Map<String, dynamic>> extractTags(String filePath) async {
    final clean = normalizeFilePath(filePath);
    try {
      final file = File(clean);
      if (!await file.exists()) return {};

      final len = await file.length();
      List<int> bytes;
      if (len > 3 * 1024 * 1024) {
        final raf = await file.open();
        try {
          bytes = await raf.read(3 * 1024 * 1024);
        } finally {
          await raf.close();
        }
      } else {
        bytes = await file.readAsBytes();
      }

      // MP3 ve ID3v2 formatı
      if (bytes.length >= 3 && latin1.decode(bytes.sublist(0, 3)) == 'ID3') {
        final mp3 = MP3Instance(bytes);
        if (mp3.parseTagsSync()) {
          return mp3.getMetaTags() ?? {};
        }
      }

      // M4A / MP4 formatı
      final m4aCover = extractM4aCover(bytes);
      if (m4aCover != null) {
        return {
          'coverBytes': m4aCover,
        };
      }
    } catch (e) {
      print('Siber Hata: ID3/M4A Künyesi Okunamadı -> $e');
    }
    return {};
  }

  static Uint8List? getCoverBytes(Map<String, dynamic> tags) {
    try {
      if (tags['coverBytes'] is Uint8List) {
        return tags['coverBytes'] as Uint8List;
      }
      // 🎯 MP3'ün içindeki APIC (Attached Picture) kodunu çözüyoruz
      if (tags['APIC'] != null && tags['APIC']['base64'] != null) {
        return base64Decode(tags['APIC']['base64']);
      }
      // 🎯 SİBER KALKAN: Bazı eski MP3'ler PIC (ID3v2.2) etiketi kullanır
      if (tags['PIC'] != null && tags['PIC']['base64'] != null) {
        return base64Decode(tags['PIC']['base64']);
      }
    } catch (_) {}
    return null;
  }
}
