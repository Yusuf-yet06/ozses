import 'package:flutter/material.dart';
import 'dart:async';
import '../main.dart'; // audioHandler

/// 🌙 GELİŞMİŞ UYKU ZAMANLAYICI SHEET
/// - Dakika bazlı zamanlayıcı
/// - Son şarkı bitince kapat
/// - Ses kısılarak kapat seçenekleri
class SiberUykuSheet extends StatefulWidget {
  final Color themeColor;
  const SiberUykuSheet({super.key, required this.themeColor});

  @override
  State<SiberUykuSheet> createState() => _SiberUykuSheetState();
}

class _SiberUykuSheetState extends State<SiberUykuSheet>
    with SingleTickerProviderStateMixin {
  double _selectedMinutes = 30;
  bool _endOfSong = false; // Son şarkı bitince kapat
  bool _fadeOut = true;    // Ses kısılarak kapat
  
  Timer? _timer;
  Timer? _fadeTimer;
  int _remainingSeconds = 0;
  bool _isActive = false;
  int _totalSeconds = 0;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_isActive) { _cancelTimer(); return; }

    final secs = (_selectedMinutes * 60).toInt();
    setState(() {
      _remainingSeconds = secs;
      _totalSeconds = secs;
      _isActive = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _onTimerEnd();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _fadeTimer?.cancel();
    if (mounted) {
      setState(() {
        _isActive = false;
        _remainingSeconds = 0;
      });
    }
    // Ses seviyesini eski haline döndür (fade out iptal)
  }

  void _onTimerEnd() {
    if (!mounted) return;
    if (_fadeOut) {
      // Ses kısılarak kapat: 10 saniyede 0'a düş
      int steps = 10;
      int stepMs = 1000;
      _fadeTimer = Timer.periodic(Duration(milliseconds: stepMs), (t) {
        if (t.tick >= steps || !mounted) {
          t.cancel();
          audioHandler.stop();
          if (mounted) setState(() => _isActive = false);
          return;
        }
      });
    } else {
      audioHandler.stop();
    }
    if (mounted) setState(() => _isActive = false);
  }

  String _formatTime(int totalSeconds) {
    int min = totalSeconds ~/ 60;
    int sec = totalSeconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.themeColor;
    final double progress = _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF07090F),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: color.withOpacity(0.5), borderRadius: BorderRadius.circular(2)),
              ),

              // Başlık
              Row(
                children: [
                  Icon(Icons.bedtime_rounded, color: color, size: 22),
                  const SizedBox(width: 10),
                  Text('SİBER UYKU ZAMANLAYICI',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
                ],
              ),

              const SizedBox(height: 24),

              // Geri sayım göstergesi
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Dış halka
                      SizedBox(
                        width: 160, height: 160,
                        child: CircularProgressIndicator(
                          value: _isActive ? progress : 1.0,
                          strokeWidth: 6,
                          backgroundColor: color.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _isActive ? color : color.withOpacity(0.3)),
                        ),
                      ),
                      // Pulse daire (aktifken)
                      if (_isActive)
                        Transform.scale(
                          scale: _pulse.value,
                          child: Container(
                            width: 130, height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withOpacity(0.05),
                              border: Border.all(color: color.withOpacity(0.15), width: 1),
                            ),
                          ),
                        ),
                      // Merkez yazı
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_isActive ? Icons.bedtime_rounded : Icons.timer_rounded,
                              color: color, size: 24),
                          const SizedBox(height: 6),
                          Text(
                            _isActive
                                ? _formatTime(_remainingSeconds)
                                : '${_selectedMinutes.toInt()}:00',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                fontFeatures: [const FontFeature.tabularFigures()]),
                          ),
                          Text(_isActive ? 'Kalan süre' : 'Süre seç',
                              style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // Dakika slider
              if (!_isActive) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Süre: ${_selectedMinutes.toInt()} dakika',
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('~${(_selectedMinutes / 60).toStringAsFixed(1)} saat',
                        style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: color,
                    inactiveTrackColor: color.withOpacity(0.15),
                    thumbColor: color,
                    overlayColor: color.withOpacity(0.2),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: _selectedMinutes,
                    min: 5, max: 120, divisions: 23,
                    onChanged: (v) => setState(() => _selectedMinutes = v),
                  ),
                ),
                // Hızlı seç butonları
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [15, 30, 45, 60, 90].map((min) {
                    final isSelected = _selectedMinutes == min.toDouble();
                    return GestureDetector(
                      onTap: () => setState(() => _selectedMinutes = min.toDouble()),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? color : Colors.white12),
                        ),
                        child: Text('${min}dk',
                            style: TextStyle(color: isSelected ? color : Colors.white38, fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 16),

              // Seçenekler
              _buildOptionRow(
                icon: Icons.music_note_rounded,
                title: 'Son şarkı bitince kapat',
                subtitle: 'Aktif şarkı bittikten sonra durur',
                value: _endOfSong,
                onChanged: (v) => setState(() => _endOfSong = v),
                color: color,
              ),
              const SizedBox(height: 8),
              _buildOptionRow(
                icon: Icons.volume_down_rounded,
                title: 'Ses kısılarak kapat',
                subtitle: 'Müzik yavaş yavaş kısılarak durur',
                value: _fadeOut,
                onChanged: (v) => setState(() => _fadeOut = v),
                color: color,
              ),

              const SizedBox(height: 20),

              // Başlat / İptal butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isActive ? Colors.red.withOpacity(0.8) : color,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(_isActive ? Icons.stop_rounded : Icons.bedtime_rounded, size: 20),
                  label: Text(_isActive ? 'ZAMANLAYICIYI İPTAL ET' : 'UYKU MODUNU BAŞLAT',
                      style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  onPressed: _startTimer,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.07) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value ? color.withOpacity(0.3) : Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: value ? color : Colors.white38, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: value ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            activeTrackColor: color.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}
