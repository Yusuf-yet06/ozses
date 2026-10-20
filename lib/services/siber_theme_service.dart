import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_analysis_service.dart';
import '../main.dart'; // for audioHandler

class SiberThemeService {
  static final SiberThemeService instance = SiberThemeService();
  
  final ValueNotifier<Color> currentThemeColor = ValueNotifier<Color>(Colors.deepPurple);
  Color _baseSavedColor = Colors.deepPurple;
  bool _isInitialized = false;
  
  // 🍃 SADE MOD (Minimalist) vs ⚡ ŞATAFATLI SİBER MOD (İmperium)
  final ValueNotifier<bool> isMinimalMode = ValueNotifier<bool>(false);
  
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final prefs = await SharedPreferences.getInstance();
    int? colorValue = prefs.getInt('siber_aura_color');
    if (colorValue != null) {
      _baseSavedColor = Color(colorValue);
      currentThemeColor.value = _baseSavedColor;
    }

    // Sade Mod tercihini hafızadan oku
    isMinimalMode.value = prefs.getBool('siber_minimal_mode') ?? false;
  }

  void updateBaseColor(Color newColor) async {
    _baseSavedColor = newColor;
    // Anında rengi değiştir (müzik çalsa bile)
    currentThemeColor.value = newColor;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('siber_aura_color', newColor.value);
  }

  // 🔀 SADE / SİBER MOD GEÇİŞ METODLARI
  Future<void> toggleMinimalMode() async {
    isMinimalMode.value = !isMinimalMode.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('siber_minimal_mode', isMinimalMode.value);
  }

  Future<void> setMinimalMode(bool value) async {
    isMinimalMode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('siber_minimal_mode', value);
  }
}
