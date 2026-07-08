import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // 🎯 Web kontrolü için
import 'dart:io'; // 🎯 Platform kontrolü için
import 'package:webview_windows/webview_windows.dart'; // 🎯 SİBER KALKAN: Windows İçi Video Motoru

class SiberVideoPlayer extends StatefulWidget {
  final String videoId;
  final String title;
  final Color themeColor;

  const SiberVideoPlayer({
    super.key,
    required this.videoId,
    required this.title,
    required this.themeColor,
  });

  @override
  State<SiberVideoPlayer> createState() => _SiberVideoPlayerState();
}

class _SiberVideoPlayerState extends State<SiberVideoPlayer> {
  late YoutubePlayerController _ytController;
  final _windowsWebviewController = WebviewController();
  bool _isWindowsReady = false;

  @override
  void initState() {
    super.initState();
    // 🛡️ SİBER KALKAN: Windows'ta Webview çökmelerini önlemek için motoru sadece desteklenen platformlarda kur!
    if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      _ytController = YoutubePlayerController.fromVideoId(
        videoId: widget.videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          mute: false,
        ),
      );
    } else if (Platform.isWindows) {
      // 🎯 SİBER HAMLE: Windows PC için uygulama içi WebView2 motorunu ateşle!
      _initWindowsWebview();
    }
  }

  Future<void> _initWindowsWebview() async {
    try {
      await _windowsWebviewController.initialize();
      // YouTube Embed URL'si oluşturarak klibi içeri hapsediyoruz!
      await _windowsWebviewController.loadUrl(
          'https://www.youtube.com/embed/${widget.videoId}?autoplay=1');
      if (mounted) {
        setState(() => _isWindowsReady = true);
      }
    } catch (e) {
      print("Siber Windows Video Hatası: $e");
    }
  }

  @override
  void dispose() {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      _ytController.close();
    } else if (Platform.isWindows) {
      _windowsWebviewController.dispose();
    }
    // Videodan çıkınca telefonu tekrar dik pozisyona zorlar
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("SİBER KLİP: ${widget.title}",
            style: TextStyle(color: widget.themeColor, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Container(
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(
                color: widget.themeColor.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5)
          ]),
          child: (!kIsWeb && Platform.isWindows)
              ? (_isWindowsReady
                  ? Webview(_windowsWebviewController)
                  : Center(
                      child:
                          CircularProgressIndicator(color: widget.themeColor)))
              : YoutubePlayer(
                  controller: _ytController,
                  aspectRatio: 16 / 9,
                ),
        ),
      ),
    );
  }
}
