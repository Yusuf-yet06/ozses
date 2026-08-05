import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

import '../screens/home_screen.dart';
import '../screens/desktop/desktop_main_screen.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key});

  @override
  Widget build(BuildContext context) {
    // Web için ekran genişliğine göre karar ver (Responsive)
    if (kIsWeb) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return const DesktopMainScreen();
          }
          return const HomeScreen();
        },
      );
    }

    // Gerçek Mobil Cihazlar (Android / iOS) - KESİNLİKLE MOBİL FORMAT
    if (Platform.isAndroid || Platform.isIOS) {
      return const HomeScreen();
    }

    // Gerçek Masaüstü Cihazlar (Windows / Mac / Linux) - KESİNLİKLE PC FORMATI
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return const DesktopMainScreen();
    }

    // Bilinmeyen platform fallback
    return const HomeScreen();
  }
}
