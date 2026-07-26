import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'universal_ad/ad_platform_interface.dart';
import 'universal_ad/siber_ad_manager.dart';
import 'universal_ad/ad_platform_windows.dart';

class AdManager {
  static AdPlatform? _platform;

  static void _ensurePlatformInitialized() {
    if (_platform == null) {
      if (!kIsWeb && Platform.isWindows) {
        _platform = AdPlatformWindows();
      } else {
        _platform = getUniversalAdPlatform();
      }
      _platform!.initialize();
    }
  }

  static void initialize() {
    _ensurePlatformInitialized();
  }


  static bool willShowAd({bool isOfflineMode = false}) {
    _ensurePlatformInitialized();
    return _platform!.willShowAd(isOfflineMode: isOfflineMode);
  }

  static void showInterstitialAdIfReady({bool isOfflineMode = false, bool forceShow = false}) {
    _ensurePlatformInitialized();
    _platform!.showInterstitialAdIfReady(isOfflineMode: isOfflineMode, forceShow: forceShow);
  }

  static Widget buildBannerAdWidget() {
    _ensurePlatformInitialized();
    return _platform!.buildBannerAdWidget();
  }

  static void disposeBannerAd() {
    _platform?.disposeBannerAd();
  }
}
