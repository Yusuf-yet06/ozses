import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// 🎯 SİBER HAMLE: Şarkı Geçmişi (History) Motoru
class HistoryRecord {
  final String path;
  String name;
  int playCount;
  int totalListenSeconds;
  int lastPlayedTimestamp;

  HistoryRecord({
    required this.path,
    required this.name,
    required this.playCount,
    required this.totalListenSeconds,
    required this.lastPlayedTimestamp,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'playCount': playCount,
        'totalListenSeconds': totalListenSeconds,
        'lastPlayedTimestamp': lastPlayedTimestamp,
      };

  factory HistoryRecord.fromJson(Map<String, dynamic> json) => HistoryRecord(
        path: json['path'],
        name: json['name'],
        playCount: json['playCount'] ?? 0,
        totalListenSeconds: json['totalListenSeconds'] ?? 0,
        lastPlayedTimestamp: json['lastPlayedTimestamp'] ?? 0,
      );
}

class HistoryService {
  static const String _key = 'siber_history_v7';

  static Future<List<HistoryRecord>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return [];
    try {
      final List<dynamic> decoded = json.decode(data);
      return decoded.map((e) => HistoryRecord.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // 🎯 SİBER HAMLE: Sadece Son 7 Günün (Haftalık) Geçmişini Döndüren Motor
  static Future<List<HistoryRecord>> getWeeklyHistory() async {
    final allHistory = await getHistory();
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int sevenDaysMs = 7 * 24 * 60 * 60 * 1000;
    
    return allHistory.where((record) {
      return (now - record.lastPlayedTimestamp) <= sevenDaysMs;
    }).toList();
  }

  static Future<void> recordPlay(String path, String safeName) async {
    if (path == 'bilinmeyen_yol' || path.isEmpty) return;
    final history = await getHistory();
    final int now = DateTime.now().millisecondsSinceEpoch;

    int existingIndex = history.indexWhere((e) => e.path == path);
    if (existingIndex != -1) {
      history[existingIndex].playCount += 1;
      history[existingIndex].name =
          safeName; // ID3'ten yeni isim geldiyse güncelle
      history[existingIndex].lastPlayedTimestamp = now;
    } else {
      history.add(HistoryRecord(
        path: path,
        name: safeName,
        playCount: 1,
        totalListenSeconds: 0,
        lastPlayedTimestamp: now,
      ));
    }

    history
        .sort((a, b) => b.lastPlayedTimestamp.compareTo(a.lastPlayedTimestamp));
    if (history.length > 200)
      history.removeRange(200, history.length); // 🛡️ Şişmeyi önle

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, json.encode(history.map((e) => e.toJson()).toList()));
  }

  // 🎯 Toplam Süreyi (Çalma Sayısı * Şarkı Süresi) otonom hesaplayan mühür
  static Future<void> updateDuration(String path, int durationSeconds) async {
    if (durationSeconds <= 0) return;
    final history = await getHistory();
    int idx = history.indexWhere((e) => e.path == path);
    if (idx != -1) {
      history[idx].totalListenSeconds =
          history[idx].playCount * durationSeconds;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, json.encode(history.map((e) => e.toJson()).toList()));
    }
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  // 🎯 SİBER HAMLE: Geçmişten Tekil Kayıt Silme (Sök At)
  static Future<void> deleteRecord(String path) async {
    final history = await getHistory();
    history.removeWhere((e) => e.path == path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, json.encode(history.map((e) => e.toJson()).toList()));
  }
  // 🎯 SİBER HAMLE: Sonic Aura (Kullanıcının Müzik Kimliği) Hesaplayıcısı
  static Future<Map<String, dynamic>> getSonicAura() async {
    final historyList = await getHistory();
    if (historyList.isEmpty) return {"aura": "Renksiz", "color": 0xFF9E9E9E, "desc": "Henüz yeterli veri yok."};

    Map<String, int> moodTags = {"Enerji": 0, "Sokak": 0, "Melankoli": 0, "Odak": 0, "Gizem": 0};
    for (var h in historyList) {
      final t = h.name.toLowerCase();
      if (t.contains("rap") || t.contains("drill") || t.contains("hip") || t.contains("ezhel") || t.contains("sokak")) moodTags["Sokak"] = moodTags["Sokak"]! + h.playCount;
      else if (t.contains("slow") || t.contains("akustik") || t.contains("aşk") || t.contains("sezen") || t.contains("müslüm") || t.contains("arabesk")) moodTags["Melankoli"] = moodTags["Melankoli"]! + h.playCount;
      else if (t.contains("mix") || t.contains("club") || t.contains("remix") || t.contains("pop") || t.contains("hareketli")) moodTags["Enerji"] = moodTags["Enerji"]! + h.playCount;
      else if (t.contains("lofi") || t.contains("chill") || t.contains("study") || t.contains("odak")) moodTags["Odak"] = moodTags["Odak"]! + h.playCount;
      else moodTags["Gizem"] = moodTags["Gizem"]! + h.playCount;
    }

    String dominant = "Gizem";
    int maxCount = -1;
    moodTags.forEach((k, v) {
      if (v > maxCount) {
        maxCount = v;
        dominant = k;
      }
    });

    switch (dominant) {
      case "Enerji": return {"aura": "Enerji Patlaması", "color": 0xFFFF5722, "desc": "Yüksek frekanslı ve hareketli bir auran var!"};
      case "Sokak": return {"aura": "Asi Sokaklar", "color": 0xFFE91E63, "desc": "Agresif ve tavizsiz bir müzik zevkin var."};
      case "Melankoli": return {"aura": "Derin Hisler", "color": 0xFF3F51B5, "desc": "Duygusal ve nostaljik frekanslarda geziyorsun."};
      case "Odak": return {"aura": "Sakin Zihin", "color": 0xFF009688, "desc": "Müzik senin için bir odaklanma ve huzur aracı."};
      default: return {"aura": "Gizemli Frekans", "color": 0xFF9C27B0, "desc": "Sınırları çizmeyen, keşfe açık bir auran var."};
    }
  }
}