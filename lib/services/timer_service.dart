import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart'; // audioHandler'a erişim için

// 🎯 SİBER HAMLE: Küresel Uyku Zamanlayıcısı
final ValueNotifier<int> globalSleepTimer = ValueNotifier<int>(0);
Timer? globalSleepTimerInstance;

void startSleepTimer(int minutes) {
  globalSleepTimerInstance?.cancel();
  globalSleepTimer.value = minutes * 60;
  if (minutes > 0) {
    globalSleepTimerInstance =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (globalSleepTimer.value > 0) {
        globalSleepTimer.value--;
      } else {
        timer.cancel();
        audioHandler.stop(); // 🎯 Süre bitince müziği kes at!
      }
    });
  }
}
