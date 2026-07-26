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
    // Açılışta mikrofon izni istememek için _speech.initialize()'i kaldırdık!
    // Artık _isReady = false olarak başlıyor, mikrofon butonuna basıldığında tetiklenecek.
    
    // Otonom beynin ayakta olup olmadığını kontrol et
    await SiberKopru.beyneBaglan();
  }
  
  // SİBER HAMLE: Sadece dinleme istendiğinde motoru uyanık hale getirir (Gizlilik kalkanı)
  Future<bool> ensureSpeechInitialized() async {
    if (_isReady) return true;
    _isReady = await _speech.initialize(
      onStatus: (status) => print('🎙️ Siber Ses Durumu: $status'),
      onError: (error) => print('❌ Siber Ses Hatası: $error'),
    );
    return _isReady;
  }

  // 🎯 SİBER HAMLE: Mikrofondan komut dinlemeye başla
  // 🎯 SİBER HAMLE: Mikrofondan komut dinlemeye başla, dinamik dil seçeneği eklendi
  void startListening(Function(String, bool) onResult, {String localeId = 'tr_TR'}) async {
    bool ready = await ensureSpeechInitialized();
    if (!ready) {
      print('⚠️ Siber Kulak hazır değil! Mikrofon iznini kontrol et.');
      return;
    }
    if (_speech.isListening) {
      await _speech.stop();
    }
    
    // Dil uyumluluk kalkanı
    var locales = await _speech.locales();
    String targetLocale = localeId;
    if (locales.isNotEmpty) {
      var match = locales.where((l) => l.localeId == localeId).toList();
      if (match.isEmpty) {
        // Tam eşleşme yoksa dil kodunun başına göre ara (tr_TR -> tr)
        var prefix = localeId.split('_').first.split('-').first;
        match = locales.where((l) => l.localeId.startsWith(prefix)).toList();
      }
      if (match.isNotEmpty) {
        targetLocale = match.first.localeId;
        print('🎯 Seçilen Siber Dil: ');
      }
    }

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      localeId: targetLocale,
      partialResults: true,
      listenMode: stt.ListenMode.search, // Arama kelimeleri (şarkı isimleri) için optimize et
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 10),
    );
  }

  // Dinlemeyi zorla durdurmak için
  void stopListening() {
    if (_speech.isListening) {
      _speech.stop();
    }
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
