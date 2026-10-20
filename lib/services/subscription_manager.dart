import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'rank_manager.dart';

enum SiberTier {
  free,
  student,
  premium,
}

class SubscriptionManager {
  static final SubscriptionManager _instance = SubscriptionManager._internal();
  factory SubscriptionManager() => _instance;
  SubscriptionManager._internal();

  SiberTier _currentTier = SiberTier.free;
  SiberRank _currentRank = SiberRank.yeniDinleyici;
  SiberRank? _manualRankForTesting;
  DateTime? _adFreeUntil;
  
  /// 🔔 SİBER REKLAMSIZ MOD BİLDİRİCİSİ (Tüm ekranlar ve bannerlar anında tepki verir)
  final ValueNotifier<bool> adFreeNotifier = ValueNotifier<bool>(false);

  void _notifyAdFree() {
    adFreeNotifier.value = isAdFree;
  }
  
  // 🛡️ SİBER KALKAN: Donanımsal Şifreleme (Keystore/Keychain)
  final _storage = const FlutterSecureStorage();

  // Key Constants
  static const String _keyTier = 'siber_tier';
  static const String _keyAiCount = 'ai_playlist_count';
  static const String _keyAiDate = 'ai_playlist_date';
  static const String _keyVoiceCount = 'voice_command_count';
  static const String _keyVoiceDate = 'voice_command_date';
  static const String _keyLastStatsDate = 'last_stats_date';
  static const String _keyArchiveCount = 'archive_count';
  static const String _keyArchiveDate = 'archive_date';
  static const String _keyAdFreeUntil = 'siber_ad_free_until';
  static const String _keyClaimedAdFreeRanks = 'siber_claimed_ad_free_ranks';

