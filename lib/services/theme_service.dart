import 'package:flutter/material.dart';

class SiberThemeManager {
  // 🎯 SİBER HAMLE: Tüm uygulamayı (MaterialApp) dinamik olarak yönetecek ana beyin
  static final ValueNotifier<ThemeData> themeNotifier =
      ValueNotifier(_siberDarkTheme);

  static void setDarkMode(int mode) {
    if (mode == 0) {
      themeNotifier.value = _siberNightTheme;
    } else {
      themeNotifier.value = _siberDarkTheme;
    }
  }

  static final ThemeData _siberDarkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    primaryColor: Colors.cyanAccent,
    iconTheme: const IconThemeData(color: Colors.cyanAccent),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.black, elevation: 0),
    sliderTheme: const SliderThemeData(activeTrackColor: Colors.cyanAccent),
  );

  static final ThemeData _siberNightTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F172A), // Siber Gece Mavisi
    primaryColor: Colors.blueAccent,
    iconTheme: const IconThemeData(color: Colors.blueAccent),
    appBarTheme:
        const AppBarTheme(backgroundColor: Color(0xFF0F172A), elevation: 0),
    sliderTheme: const SliderThemeData(activeTrackColor: Colors.blueAccent),
  );
}
