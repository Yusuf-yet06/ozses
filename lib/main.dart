import 'dart:io'; // Platform kontrolü için ŞART!
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart'; // 🌐 WEB KALKANI İÇİN
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart'; // 🎯 SİBER HAMLE: Güvenlik Motoru
import 'package:purchases_flutter/purchases_flutter.dart'; // 🎯 SİBER HAMLE: RevenueCat Ödeme Altyapısı
import 'responsive/responsive_layout.dart';
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
  
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // ⚡ Gömülü yt-dlp Kalkanı Başlat
  YtDlpService().init();
  
  // ⚡ Siber Proxy'yi Başlat
  OzsesBridge.initProxy();
  
  // 🔥 SİBER HAMLE: Çevrimdışı Belleği Başlat
  try {
    await OfflineCacheService().init();
    print('🚀 Siber Durum: Çevrimdışı Bellek Aktif!');
  } catch (e) {
    print('❌ Siber Hata: Çevrimdışı Bellek Başlatılamadı: ');
  }
  
  // 🔥 SİBER HAMLE: Firebase Güvenlik Mührünü Başlat
  try {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isWindows) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('🚀 Siber Durum: Firebase Güvenlik Kalkanı devrede!');
    }
  } catch (e) {
    print('❌ Siber Hata: Firebase kurulamadı (native ayarlar yapılmamış olabilir): $e');
  }

  // 💰 SİBER HAMLE: RevenueCat Ödeme Motorunu Başlat
  try {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await Purchases.setLogLevel(LogLevel.debug);
      
      // ⚠️ DİKKAT: Buraya kendi RevenueCat Public API Key'lerini yazmalısın!
      PurchasesConfiguration configuration;
      if (Platform.isAndroid) {
        // Play Store Key
        configuration = PurchasesConfiguration("goog_SipKkOxxxxxxxxx"); 
      } else {
        // App Store Key
        configuration = PurchasesConfiguration("appl_JjXxXxxxxxxxxx"); 
      }
      await Purchases.configure(configuration);
      print('🚀 Siber Durum: RevenueCat (Ödeme Altyapısı) devrede!');
    }
  } catch (e) {
    print('❌ Siber Hata: RevenueCat başlatılamadı: $e');
  }

  // 🛡 Windows Sinerjisi: Ses motoru uyanmadan önce kısa bir nefes aldırıyoruz
  if (!kIsWeb && Platform.isWindows) {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  try {
    audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.ozses.v7.audio',
        androidNotificationChannelName: 'ÖZSES Kontrol',
        androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );
    print('🚀 Siber Durum: AudioHandler mühürlendi!');
  } catch (e) {
    print('❌ Siber Hata: Başlatma çöktü: $e');
  }

  // 🔮 Siber Tema Motorunu Başlat
  try {
    await SiberThemeService.instance.init();
  } catch (e) {
    print('❌ Siber Hata: Siber Tema Motoru çöktü: ');
  }

  try {
    AdManager.initialize();
  } catch (e) {
    print('❌ Siber Hata: AdManager çöktü: ');
  }
  runApp(const OzsesMusicApp());
}

class OzsesMusicApp extends StatelessWidget {
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
          title: 'ÖZSES V7',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(useMaterial3: true).copyWith(
            scaffoldBackgroundColor: Colors.transparent, // 🔮 Global siber ışık için şeffaflaştırıldı
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeColor,
              brightness: Brightness.dark,
            ),
          ),
          home: const ResponsiveLayout(),
        );
      },
    );
  }
}
