import 'package:flutter/material.dart';

class VibePackage {
  final Color themeColor;
  final List<Color> gradientColors;
  final Duration animationSpeed;
  final double sharpness;

  VibePackage({
    required this.themeColor,
    this.gradientColors = const [
      Colors.black,
      Colors.transparent,
      Colors.black
    ],
    this.animationSpeed = const Duration(milliseconds: 1000),
    this.sharpness = 0.5,
  });
}

class VibeEngine {
  // SİBER MODLAR: AICommander buradaki modları tetikleyecek
  static VibePackage getPackageByMode(String? mode) {
    final safeMode = mode ?? 'DEFAULT';

    // 🎯 SİBER HAMLE: Frekans Motorundan gelen metne göre Otonom Renk Değişimi
    if (safeMode.contains('Deprem')) {
      return VibePackage(themeColor: Colors.deepPurpleAccent);
    }
    if (safeMode.contains('Sıcak')) {
      return VibePackage(themeColor: Colors.orangeAccent);
    }
    if (safeMode.contains('Vokal')) {
      return VibePackage(themeColor: Colors.cyanAccent);
    }
    if (safeMode.contains('Parlak')) {
      return VibePackage(themeColor: Colors.greenAccent);
    }
    if (safeMode.contains('Kristal')) {
      return VibePackage(themeColor: Colors.pinkAccent);
    }

    // Siber Kalkan: Null değer gelirse bodoslama patlamasın diye güvenli dönüşüm
    final upperMode = safeMode.toUpperCase();
    switch (upperMode) {
      case 'RELAX': // Düşük Enerji / Şifa Modu
        return VibePackage(
          themeColor: Colors.greenAccent,
          gradientColors: [
            Colors.black,
            Colors.green.withValues(alpha: 0.2),
            Colors.black
          ],
          animationSpeed: const Duration(milliseconds: 2000),
          sharpness: 0.3,
        );
      case 'WAR': // Yüksek Enerji / Agresif Mod
        return VibePackage(
          themeColor: Colors.redAccent,
          gradientColors: [
            Colors.black,
            Colors.red.withValues(alpha: 0.4),
            Colors.black
          ],
          animationSpeed: const Duration(milliseconds: 400),
          sharpness: 1.0,
        );
      default: // Standart Imperium Modu
        return VibePackage(
          themeColor: Colors.deepPurpleAccent,
          gradientColors: [
            Colors.black,
            Colors.purple.withValues(alpha: 0.15),
            Colors.black
          ],
          animationSpeed: const Duration(milliseconds: 1300),
          sharpness: 0.5,
        );
    }
  }

  // Mevcut şarkı ismi analiz fonksiyonun kalsın, ama bu yeni metotla birleşsin
  VibePackage analyzeVibe(String? songName, [bool? isPlaying]) =>
      VibeEngine.getPackageByMode('DEFAULT');
}
