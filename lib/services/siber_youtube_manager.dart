import 'package:flutter/foundation.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'dart:async';

class SiberYoutubeManager {
  static final SiberYoutubeManager instance = SiberYoutubeManager._internal();
  SiberYoutubeManager._internal();

  late YoutubePlayerController controller;
  bool isInitialized = false;

  final StreamController<Duration> positionStreamController = StreamController<Duration>.broadcast();
  final StreamController<Duration> durationStreamController = StreamController<Duration>.broadcast();
  final StreamController<bool> playingStreamController = StreamController<bool>.broadcast();
  final StreamController<void> playbackEndedStreamController = StreamController<void>.broadcast();
  
  Timer? _positionTimer;
  String? currentVideoId;

  void init() {
    if (isInitialized) return;
    
    controller = YoutubePlayerController.fromVideoId(
      videoId: 'TlHpbizbhqc', // Dummy ID to boot the IFrame properly
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: false,
        mute: true, // SİBER HACK: Android'in autoplay engelini aşmak için ilk başta MUTE olarak başlatıyoruz!
        showFullscreenButton: false,
        loop: false,
      ),
    );

    controller.listen((event) {
      print('▶️ YOUTUBE STATE: ${event.playerState}');
      if (event.playerState == PlayerState.playing) {
        // SİBER HACK: Video oynamaya başlar başlamaz sesi aç! (Android kısıtlamasını aşmak için)
        controller.unMute();
        controller.setVolume(100);
        
        playingStreamController.add(true);
        _startPositionTimer();
        controller.duration.then((d) {
           final sec = d.truncate(); // usually returns double in seconds
           durationStreamController.add(Duration(seconds: sec));
        });
      } else if (event.playerState == PlayerState.paused || event.playerState == PlayerState.ended) {
        playingStreamController.add(false);
        _stopPositionTimer();
        
        if (event.playerState == PlayerState.ended) {
          playbackEndedStreamController.add(null);
        }
      }
    });

    isInitialized = true;
    print('🚀 SİBER YOUTUBE MANAGER: Görünmez IFrame Motoru Kuruldu!');
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      try {
        final posSeconds = await controller.currentTime; // double representing seconds
        positionStreamController.add(Duration(milliseconds: (posSeconds * 1000).toInt()));
      } catch (_) {}
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
  }

  Future<void> playVideo(String videoId) async {
    if (!isInitialized) init();
    currentVideoId = videoId;
    await controller.loadVideoById(videoId: videoId);
    
    // SİBER HACK: Android WebView autoplay engeline karşı zorla tetikle
    Future.delayed(const Duration(milliseconds: 500), () {
      controller.playVideo();
    });
    
    print('▶️ SİBER YOUTUBE MANAGER: $videoId oynatılıyor...');
  }

  Future<void> pause() async {
    await controller.pauseVideo();
  }

  Future<void> resume() async {
    await controller.playVideo();
  }

  Future<void> seekTo(Duration position) async {
    await controller.seekTo(seconds: position.inSeconds.toDouble(), allowSeekAhead: true);
  }
}
