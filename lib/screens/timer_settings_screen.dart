import 'package:flutter/material.dart';
import 'dart:async';
import '../main.dart'; // 🎯 SİBER HAMLE: Ana motor bağlantısı (audioHandler)

class TimerSettingsScreen extends StatefulWidget {
  const TimerSettingsScreen({super.key});

  @override
  State<TimerSettingsScreen> createState() => _TimerSettingsScreenState();
}

class _TimerSettingsScreenState extends State<TimerSettingsScreen> {
  double _selectedMinutes = 30; // Başlangıç değeri
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isTimerActive = false;
  int _totalSeconds = 0;

  void _startTimer() {
    setState(() {
      _remainingSeconds = (_selectedMinutes * 60).toInt();
      _totalSeconds = _remainingSeconds;
      _isTimerActive = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        _stopTimer();
        // 🎯 SİBER HAMLE: Süre bitince motoru otonom durdur
        audioHandler.stop();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _isTimerActive = false;
        _remainingSeconds = 0;
      });
    }
  }

  // Saniye bazlı veriyi Dakika:Saniye formatına çevirir
  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    // Çemberin ne kadarının dolu olacağını hesaplar (0.0 - 1.0 arası)
    double progress = _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('SİSTEM ZAMANLAYICI', style: TextStyle(fontSize: 14)),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // --- SİBER GERİ SAYIM ÇEMBERİ ---
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Arka plandaki ince sabit halka
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 2,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  // Öndeki eriyen kalın halka
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: _isTimerActive ? progress : 1.0,
                      strokeWidth: 8, // Kalın dönerek azalır
                      color: Colors.cyanAccent,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  // İçerideki dijital saat
                  Column(
                    children: [
                      Text(
                        _isTimerActive
                            ? _formatTime(_remainingSeconds)
                            : '${_selectedMinutes.toInt()}:00',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier', // Siber hava katması için
                        ),
                      ),
                      Text(
                        _isTimerActive ? 'SİSTEM UYKUDA' : 'BEKLEMEDE',
                        style: TextStyle(
                            color: _isTimerActive
                                ? Colors.cyanAccent
                                : Colors.white24,
                            fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),

            // Sadece zamanlayıcı aktif değilken slider'ı göster
            if (!_isTimerActive)
              Slider(
                value: _selectedMinutes,
                min: 1,
                max: 120,
                activeColor: Colors.cyanAccent,
                onChanged: (v) => setState(() => _selectedMinutes = v),
              )
            else
              const Text('OPERASYON DEVAM EDİYOR',
                  style: TextStyle(color: Colors.cyanAccent, letterSpacing: 2)),

            const SizedBox(height: 40),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTimerActive
                          ? Colors.redAccent.withValues(alpha: 0.2)
                          : Colors.cyanAccent.withValues(alpha: 0.2),
                      side: BorderSide(
                          color: _isTimerActive
                              ? Colors.redAccent
                              : Colors.cyanAccent),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: _isTimerActive ? _stopTimer : _startTimer,
                    icon: Icon(_isTimerActive ? Icons.timer_off : Icons.timer,
                        color: Colors.white),
                    label: Text(
                        _isTimerActive
                            ? 'ZAMANLAYICIYI İPTAL ET'
                            : 'GERİ SAYIMI BAŞLAT',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                // Otonom Buton
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.purpleAccent),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.auto_awesome,
                        color: Colors.purpleAccent),
                    onPressed: () {}, // Gelecek operasyon
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel(); // Sayfadan çıkınca sızıntıyı önler
    super.dispose();
  }
}
