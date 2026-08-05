import '../core/platform/siber_platform.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart'; // 🎯 SİBER HAMLE: Donanım (DSP) Destekli Yeni Nesil Motor
import 'dart:math';
import 'dart:async';
import '../utils/song_media_utils.dart'; // safeParseUri için
import '../services/audio_engine.dart'; // 🎯 SİBER HAMLE: Otonom DSP Kontrolü İçin
import 'package:universal_io/io.dart';
import 'ad_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart'; // 🎯 SİBER HAMLE: Platform Algılayıcı
import 'package:flutter/foundation.dart'; // 🌐 WEB KALKANI İÇİN
import '../services/services.dart'; // 🎯 SİBER HAMLE: OzsesBridge için
import 'package:http/http.dart' as http; // SİBER AKIŞ İÇİN
import 'dart:convert'; // JSON İÇİN
import 'package:youtube_explode_dart/youtube_explode_dart.dart'; // 🎯 NÜKLEER ÇÖZÜM V2 İÇİN
import '../services/analytics_service.dart'; // 📈 SİBER ANALİTİK İÇİN
import '../services/subscription_manager.dart';

class MyAudioHandler extends BaseAudioHandler {
  late final AudioPlayer
      _player; // 🎯 SİBER HAMLE: Motoru sonradan bağlamak için zırhladık

  // 🧬 SİBER HAMLE: Biyolojik Hack için görünmez arka plan oynatıcısı
  final AudioPlayer _bioPlayer = AudioPlayer();

  List<MediaItem> _playlist = [];
  int _currentIndex = -1;
  int _consecutiveErrors = 0;
  bool _analyticsLogged = false; // 📊 SİBER ANALİTİK: Kayıt atıldı mı?

  // 🎯 SİBER HAMLE: Android DSP Ekolayzır ve Bas Güçlendirici
  final AndroidEqualizer siberEqualizer = AndroidEqualizer();
  final AndroidLoudnessEnhancer siberBassBooster = AndroidLoudnessEnhancer();

  // 🎯 SİBER HAMLE: Güçlendirilmiş Ses Motoru (Crossfade bugları sökülüp atıldı)
  final double _currentVolume = 1.0;

  // 🎯 SİBER HAFIZA: Ekolayzırı kilitleyip kasmayı önleyen Otonom Sensörler!
  double _lastBass = -1.0;
  double _lastTreble = -1.0;
  double _lastVocal = -1.0;
  double _lastTempo = -1.0;
  double _lastVolume = -1.0;
  String _lastBioFrequency = 'Kapalı';

