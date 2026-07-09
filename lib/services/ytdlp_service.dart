import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class YtDlpService {
  static final YtDlpService _instance = YtDlpService._internal();
  factory YtDlpService() => _instance;
  YtDlpService._internal();

  String? _executablePath;
  bool _isDownloading = false;

  Future<void> init() async {
    if (!(!kIsWeb && Platform.isWindows)) return;
    
    try {
      final dir = await getApplicationSupportDirectory();
      final exePath = '${dir.path}\\yt-dlp.exe';
      _executablePath = exePath;

      final file = File(exePath);
      if (!await file.exists()) {
        await _downloadExecutable(file);
      } else {
        final size = await file.length();
        if (size < 10000000) {
          await _downloadExecutable(file);
        }
      }
    } catch (e) {
      print('❌ YtDlpService başlatılamadı: $e');
    }
  }

  Future<void> _downloadExecutable(File file) async {
    if (_isDownloading) return;
    _isDownloading = true;
    print('⬇️ yt-dlp.exe indiriliyor...');

    try {
      final response = await http.get(Uri.parse(
          'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe'));

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        print('✅ yt-dlp.exe başarıyla indirildi ve kuruldu.');
      } else {
        print('❌ yt-dlp.exe indirme hatası: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ yt-dlp.exe indirme hatası: $e');
    } finally {
      _isDownloading = false;
    }
  }

  Future<String> getExecutablePath() async {
    // Eğer şu an indiriliyorsa bitmesini bekle
    while (_isDownloading) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    if (_executablePath == null) {
      // Belki başlatılamadı, son bir kez dene
      await init();
    }
    
    if (_executablePath == null) {
      throw Exception('YtDlpService başlatılamadı veya Windows değil!');
    }
    return _executablePath!;
  }
}
