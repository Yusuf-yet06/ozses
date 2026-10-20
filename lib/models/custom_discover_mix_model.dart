import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 🎧 MANUEL KEŞFET MİKS MODELİ (Tamamen Ücretsiz)
/// Kullanıcının Keşfet'te gezerken beğendiği şarkıları bir araya getirdiği özel manuel çalma listeleri / miksler.
class CustomDiscoverMix {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<Map<String, dynamic>> tracks;

  CustomDiscoverMix({
    required this.id,
    required this.title,
    required this.createdAt,
    this.tracks = const [],
  });

  CustomDiscoverMix copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    List<Map<String, dynamic>>? tracks,
  }) {
    return CustomDiscoverMix(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      tracks: tracks ?? this.tracks,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'tracks': tracks,
      };

  factory CustomDiscoverMix.fromJson(Map<String, dynamic> json) =>
      CustomDiscoverMix(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] ?? 'Özel Miks',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
        tracks: json['tracks'] != null
            ? List<Map<String, dynamic>>.from(
                (json['tracks'] as List)
                    .map((x) => Map<String, dynamic>.from(x as Map)))
            : const [],
      );
}

/// 🎧 MANUEL KEŞFET MİKS SERVİSİ
class CustomDiscoverMixService {
  static const String _prefKey = 'siber_custom_discover_mixes_v1';

  /// Tüm manuel miksleri çeker
  static Future<List<CustomDiscoverMix>> getMixes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => CustomDiscoverMix.fromJson(e)).toList();
    } catch (e) {
      print('CustomDiscoverMixService okuma hatası: $e');
      return [];
    }
  }

  /// Yeni manuel miks oluşturur
  static Future<CustomDiscoverMix?> createMix(String title, {List<Map<String, dynamic>>? initialTracks}) async {
    try {
      final cleanTitle = title.trim().isEmpty ? 'Özel Miks' : title.trim();
      final newMix = CustomDiscoverMix(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: cleanTitle,
        createdAt: DateTime.now(),
        tracks: initialTracks ?? [],
      );
      final currentList = await getMixes();
      currentList.insert(0, newMix);
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(currentList.map((e) => e.toJson()).toList());
      await prefs.setString(_prefKey, raw);
      return newMix;
    } catch (e) {
      print('CustomDiscoverMixService oluşturma hatası: $e');
      return null;
    }
  }

  /// Bir mikse parça ekler
  static Future<bool> addTrackToMix(String mixId, Map<String, dynamic> track) async {
    try {
      final currentList = await getMixes();
      final index = currentList.indexWhere((m) => m.id == mixId);
      if (index == -1) return false;

      final mix = currentList[index];
      final trackId = track['id'] ?? track['videoId'] ?? track['video_id'];

      final tracks = List<Map<String, dynamic>>.from(mix.tracks);
      final exists = tracks.any((t) {
        final tid = t['id'] ?? t['videoId'] ?? t['video_id'];
        return tid != null && tid == trackId;
      });

      if (!exists) {
        tracks.add(Map<String, dynamic>.from(track));
      }

      currentList[index] = mix.copyWith(tracks: tracks);
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(currentList.map((e) => e.toJson()).toList());
      return await prefs.setString(_prefKey, raw);
    } catch (e) {
      print('CustomDiscoverMixService parça ekleme hatası: $e');
      return false;
    }
  }

  /// Miksten parça çıkarır
  static Future<bool> removeTrackFromMix(String mixId, String trackId) async {
    try {
      final currentList = await getMixes();
      final index = currentList.indexWhere((m) => m.id == mixId);
      if (index == -1) return false;

      final mix = currentList[index];
      final tracks = List<Map<String, dynamic>>.from(mix.tracks);
      tracks.removeWhere((t) {
        final tid = t['id'] ?? t['videoId'] ?? t['video_id'];
        return tid != null && tid == trackId;
      });

      currentList[index] = mix.copyWith(tracks: tracks);
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(currentList.map((e) => e.toJson()).toList());
      return await prefs.setString(_prefKey, raw);
    } catch (e) {
      print('CustomDiscoverMixService parça silme hatası: $e');
      return false;
    }
  }

  /// Miksi tamamen siler
  static Future<bool> deleteMix(String mixId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = await getMixes();
      currentList.removeWhere((m) => m.id == mixId);
      final raw = jsonEncode(currentList.map((e) => e.toJson()).toList());
      return await prefs.setString(_prefKey, raw);
    } catch (e) {
      print('CustomDiscoverMixService silme hatası: $e');
      return false;
    }
  }
}
