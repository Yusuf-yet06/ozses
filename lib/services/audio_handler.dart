import '../core/platform/siber_platform.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart'; // 🎯 SİBER HAMLE: Donanım (DSP) Destekli Yeni Nesil Motor
import 'dart:math';
import 'dart:async';
import '../services/audio_engine.dart'; // 🎯 SİBER HAMLE: Otonom DSP Kontrolü İçin
import 'dart:io'; // 🎯 SİBER HAMLE: Platform Algılayıcı
import 'package:flutter/foundation.dart'; // 🌐 WEB KALKANI İÇİN
import '../services/services.dart'; // 🎯 SİBER HAMLE: OzsesBridge için
import 'package:http/http.dart' as http; // SİBER AKIŞ İÇİN

class MyAudioHandler extends BaseAudioHandler {
  late final AudioPlayer
      _player; // 🎯 SİBER HAMLE: Motoru sonradan bağlamak için zırhladık
  
  // 🧬 SİBER HAMLE: Biyolojik Hack için görünmez arka plan oynatıcısı
  final AudioPlayer _bioPlayer = AudioPlayer();

  List<MediaItem> _playlist = [];
  int _currentIndex = -1;

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
      // 🎛️ SİBER DJ CROSSFADE: Kesintisiz ve akıcı müzik geçişi!
      final duration = _player.duration;
      if (duration != null && _player.playing) {
        final remaining = duration - position;
        double fadeVolume = 1.0;
        
        if (remaining.inMilliseconds <= 5000) {
           // Son 5 saniye kala yavaşça sesi kıs (Fade Out)
           fadeVolume = max(0.0, remaining.inMilliseconds / 5000.0);
        } else if (position.inMilliseconds <= 4000) {
           // İlk 4 saniye yavaşça sesi aç (Fade In)
           fadeVolume = min(1.0, position.inMilliseconds / 4000.0);
        }
        
        // Eğer Fake DSP varsa o da etkilensin
        double targetVolume = fadeVolume;
        if (!SiberPlatform.instance.supportsHardwareDSP && AudioEngine.manualBass > 1.0) {
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
          if (_lastBioFrequency == 'Rahatlama (Relax)') assetPath = 'assets/audio/frequencies/432hz.mp3';
          else if (_lastBioFrequency == 'Yenilenme (Recovery)') assetPath = 'assets/audio/frequencies/528hz.mp3';
          else if (_lastBioFrequency == 'Derin Odak (Focus)') assetPath = 'assets/audio/frequencies/focus_40hz.mp3';
          else if (_lastBioFrequency == 'Derin Uyku (Sleep)') assetPath = 'assets/audio/frequencies/sleep_4hz.mp3';

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
            if (!siberBassBooster.enabled)
              await siberBassBooster.setEnabled(true);
              
            // 🎯 SİBER MOBİL KALKAN: Telefon hoparlörlerinin çatlamasını (clipping) önlemek için Bass limiti
            double safeBass = AudioEngine.manualBass;
            if (safeBass > 1.4) safeBass = 1.4; // Telefondaki patlamaları önler
            
            await siberBassBooster
                .setTargetGain((safeBass - 1.0) * 1000.0);
          } else {
            if (siberBassBooster.enabled)
              await siberBassBooster.setEnabled(false);
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
            if (targetGain > params.maxDecibels)
              targetGain = params.maxDecibels;

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
        if (_lastVolume != simulatedVolume) {
          _lastVolume = simulatedVolume;
          await _player.setVolume(simulatedVolume);
        }
      }
    } catch (e) {
      print("DSP Hata: $e");
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
    // 🎛️ SİBER DJ: Metamorfoz - Şarkı tam bitmeden (son saniyelerde) sonraki şarkıya pürüzsüz geç
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
    if ((_player.audioSource == null || _player.processingState == ProcessingState.idle) && _playlist.isNotEmpty) {
      int idx = _currentIndex >= 0 ? _currentIndex : 0;
      await skipToQueueItem(idx);
    }
    
    if (_player.audioSource != null && _player.processingState != ProcessingState.idle) {
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
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    _playlist = newQueue;
    queue.add(newQueue);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    _currentIndex = index;
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

    if (!item.id.startsWith('http') &&
        !item.id.startsWith('yt:') &&
        !File(item.id).existsSync()) {
      print("❌ Yerel dosya bulunamadı, sıradakine atlanmıyor: ${item.id}");
      return;
    }

    try {
      String resolvedUrl = item.id;

      // 🎯 SİBER OPERASYON: DİNAMİK AKIŞ ÇÖZÜCÜ
      if (item.id.startsWith('yt:')) {
        print("▶️ Siber Mühür Yakalandı: 'yt:' ID'li akış çözülüyor...");
        final videoId = item.id.substring(3);
        final bridge = OzsesBridge();

        // 🔥 UI'ya "indiriliyor" sinyali ver (kullanıcı bekleyeceğini bilsin)
        playbackState.add(playbackState.value.copyWith(
          playing: false,
          processingState: AudioProcessingState.loading,
        ));
        // ⏳ Dosya indirilene kadar bekle — timeout YOK (şarkı boyutuna göre 10-60sn)
        final res = await bridge.getStreamUrl(videoId);

        if (_currentIndex != index) {
          print("⏭️ Hız: Kullanıcı başka şarkıya atladı, eski akış çözme işlemi iptal edildi.");
          return;
        }

        if (res['status'] == 'basarili' && res['stream_url'] != null) {
          resolvedUrl = res['stream_url'];
          // 🔥 SİBER KALKAN: Eğer YoutubeExplode native indirme yaptıysa (temp dosya)
          // just_audio'nun dahili proxy'sini bypass edip direkt dosyayı oku
          if (res['is_file'] == true) {
            // Yerel dosyadan oynat — timeout yok, dosya zaten var
            await _player.setAudioSource(AudioSource.file(resolvedUrl));
            _lastBass = -1.0; _lastTreble = -1.0; _lastVocal = -1.0; _lastTempo = -1.0; _lastVolume = -1.0;
            applySiberDSP();
            await _player.play();
            return;
          }
          // 🚀 SİBER HAMLE: Windows ve iOS üzerinde yerel player'lar (MediaFoundation/AVPlayer) 
          // YouTube 403 Forbidden hatası atabiliyor. Bunu aşmak için yerel proxy üzerinden geçiriyoruz!
          if (!kIsWeb && (Platform.isWindows || Platform.isIOS || Platform.isMacOS)) {
             resolvedUrl = 'http://127.0.0.1:${OzsesBridge.proxyPort}/$videoId';
             print("🎯 Siber Proxy Yönlendirmesi: $resolvedUrl");
          }
        } else {
          print("❌ Hata: Akış çözülemedi, siber kalkan ile oynatma durduruldu!");
          playbackState.add(playbackState.value.copyWith(
            playing: false,
            processingState: AudioProcessingState.idle,
          ));
          return;
        }
      }

      if (resolvedUrl.startsWith('http://') || resolvedUrl.startsWith('https://')) {
        await _player.setAudioSource(AudioSource.uri(
          Uri.parse(resolvedUrl),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Referer': 'https://www.youtube.com/'
          },
        )).timeout(
          const Duration(seconds: 120),
          onTimeout: () {
            throw TimeoutException("Akış yüklenemedi veya dosya bağlantısı koptu.");
          },
        );
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
    } catch (e) {
      print("HATA: Platform oynatma hatası -> $e");

      // 🛡️ SİBER KALKAN: Akış hatasında sessizce dur, otomatik sıradakine ATLAMIYOR!
      // (Eski skipToNext() çağrısı Şakı sonraya atlama hatasına yol açıyordu)
      playbackState.add(playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
      ));
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
          _currentIndex = _playlist.length - 1;
          await stop(); // Tekrar kapalıysa bitir
          return;
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
    print("🧹 Önbellek (Cache) tamamen temizlendi!");
  }
}
