import 'package:universal_io/io.dart'; // Platform kontrolü için ŞART!
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart'; // 🌐 WEB KALKANI İÇİN
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart'; // 🎯 SİBER HAMLE: Güvenlik Motoru
import 'package:purchases_flutter/purchases_flutter.dart'; // 🎯 SİBER HAMLE: RevenueCat Ödeme Altyapısı
import 'responsive/responsive_layout.dart';
import 'screens/splash_screen.dart';
import 'services/audio_handler.dart';
import 'services/siber_theme_service.dart';
import 'widgets/global_ambient_background.dart';

import 'firebase_options.dart'; // Yeni oluşan siber dosyayı ekledik
import 'services/ytdlp_service.dart';
import 'services/services.dart';
import 'services/ad_manager.dart';
import 'services/offline_cache_service.dart';

// Küresel erişim için mühürlendi
late MyAudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 🔮 Siber Tema Motorunu Başlat (Yerel SharedPreferences, anında biter)
  try {
    await SiberThemeService.instance.init();
  } catch (_) {}

  // 🎵 AudioHandler Başlat (Kilit ekranı ve bildirim paneli çekirdeği)
  try {
    audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.ozses.v7.audio',
        androidNotificationChannelName: 'ÖZSES Kontrol',
        androidNotificationIcon: 'mipmap/launcher_icon',
        androidStopForegroundOnPause: false,
        androidNotificationOngoing: false,
        androidResumeOnClick: true,
      ),
    );
    print('🚀 Siber Durum: AudioHandler mühürlendi!');
  } catch (e) {
    print('❌ Siber Hata: Başlatma çöktü: $e');
  }

  // ⚡ SİBER TURBO HAMLE: Ağır arka plan servislerini paralel başlat (Açılış ekranını ASLA bekletmez!)
  OzsesMusicApp.backgroundServicesFuture = _initBackgroundServices();

  // 🚀 ANINDA ARAYÜZÜ ÇİZ (Kullanıcı 0.1 saniyede animasyonlu logoyu görür, siyah ekranda beklemez!)
  runApp(const OzsesMusicApp());
}

Future<void> _initBackgroundServices() async {
  // Gömülü yt-dlp ve Proxy
  if (!kIsWeb) {
    YtDlpService().init();
    OzsesBridge.initProxy();
  }

  // Çevrimdışı Bellek, Firebase, RevenueCat, AdManager PARALEL başlar
  await Future.wait([
    // 1. Çevrimdışı Bellek
    () async {
      try {
        await OfflineCacheService().init();
        print('🚀 Siber Durum: Çevrimdışı Bellek Aktif!');
      } catch (e) {
        print('❌ Siber Hata: Çevrimdışı Bellek: $e');
      }
    }(),

    // 2. Firebase
    () async {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('🔥 Siber Durum: Firebase Bağlantısı Sağlandı!');
      } catch (e) {
        print('❌ Siber Hata: Firebase: $e');
      }
    }(),

    // 3. RevenueCat (Abonelik)
    () async {
      try {
        await Purchases.setLogLevel(LogLevel.warn);
        final apiKey = Platform.isAndroid
            ? 'goog_gAevCylwSjZfEoytSjYvUeKxXwW'
            : 'appl_mock_key';
        await Purchases.configure(PurchasesConfiguration(apiKey));
        print('💎 Siber Durum: RevenueCat Zırhı Aktif!');
      } catch (e) {
        print('❌ Siber Hata: RevenueCat: $e');
      }
    }(),

    // 4. AdManager
    () async {
      try {
        AdManager.initialize();
      } catch (e) {
        print('❌ Siber Hata: AdManager: $e');
      }
    }(),
  ]);
}

class OzsesMusicApp extends StatelessWidget {
  static Future<void>? backgroundServicesFuture;
  const OzsesMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: SiberThemeService.instance.currentThemeColor,
      builder: (context, themeColor, child) {
        return MaterialApp(
          builder: (context, appChild) {
            return GlobalAmbientBackground(child: appChild!);
          },
          title: 'ÖZSES',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(useMaterial3: true).copyWith(
            scaffoldBackgroundColor: Colors.transparent, // 🔮 Global siber ışık için şeffaflaştırıldı
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeColor,
              brightness: Brightness.dark,
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
