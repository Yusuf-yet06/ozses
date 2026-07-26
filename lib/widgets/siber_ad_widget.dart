import 'package:flutter/material.dart';
import '../services/ad_manager.dart';
import '../services/subscription_manager.dart';

class SiberAdWidget extends StatelessWidget {
  const SiberAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (SubscriptionManager().currentTier != SiberTier.free) {
      return const SizedBox.shrink(); // Premium kullanıcılar reklam görmez
    }
    return AdManager.buildBannerAdWidget();
  }
}