import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'ad_platform_interface.dart';
import '../subscription_manager.dart';

class AdPlatformMobile implements AdPlatform {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2934735716';
    return '';
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
    return '';
  }

  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;
  DateTime? _lastAdTime;
  
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  StateSetter? _bannerStateSetter;

  @override
  void initialize() {
    MobileAds.instance.initialize();
    _createInterstitialAd();
  }

  void _createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialLoadAttempts += 1;
          _interstitialAd = null;
          if (_interstitialLoadAttempts <= 3) {
            _createInterstitialAd();
          }
        },
      ),
    );
  }


  @override
  bool willShowAd({bool isOfflineMode = false}) {
    if (SubscriptionManager().currentTier != SiberTier.free) return false;
    if (_lastAdTime == null) return true; // Eğer hiç reklam gösterilmediyse hazırdır
    final difference = DateTime.now().difference(_lastAdTime!);
    final requiredMinutes = isOfflineMode ? 35 : 25;
    return difference.inSeconds >= (requiredMinutes * 60) - 30; // 30 saniye tolerans
  }

  @override
  void showInterstitialAdIfReady({bool isOfflineMode = false, bool forceShow = false}) {
    if (SubscriptionManager().currentTier != SiberTier.free) return; // 🎯 SİBER KALKAN: Premium kullanıcılara tam ekran reklam gösterilmez!

    _lastAdTime ??= DateTime.now();
    final now = DateTime.now();
    final difference = now.difference(_lastAdTime!);
    
    final requiredMinutes = isOfflineMode ? 35 : 25;

    if (forceShow || difference.inMinutes >= requiredMinutes) {
      if (_interstitialAd != null) {
        Fluttertoast.showToast(
            msg: "Siber Keşiflere kısa bir ara... Reklam yükleniyor 🚀",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 3,
            backgroundColor: Colors.deepPurpleAccent,
            textColor: Colors.white,
            fontSize: 14.0
        );

        final adToShow = _interstitialAd;
        _interstitialAd = null; // Hemen null yap ki birden fazla kez tetiklenmesin
        
        Future.delayed(const Duration(seconds: 3), () {
          if (adToShow == null) return;
          adToShow.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              ad.dispose();
              _createInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              ad.dispose();
              _createInterstitialAd();
            },
          );
          adToShow.show();
          _lastAdTime = DateTime.now();
        });
      } else {
        _createInterstitialAd();
      }
    }
  }

  @override
  Widget buildBannerAdWidget() {
    if (_bannerAd == null) {
      _bannerAd = BannerAd(
        adUnitId: bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _isBannerAdLoaded = true;
            if (_bannerStateSetter != null) {
              _bannerStateSetter!(() {});
            }
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
          },
        ),
      )..load();
    }

    return StatefulBuilder(
      builder: (context, setState) {
        _bannerStateSetter = setState;
        if (_isBannerAdLoaded && _bannerAd != null) {
          return Container(
            alignment: Alignment.center,
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            margin: EdgeInsets.zero,
            child: AdWidget(ad: _bannerAd!),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  @override
  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }
}

AdPlatform getAdPlatform() => AdPlatformMobile();
