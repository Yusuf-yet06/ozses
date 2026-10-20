import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 🔮 SİBER METAMORFOZ MİX MODELİ
/// Kullanıcının belirlediği Başlangıç Ruh Hali/Türü ➔ Hedef Ruh Hali/Türü dönüşümünü saklar.
class MetamorphosisMix {
  final String id;
  final String title; // Örn: 'Rap Depresif ➔ Enerji Patlaması'
  final String startMood; // Başlangıç ruh hali / tarzı (Örn: 'Rap Depresif')
  final String targetMood; // Hedef ruh hali / boyutu (Örn: 'Enerji Patlaması')
  final String query; // Arama ve otonom akış sorgusu
  final String thumbnail; // Kapak görseli
  final DateTime createdAt;
  final List<Map<String, dynamic>> customTracks; // 🎯 Kullanıcının Keşfet'ten manuel eklediği özel parçalar

  MetamorphosisMix({
    required this.id,
    required this.title,
    required this.startMood,
    required this.targetMood,
    required this.query,
    this.thumbnail = '',
    required this.createdAt,
    this.customTracks = const [],
  });

  MetamorphosisMix copyWith({
    String? id,
    String? title,
    String? startMood,
    String? targetMood,
    String? query,
    String? thumbnail,
    DateTime? createdAt,
    List<Map<String, dynamic>>? customTracks,
  }) {
    return MetamorphosisMix(
      id: id ?? this.id,
      title: title ?? this.title,
      startMood: startMood ?? this.startMood,
      targetMood: targetMood ?? this.targetMood,
      query: query ?? this.query,
      thumbnail: thumbnail ?? this.thumbnail,
      createdAt: createdAt ?? this.createdAt,
      customTracks: customTracks ?? this.customTracks,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'startMood': startMood,
        'targetMood': targetMood,
        'query': query,
        'thumbnail': thumbnail,
        'createdAt': createdAt.toIso8601String(),
        'customTracks': customTracks,
      };

  factory MetamorphosisMix.fromJson(Map<String, dynamic> json) =>
      MetamorphosisMix(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] ?? 'Duygu Dönüşümü',
        startMood: json['startMood'] ?? 'Depresif',
        targetMood: json['targetMood'] ?? 'Enerji',
        query: json['query'] ?? 'Mix',
        thumbnail: json['thumbnail'] ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
        customTracks: json['customTracks'] != null
            ? List<Map<String, dynamic>>.from(
                (json['customTracks'] as List)
                    .map((x) => Map<String, dynamic>.from(x as Map)))
            : const [],
      );
}

/// 🔮 SİBER METAMORFOZ HAFIZA VE YÖNETİM SERVİSİ
class MetamorphosisService {
  static const String _prefKey = 'siber_saved_metamorphosis_mixes';

  /// Kayıtlı tüm dönüşüm mikslerini çeker
  static Future<List<MetamorphosisMix>> getSavedMixes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => MetamorphosisMix.fromJson(e)).toList();
    } catch (e) {
      print('Siber Metamorfoz okuma hatası: $e');
      return [];
    }
  }

  /// Yeni bir dönüşüm miksi kaydeder
  static Future<bool> saveMix(MetamorphosisMix mix) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = await getSavedMixes();
      currentList.removeWhere((item) => item.id == mix.id);
      currentList.insert(0, mix);
      final raw = jsonEncode(currentList.map((e) => e.toJson()).toList());
      return await prefs.setString(_prefKey, raw);
    } catch (e) {
      print('Siber Metamorfoz kaydetme hatası: $e');
      return false;
    }
  }

  /// Kayıtlı bir dönüşüm miksine Keşfet'ten tek parça mühürler
  static Future<bool> addTrackToMix(String mixId, Map<String, dynamic> track) async {
    try {
      final currentList = await getSavedMixes();
      final index = currentList.indexWhere((item) => item.id == mixId);
      if (index == -1) return false;

      final existingMix = currentList[index];
      final trackId = track['id'] ?? track['videoId'] ?? track['video_id'];
      
      // Zaten varsa tekrar ekleme
      final tracks = List<Map<String, dynamic>>.from(existingMix.customTracks);
      final exists = tracks.any((t) {
        final tid = t['id'] ?? t['videoId'] ?? t['video_id'];
        return tid != null && tid == trackId;
      });

      if (!exists) {
        tracks.add(Map<String, dynamic>.from(track));
      }

      currentList[index] = existingMix.copyWith(customTracks: tracks);
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(currentList.map((e) => e.toJson()).toList());
      return await prefs.setString(_prefKey, raw);
    } catch (e) {
      print('Siber Metamorfoz parça ekleme hatası: $e');
      return false;
    }
  }

  /// Kayıtlı bir dönüşüm miksinden parça çıkarır
  static Future<bool> removeTrackFromMix(String mixId, String trackId) async {
    try {
      final currentList = await getSavedMixes();
      final index = currentList.indexWhere((item) => item.id == mixId);
      if (index == -1) return false;

      final existingMix = currentList[index];
      final tracks = List<Map<String, dynamic>>.from(existingMix.customTracks);
      tracks.removeWhere((t) {
        final tid = t['id'] ?? t['videoId'] ?? t['video_id'];
        return tid != null && tid == trackId;
      });

      currentList[index] = existingMix.copyWith(customTracks: tracks);
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(currentList.map((e) => e.toJson()).toList());
      return await prefs.setString(_prefKey, raw);
    } catch (e) {
      print('Siber Metamorfoz parça silme hatası: $e');
      return false;
    }
  }

  /// Kayıtlı bir dönüşüm miksini siler
  static Future<bool> deleteMix(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = await getSavedMixes();
      currentList.removeWhere((item) => item.id == id);
      final raw = jsonEncode(currentList.map((e) => e.toJson()).toList());
      return await prefs.setString(_prefKey, raw);
    } catch (e) {
      print('Siber Metamorfoz silme hatası: $e');
      return false;
    }
  }
}
