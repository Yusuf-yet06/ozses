import 'dart:io';

class RadarFilter {
  static const List<String> _allowedExtensions = [
    '.mp3',
    '.wav',
    '.flac',
    '.m4a',
    '.aac'
  ];

  static bool isMusicFile(FileSystemEntity file) {
    if (file is! File) return false;
    final String path = file.path.toLowerCase();

    // Uzantı Kontrolü
    bool hasValidExtension =
        _allowedExtensions.any((ext) => path.endsWith(ext));
    if (!hasValidExtension) return false;

    // Boyut Kontrolü (100KB altı ses kayıtlarını eler)
    try {
      final int fileSize = file.lengthSync();
      return fileSize > (100 * 1024);
    } catch (e) {
      return false;
    }
  }
}
