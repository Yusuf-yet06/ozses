import 'package:flutter/material.dart';

abstract class AdPlatform {
  /// Reklam motorunu başlatır
  void initialize();

  /// Eğer reklam hazırsa bir Geçiş (Interstitial) Reklamı gösterir.
  /// Çevrimdışı moda göre zaman limiti değişiklik gösterir.
  void showInterstitialAdIfReady({bool isOfflineMode = false, bool forceShow = false});
  bool willShowAd({bool isOfflineMode = false});

  /// Banner reklam widget'ı döner
  Widget buildBannerAdWidget();
  
  /// Banner'ı bellekten temizler
  void disposeBannerAd();
}