  void _safeShowToast(String msg, {Toast? toastLength, Color? backgroundColor, Color? textColor}) {
    try {
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        print('💻 Siber Masaüstü Toast: $msg');
        return;
      }
      Fluttertoast.showToast(msg: msg, toastLength: toastLength, backgroundColor: backgroundColor, textColor: textColor);
    } catch (e) {
      print('⚠️ Siber Toast Hatası: $msg');
    }
  }

  MyAudioHandler() {
    // 🎯 SİBER HAMLE: Windows ve Android Çakışmasını Bitiren Saf Motor
    _player = AudioPlayer(
      audioPipeline: SiberPlatform.instance.supportsHardwareDSP
          ? AudioPipeline(
              androidAudioEffects: [siberEqualizer, siberBassBooster],
            )
          : null,
    );

    // 🎯 SİBER DİNLEYİCİ: Şarkı pozisyonu (saniye saniye) değiştikçe Slider'a sinyal gönder
    _player.positionStream.listen((position) {
      // 🎯 SİBER KALKAN: Şarkı 30 dakikayı devirirse (1800 sn) araya serpmeli reklam (Interstitial) tetikle
      if (position.inSeconds == 1770) {
        _safeShowToast('🎧 Birazdan Siber Keşiflere ufak bir reklam molası vereceğiz...', toastLength: Toast.LENGTH_LONG, backgroundColor: Colors.deepPurple, textColor: Colors.white);
      }
      if (position.inSeconds == 1800) {
        final isOffline = mediaItem.value?.id.startsWith('yt:') != true;
        AdManager.showInterstitialAdIfReady(isOfflineMode: isOffline, forceShow: true);
      }
      
      // 🎯 SİBER REKLAM BİLDİRİMİ: Şarkı bitimine 30 saniye kala eğer reklam çıkacaksa uyar
      if (mediaItem.value != null && _player.duration != null) {
        final remaining = _player.duration!.inSeconds - position.inSeconds;
        if (remaining == 30) {
          final isOffline = !mediaItem.value!.id.startsWith('yt:');
          final prevDuration = mediaItem.value!.duration?.inMinutes ?? 0;
          final forceAd = prevDuration >= 10;
          
          if (forceAd || AdManager.willShowAd(isOfflineMode: isOffline)) {
            _safeShowToast('🎧 Sonraki şarkıya geçerken ufak bir reklam molamız olacak...', toastLength: Toast.LENGTH_LONG, backgroundColor: Colors.deepPurple, textColor: Colors.white);
          }
        }
      }

      // 📊 SİBER ANALİTİK: Şarkı 30 saniye boyunca çalarsa dinleme olarak kaydet!
      if (position.inSeconds == 30 && !_analyticsLogged && mediaItem.value != null) {
        _analyticsLogged = true;
        final item = mediaItem.value!;
        final duration = item.duration?.inSeconds ?? 0;
        AnalyticsService().logPlay(item.id, item.title, item.artist ?? 'Bilinmiyor', duration);
      }

      // 🎯 SİBER DJ CROSSFADE (METAMORFOZ): Sadece yetkisi olanlarda çalışır!
      final duration = _player.duration;
      if (duration != null && _player.playing) {
        double fadeVolume = 1.0;

        if (SubscriptionManager().canUseMetamorphosis()) {
          final remaining = duration - position;

          if (remaining.inMilliseconds <= 2000) {
            // Son 2 saniye kala yavaşça sesi kıs (Fade Out - 5 saniye çok uzundu, ses kesildi sanılıyordu)
            fadeVolume = max(0.0, remaining.inMilliseconds / 2000.0);
          } else if (position.inMilliseconds <= 3000) {
            // İlk 3 saniye yavaşça sesi aç (Fade In)
            fadeVolume = min(1.0, position.inMilliseconds / 3000.0);
          }
        }

        // Eğer Fake DSP varsa o da etkilensin
        double targetVolume = fadeVolume;
        if (!SiberPlatform.instance.supportsHardwareDSP &&
            AudioEngine.manualBass > 1.0) {
          targetVolume += (AudioEngine.manualBass - 1.0) * 0.5;
        }
        _player.setVolume(targetVolume);
      }

      final currentState = playbackState.value;
      playbackState.add(currentState.copyWith(
        updatePosition: position,
      ));
    });

    // 🎯 Şarkının toplam süresi belli olunca UI'a mühürle
    _player.durationStream.listen((duration) {
      final item = mediaItem.value;
      if (item != null && duration != null) {
        mediaItem.add(item.copyWith(duration: duration));
      }
    });

    // 🎯 Play/Pause durumunu otonom dinle
    _player.playerStateStream.listen((state) {
      final playing = state.playing;
      final processingState = _getProcessingState(state.processingState);

      // 🧬 Biyolojik frekansı ana müzikle senkronize et (birlikte çalsın/dursun)
      if (playing && AudioEngine.currentBioFrequency != 'Kapalı') {
        _bioPlayer.play();
      } else {
        _bioPlayer.pause();
      }

      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        playing: playing,
        processingState: processingState,
        updatePosition: _player.position,
      ));

      // 🎯 Şarkı bitince otonom olarak sıradakine geç veya tekrarla
      if (state.processingState == ProcessingState.completed) {
        _handlePlaybackComplete();
      }
    });

    // 🎯 Otonom DSP Dinleyicisi (Siber Efektlerin Sese Yansıması)
    // AudioEngine içindeki değişimleri her saniye süzüp donanıma basıyoruz
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_player.playing) {
        applySiberDSP();
      }
    });
  }

  void applySiberDSP() async {
    try {
      // 🧬 0. BİYOLOJİK FREKANS MOTORU (SİBER BİOHACKİNG)
      if (_lastBioFrequency != AudioEngine.currentBioFrequency) {
        _lastBioFrequency = AudioEngine.currentBioFrequency;
        if (_lastBioFrequency == 'Kapalı') {
          await _bioPlayer.stop();
        } else {
          String assetPath = '';
          if (_lastBioFrequency == 'Rahatlama (Relax)') {
            assetPath = 'assets/audio/frequencies/432hz.mp3';
          } else if (_lastBioFrequency == 'Yenilenme (Recovery)')
            assetPath = 'assets/audio/frequencies/528hz.mp3';
          else if (_lastBioFrequency == 'Derin Odak (Focus)')
            assetPath = 'assets/audio/frequencies/focus_40hz.mp3';
          else if (_lastBioFrequency == 'Derin Uyku (Sleep)')
            assetPath = 'assets/audio/frequencies/sleep_4hz.mp3';

          if (assetPath.isNotEmpty) {
            await _bioPlayer.setAsset(assetPath);
            await _bioPlayer.setLoopMode(LoopMode.one); // Sonsuz döngü
            await _bioPlayer.setVolume(AudioEngine.bioVolume);
            if (_player.playing) {
              _bioPlayer.play();
            }
          }
        }
      } else if (_lastBioFrequency != 'Kapalı') {
        // Ses ayarı değişirse anında uygula
        if (_bioPlayer.volume != AudioEngine.bioVolume) {
          await _bioPlayer.setVolume(AudioEngine.bioVolume);
        }
      }

      // 1. TEMPO VE PITCH (Evrensel PC/Mobil)
      if (_lastTempo != AudioEngine.manualTempo) {
        _lastTempo = AudioEngine.manualTempo;
        await _player.setSpeed(AudioEngine.manualTempo);
        await _player.setPitch(AudioEngine.manualTempo); // Pitch senkronu
      }

      // 2. ANDROID GERÇEK DONANIM DSP (Çip Seviyesi)
      if (SiberPlatform.instance.supportsHardwareDSP) {
        // Bas Güçlendirici (Mobil Hoparlör Koruma Kalkanı eklendi)
        if (_lastBass != AudioEngine.manualBass) {
          _lastBass = AudioEngine.manualBass;
          if (AudioEngine.manualBass > 1.0) {
            if (!siberBassBooster.enabled) {
              await siberBassBooster.setEnabled(true);
            }

            // 🎯 SİBER MOBİL KALKAN: Telefon hoparlörlerinin çatlamasını (clipping) önlemek için Bass limiti
            double safeBass = AudioEngine.manualBass;
            if (safeBass > 1.4) safeBass = 1.4; // Telefondaki patlamaları önler

            await siberBassBooster.setTargetGain((safeBass - 1.0) * 1000.0);
          } else {
            if (siberBassBooster.enabled) {
              await siberBassBooster.setEnabled(false);
            }
          }
        }

        // Tiz/Vokal Ekolayzır (Dinamik Hesaplama)
        if (_lastTreble != AudioEngine.manualTreble ||
            _lastVocal != AudioEngine.manualVocal) {
          _lastTreble = AudioEngine.manualTreble;
          _lastVocal = AudioEngine.manualVocal;

          if (_lastTreble > 1.0 || _lastVocal > 1.0) {
            if (!siberEqualizer.enabled) await siberEqualizer.setEnabled(true);
            final params = await siberEqualizer.parameters;

            double highestGainReq =
                max(_lastTreble, _lastVocal); // En çok kim istiyor
            double targetGain = (highestGainReq - 1.0) * params.maxDecibels;
            if (targetGain > params.maxDecibels) {
              targetGain = params.maxDecibels;
            }

            for (var band in params.bands) {
              if (band.centerFrequency > 3000) {
                await band
                    .setGain(targetGain); // Sabit %50 yerine DİNAMİK siber güç!
              }
            }
          } else {
            if (siberEqualizer.enabled) await siberEqualizer.setEnabled(false);
          }
        }
      }
      // 3. MASAÜSTÜ (PC) VE WEB SİMÜLASYONU (Yazılımsal Fake DSP)
      else {
        double simulatedVolume = 1.0;
        if (AudioEngine.manualBass > 1.0) {
          // Bas hissiyatı yaratmak için PC'de ana sesi kökler!
          simulatedVolume += (AudioEngine.manualBass - 1.0) * 0.5;
        }
        
        // 🔊 UI'dan gelen Master Volume değerini uygula
        simulatedVolume = simulatedVolume * AudioEngine.masterVolume;
        
        if (_lastVolume != simulatedVolume) {
          _lastVolume = simulatedVolume;
          await _player.setVolume(simulatedVolume);
        }
      }
    } catch (e) {
      print('DSP Hata: $e');
    }
  }

  AudioProcessingState _getProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      // ignore: unreachable_switch_default
      default:
        return AudioProcessingState.idle;
    }
  }

  void _handlePlaybackComplete() {
    // 🛡️ SİBER KALKAN: Sahte tamamlanma koruması (Çok kısa süreli çalmalar)
    if (_player.position.inSeconds < 2) {
      print('⚠️ SİBER KALKAN: Sahte tamamlanma algılandı (pozisyon ${_player.position.inSeconds}sn < 2sn), atlama iptal edildi.');
      _consecutiveErrors++;
      if (_consecutiveErrors > 3) {
        print('🛑 SİBER KALKAN: Üst üste sahte tamamlanma! Oynatma durduruldu.');
        _consecutiveErrors = 0;
        stop();
        return;
      }
      Future.delayed(Duration(milliseconds: 1500 * _consecutiveErrors), skipToNext);
      return;
    }

    // 🛡️ SİBER KALKAN V2: Erken kesilme koruması (YouTube Throttling)
    final duration = _player.duration;
    if (duration != null) {
      final difference = duration.inSeconds - _player.position.inSeconds;
      if (difference > 4) {
        print('⚠️ SİBER KALKAN: Şarkı $difference saniye erken kesildi! (Büyük ihtimalle YouTube bağlantıyı kopardı)');
        // Şarkı yarıda kesildiği için atlama yapmak en sağlıklısı, ancak hata kaydı düşüyoruz.
        _safeShowToast('Bağlantı zayıfladı, sıradakine geçiliyor...', backgroundColor: Colors.orange, textColor: Colors.white);
      }
    }
    
    // 🎛️ SİBER DJ: Metamorfoz - Şarkı tam bitmeden (son saniyelerde) sonraki şarkıya pürüzsüz geç
    _consecutiveErrors = 0; // Başarılı çalma, hata sayacını sıfırla
    final repeatMode = playbackState.value.repeatMode;
    if (repeatMode == AudioServiceRepeatMode.one) {
      seek(Duration.zero);
      play();
    } else {
      skipToNext();
    }
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    _playlist.add(mediaItem);
    queue.add(_playlist);
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    if (index < 0) index = 0;
    if (index > _playlist.length) index = _playlist.length;
    _playlist.insert(index, mediaItem);
    queue.add(_playlist);
  }

  @override
  Future<void> play() async {
    if ((_player.audioSource == null ||
            _player.processingState == ProcessingState.idle) &&
        _playlist.isNotEmpty) {
      int idx = _currentIndex >= 0 ? _currentIndex : 0;
      await skipToQueueItem(idx);
    }

    if (_player.audioSource != null &&
        _player.processingState != ProcessingState.idle) {
      await _player.play();
    }
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'setVolume') {
      final double vol = extras?['volume'] ?? 1.0;
      AudioEngine.masterVolume = vol; // Master volume'u kaydet
      
      // Anında etki etmesi için hesaplayıp player'a basıyoruz
      double simulatedVolume = vol;
      if (AudioEngine.manualBass > 1.0) {
        simulatedVolume += (AudioEngine.manualBass - 1.0) * 0.5;
        simulatedVolume = simulatedVolume * vol; // vol çarpanını uygula
      }
      
      _lastVolume = simulatedVolume;
      await _player.setVolume(simulatedVolume);
      
      return null;
    }
    return super.customAction(name, extras);
  }

  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    _playlist = newQueue;
    queue.add(newQueue);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    // 🎯 SİBER REKLAM KONTROLÜ: Geçişlerde reklam patlat
    if (mediaItem.value != null) {
      final prevDuration = mediaItem.value!.duration?.inMinutes ?? 0;
      final isOffline = !mediaItem.value!.id.startsWith('yt:');
      final forceAd = prevDuration >= 10; // Son şarkı 10 dk'dan uzunsa kesin reklam
      AdManager.showInterstitialAdIfReady(isOfflineMode: isOffline, forceShow: forceAd);
    }

    if (index < 0 || index >= _playlist.length) return;
    _currentIndex = index;
    _analyticsLogged = false; // 📊 Yeni şarkı, kayıt bayrağını sıfırla
    final item = _playlist[index];
    mediaItem.add(item);

    // 🛡️ SİBER KALKAN: Kuyruk sırasını sisteme mühürle ki araya şarkı ekleyebilelim
    playbackState.add(playbackState.value.copyWith(
      queueIndex: _currentIndex,
    ));

    // 🛡️ SİBER KALKAN: Yeni şarkı gelirken Android motorunu bodoslama boğmamak için pause yapıyoruz (Stop tamamen kapatır)
    if (_player.playing) {
      await _player.pause();
    }

    // 🛡️ SİBER KALKAN: Geçersiz yollar Android motorunu çökertmesin!
    if (item.id == 'bilinmeyen_yol' ||
        item.id.isEmpty ||
        item.id.startsWith('downloading:')) {
      return;
    }

    if (!kIsWeb) {
      if (!item.id.startsWith('http') &&
          !item.id.startsWith('yt:')) {
        final file = File(item.id);
        if (!file.existsSync() || file.lengthSync() < 1024) {
          print('❌ Yerel dosya bulunamadı veya bozuk (0 byte): ${item.id}');
          throw Exception('Dosya bozuk veya bulunamadı.');
        }
      }
    }

    try {
      String resolvedUrl = item.id;

      // 🎯 SİBER OPERASYON: DİNAMİK AKIŞ ÇÖZÜCÜ
      if (item.id.startsWith('yt:')) {
        print("▶️ Siber Mühür Yakalandı: 'yt:' ID'li akış çözülüyor...");
        final videoId = item.id.substring(3);
        final bridge = OzsesBridge();

        playbackState.add(playbackState.value.copyWith(
          playing: false,
          processingState: AudioProcessingState.loading,
        ));

        // ⏳ Dosya indirilene kadar bekle
        final res = await bridge.getStreamUrl(videoId);

        if (_currentIndex != index) {
          print(
              '⏭️ Hız: Kullanıcı başka şarkıya atladı, eski akış çözme işlemi iptal edildi.');
          return;
        }

        if (res['status'] == 'basarili' && res['stream_url'] != null) {
          resolvedUrl = res['stream_url'];

          // 🎯 SİBER HAMLE: Dosya zaten varsa anında çal (Çift Çekirdek)
          if (res['is_file'] == true) {
            await _player.setAudioSource(AudioSource.file(resolvedUrl));
            _lastBass = -1.0;
            _lastTreble = -1.0;
            _lastVocal = -1.0;
            _lastTempo = -1.0;
            _lastVolume = -1.0;
            applySiberDSP();
            await _player.play();
            return;
          }

          // 🚀 Doğrudan URL geldi, kullan
          print('🎯 Doğrudan Akış URL: $resolvedUrl');
        } else {
          throw Exception("Siber Kalkan: Akış çözülemedi (${res['mesaj']})");
        }
      }

      if (resolvedUrl.startsWith('http://') ||
          resolvedUrl.startsWith('https://')) {
        await _player
            .setAudioSource(AudioSource.uri(
          Uri.parse(resolvedUrl),
          headers: {
            // 🛡️ SİBER KALKAN: YouTube'un stream'i yarıda kesmesini (throttling) engellemek için tarayıcı kimliği eklendi!
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          }
        ))
            .timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            throw TimeoutException(
                'Akış yüklenemedi veya dosya bağlantısı koptu.');
          },
        ).catchError((error) {
          print('🔥 DETAYLI SİBER HATA (LÜTFEN BANA BUNU AT): $error');
          throw error;
        });
      } else {
        await _player.setAudioSource(AudioSource.file(resolvedUrl)).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException('Yerel dosya yüklenemedi: $resolvedUrl');
          },
        );
      }

      // 🎯 SİBER HAFIZA SIFIRLAMA
      _lastBass = -1.0;
      _lastTreble = -1.0;
      _lastVocal = -1.0;
      _lastTempo = -1.0;
      _lastVolume = -1.0;

      applySiberDSP();

      await _player.play();
      _consecutiveErrors = 0; // SİBER BAŞARI: Hata sayacını sıfırla
    } catch (e) {
      print('HATA: Platform oynatma hatası -> $e');
      _consecutiveErrors++;

      try { await _player.stop(); } catch (_) {} // 🛡️ SİBER KALKAN: Sıkışmış player state'i temizle

      if (_consecutiveErrors > 3) {
        print('🛑 Siber Kalkan: Üst üste 3 defa hata alındı! Oynatma sonsuz döngüye girmemesi için durduruldu.');
        _consecutiveErrors = 0; // Sonraki elle oynatmada tekrar deneyebilsin diye sıfırlıyoruz.
        _safeShowToast(
          'Bağlantı koptu veya şarkı bozuk. Oynatma durduruldu.',
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
        return;
      }

      // 🛡️ SİBER KALKAN: Akış hatasında otonom geçiş (ardışık hata sayısına göre artan gecikme)
      final delayMs = 1500 * _consecutiveErrors;
      print('⚠️ Hata yakalandı, ${delayMs}ms sonra sıradaki şarkıya geçiliyor... (ardışık hata: $_consecutiveErrors)');
      Future.delayed(Duration(milliseconds: delayMs), skipToNext);
    }
  }

  @override
  Future<void> skipToNext() async {
    if (_playlist.isEmpty) return;

    final shuffleMode = playbackState.value.shuffleMode;
    if (shuffleMode == AudioServiceShuffleMode.all) {
      _currentIndex =
          Random().nextInt(_playlist.length); // Rastgele siber atlama
    } else {
      _currentIndex++;
      if (_currentIndex >= _playlist.length) {
        final repeatMode = playbackState.value.repeatMode;
        if (repeatMode == AudioServiceRepeatMode.all) {
          _currentIndex = 0; // Liste başına dön
        } else {
          // 🛡️ SİBER KALKAN: Otonom Sonsuz Radyo! Eğer yt: akışıysa bitince yeni şarkılar ekle
          if (_playlist.isNotEmpty && _playlist.last.id.startsWith('yt:')) {
            final lastVideoId = _playlist.last.id.substring(3);
            
            _safeShowToast(
              '📻 Otonom Radyo Devrede: Sonsuz akış uzatılıyor...',
              backgroundColor: Colors.deepPurple,
              textColor: Colors.white,
            );
            
            final bridge = OzsesBridge();
            final radioSongs = await bridge.getRadio(lastVideoId);
            
            if (radioSongs.isNotEmpty) {
              final newItems = <MediaItem>[];
              for (var rSong in radioSongs) {
                final rTitle = rSong['title'] ?? 'Bilinmeyen';
                final rVId = rSong['id'];
                final rImgUrl = rSong['thumbnail'];
                final rArtist = rSong['channel'] ?? 'Victus V7';
                final rDur = rSong['duration'] ?? 0;
                
                int rFinalDur = 0;
                if (rDur is int) {
                  rFinalDur = rDur;
                } else if (rDur is String) {
                  final parts = rDur.split(':');
                  if (parts.length == 2) {
                    rFinalDur = (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
                  } else if (parts.length == 3) {
                    rFinalDur = (int.tryParse(parts[0]) ?? 0) * 3600 + (int.tryParse(parts[1]) ?? 0) * 60 + (int.tryParse(parts[2]) ?? 0);
                  }
                }

                // Önceden eklenen şarkıları tekrar ekleme ihtimalini azaltalım
                if (rVId != null && !_playlist.any((item) => item.id == 'yt:$rVId')) {
                  newItems.add(MediaItem(
                    id: 'yt:$rVId',
                    album: 'Siber Keşfet Akışı',
                    title: rTitle,
                    artist: rArtist,
                    duration: Duration(seconds: rFinalDur),
                    artUri: safeParseUri(rImgUrl),
                  ));
                }
              }
              
              if (newItems.isNotEmpty) {
                _playlist.addAll(newItems);
                queue.add(_playlist);
                
                _safeShowToast(
                  '✅ Radyo Güncellendi: ${newItems.length} yeni parça eklendi!',
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                );
              } else {
                _currentIndex = 0; // Hata veya boşsa başa dön
              }
            } else {
              _currentIndex = 0; // Hata veya boşsa başa dön
            }
          } else {
            _currentIndex = _playlist.length - 1;
            await stop(); // Tekrar kapalıysa bitir
            return;
          }
        }
      }
    }
    await skipToQueueItem(_currentIndex);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_playlist.isEmpty) return;

    _currentIndex--;
    if (_currentIndex < 0) {
      _currentIndex = _playlist.length - 1; // En sona atla
    }
    await skipToQueueItem(_currentIndex);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    final index = _playlist.indexOf(mediaItem);
    if (index == -1) return;

    _playlist.removeAt(index);
    queue.add(_playlist);

    // 🛡️ SİBER KALKAN: Silinen şarkı çalınan şarkıdan önceyse indexi kaydır
    if (index < _currentIndex) {
      _currentIndex--;
      playbackState
          .add(playbackState.value.copyWith(queueIndex: _currentIndex));
    }
    // 🛡️ SİBER KALKAN: Silinen şarkı şu an çalan şarkıysa otonom olarak sıradakine geç
    else if (index == _currentIndex) {
      if (_playlist.isEmpty) {
        await stop();
      } else {
        if (_currentIndex >= _playlist.length) _currentIndex = 0;
        await skipToQueueItem(_currentIndex);
      }
    }
  }

  // 🎯 SİBER HAMLE: Şarkı Sürükle-Bırak (Reorder) yeteneği
  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _playlist.length) return;
    if (newIndex < 0 || newIndex > _playlist.length) return;

    final item = _playlist.removeAt(oldIndex);
    _playlist.insert(newIndex, item);
    queue.add(_playlist);

    // 🛡️ SİBER KALKAN: Çalan şarkının indexi kaydıysa onu da otonom olarak düzelt
    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }
    playbackState.add(playbackState.value.copyWith(queueIndex: _currentIndex));
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
  }

  // 🎯 SİBER HAMLE: Depolama Yönetimi (Cache Temizliği)
  Future<void> clearStreamCache() async {
    await AudioPlayer.clearAssetCache();
    print('🧹 Önbellek (Cache) tamamen temizlendi!');
  }
}
