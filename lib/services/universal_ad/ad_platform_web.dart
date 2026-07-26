// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'ad_platform_interface.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class AdPlatformWeb implements AdPlatform {
  DateTime? _lastAdTime;

  @override
  void initialize() {
    // Web (AdSense) başlatma kodları buraya gelecek
    // AdSense scriptleri eklenebilir
    // ui_web.platformViewRegistry.registerViewFactory('adsense-banner', ...);
  }


  @override
  bool willShowAd({bool isOfflineMode = false}) => false;

  @override
  void showInterstitialAdIfReady({bool isOfflineMode = false, bool forceShow = false}) {
    _lastAdTime ??= DateTime.now();
    final now = DateTime.now();
    final difference = now.difference(_lastAdTime!);
    
    final requiredMinutes = isOfflineMode ? 40 : 25;

    if (difference.inMinutes >= requiredMinutes) {
      Fluttertoast.showToast(
          msg: "Siber Keşiflere kısa bir ara... Reklam yükleniyor 🚀",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 3,
          backgroundColor: Colors.deepPurpleAccent,
          textColor: Colors.white,
          fontSize: 14.0
      );

      Future.delayed(const Duration(seconds: 3), () {
        // Tam ekran AdSense pop-up veya IFrame gösterimi eklenecek
        print("SİBER WEB: Geçiş reklamı tetiklendi (AdSense onayı bekleniyor)");
        _lastAdTime = DateTime.now();
      });
    }
  }

  @override
  Widget buildBannerAdWidget() {
    // Şimdilik AdSense konteyneri. Onaylandığında platform view kullanılacak.
    return Container(
      width: 320,
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Text(
          'SİBER WEB REKLAM ALANI\n(AdSense Onayı Bekleniyor)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ),
    );
  }

  @override
  void disposeBannerAd() {
    // Web banner temizliği
  }
}

AdPlatform getAdPlatform() => AdPlatformWeb();
