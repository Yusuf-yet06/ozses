import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ozses_v7/services/subscription_manager.dart';

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
        } else if (methodCall.method == 'deleteAll') {
          mockStorage.clear();
          return null;
        }
        return null;
      },
    );
  });

  group('🎯 ÖZSES V7 - Zirvedekiler & Reklamsız Mod Testleri', () {
    test('1. adFreeNotifier abonelik değiştiğinde reaktif tetiklenmeli', () async {
      final sub = SubscriptionManager();
      bool notified = false;
      sub.adFreeNotifier.addListener(() {
        notified = true;
      });

      expect(sub.isAdFree, false);
      expect(sub.adFreeNotifier.value, false);

      await sub.setTier(SiberTier.premium);
      expect(sub.isAdFree, true);
      expect(sub.adFreeNotifier.value, true);
      expect(notified, true);

      notified = false;
      await sub.setTier(SiberTier.free);
      expect(sub.isAdFree, false);
      expect(sub.adFreeNotifier.value, false);
      expect(notified, true);
    });

    test('2. Geçici reklamsız pass aktif edilince adFreeNotifier tetiklenmeli', () async {
      final sub = SubscriptionManager();
      await sub.setTier(SiberTier.free);
      
      bool notified = false;
      sub.adFreeNotifier.addListener(() {
        notified = true;
      });

      sub.setAdFreeUntilForTesting(DateTime.now().add(const Duration(hours: 1)));
      expect(sub.isAdFree, true);
      expect(sub.adFreeNotifier.value, true);
      expect(notified, true);

      notified = false;
      sub.setAdFreeUntilForTesting(DateTime.now().subtract(const Duration(minutes: 5)));
      expect(sub.isAdFree, false);
      expect(sub.adFreeNotifier.value, false);
      expect(notified, true);
    });

    test('3. Zirvedekiler sadece yerel arşiv yollarını seçmeli ve Keşfet linklerini (http/stream) süzmeli', () {
      final archivePaths = {
        '/storage/emulated/0/Music/sarki1.mp3',
        '/storage/emulated/0/Music/sarki2.mp3',
        '/storage/emulated/0/Music/sarki3.mp3',
      };

      final simulatedHistory = [
        {'path': 'https://rr4---sn.googlevideo.com/videoplayback?id=123', 'playCount': 100, 'duration': 5000},
        {'path': 'http://185.198.57.199:8080/stream/abc', 'playCount': 90, 'duration': 4000},
        {'path': '/storage/emulated/0/Music/sarki1.mp3', 'playCount': 25, 'duration': 1200},
        {'path': '/storage/emulated/0/Music/sarki2.mp3', 'playCount': 40, 'duration': 1500},
        {'path': 'stream:youtube_video_id', 'playCount': 30, 'duration': 900},
        {'path': '/storage/emulated/0/Music/sarki3.mp3', 'playCount': 10, 'duration': 600},
      ];

      final validArchiveHistory = simulatedHistory.where((h) {
        final p = h['path'] as String;
        return archivePaths.contains(p) && !p.startsWith('http') && !p.startsWith('stream:');
      }).toList();

      validArchiveHistory.sort((a, b) {
        final countA = a['playCount'] as int;
        final countB = b['playCount'] as int;
        if (countB != countA) return countB.compareTo(countA);
        return (b['duration'] as int).compareTo(a['duration'] as int);
      });

      final topPaths = validArchiveHistory.take(15).map((h) => h['path'] as String).toList();

      expect(topPaths.length, 3);
      expect(topPaths[0], '/storage/emulated/0/Music/sarki2.mp3');
      expect(topPaths[1], '/storage/emulated/0/Music/sarki1.mp3');
      expect(topPaths[2], '/storage/emulated/0/Music/sarki3.mp3');
      expect(topPaths.any((p) => p.startsWith('http')), false);
      expect(topPaths.any((p) => p.startsWith('stream:')), false);
    });
  });
}
