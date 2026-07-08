import '../core/platform/siber_platform.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
// ignore: unused_import
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'radar_filter.dart';

class StorageService {
  static Future<String> getOzsesDownloadPath() async {
    return await SiberPlatform.instance.getDownloadPath();
  }

  Future<List<String>> autoScanMusicFolder() async {
    try {
      return await SiberPlatform.instance.scanMusicFolders();
    } catch (e) {
      print("Siber Tarama Hatası: $e");
      return [];
    }
  }

  Future<List<String>> getPlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('all_songs') ?? [];
  }
}
