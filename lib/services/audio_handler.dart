import 'dart:io';
import '../core/platform/siber_platform.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
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
import 'audio_analysis_service.dart';
import 'lyrics_service.dart';

class MyAudioHandler extends BaseAudioHandler {
  late final AudioPlayer
      _player; // 🎯 SİBER HAMLE: Motoru sonradan bağlamak için zırhladık

  // 🧬 SİBER HAMLE: Biyolojik Hack için görünmez arka plan oynatıcısı
  final AudioPlayer _bioPlayer = AudioPlayer();

  List<MediaItem> _playlist = [];
  int _currentIndex = -1;
  int _consecutiveErrors = 0;
  int _songsPlayedSinceLastAd = 0; // 🎯 SİBER REKLAM SAYACI (4-5 şarkıda bir reklam)
  DateTime? _lastInterstitialAdTime; // 🎯 SİBER ZAMANLAYICI: İki reklam arası asgari bekleme süresi (Cooldown)
  bool _adWarningToastShown = false; // 🎯 SİBER KALKAN: Bildirimin mükerrer çıkmasını önler (1-2 defa uyarır)
  bool _analyticsLogged = false; // 📊 SİBER ANALİTİK: Kayıt atıldı mı?
  bool _isTransitioning = false; // 🛡️ SİBER KALKAN: Şarkı geçiş kilidi (Arka planda çökme ve mükerrer tetiklemeyi önler)
  Duration _maxObservedPosition = Duration.zero; // ⏱️ SİBER KRONOMETRE: Şarkının gerçekten dinlendiğini kanıtlayan zirve süre

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

    _initAudioSession();

