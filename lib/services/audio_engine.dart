import '../core/platform/siber_platform.dart';

import 'package:flutter/foundation.dart'; // 🌐 WEB KALKANI İÇİN

class AudioEngine {
  static double manualBass = 1.0;
  static double manualVocal = 1.0;
  static double manualTreble = 1.0;

  // 🎯 SİBER EFEKTLER
  static double manual3DDepth = 0.0; // 0.0 - 1.0 arası
  static double manualTempo = 1.0; // 0.5 (Yavaş) - 2.0 (Hızlı) arası
  static double manualEcho = 0.0; // 0.0 - 1.0 arası

  // 🎯 SİBER GÖRSEL MODLAR
  static bool visualEffectsEnabled = true; // Siber Efekt Şalteri
  static int visualMode = 0; // 0: Çizgisel Neon, 1: Okyanus Dalgası
  static int darkMode =
      0; // 0: Night Mod (Hafif Çizgi), 1: Dark Mod (Zifiri Karanlık)

  // 🧬 SİBER BİYOLOJİK FREKANSLAR (BİOHACKİNG)
  static String currentBioFrequency = 'Kapalı';
  static double bioVolume = 0.05; // %5 default görünmez ses seviyesi

  static void applyPreset(String mode) {
    print("Siber Mod Aktif: $mode");
    if (mode == "Normal") {
      manualBass = 1.0;
      manualVocal = 1.0;
      manualTreble = 1.0;
      manual3DDepth = 0.0;
      manualTempo = 1.0;
      manualEcho = 0.0;
    } else if (mode == "Bas Boost") {
      manualBass = 2.0;
      manualVocal = 0.8;
      manualTreble = 0.5;
      manual3DDepth = 0.2;
      manualTempo = 1.0;
      manualEcho = 0.0;
    } else if (mode == "Şifa Modu") {
      // 🎯 Slowed & Reverb tarzı melankolik/şifa etkisi
      manualBass = 0.5;
      manualVocal = 1.2;
      manualTreble = 0.8;
      manual3DDepth = 0.8; // Derinlik stüdyo hissi
      manualTempo = 0.8; // Yavaşlatılmış (Slowed)
      manualEcho = 0.6; // Yankılı (Reverb)
    } else if (mode == "Savaş Modu") {
      // 🎯 Agresif, hızlı ve patlayan frekanslar
      manualBass = 1.8;
      manualVocal = 1.0;
      manualTreble = 1.5;
      manual3DDepth = 0.5;
      manualTempo = 1.2; // Hızlandırılmış
      manualEcho = 0.2;
    } else if (mode == "Vokal Öncelikli") {
      manualBass = 0.5;
      manualVocal = 1.8;
      manualTreble = 1.2;
      manual3DDepth = 0.1;
      manualTempo = 1.0;
      manualEcho = 0.1;
    }
  }

  static void syncHardware() {
    if (kIsWeb) {
      print("SİBER WEB DSP: Web tarayıcı yazılımsal EQ motoruna hükmediliyor!");
    } else if (!SiberPlatform.instance.supportsHardwareDSP) {
      print("SİBER MASAÜSTÜ DSP: Yazılımsal PC EQ motoruna (${manualBass}x Bass) hükmediliyor!");
    } else {
      print("SİBER MOBİL DSP: Android/iOS donanımsal çipine frekans basılıyor!");
    }
  }

  static List<String> getAllModes() {
    return [
      "Normal",
      "Bas Boost",
      "Şifa Modu",
      "Savaş Modu",
      "Vokal Öncelikli",
    ];
  }
}
