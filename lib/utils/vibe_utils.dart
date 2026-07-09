import 'package:flutter/material.dart';

class VibeController {
  static Color getVibeColor(String songName) {
    String name = songName.toLowerCase();

    // Siber Savunma ve Focus Modu Renkleri
    if (name.contains('focus') || name.contains('çalışma')) {
      return Colors.cyanAccent;
    }
    if (name.contains('relax') || name.contains('şifa')) {
      return Colors.tealAccent;
    }
    if (name.contains('bass') || name.contains('high')) return Colors.redAccent;
    if (name.contains('night') || name.contains('gece')) {
      return Colors.indigoAccent;
    }

    return Colors.deepPurpleAccent; // Standart Imperium Rengi
  }

  // Focus Flow aktifken ekranın alacağı sakinleştirici gradyan
  static List<Color> getFocusGradient(Color themeColor) {
    return [
      Colors.black,
      themeColor.withValues(alpha: 0.05),
      Colors.black,
    ];
  }
}
