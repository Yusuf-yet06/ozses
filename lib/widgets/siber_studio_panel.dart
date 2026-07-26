import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/audio_engine.dart';
import '../services/subscription_manager.dart';
import '../screens/siber_payment_screen.dart';

class SiberStudioPanel extends StatefulWidget {
  final Color themeColor;

  const SiberStudioPanel({super.key, required this.themeColor});

  @override
  State<SiberStudioPanel> createState() => _SiberStudioPanelState();
}

class _SiberStudioPanelState extends State<SiberStudioPanel> {
  final subManager = SubscriptionManager();
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _isPremium = subManager.canUseAdvancedCyberStudio();
  }

  void _enforcePremiumLimit() {
    Navigator.pop(context); // Paneli kapat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SiberPaymentScreen(themeColor: widget.themeColor),
      ),
    );
  }

  Widget _buildSliderRow({
    required String title,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    bool isPremium = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: isPremium && !_isPremium ? Colors.grey : widget.themeColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isPremium && !_isPremium ? Colors.grey : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isPremium) ...[
              const Spacer(),
              Icon(Icons.lock, color: _isPremium ? Colors.transparent : Colors.amber, size: 16),
            ]
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: widget.themeColor,
            inactiveTrackColor: Colors.white24,
            thumbColor: widget.themeColor,
            overlayColor: widget.themeColor.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: (val) {
              if (isPremium && !_isPremium) {
                _enforcePremiumLimit();
                return;
              }
              onChanged(val);
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isPremium = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, color: isPremium && !_isPremium ? Colors.grey : widget.themeColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isPremium && !_isPremium ? Colors.grey : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (isPremium && !_isPremium)
            const Icon(Icons.lock, color: Colors.amber, size: 18)
          else
            Switch(
              value: value,
              activeColor: widget.themeColor,
              onChanged: (val) {
                if (isPremium && !_isPremium) {
                  _enforcePremiumLimit();
                  return;
                }
                onChanged(val);
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.70,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: widget.themeColor.withValues(alpha: 0.5), width: 2)),
        boxShadow: [
          BoxShadow(color: widget.themeColor.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 5)
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.graphic_eq_rounded, color: widget.themeColor, size: 28),
                  const SizedBox(width: 10),
                  Text('SİBER SES STÜDYOSU',
                      style: TextStyle(
                          color: widget.themeColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5)),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    // --- TEMEL ÖZELLİKLER (FREE) ---
                    const Text('TEMEL KONTROLLER', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    _buildSliderRow(
                      title: 'Bass Yoğunluğu (Deep Bass)',
                      icon: Icons.speaker,
                      value: AudioEngine.manualBass,
                      min: 0.5,
                      max: 3.0,
                      onChanged: (val) => setState(() => AudioEngine.manualBass = val),
                    ),
                    _buildSliderRow(
                      title: 'Treble (Tiz Keskinliği)',
                      icon: Icons.multitrack_audio,
                      value: AudioEngine.manualTreble,
                      min: 0.5,
                      max: 2.0,
                      onChanged: (val) => setState(() => AudioEngine.manualTreble = val),
                    ),

                    const Divider(color: Colors.white12, height: 40),

                    // --- GELİŞMİŞ ÖZELLİKLER (PREMIUM) ---
                    Row(
                      children: [
                        const Text('SİBER EFEKTLER (LORD)', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        if (!_isPremium)
                          const Icon(Icons.lock, color: Colors.amber, size: 14),
                      ],
                    ),
                    const SizedBox(height: 15),

                    _buildSwitchRow(
                      title: 'Vokal Ayrıştırıcı (Karaoke)',
                      icon: Icons.mic_off,
                      isPremium: true,
                      value: AudioEngine.manualVocal < 0.5,
                      onChanged: (val) => setState(() {
                        AudioEngine.manualVocal = val ? 0.05 : 1.0;
                      }),
                    ),

                    _buildSliderRow(
                      title: '3D Siber Akustik (Derinlik)',
                      icon: Icons.threed_rotation,
                      isPremium: true,
                      value: AudioEngine.manual3DDepth,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (val) => setState(() => AudioEngine.manual3DDepth = val),
                    ),

                    _buildSliderRow(
                      title: 'Siber Tempo (Hız)',
                      icon: Icons.speed,
                      isPremium: true,
                      value: AudioEngine.manualTempo,
                      min: 0.5,
                      max: 2.0,
                      onChanged: (val) => setState(() => AudioEngine.manualTempo = val),
                    ),

                    const Divider(color: Colors.white12, height: 40),

                    // --- BIO-HACKING (PREMIUM) ---
                    Row(
                      children: [
                        const Text('BİYOLOJİK FREKANSLAR', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        if (!_isPremium)
                          const Icon(Icons.lock, color: Colors.amber, size: 14),
                      ],
                    ),
                    const SizedBox(height: 15),

                    GestureDetector(
                      onTap: () {
                        if (!_isPremium) _enforcePremiumLimit();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: widget.themeColor.withValues(alpha: 0.3)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: AudioEngine.currentBioFrequency,
                            dropdownColor: const Color(0xFF1E1E2C),
                            isExpanded: true,
                            icon: Icon(Icons.keyboard_arrow_down, color: widget.themeColor),
                            items: const [
                              DropdownMenuItem(value: "Kapalı", child: Text("Kapalı", style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: "Odak (Alfa 10Hz)", child: Text("Odaklanma - Alfa Dalgası", style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: "Uyku (Delta 3Hz)", child: Text("Derin Uyku - Delta Dalgası", style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: "Rahatlama (Teta 6Hz)", child: Text("Meditasyon - Teta Dalgası", style: TextStyle(color: Colors.white))),
                            ],
                            onChanged: (val) {
                              if (!_isPremium) {
                                _enforcePremiumLimit();
                                return;
                              }
                              if (val != null) {
                                setState(() => AudioEngine.currentBioFrequency = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
