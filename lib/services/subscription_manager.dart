import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  SiberRank _currentRank = SiberRank.caylak;

  // Key Constants
  static const String _keyTier = 'siber_tier';
  static const String _keyAiCount = 'ai_playlist_count';
  static const String _keyAiDate = 'ai_playlist_date';
  static const String _keyVoiceCount = 'voice_command_count';
  static const String _keyVoiceDate = 'voice_command_date';
  static const String _keyLastStatsDate = 'last_stats_date';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 💰 SİBER HAMLE: RevenueCat'ten en güncel abonelik durumunu al
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        CustomerInfo customerInfo = await Purchases.getCustomerInfo();
        _updateTierFromCustomerInfo(customerInfo, prefs);
      } else {
        _loadLocalTier(prefs);
      }
    } catch (e) {
      print('❌ Siber Hata: RevenueCat bağlantısı kurulamadı. Lokal önbelleğe dönülüyor. Hata: $e');
      _loadLocalTier(prefs);
    }
    
    // Rütbeyi hesapla ve önbelleğe al
    _currentRank = await RankManager().calculateCurrentRank();
  }

  void _loadLocalTier(SharedPreferences prefs) {
    final tierStr = prefs.getString(_keyTier) ?? 'free';
    if (tierStr == 'premium') {
      _currentTier = SiberTier.premium;
    } else if (tierStr == 'student') {
      _currentTier = SiberTier.student;
    } else {
      _currentTier = SiberTier.free;
    }
  }

  void _updateTierFromCustomerInfo(CustomerInfo customerInfo, SharedPreferences prefs) async {
    // ⚠️ NOT: "premium" ve "student", RevenueCat panelinde oluşturacağın Entitlement (Hak) ID'leridir.
    if (customerInfo.entitlements.all["premium"]?.isActive == true) {
      _currentTier = SiberTier.premium;
      await prefs.setString(_keyTier, 'premium');
    } else if (customerInfo.entitlements.all["student"]?.isActive == true) {
      _currentTier = SiberTier.student;
      await prefs.setString(_keyTier, 'student');
    } else {
      // 🎯 SİBER KALKAN (Developer Mode Bypass): 
      // Henüz Google Play hesabımız olmadığı için RevenueCat'ten paket dönmüyor.
      // Kendi lokal telefonumuzda Premium testini yapabilmek için eğer daha önce 
      // sahte premium aldıysak onu bozmayalım. (Canlıda bu satırlar silinebilir).
      final local = prefs.getString(_keyTier) ?? 'free';
      if (local == 'premium' || local == 'student') {
        _loadLocalTier(prefs); 
      } else {
        _currentTier = SiberTier.free;
        await prefs.setString(_keyTier, 'free');
      }
    }
  }

  Future<void> syncPurchases() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        CustomerInfo customerInfo = await Purchases.restorePurchases();
        final prefs = await SharedPreferences.getInstance();
        _updateTierFromCustomerInfo(customerInfo, prefs);
      }
    } catch (e) {
      print('❌ Siber Hata: Alımlar senkronize edilemedi $e');
    }
  }

  SiberTier get currentTier => _currentTier;

  Future<void> setTier(SiberTier newTier) async {
    final prefs = await SharedPreferences.getInstance();
    _currentTier = newTier;
    await prefs.setString(_keyTier, newTier.name);
  }

  // --- SİBER LİMİT KONTROLLERİ ---

  /// Yapay Zeka Çalma Listesi Limiti
  Future<bool> canUseAiPlaylist() async {
    if (_currentTier == SiberTier.premium) return true;

    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_keyAiDate) ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);

    int count = 0;
    if (lastDate == today) {
      count = prefs.getInt(_keyAiCount) ?? 0;
    } else {
      await prefs.setString(_keyAiDate, today);
      await prefs.setInt(_keyAiCount, 0);
    }

    // Rank Bonusları
    int baseLimit = _currentTier == SiberTier.student ? 5 : 1;
    if (_currentTier == SiberTier.free && _currentRank.index >= SiberRank.er.index) {
      baseLimit += 1; // Siber Er ve üstüne ekstra 1 hak
    }

    return count < baseLimit;
  }

  Future<void> incrementAiPlaylistUsage() async {
    if (_currentTier == SiberTier.premium) return;
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keyAiCount) ?? 0;
    await prefs.setInt(_keyAiCount, count + 1);
  }

  /// Sesli Komut Limiti
  Future<bool> canUseVoiceCommand() async {
    if (_currentTier == SiberTier.free) return false;
    if (_currentTier == SiberTier.premium) return true; // Limitsiz

    // Student limit check
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_keyVoiceDate) ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);

    int count = 0;
    if (lastDate == today) {
      count = prefs.getInt(_keyVoiceCount) ?? 0;
    } else {
      await prefs.setString(_keyVoiceDate, today);
      await prefs.setInt(_keyVoiceCount, 0);
    }

    // Öğrenci için günde 20 sesli komut limiti
    return count < 20; 
  }

  Future<void> incrementVoiceCommandUsage() async {
    if (_currentTier == SiberTier.premium || _currentTier == SiberTier.free) return;
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keyVoiceCount) ?? 0;
    await prefs.setInt(_keyVoiceCount, count + 1);
  }

  /// İstatistik Raporu Tarih Kontrolü
  Future<bool> canViewStatsReport() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString(_keyLastStatsDate);

    if (lastDateStr == null) return true; // Hiç bakılmamışsa izin ver

    final lastDate = DateTime.parse(lastDateStr);
    final now = DateTime.now();
    final diffDays = now.difference(lastDate).inDays;

    if (_currentTier == SiberTier.premium) {
      // 2 Haftada 1 (14 gün)
      return diffDays >= 14;
    } else if (_currentTier == SiberTier.student) {
      // Ayda 1 (30 gün)
      return diffDays >= 30;
    } else {
      // Yılda 3 kez demek, ortalama 4 ayda bir (120 gün) demek.
      return diffDays >= 120;
    }
  }

  Future<void> updateStatsReportDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastStatsDate, DateTime.now().toIso8601String());
  }

  // SİBER KEŞFET & METAMORFOZ
  bool canUsePersonalDiscovery() {
    // Çavuş ve üzeri ranklara özel erişim
    if (_currentTier != SiberTier.free) return true;
    if (_currentRank.index >= SiberRank.komando.index) return true; 
    return false;
  }
  
  bool canUseAutoMix() => _currentTier != SiberTier.free;
  
  bool canUseMetamorphosis() {
    // İlah rütbesine premium olmasa da açık
    if (_currentTier == SiberTier.premium) return true;
    if (_currentRank == SiberRank.ilah) return true;
    return false;
  }
  
  // KARAOKE EFEKTLERİ
  bool canUseAdvancedKaraoke() => _currentTier != SiberTier.free;

  // AURA TEMALARI
  bool canChangeAuraTheme() => _currentTier != SiberTier.free;

  // SİBER SES STÜDYOSU (GELİŞMİŞ EFEKTLER)
  bool canUseAdvancedCyberStudio() => _currentTier != SiberTier.free;
}