    // 🎯 SİBER DİNLEYİCİ: Şarkı pozisyonu (saniye saniye) değiştikçe Slider'a sinyal gönder
    _player.positionStream.listen((position) {
      if (position > _maxObservedPosition) {
        _maxObservedPosition = position;
      }
      
      // 🎯 SİBER REKLAM BİLDİRİMİ: Şarkı bitimine 30 saniye kala eğer reklam çıkacaksa tek seferlik uyar
      if (mediaItem.value != null && _player.duration != null) {
        final remaining = _player.duration!.inSeconds - position.inSeconds;
        if (remaining == 30 && !_adWarningToastShown) {
          final isOffline = !mediaItem.value!.id.startsWith('yt:');
          final prevDuration = mediaItem.value!.duration?.inMinutes ?? 0;
          final forceAd = prevDuration >= 10;
          
          if (_willNextSongTriggerAd(isOffline: isOffline, forceAd: forceAd)) {
            _adWarningToastShown = true;
            _safeShowToast('🎧 Sonraki şarkıya geçerken ufak bir reklam molamız olacak...', toastLength: Toast.LENGTH_SHORT, backgroundColor: Colors.deepPurple, textColor: Colors.white);
          }
        }
      }

      // 📊 SİBER ANALİTİK: Şarkı 30 saniye (veya kısa şarkılarda yarısı) çalarsa dinleme olarak kaydet!
      final totalSec = mediaItem.value?.duration?.inSeconds ?? 0;
      final threshold = (totalSec > 0 && totalSec < 60) ? (totalSec ~/ 2) : 30;
      if (position.inSeconds >= threshold && !_analyticsLogged && mediaItem.value != null) {
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

      // 🎵 FFTea Yerel Görselleştirici Entegrasyonu
      if (playing) {
        AudioAnalysisService.instance.startBackgroundAnalysis(
          songTitle: mediaItem.value?.title ?? '',
          artist: mediaItem.value?.artist ?? '',
        );
      } else {
        AudioAnalysisService.instance.stopBackgroundAnalysis();
      }

      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          const MediaControl(
            androidIcon: 'drawable/ic_close',
            label: 'Kapat',
            action: MediaAction.stop,
          ),
        ],
        androidCompactActionIndices: const [0, 1, 2],
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

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(0.2);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              _player.pause();
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(1.0);
              break;
            case AudioInterruptionType.pause:
              if (mediaItem.value != null && !_player.playing) {
                _player.play();
              }
              break;
            case AudioInterruptionType.unknown:
              break;
          }
        }
      });

      session.becomingNoisyEventStream.listen((_) {
        _player.pause();
      });
      print('🎧 Siber Kalkan: AudioSession kesinti yöneticisi (Instagram & Çağrı Kalkanı) aktif!');
    } catch (e) {
      print('⚠️ AudioSession başlatma hatası: $e');
    }
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
        // 🛡️ SİBER KALKAN: Eğer seçili bir şarkı varsa (özellikle Keşfet çevrimiçi akışları)
        // geçici ağ kopması veya tamponlamada ASLA AudioProcessingState.idle bildirme!
        // Çünkü Android AudioService idle durumunu görünce otonom stop() çağırıp servisi öldürür!
        if (mediaItem.value != null) {
          return AudioProcessingState.buffering;
        }
        return AudioProcessingState.idle;
      case ProcessingState.loading:
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      default:
        return mediaItem.value != null ? AudioProcessingState.buffering : AudioProcessingState.idle;
    }
  }

  Future<void> _handlePlaybackComplete() async {
    // 🛡️ SİBER KALKAN: Geçiş kilidini sıfırla ki şarkı bitince sıradakine geçiş ASLA tıkanmasın
    _isTransitioning = false;

    // 🛡️ SİBER KALKAN: Şarkı gerçekten çaldı mı kontrolü (0-byte / sahte tamamlanma tespiti)
    final dur = _player.duration;
    final bool hasActuallyPlayed = _maxObservedPosition.inSeconds >= 2 ||
        (dur != null &&
            dur.inSeconds >= 2 &&
            _player.position.inSeconds >= dur.inSeconds - 3);

    if (!hasActuallyPlayed) {
      print(
          '⚠️ SİBER KALKAN: Erken/sahte tamamlanma sinyali (çalınma: ${_maxObservedPosition.inSeconds}sn), sıradakine atlanıyor.');
      _consecutiveErrors++;
      if (_consecutiveErrors > 4) {
        print('🛑 SİBER KALKAN: Üst üste sahte tamamlanma! Oynatma durduruldu.');
        _consecutiveErrors = 0;
        _safeShowToast('Şarkı açılamadı veya dosya bozuk.',
            backgroundColor: Colors.redAccent, textColor: Colors.white);
        return;
      }
      await skipToNext();
      return;
    }

    _consecutiveErrors = 0; // Başarılı çalma, hata sayacını sıfırla
    final repeatMode = playbackState.value.repeatMode;

    // 🔂 1. TEKLİ DÖNGÜ (Repeat One)
    if (repeatMode == AudioServiceRepeatMode.one) {
      print('🔂 SİBER TEKLİ DÖNGÜ: Şarkı baştan başlatılıyor...');
      _maxObservedPosition = Duration.zero;
      try {
        await _player.setLoopMode(LoopMode.one);
        await _player.seek(Duration.zero);
        await _player.play();
      } catch (e) {
        print('⚠️ Tekli döngü seek hatası, parça yenileniyor: $e');
        await skipToQueueItem(_currentIndex);
      }
      return;
    }

    // ⏭️ 2. SIRADAKİ ŞARKIYA GEÇİŞ (Normal veya Liste Tekrarı)
    print('⏭️ SİBER DJ: Şarkı tamamlandı, sıradakine pürüzsüz geçiliyor...');
    _maxObservedPosition = Duration.zero;
    await skipToNext();
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
    try {
      await _player.stop();
    } catch (_) {}
    mediaItem.add(null); // 🛑 SİBER KALKAN: BehaviorSubject sıfırla → player bar kapandıktan sonra yeniden açılmaz
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      controls: [],
      processingState: AudioProcessingState.idle,
    ));
    try {
      await super.stop();
    } catch (_) {}
  }

  @override
  Future<void> onTaskRemoved() async {
    // 🛡️ SİBER KALKAN: Uygulama arka plandan/son uygulamalardan kapatılsa bile
    // müzik ASLA durdurulmaz, bildirim paneli ve ses motoru arka planda çalmaya devam eder!
    // super.onTaskRemoved() çağrılmaz çünkü servisi öldürür.
    return;
  }

  @override
  Future<void> onNotificationDeleted() async {
    // 🛡️ SİBER KALKAN: Bildirim temizlense dahi müzik çalıyorsa durdurma!
    if (_player.playing) {
      print('🛡️ Siber Kalkan: onNotificationDeleted yakalandı ama müzik çalıyor. Durdurma engellendi!');
      return;
    }
    await stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> setSpeed(double speed) async {
    AudioEngine.manualTempo = speed;
    try {
      await _player.setSpeed(speed);
      playbackState.add(playbackState.value.copyWith(speed: speed));
      print('🚀 SİBER DJ: Oynatma hızı $speed x olarak ayarlandı!');
    } catch (e) {
      print('⚠️ Hız ayar hatası: $e');
    }
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
    _consecutiveErrors = 0; // 🎯 SİBER HAMLE: Yeni liste geldiğinde hataları sıfırla
    _playlist = newQueue;
    queue.add(newQueue);

    // 🚀 SİBER ÖN ISITMA: Kuyruktaki ilk 2 çevrimiçi parçayı hemen arka planda çöz
    for (int i = 0; i < min(2, newQueue.length); i++) {
      final item = newQueue[i];
      if (item.id.startsWith('yt:')) {
        OzsesBridge().preWarm(item.id.substring(3));
      }
    }
  }


  // 🎯 SİBER ÖNCÜ KONTROL: Sıradaki şarkıya geçişte reklam çıkacak mı?
  bool _willNextSongTriggerAd({required bool isOffline, bool forceAd = false}) {
    if (SubscriptionManager().isAdFree) return false;
    if (forceAd) return true;

    final now = DateTime.now();
    final minMinutes = isOffline ? 25 : 15;
    final minSongs = isOffline ? 5 : 4;

    bool timePassed = false;
    if (_lastInterstitialAdTime == null) {
      timePassed = true;
    } else {
      final elapsed = now.difference(_lastInterstitialAdTime!);
      timePassed = elapsed.inMinutes >= minMinutes;
    }

    // Gelecek geçişte _songsPlayedSinceLastAd + 1 olacak
    final willReachLimit = (_songsPlayedSinceLastAd + 1) >= minSongs;
    return willReachLimit && timePassed;
  }

  // 🎯 SİBER REKLAM MOTORU: 4-5 Şarkı Sayacı + Gerçek Zamanlayıcı (Cooldown) + Switch-Case Mod Kontrolü
  void _checkAndTriggerAd({required bool isOffline, bool forceAd = false}) {
    // 1. Reklamsız yetki kontrolü (Abonelik veya Geçici Reklamsız Pass)
    if (SubscriptionManager().isAdFree) return;

    _songsPlayedSinceLastAd++;
    final now = DateTime.now();

    // 2. Modlara göre asgari bekleme süresi ve şarkı limiti (Switch-Case)
    int minMinutesBetweenAds = 15; // Varsayılan: 15 dakika geçmeden asla reklam yok
    int minSongsLimit = 4;        // En az 4 şarkı dinlenmeli

    final currentMode = isOffline ? 'offline' : 'online';
    switch (currentMode) {
      case 'offline':
        minMinutesBetweenAds = 25; // Çevrimdışı modda daha seyrek (25 dk)
        minSongsLimit = 5;         // Çevrimdışında en az 5 şarkı
        break;
      case 'online':
      default:
        minMinutesBetweenAds = 15; // Çevrimiçi modda 15 dk
        minSongsLimit = 4;         // 4 şarkı
        break;
    }

    // 3. Zamanlayıcı ve sayaç sorgusu
    bool timePassed = false;
    if (_lastInterstitialAdTime == null) {
      timePassed = true; // İlk açılışta süre şartı aranmaz
    } else {
      final elapsed = now.difference(_lastInterstitialAdTime!);
      timePassed = elapsed.inMinutes >= minMinutesBetweenAds;
    }

    bool songLimitReached = _songsPlayedSinceLastAd >= minSongsLimit;

    if (forceAd || (songLimitReached && timePassed)) {
      print('🚀 Siber Reklam Tetiklendi: Şarkı Sayısı=$_songsPlayedSinceLastAd, Zaman Uygun=$timePassed');
      AdManager.showInterstitialAdIfReady(isOfflineMode: isOffline, forceShow: forceAd);
      _songsPlayedSinceLastAd = 0;
      _lastInterstitialAdTime = now;
      _adWarningToastShown = false; // Reklam tetiklendi, uyarı bayrağını sıfırla
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.length) return;

    _isTransitioning = true;
    _adWarningToastShown = false; // Yeni şarkıya geçildi, uyarı bayrağını sıfırla
    try {
      // 🎯 SİBER REKLAM KONTROLÜ: Sadece uygulama ÖN PLANDAYSA reklam tetikle (Arka planda Android Activity çökmesini önler)
      if (mediaItem.value != null &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        final prevDuration = mediaItem.value!.duration?.inMinutes ?? 0;
        final isOffline = !mediaItem.value!.id.startsWith('yt:');
        final forceAd = prevDuration >= 10; // 10 dk üzeri uzun videolarda zorla
        _checkAndTriggerAd(isOffline: isOffline, forceAd: forceAd);
      }

      _currentIndex = index;
      _maxObservedPosition = Duration.zero; // ⏱️ Yeni şarkıya geçildi, pozisyon hafızasını sıfırla
      final currentRepeat = playbackState.value.repeatMode;
      try {
        if (currentRepeat == AudioServiceRepeatMode.one) {
          await _player.setLoopMode(LoopMode.one);
        } else {
          await _player.setLoopMode(LoopMode.off);
        }
      } catch (_) {}
      _analyticsLogged = false; // 📊 Yeni şarkı, kayıt bayrağını sıfırla
      final item = _playlist[index];
      mediaItem.add(item);

      // 🧠 SÖZ RADARI: Şarkı başladığı an arka planda sözleri sessizce RAM'e hazırla
      LyricsService.preloadLyrics(
        item.id,
        item.title,
        item.artist ?? '',
        duration: item.duration,
        videoId: item.extras?['videoId']?.toString(),
      );

      // 🛡️ SİBER KALKAN: Kuyruk sırasını sisteme mühürle ki araya şarkı ekleyebilelim
      playbackState.add(playbackState.value.copyWith(
        queueIndex: _currentIndex,
        playing: true,
        processingState: AudioProcessingState.loading,
      ));

      // 🛡️ SİBER KALKAN: Geçersiz yollar Android motorunu çökertmesin!
      if (item.id == 'bilinmeyen_yol' ||
          item.id.isEmpty ||
          item.id.startsWith('downloading:')) {
        print('⚠️ Geçersiz şarkı ID / yolu: ${item.id}, sıradakine geçiliyor...');
        Future.delayed(const Duration(milliseconds: 300), skipToNext);
        return;
      }

      // 🛡️ Yerel dosya kontrolü (HATA FIRLATMAZ, SIRADAKİNE ATLAR)
      if (!kIsWeb && !item.id.startsWith('http') && !item.id.startsWith('yt:')) {
        final file = File(item.id);
        if (!file.existsSync() || file.lengthSync() < 1024) {
          print('⚠️ Yerel dosya bulunamadı veya bozuk (0 byte): ${item.id}');
          _safeShowToast('Dosya açılamadı, sıradakine geçiliyor...', backgroundColor: Colors.orange, textColor: Colors.white);
          Future.delayed(const Duration(milliseconds: 400), skipToNext);
          return;
        }
      }

      String resolvedUrl = item.id;

      // 🎯 SİBER OPERASYON: DİNAMİK AKIŞ ÇÖZÜCÜ
      if (item.id.startsWith('yt:')) {
        print("▶️ Siber Mühür Yakalandı: 'yt:' ID'li akış çözülüyor...");
        final videoId = item.id.substring(3);
        final bridge = OzsesBridge();

        playbackState.add(playbackState.value.copyWith(
          playing: true,
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
            _consecutiveErrors = 0;
            return;
          }

          // 🎯 Doğrudan URL geldi, kullan
          print('🎯 Doğrudan Akış URL: $resolvedUrl');
        } else {
          throw Exception("Siber Kalkan: Akış çözülemedi (${res['mesaj']})");
        }
      }

      // ⚡ FAST-START: Oynatıcıya hemen çalma yetkisi (playWhenReady) veriyoruz.
      // İlk ses paketi indiğinde ExoPlayer ekstra beklemeden derhal çalmaya başlar!
      final Future<void>? playFuture = (!kIsWeb) ? _player.play() : null;

      if (resolvedUrl.startsWith('http://') ||
          resolvedUrl.startsWith('https://')) {
        await _player
            .setAudioSource(AudioSource.uri(
          Uri.parse(resolvedUrl),
        ))
            .timeout(
          const Duration(seconds: 45),
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

      if (playFuture != null) {
        await playFuture;
      } else {
        await _player.play();
      }
      _consecutiveErrors = 0; // 🎯 SİBER KALKAN: Başarılı çalma, hata sayacını anında sıfırla

      // 🚀 SİBER RADAR: Sıradaki 2 şarkıyı arka planda önceden çöz (Kuyruk geçişi 0 ms olsun)
      _preloadNextQueueTracks(index);
    } catch (e) {
      // 🚨 SİBER KALKAN HATA YAKALAMA (ÇİFT ATLAMA FİXİ)
      if (_currentIndex != index) {
        print('⏭️ Kullanıcı zaten başka şarkıya geçti, iptal işleminden kaynaklı hata yoksayılıyor.');
        return;
      }
      
      print('HATA: Platform oynatma hatası -> $e');
      _consecutiveErrors++;

      try { await _player.pause(); } catch (_) {} // 🛡️ SİBER KALKAN: Servisi kapatma, duraklat

      if (_consecutiveErrors > 4) {
        print('🛑 Siber Kalkan: Üst üste hatalar alındı! Oynatma duraklatıldı.');
        _consecutiveErrors = 0;
        _safeShowToast(
          'Bağlantı koptu veya şarkı açılamadı.',
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
        return;
      }

      // 🛡️ SİBER KALKAN: Akış hatasında otonom geçiş (ardışık hata sayısına göre artan gecikme)
      final delayMs = 1200 * _consecutiveErrors;
      print('⚠️ Hata yakalandı, ${delayMs}ms sonra sıradaki şarkıya geçiliyor... (ardışık hata: $_consecutiveErrors)');
      Future.delayed(Duration(milliseconds: delayMs), skipToNext);
    } finally {
      Future.delayed(const Duration(milliseconds: 500), () {
        _isTransitioning = false;
      });
    }
  }

  // 🚀 SİBER RADAR: Sıradaki şarkıları arka planda önceden çöz (0 ms geçiş için)
  void _preloadNextQueueTracks(int currentIndex) {
    for (int offset = 1; offset <= 2; offset++) {
      final nextIdx = currentIndex + offset;
      if (nextIdx < _playlist.length) {
        final nextItem = _playlist[nextIdx];
        if (nextItem.id.startsWith('yt:')) {
          final nextVId = nextItem.id.substring(3);
          OzsesBridge().preWarm(nextVId);
        }
      }
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
            final lastItem = _playlist.last;
            final lastVideoId = lastItem.id.substring(3);
            final lastTitle = lastItem.title;
            final lastArtist = lastItem.artist;
            
            _safeShowToast(
              '📻 Otonom Akış Devrede: Benzer şarkılar ekleniyor...',
              backgroundColor: Colors.deepPurple,
              textColor: Colors.white,
            );
            
            try {
              final bridge = OzsesBridge();
              final radioSongs = await bridge.getRadio(
                lastVideoId,
                title: lastTitle,
                artist: lastArtist,
              );
              
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
                  final prevLen = _playlist.length;
                  _playlist.addAll(newItems);
                  queue.add(_playlist);
                  _currentIndex = prevLen; // Yeni eklenen ilk parçaya pürüzsüz geç
                  
                  _safeShowToast(
                    '✅ Otonom Akış: ${newItems.length} yeni parça eklendi!',
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                  );
                } else {
                  _currentIndex = 0; // Şarkı bulunamazsa başa dön, ASLA durma!
                }
              } else {
                _currentIndex = 0; // Boşsa başa dön
              }
            } catch (e) {
              print('⚠️ Radyo uzatma hatası, başa sarılıyor: $e');
              _currentIndex = 0;
            }
          } else {
            // 🛡️ İndirilen şarkılar ve yerel arşiv: Liste bittiğinde başa dön (otonom siber döngü, ASLA stop() çağrılmaz!)
            _currentIndex = 0;
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
    try {
      if (repeatMode == AudioServiceRepeatMode.one) {
        await _player.setLoopMode(LoopMode.one);
        print('🔂 SİBER MOTOR: Donanım LoopMode.one (Tekli Döngü) aktif!');
      } else {
        await _player.setLoopMode(LoopMode.off);
        print('🔁 SİBER MOTOR: Donanım LoopMode.off (Liste/Kapalı) aktif!');
      }
    } catch (e) {
      print('⚠️ Siber LoopMode ayar hatası: $e');
    }
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