  Future<void> init() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        CustomerInfo customerInfo = await Purchases.getCustomerInfo();
        await _updateTierFromCustomerInfo(customerInfo);
      } else {
        await _loadLocalTier();
      }
    } catch (e) {
      print('⚡ Siber Hata: RevenueCat bağlantısı kurulamadı. Şifreli lokal belleğe dönülüyor. Hata: $e');
      await _loadLocalTier();
    }
    
    final untilStr = await _storage.read(key: _keyAdFreeUntil);
    if (untilStr != null) {
      final parsed = DateTime.tryParse(untilStr);
      if (parsed != null && DateTime.now().isBefore(parsed)) {
        _adFreeUntil = parsed;
      }
    }

    _currentRank = await RankManager().calculateCurrentRank();
    _notifyAdFree();
  }

  Future<void> _loadLocalTier() async {
    final tierStr = await _storage.read(key: _keyTier) ?? 'free';
    if (tierStr == 'premium') {
      _currentTier = SiberTier.premium;
    } else if (tierStr == 'student') {
      _currentTier = SiberTier.student;
    } else {
      _currentTier = SiberTier.free;
    }
    _notifyAdFree();
  }

  Future<void> _updateTierFromCustomerInfo(CustomerInfo customerInfo) async {
    if (customerInfo.entitlements.all["premium"]?.isActive == true) {
      _currentTier = SiberTier.premium;
      await _storage.write(key: _keyTier, value: 'premium');
    } else if (customerInfo.entitlements.all["student"]?.isActive == true) {
      _currentTier = SiberTier.student;
      await _storage.write(key: _keyTier, value: 'student');
    } else {
      // Developer Mode Bypass
      final local = await _storage.read(key: _keyTier) ?? 'free';
      if (local == 'premium' || local == 'student') {
        await _loadLocalTier(); 
      } else {
        _currentTier = SiberTier.free;
        await _storage.write(key: _keyTier, value: 'free');
      }
    }
    _notifyAdFree();
  }

  Future<void> syncPurchases() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        CustomerInfo customerInfo = await Purchases.restorePurchases();
        await _updateTierFromCustomerInfo(customerInfo);
      }
    } catch (e) {
      print('⚡ Siber Hata: Alımlar senkronize edilemedi $e');
    }
    _notifyAdFree();
  }

  SiberTier get currentTier => _currentTier;
  SiberRank get currentRank => _manualRankForTesting ?? _currentRank;

  void setCurrentRankForTesting(SiberRank? rank) {
    _manualRankForTesting = rank;
    if (rank != null) _currentRank = rank;
  }

  Future<void> setTier(SiberTier newTier) async {
    _currentTier = newTier;
    await _storage.write(key: _keyTier, value: newTier.name);
    _notifyAdFree();
  }

  // --- SİBER LİMİT KONTROLLERİ ---

  // --- SİBER LİMİT VE RÜTBE AYRICALIKLARI KONTROLLERİ ---

  Future<bool> canUseAiPlaylist() async {
    if (_currentTier == SiberTier.premium) return true;
    _currentRank = _manualRankForTesting ?? await RankManager().calculateCurrentRank();
    final rankInfo = RankManager().getTierInfo(_currentRank);
    if (rankInfo.extraAiListQuota >= 999) return true; // Efsane rütbesi sınırsız!

    final lastDate = await _storage.read(key: _keyAiDate) ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);

    int count = 0;
    if (lastDate == today) {
      count = int.tryParse(await _storage.read(key: _keyAiCount) ?? '0') ?? 0;
    } else {
      await _storage.write(key: _keyAiDate, value: today);
      await _storage.write(key: _keyAiCount, value: '0');
    }

    int baseLimit = _currentTier == SiberTier.student ? 5 : 1;
    return count < (baseLimit + rankInfo.extraAiListQuota);
  }

  Future<void> incrementAiPlaylistUsage() async {
    if (_currentTier == SiberTier.premium) return;
    final count = int.tryParse(await _storage.read(key: _keyAiCount) ?? '0') ?? 0;
    await _storage.write(key: _keyAiCount, value: (count + 1).toString());
  }

  static const String _keyArchiveBonus = 'archive_bonus';

  Future<bool> canAddArchive() async {
    if (_currentTier == SiberTier.premium) return true;
    _currentRank = _manualRankForTesting ?? await RankManager().calculateCurrentRank();
    final rankInfo = RankManager().getTierInfo(_currentRank);
    if (rankInfo.extraArchiveQuota >= 999) return true; // Efsane rütbesi sınırsız!

    final lastDate = await _storage.read(key: _keyArchiveDate) ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);

    int count = 0;
    int bonus = 0;
    if (lastDate == today) {
      count = int.tryParse(await _storage.read(key: _keyArchiveCount) ?? '0') ?? 0;
      bonus = int.tryParse(await _storage.read(key: _keyArchiveBonus) ?? '0') ?? 0;
    } else {
      await _storage.write(key: _keyArchiveDate, value: today);
      await _storage.write(key: _keyArchiveCount, value: '0');
      await _storage.write(key: _keyArchiveBonus, value: '0');
    }

    int baseLimit = _currentTier == SiberTier.student ? 15 : 5;
    return count < (baseLimit + bonus + rankInfo.extraArchiveQuota);
  }

  Future<void> incrementArchiveUsage() async {
    if (_currentTier == SiberTier.premium) return;
    final count = int.tryParse(await _storage.read(key: _keyArchiveCount) ?? '0') ?? 0;
    await _storage.write(key: _keyArchiveCount, value: (count + 1).toString());
  }

  /// 🎬 REKLAM İLE EKSTRA İNDİRME HAKKI KAZANMA (+2 Hak)
  Future<void> grantBonusArchiveDownloads({int amount = 2}) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = await _storage.read(key: _keyArchiveDate) ?? '';
    if (lastDate != today) {
      await _storage.write(key: _keyArchiveDate, value: today);
      await _storage.write(key: _keyArchiveCount, value: '0');
      await _storage.write(key: _keyArchiveBonus, value: '0');
    }
    final bonus = int.tryParse(await _storage.read(key: _keyArchiveBonus) ?? '0') ?? 0;
    await _storage.write(key: _keyArchiveBonus, value: (bonus + amount).toString());
  }

  Future<int> getRemainingArchiveDownloads() async {
    if (_currentTier == SiberTier.premium) return 999;
    _currentRank = _manualRankForTesting ?? await RankManager().calculateCurrentRank();
    final rankInfo = RankManager().getTierInfo(_currentRank);
    if (rankInfo.extraArchiveQuota >= 999) return 999;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = await _storage.read(key: _keyArchiveDate) ?? '';
    int count = 0;
    int bonus = 0;
    if (lastDate == today) {
      count = int.tryParse(await _storage.read(key: _keyArchiveCount) ?? '0') ?? 0;
      bonus = int.tryParse(await _storage.read(key: _keyArchiveBonus) ?? '0') ?? 0;
    }
    int baseLimit = _currentTier == SiberTier.student ? 15 : 5;
    return ((baseLimit + bonus + rankInfo.extraArchiveQuota) - count).clamp(0, 999);
  }

  Future<bool> canViewStatsReport() async {
    if (_currentTier == SiberTier.premium) return true;
    _currentRank = _manualRankForTesting ?? await RankManager().calculateCurrentRank();
    final rankInfo = RankManager().getTierInfo(_currentRank);
    if (rankInfo.rank == SiberRank.ozsesEfsanesi) return true;

    final lastDateStr = await _storage.read(key: _keyLastStatsDate);
    if (lastDateStr == null) return true;

    final lastDate = DateTime.parse(lastDateStr);
    final now = DateTime.now();
    final diffDays = now.difference(lastDate).inDays;

    if (_currentTier == SiberTier.student) {
      return diffDays >= 60; // 2 Ayda 1 kez
    } else {
      if (rankInfo.rank == SiberRank.sesGurmesi) return diffDays >= 15;
      if (rankInfo.rank == SiberRank.melodiUstasi) return diffDays >= 30;
      if (rankInfo.rank == SiberRank.ritimTutkunu) return diffDays >= 60;
      if (rankInfo.rank == SiberRank.muziksever) return diffDays >= 90;
      return diffDays >= 180; // Yılda 2 kez (6 ayda 1)
    }
  }

  Future<void> updateStatsReportDate() async {
    if (_currentTier == SiberTier.premium) return;
    await _storage.write(key: _keyLastStatsDate, value: DateTime.now().toIso8601String());
  }

  Future<bool> isRankAdFreeClaimed(SiberRank rank) async {
    final claimedStr = await _storage.read(key: _keyClaimedAdFreeRanks) ?? '';
    final claimedList = claimedStr.split(',').where((s) => s.isNotEmpty).toList();
    return claimedList.contains(rank.name);
  }

  Future<bool> claimAdFreePass(SiberRank rank) async {
    final tierInfo = RankManager().getTierInfo(rank);
    if (tierInfo.adFreeMinutes <= 0) return false;

    final isClaimed = await isRankAdFreeClaimed(rank);
    if (isClaimed) return false;

    final now = DateTime.now();
    DateTime baseTime = now;
    if (_adFreeUntil != null && _adFreeUntil!.isAfter(now)) {
      baseTime = _adFreeUntil!;
    }
    _adFreeUntil = baseTime.add(Duration(minutes: tierInfo.adFreeMinutes));
    await _storage.write(key: _keyAdFreeUntil, value: _adFreeUntil!.toIso8601String());

    final claimedStr = await _storage.read(key: _keyClaimedAdFreeRanks) ?? '';
    final claimedList = claimedStr.split(',').where((s) => s.isNotEmpty).toList();
    if (!claimedList.contains(rank.name)) {
      claimedList.add(rank.name);
      await _storage.write(key: _keyClaimedAdFreeRanks, value: claimedList.join(','));
    }
    _notifyAdFree();
    return true;
  }

  bool get isAdFree {
    if (_currentTier != SiberTier.free) return true;
    if (_adFreeUntil != null && DateTime.now().isBefore(_adFreeUntil!)) return true;
    return false;
  }

  Duration? get remainingAdFreeTime {
    if (_adFreeUntil == null) return null;
    final diff = _adFreeUntil!.difference(DateTime.now());
    return diff.isNegative ? null : diff;
  }

  String get remainingAdFreeFormatted {
    final d = remainingAdFreeTime;
    if (d == null) return '';
    if (d.inHours > 0) {
      return '${d.inHours} sa ${d.inMinutes % 60} dk';
    }
    return '${d.inMinutes} dk';
  }

  void setAdFreeUntilForTesting(DateTime? until) {
    _adFreeUntil = until;
    _notifyAdFree();
  }

  bool canUseMetamorphosis() {
    return _currentTier == SiberTier.premium;
  }

  // 🌤️ SİBER ATMOSFER: Hava Durumu Mixi Siber Öğrenci ve Imperium Premium üyelerine özeldir
  bool canUseWeatherMix() {
    return _currentTier == SiberTier.student || _currentTier == SiberTier.premium;
  }
  
  bool canUseAdvancedKaraoke() => true;
  bool canChangeAuraTheme() => true; // 🎨 Herkes tema rengini özgürce değiştirebilir
  bool canUseAdvancedCyberStudio() => true;
}
