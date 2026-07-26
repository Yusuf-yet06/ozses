import 'package:shared_preferences/shared_preferences.dart';
import 'history_service.dart';

enum SiberRank {
  caylak,       // 0 - 10 hours
  er,           // 10 - 50 hours
  cavus,        // 50 - 150 hours
  komando,      // 150 - 300 hours
  bordoBereli,  // 300 - 600 hours
  general,      // 600 - 1000 hours
  ilah          // 1000+ hours
}

class RankManager {
  static final RankManager _instance = RankManager._internal();
  factory RankManager() => _instance;
  RankManager._internal();

  static const String _keyNotifiedRank = 'siber_notified_rank';

  // Rütbe isimleri
  String getRankTitle(SiberRank rank) {
    switch (rank) {
      case SiberRank.caylak: return 'Siber Çaylak';
      case SiberRank.er: return 'Siber Er';
      case SiberRank.cavus: return 'Siber Çavuş';
      case SiberRank.komando: return 'Siber Komando';
      case SiberRank.bordoBereli: return 'Siber Bordo Bereli';
      case SiberRank.general: return 'Siber General';
      case SiberRank.ilah: return 'Siber İlah';
    }
  }

  // Toplam süreyi (saat) history'den hesapla
  Future<int> getTotalListeningHours() async {
    final history = await HistoryService.getHistory();
    int totalSec = 0;
    for (var rec in history) {
      totalSec += rec.totalListenSeconds;
    }
    return totalSec ~/ 3600; // Saniyeden saate
  }

  // Rütbeyi hesapla
  Future<SiberRank> calculateCurrentRank() async {
    final hours = await getTotalListeningHours();
    if (hours >= 1000) return SiberRank.ilah;
    if (hours >= 600) return SiberRank.general;
    if (hours >= 300) return SiberRank.bordoBereli;
    if (hours >= 150) return SiberRank.komando;
    if (hours >= 50) return SiberRank.cavus;
    if (hours >= 10) return SiberRank.er;
    return SiberRank.caylak;
  }

  // Yeni rütbeye geçildi mi kontrolü (Bildirim için)
  Future<SiberRank?> checkRankUp() async {
    final currentRank = await calculateCurrentRank();
    final prefs = await SharedPreferences.getInstance();
    final savedRankIndex = prefs.getInt(_keyNotifiedRank) ?? 0;

    if (currentRank.index > savedRankIndex) {
      await prefs.setInt(_keyNotifiedRank, currentRank.index);
      return currentRank; // Rütbe atladı!
    }
    return null;
  }
}
