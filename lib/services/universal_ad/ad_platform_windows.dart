import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'ad_platform_interface.dart';
import 'package:webview_windows/webview_windows.dart';

class AdPlatformWindows implements AdPlatform {
  DateTime? _lastAdTime;

  @override
  void initialize() {
    // Windows Webview başlatma (AdSense barındırmak için)
    print("SİBER WINDOWS REKLAM MOTORU BAŞLATILDI");
  }


  @override
  bool willShowAd({bool isOfflineMode = false}) => false;

  @override
  void showInterstitialAdIfReady({bool isOfflineMode = false, bool forceShow = false}) {
    _lastAdTime ??= DateTime.now();
    final now = DateTime.now();
    final difference = now.difference(_lastAdTime!);
    
    final requiredMinutes = isOfflineMode ? 40 : 25;

    if (difference.inMinutes >= requiredMinutes) {
      Fluttertoast.showToast(
          msg: "Siber Keşiflere kısa bir ara... Reklam yükleniyor 🚀",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 3,
          backgroundColor: Colors.deepPurpleAccent,
          textColor: Colors.white,
          fontSize: 14.0
      );

      Future.delayed(const Duration(seconds: 3), () {
        // İleride buraya WebviewWindows ile çalışan bir Dialog Popup açılacak.
        print("SİBER WINDOWS: Geçiş reklamı tetiklendi (WebView AdSense bekleniyor)");
        _lastAdTime = DateTime.now();
      });
    }
  }

  @override
  Widget buildBannerAdWidget() {
    // Şimdilik Windows AdSense konteyneri. Onaylandığında WebviewWindows gömülecek.
    return Container(
      width: 320,
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Text(
          'SİBER WINDOWS REKLAM ALANI\n(WebView AdSense Bekleniyor)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ),
    );
  }

  @override
  void disposeBannerAd() {
    // Webview temizliği
  }
}

AdPlatform getAdPlatform() => AdPlatformWindows();
