import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_analysis_service.dart';
import '../main.dart'; // for audioHandler

class SiberThemeService {
  static final SiberThemeService instance = SiberThemeService();
  
  final ValueNotifier<Color> currentThemeColor = ValueNotifier<Color>(Colors.deepPurple);
  Color _baseSavedColor = Colors.deepPurple;
  bool _isInitialized = false;
  
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final prefs = await SharedPreferences.getInstance();
    int? colorValue = prefs.getInt('siber_aura_color');
    if (colorValue != null) {
      _baseSavedColor = Color(colorValue);
      currentThemeColor.value = _baseSavedColor;
    }

    // Müzik Ruh Haline Göre Renk Değişimi
    AudioAnalysisService.instance.getAnalysisStream().listen((data) {
      if (audioHandler.playbackState.value.playing) {
        Color moodColor;
        switch (data.waveType) {
          case 'Chill':
            moodColor = Colors.cyanAccent;
            break;
          case 'Enerjik':
            moodColor = Colors.orangeAccent;
            break;
          case 'Agresif':
            moodColor = Colors.redAccent;
            break;
          case 'Karanlık/Bass':
            moodColor = Colors.purpleAccent;
            break;
          default:
            moodColor = _baseSavedColor;
        }
        
        if (currentThemeColor.value != moodColor) {
          currentThemeColor.value = moodColor;
        }
      } else {
        if (currentThemeColor.value != _baseSavedColor) {
          currentThemeColor.value = _baseSavedColor;
        }
      }
    });

    // Müzik durduğunda base renge dönmek için playback state'i de dinle
    audioHandler.playbackState.listen((state) {
      if (!state.playing) {
        if (currentThemeColor.value != _baseSavedColor) {
          currentThemeColor.value = _baseSavedColor;
        }
      }
    });
  }

  void updateBaseColor(Color newColor) async {
    _baseSavedColor = newColor;
    if (!audioHandler.playbackState.value.playing) {
      currentThemeColor.value = newColor;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('siber_aura_color', newColor.value);
  }
}
