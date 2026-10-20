import 'package:shared_preferences/shared_preferences.dart';
import 'history_service.dart';

enum SiberRank {
  yeniDinleyici,   // 0 saat
  cirakTaktisyen,  // 5 saat
  muziksever,      // 25 saat
  ritimTutkunu,    // 75 saat
  melodiUstasi,    // 150 saat
  sesGurmesi,      // 300 saat
  ozsesEfsanesi,   // 500+ saat
}

class RankTierInfo {
  final SiberRank rank;
  final String name;
  final int hours;
  final String perk;
  final String bonus;
  final int extraArchiveQuota;
  final int extraAiListQuota;
  final int adFreeMinutes;
  final bool unlocksWeatherMix;
  final bool unlocksMetamorphosis;

  const RankTierInfo({
    required this.rank,
    required this.name,
    required this.hours,
    required this.perk,
    required this.bonus,
    this.extraArchiveQuota = 0,
    this.extraAiListQuota = 0,
    this.adFreeMinutes = 0,
    this.unlocksWeatherMix = false,
    this.unlocksMetamorphosis = false,
  });
}

class RankManager {
  static final RankManager _instance = RankManager._internal();
  factory RankManager() => _instance;
  RankManager._internal();

  static const String _keyNotifiedRank = 'siber_notified_rank';

  static const List<RankTierInfo> allTiers = [
    RankTierInfo(
      rank: SiberRank.yeniDinleyici,
      name: 'Yeni Dinleyici',
      hours: 0,
      perk: 'Temel Erişim: Günlük 5 İndirme & 1 AI Liste',
      bonus: 'Standart Ekolayzer & Keşfet Akışı',
      extraArchiveQuota: 0,
      extraAiListQuota: 0,
      adFreeMinutes: 0,
    ),
    RankTierInfo(
      rank: SiberRank.cirakTaktisyen,
      name: 'Çırak Taktisyen',
      hours: 5,
      perk: '30 Dakika Geçici Reklamsız Dinleme Hediyesi',
      bonus: '+1 Günlük Ek İndirme (Günde 6 Şarkı)',
      extraArchiveQuota: 1,
      extraAiListQuota: 0,
      adFreeMinutes: 30,
    ),
    RankTierInfo(
      rank: SiberRank.muziksever,
      name: 'Müziksever',
      hours: 25,
      perk: '1 Saat Kesintisiz Reklamsız Dinleme Pass',
      bonus: '+2 Günlük Ek İndirme (Günde 7 Şarkı) & 2 AI Liste',
      extraArchiveQuota: 2,
      extraAiListQuota: 1,
      adFreeMinutes: 60,
    ),
    RankTierInfo(
      rank: SiberRank.ritimTutkunu,
      name: 'Ritim Tutkunu',
      hours: 75,
      perk: '2 Saat Geçici Reklamsız Siber Dinleme',
      bonus: '+3 Günlük Ek İndirme (Günde 8 Şarkı) & 2 Ayda 1 DNA Raporu',
      extraArchiveQuota: 3,
      extraAiListQuota: 1,
      adFreeMinutes: 120,
    ),
    RankTierInfo(
      rank: SiberRank.melodiUstasi,
      name: 'Melodi Ustası',
      hours: 150,
      perk: '4 Saat Kesintisiz Reklamsız Dinleme Pass',
      bonus: '+4 Günlük Ek İndirme (Günde 9 Şarkı) & 3 AI Çalma Listesi',
      extraArchiveQuota: 4,
      extraAiListQuota: 2,
      adFreeMinutes: 240,
    ),
    RankTierInfo(
      rank: SiberRank.sesGurmesi,
      name: 'Ses Gurmesi',
      hours: 300,
      perk: '8 Saat Boyunca Tamamen Reklamsız Deneyim',
      bonus: '+5 Günlük Ek İndirme (Günde 10 Şarkı) & 15 Günde 1 DNA Raporu',
      extraArchiveQuota: 5,
      extraAiListQuota: 2,
      adFreeMinutes: 480,
    ),
    RankTierInfo(
      rank: SiberRank.ozsesEfsanesi,
      name: 'ÖZSES Efsanesi',
      hours: 500,
      perk: '24 Saat (1 Tam Gün) Reklamsız Siber Dinleme Pass',
      bonus: '+7 Günlük Ek İndirme (Günde 12 Şarkı) & 4 AI Liste + Efsane Rozeti',
      extraArchiveQuota: 7,
      extraAiListQuota: 3,
      adFreeMinutes: 1440,
    ),
  ];

  RankTierInfo getTierInfo(SiberRank rank) {
    return allTiers.firstWhere((t) => t.rank == rank, orElse: () => allTiers.first);
  }

  // Rütbe isimleri
  String getRankTitle(SiberRank rank) {
    return getTierInfo(rank).name;
  }

  // Toplam süreyi (saat) history'den hesapla
  Future<int> getTotalListeningHours() async {
    try {
      final history = await HistoryService.getHistory();
      int totalSec = 0;
      for (var rec in history) {
        totalSec += rec.totalListenSeconds;
      }
      return totalSec ~/ 3600; // Saniyeden saate
    } catch (_) {
      return 0;
    }
  }

  // Rütbeyi hesapla
  Future<SiberRank> calculateCurrentRank() async {
    final hours = await getTotalListeningHours();
    if (hours >= 500) return SiberRank.ozsesEfsanesi;
    if (hours >= 300) return SiberRank.sesGurmesi;
    if (hours >= 150) return SiberRank.melodiUstasi;
    if (hours >= 75) return SiberRank.ritimTutkunu;
    if (hours >= 25) return SiberRank.muziksever;
    if (hours >= 5) return SiberRank.cirakTaktisyen;
    return SiberRank.yeniDinleyici;
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
