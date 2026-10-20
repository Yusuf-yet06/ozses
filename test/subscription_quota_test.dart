import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ozses_v7/services/subscription_manager.dart';
import 'package:ozses_v7/services/rank_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Map<String, String> mockStorage = {};

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'write') {
          final key = methodCall.arguments['key'] as String;
          final value = methodCall.arguments['value'] as String?;
          if (value != null) {
            mockStorage[key] = value;
          }
          return null;
        } else if (methodCall.method == 'read') {
          final key = methodCall.arguments['key'] as String;
          return mockStorage[key];
        } else if (methodCall.method == 'containsKey') {
          final key = methodCall.arguments['key'] as String;
          return mockStorage.containsKey(key);
        } else if (methodCall.method == 'delete') {
          final key = methodCall.arguments['key'] as String;
          mockStorage.remove(key);
          return null;
        }
        return null;
      },
    );
  });

  group('🎯 ÖZSES V7 - SİBER ABONELİK VE KOTA TESTLERİ', () {
    late SubscriptionManager subManager;

    setUp(() {
      subManager = SubscriptionManager();
      mockStorage.clear();
    });

    test('1. Başlangıç Paketi Varsayılan Olarak Free (Ücretsiz) Olmalı', () {
      expect(subManager.currentTier, SiberTier.free);
    });

    test('2. Hava Durumu Mixi Yetki Kuralı: Free Kapalı, Student & Premium Açık Olmalı', () async {
      await subManager.setTier(SiberTier.free);
      expect(subManager.canUseWeatherMix(), false, reason: 'Ücretsiz pakette hava durumu mixi kilitli olmalı');

      await subManager.setTier(SiberTier.student);
      expect(subManager.canUseWeatherMix(), true, reason: 'Siber Öğrenci paketinde hava durumu mixi açık olmalı');

      await subManager.setTier(SiberTier.premium);
      expect(subManager.canUseWeatherMix(), true, reason: 'Imperium Premium paketinde hava durumu mixi açık olmalı');
    });

    test('3. Siber Metamorfoz Kuralı: Sadece Imperium Premium Açık Olmalı', () async {
      await subManager.setTier(SiberTier.free);
      expect(subManager.canUseMetamorphosis(), false);

      await subManager.setTier(SiberTier.student);
      expect(subManager.canUseMetamorphosis(), false);

      await subManager.setTier(SiberTier.premium);
      expect(subManager.canUseMetamorphosis(), true);
    });

    test('4. Imperium Premium Kullanıcısı Arşiv İndirmelerinde Sınırsız Olmalı', () async {
      await subManager.setTier(SiberTier.premium);
      final canAdd = await subManager.canAddArchive();
      expect(canAdd, true);
      final remaining = await subManager.getRemainingArchiveDownloads();
      expect(remaining, 999);
    });

    test('5. Imperium Premium AI Listelemede Sınırsız Olmalı', () async {
      await subManager.setTier(SiberTier.premium);
      final canUseAi = await subManager.canUseAiPlaylist();
      expect(canUseAi, true);
    });

    test('6. Ücretsiz Kullanıcı Kotası 5 İndirme ve Bonus Hak Kazanımı Çalışmalı', () async {
      await subManager.setTier(SiberTier.free);
      
      // İlk 5 indirme hakkı olmalı
      for (int i = 0; i < 5; i++) {
        expect(await subManager.canAddArchive(), true, reason: '. indirme serbest olmalı');
        await subManager.incrementArchiveUsage();
      }

      // 6. indirmede kota dolmalı
      expect(await subManager.canAddArchive(), false, reason: '5 indirmeden sonra kota dolmalı');

      // Reklam izleyip +2 bonus hak kazandıralım
      await subManager.grantBonusArchiveDownloads(amount: 2);

      // Artık 2 indirme daha serbest olmalı
      expect(await subManager.canAddArchive(), true, reason: 'Bonus ile 6. indirme serbest olmalı');
      await subManager.incrementArchiveUsage();

      expect(await subManager.canAddArchive(), true, reason: 'Bonus ile 7. indirme serbest olmalı');
      await subManager.incrementArchiveUsage();

      // Tekrar kota dolmalı
      expect(await subManager.canAddArchive(), false, reason: 'Bonuslar da bitince kota tekrar dolmalı');
    });

    test('7. Rütbe Yükselmesiyle Kısılmış Ölçülü Kotalar (Maks 12 İndirme, 4 AI) Çalışmalı', () async {
      await subManager.setTier(SiberTier.free);

      // Yeni Dinleyici: 5 indirme, 1 AI liste
      subManager.setCurrentRankForTesting(SiberRank.yeniDinleyici);
      expect(await subManager.getRemainingArchiveDownloads(), 5);

      // Çırak Taktisyen: 5 + 1 = 6 indirme
      subManager.setCurrentRankForTesting(SiberRank.cirakTaktisyen);
      expect(await subManager.getRemainingArchiveDownloads(), 6);

      // Müziksever: 5 + 2 = 7 indirme
      subManager.setCurrentRankForTesting(SiberRank.muziksever);
      expect(await subManager.getRemainingArchiveDownloads(), 7);

      // Melodi Ustası: 5 + 4 = 9 indirme
      subManager.setCurrentRankForTesting(SiberRank.melodiUstasi);
      expect(await subManager.getRemainingArchiveDownloads(), 9);

      // Ses Gurmesi: 5 + 5 = 10 indirme
      subManager.setCurrentRankForTesting(SiberRank.sesGurmesi);
      expect(await subManager.getRemainingArchiveDownloads(), 10);

      // ÖZSES Efsanesi: 5 + 7 = 12 indirme (Sınırsız değil, ölçülü kota!)
      subManager.setCurrentRankForTesting(SiberRank.ozsesEfsanesi);
      expect(await subManager.getRemainingArchiveDownloads(), 12);
    });

    test('8. Hava Durumu Mixi ve Siber Metamorfoz Ücretli Aboneliklere Özel Kalmalı', () async {
      await subManager.setTier(SiberTier.free);

      // Ücretsiz kullanıcı 500 saat dinleyip ÖZSES Efsanesi olsa dahi bu özellikler ücretli paketlere saklanır
      subManager.setCurrentRankForTesting(SiberRank.ozsesEfsanesi);
      expect(subManager.canUseWeatherMix(), false, reason: 'Hava durumu mixi sadece Siber Öğrenci ve Imperium Premiumda açık olmalı');
      expect(subManager.canUseMetamorphosis(), false, reason: 'Metamorfoz sadece Imperium Premiumda açık olmalı');

      await subManager.setTier(SiberTier.student);
      expect(subManager.canUseWeatherMix(), true);
      expect(subManager.canUseMetamorphosis(), false);

      await subManager.setTier(SiberTier.premium);
      expect(subManager.canUseWeatherMix(), true);
      expect(subManager.canUseMetamorphosis(), true);
    });

    test('9. Geçici Reklamsız Dinleme Pass Mekanizması Doğru Çalışmalı', () async {
      await subManager.setTier(SiberTier.free);
      subManager.setAdFreeUntilForTesting(null);
      expect(subManager.isAdFree, false);

      // Çırak Taktisyen (30 dk) hediye passini aktif edelim
      final success = await subManager.claimAdFreePass(SiberRank.cirakTaktisyen);
      expect(success, true);
      expect(subManager.isAdFree, true);
      expect(subManager.remainingAdFreeTime!.inMinutes >= 29, true);

      // Aynı rütbenin hediyesi 2. kez alınamaz
      final secondTry = await subManager.claimAdFreePass(SiberRank.cirakTaktisyen);
      expect(secondTry, false);

      // Süre bittiğinde reklamsız mod sonlanmalı
      subManager.setAdFreeUntilForTesting(DateTime.now().subtract(const Duration(minutes: 1)));
      expect(subManager.isAdFree, false);
    });
  });
}
