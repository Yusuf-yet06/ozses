import 'package:flutter/material.dart';
import '../services/ad_manager.dart';
import '../services/subscription_manager.dart';

class SiberAdWidget extends StatelessWidget {
  const SiberAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SubscriptionManager().adFreeNotifier,
      builder: (context, isAdFree, _) {
        if (isAdFree || SubscriptionManager().isAdFree) {
          return const SizedBox.shrink(); // Premium veya Geçici Reklamsız kullanıcılar reklam görmez
        }

        final themeColor = Theme.of(context).colorScheme.primary;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(2), // Çerçeve kalınlığı
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: themeColor.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.25),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: Colors.black, // Reklam yüklenene kadar arkaplan
              alignment: Alignment.center,
              constraints: const BoxConstraints(minHeight: 50),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'KISA BİR MOLA (DESTEK)',
                    style: TextStyle(
                      color: themeColor.withValues(alpha: 0.3),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  AdManager.buildBannerAdWidget(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
