import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'ad_platform_interface.dart';
import '../subscription_manager.dart';

class AdPlatformMobile implements AdPlatform {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-1775209250876098/4411279991';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2934735716';
    return '';
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-1775209250876098/1022785047';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
    return '';
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-1775209250876098/9040875862';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/1712485313';
    return '';
  }

  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;
  DateTime? _lastAdTime;
  
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;
  
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
    if (SubscriptionManager().isAdFree) return false;
    return _interstitialAd != null;
  }

  @override
  void showInterstitialAdIfReady({bool isOfflineMode = false, bool forceShow = false}) {
    if (SubscriptionManager().isAdFree) return; // 🎯 SİBER KALKAN: Premium veya Geçici Reklamsız kullanıcılara tam ekran reklam gösterilmez!

    // 🛡️ SİBER KALKAN: Arka planda veya ekran kilitliyken reklam gösterilemez (Android Activity çökmesini önler)
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      print('🛡️ SİBER KALKAN: Arka planda interstitial reklam atlandı.');
      return;
    }

    if (_interstitialAd != null) {
      final adToShow = _interstitialAd!;
      _interstitialAd = null; // Hemen null yap ki mükerrer tetiklenmesin
      
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
      print('✅ [REKLAM]: Tam ekran reklam başarıyla gösterildi.');
    } else {
      print('⚠️ [REKLAM]: Interstitial reklam hazır değil, yeniden yükleniyor...');
      _interstitialLoadAttempts = 0;
      _createInterstitialAd();
    }
  }

  @override
  Widget buildBannerAdWidget() {
    return const _MobileBannerAdWidget();
  }

  @override
  void disposeBannerAd() {
    // Banner ads are now self-disposing in their StatefulWidgets
  }

  void _loadRewardedAd() {
    if (_isRewardedAdLoading || _rewardedAd != null) return;
    _isRewardedAdLoading = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          _isRewardedAdLoading = false;
        },
      ),
    );
  }

  @override
  void showRewardedAd({required VoidCallback onReward, VoidCallback? onFailed}) {
    if (_rewardedAd != null) {
      final ad = _rewardedAd!;
      _rewardedAd = null;
      bool userEarnedReward = false;

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadRewardedAd();
          if (userEarnedReward) {
            onReward();
          } else {
            onFailed?.call();
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _loadRewardedAd();
          // Hata durumunda kullanıcıyı cezalandırma, ödülü ver
          onReward();
        },
      );

      ad.show(onUserEarnedReward: (adWithoutView, reward) {
        userEarnedReward = true;
      });
    } else {
      // Reklam o anda hazır değilse direkt AdMob yükleme denemesi yapalım
      RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            bool userEarned = false;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                if (userEarned) onReward(); else onFailed?.call();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                onReward();
              },
            );
            ad.show(onUserEarnedReward: (adWithoutView, reward) {
              userEarned = true;
            });
          },
          onAdFailedToLoad: (LoadAdError error) {
            // Reklam servisine ulaşılamadıysa kullanıcıyı mağdur etme, bonusu ver
            Fluttertoast.showToast(msg: '🎬 Reklam ağına bağlanamadı, +2 hak tanımlandı!');
            onReward();
          },
        ),
      );
    }
  }
}

class _MobileBannerAdWidget extends StatefulWidget {
  const _MobileBannerAdWidget({Key? key}) : super(key: key);

  @override
  _MobileBannerAdWidgetState createState() => _MobileBannerAdWidgetState();
}

class _MobileBannerAdWidgetState extends State<_MobileBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    // 🛡️ SİBER REKLAMSIZ KALKAN: Siber Öğrenci, Imperium Premium veya Geçici Reklamsız Mod
    if (SubscriptionManager().isAdFree) {
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: AdPlatformMobile.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _isLoaded = false;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (SubscriptionManager().isAdFree) {
      return const SizedBox.shrink();
    }
    if (_isLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        margin: EdgeInsets.zero,
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox.shrink();
  }


}

AdPlatform getAdPlatform() => AdPlatformMobile();
