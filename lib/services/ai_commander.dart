import '../core/platform/siber_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:io'; // 🛡️ SİBER KALKAN İÇİN
import '../models/song_model.dart';
import 'siber_kopru.dart';
import '../main.dart'; // 🎯 audioHandler bağlantısı için

class AICommander {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isReady = false;

  // 🎯 SİBER HAMLE: Ses motorunu ve Otonom motoru uyandır
  Future<void> initCommander() async {
    _isReady = await _speech.initialize(
      onStatus: (status) => print('🎙️ Siber Ses Durumu: $status'),
      onError: (error) => print('❌ Siber Ses Hatası: $error'),
    );

    // Otonom beynin ayakta olup olmadığını kontrol et
    await SiberKopru.beyneBaglan();
  }

  // 🎯 SİBER HAMLE: Mikrofondan komut dinlemeye başla
  void startListening(Function(String) onResult) async {
    if (!_isReady) {
      print('⚠️ Siber Kulak hazır değil! Mikrofon iznini kontrol et.');
      return;
    }
    if (_speech.isListening) {
      _speech.stop();
      return;
    }
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        }
      },
      localeId: 'tr_TR', // Gardaşımın dilini mühürledik
    );
  }

  // 🎯 SİBER HAMLE: Komutu Siber Beyin'e gönder ve uygula
  Future<void> executeSiberAction(
    String command,
    List<SongModel> Function() getPlaylist,
    Function(List<SongModel>) onUpdate,
  ) async {
    print('🤖 Siber Komut Alındı: $command');

    String karar = await SiberKopru.komutGonder(command);

    // 🛡️ SİBER İZOLATÖR: Ağa ulaşılamadıysa LOKAL MOTOR devreye girer!
    if (karar == 'offline_mod' || karar == 'hata') {
      print(
          '🛡️ SİBER İZOLATÖR: Ağ koptu, Lokal Zeka (Yedek Beyin) devreye giriyor!');
      karar = _lokalZekaKararVer(command.toLowerCase());
    }
    print('🧠 Nihai Karar: $karar');

    if (karar == 'play') {
      audioHandler.play();
    } else if (karar == 'pause') {
      audioHandler.pause();
    } else if (karar == 'bass_boost_on') {
      print('🔊 Siber Bass Motoru Kökleniyor!');
      if (SiberPlatform.instance.supportsHardwareDSP) {
        audioHandler.siberBassBooster.setEnabled(true);
        audioHandler.siberBassBooster
            .setTargetGain(1000.0); // 🎯 Maksimum derinlik!
      }
    } else if (karar == 'bass_boost_off') {
      print('🔈 Siber Bass Motoru Kapatılıyor!');
      if (SiberPlatform.instance.supportsHardwareDSP) audioHandler.siberBassBooster.setEnabled(false);
    } else if (karar == 'eq_on') {
      print('🎛️ Siber EQ Motoru Açılıyor!');
      if (SiberPlatform.instance.supportsHardwareDSP) audioHandler.siberEqualizer.setEnabled(true);
    } else if (karar == 'eq_off') {
      print('🎛️ Siber EQ Motoru Kapatılıyor!');
      if (SiberPlatform.instance.supportsHardwareDSP) audioHandler.siberEqualizer.setEnabled(false);
    }

    onUpdate(getPlaylist());
  }

  // 🛡️ LOKAL ZEKA (İnternetsiz / Çevrimdışı Çevrimdışı Kural Motoru)
  String _lokalZekaKararVer(String metin) {
    if (metin.contains('çal') ||
        metin.contains('başlat') ||
        metin.contains('devam')) {
      return 'play';
    }
    if (metin.contains('durdur') ||
        metin.contains('bekle') ||
        metin.contains('sus')) {
      return 'pause';
    }
    if (metin.contains('bas') || metin.contains('bass')) {
      if (metin.contains('aç') ||
          metin.contains('kökle') ||
          metin.contains('arttır')) {
        return 'bass_boost_on';
      }
      if (metin.contains('kapat') || metin.contains('kıs')) {
        return 'bass_boost_off';
      }
    }
    if (metin.contains('ekolayzır') ||
        metin.contains('eq') ||
        metin.contains('frekans')) {
      if (metin.contains('aç') || metin.contains('başlat')) return 'eq_on';
      if (metin.contains('kapat') || metin.contains('durdur')) return 'eq_off';
    }

    return 'bilinmiyor';
  }
}
