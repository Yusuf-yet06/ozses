// ignore_for_file: prefer_final_fields, unused_field

import 'dart:async'; // 1. BU MUTLAKA ÜSTTE OLMALI
import 'package:flutter/material.dart';
import 'dart:ui' as ui; // 🎯 SİBER CAM EFEKTİ İÇİN
import 'package:permission_handler/permission_handler.dart';
import 'audio_analysis_service.dart'; // Python servisi yerine yeni siber beynimizi ekledik
import 'audio_engine.dart'; // 🎯 SİBER EFEKT SLIDER'LARI İÇİN

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- SİBER BEYİN VE DURUM DEĞİŞKENLERİ ---
  final AudioAnalysisService _audioService = AudioAnalysisService();
  StreamSubscription<AudioAnalysisData>? _analysisSubscription;

  double _neonScale = 1.0;
  double _dominantHz = 0.0;
  bool _isAutonomous = true;
  String _statusMessage = 'Ses Motoru Aktif';

  @override
  void initState() {
    super.initState();
    _initializeAudioStream();
  }

  Future<void> _initializeAudioStream() async {
    // Önce mikrofon izni istiyoruz, bu siber kuraldır!
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      setState(() {
        _statusMessage = 'Mikrofon izni reddedildi!';
      });
      return;
    }

    // İzin verildiyse, siber beynin analiz akışını dinlemeye başlıyoruz
    _analysisSubscription = _audioService.getAnalysisStream().listen(
      (data) {
        if (mounted) {
          setState(() {
            _neonScale = data.neonScale;
            _dominantHz = data.dominantHz;
            _statusMessage = '${_dominantHz.toInt()} Hz';
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _statusMessage = 'Siber Hata!';
            _neonScale = 1.0; // Hata durumunda animasyonu durdur
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _analysisSubscription?.cancel(); // Ekran kapanınca siber beyni susturuyoruz
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... Burada senin daha önce yazdığımız Scaffold ve Neon kart kodların var
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Ses Ayarları',
            style: TextStyle(
                color: Colors.deepPurpleAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [Colors.deepPurple.withValues(alpha: 0.2), Colors.black],
          ),
        ),
        child: SafeArea(
          // 🛡️ SİBER KALKAN: Ekranın en üstündeki telefon çentiğini (Notch) ezip pixel taşmasını engeller!
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                // 🛡️ SİBER RADAR: Kokpit Merkezi
                ExcludeSemantics(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 75),
                    transform: Matrix4.identity()..scale(_neonScale),
                    child: _buildNeonGlassCard(
                      neonColor: _isAutonomous
                          ? Colors.deepPurpleAccent
                          : Colors.purpleAccent,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.graphic_eq,
                              color: _isAutonomous
                                  ? Colors.deepPurpleAccent
                                  : Colors.purpleAccent,
                              size: 50),
                          const SizedBox(height: 10),
                          Text(_statusMessage,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // 🎯 SİBER KONTROL PANELLERİ (Glassmorphism Tasarım)
                _buildSiberSlider(
                    'BAS GÜCÜ',
                    Icons.speaker,
                    AudioEngine.manualBass,
                    1.0,
                    3.0,
                    Colors.deepPurpleAccent,
                    (val) => setState(() => AudioEngine.manualBass = val)),
                _buildSiberSlider(
                    'VOKAL GÜCÜ',
                    Icons.mic_external_on,
                    AudioEngine.manualVocal,
                    1.0,
                    3.0,
                    Colors.deepPurpleAccent,
                    (val) => setState(() => AudioEngine.manualVocal = val)),
                _buildSiberSlider(
                    'TİZ GÜCÜ',
                    Icons.waves,
                    AudioEngine.manualTreble,
                    1.0,
                    3.0,
                    Colors.deepPurpleAccent,
                    (val) => setState(() => AudioEngine.manualTreble = val)),
                _buildSiberSlider(
                    'ZAMAN BÜKÜCÜ',
                    Icons.speed,
                    AudioEngine.manualTempo,
                    0.5,
                    2.0,
                    Colors.deepPurpleAccent,
                    (val) => setState(() => AudioEngine.manualTempo = val)),
                _buildSiberSlider(
                    '3D DERİNLİK (DEPTH)',
                    Icons.threed_rotation,
                    AudioEngine.manual3DDepth,
                    0.0,
                    1.0,
                    Colors.deepPurpleAccent,
                    (val) => setState(() => AudioEngine.manual3DDepth = val)),
                _buildSiberSlider(
                    'SİBER YANKI (ECHO)',
                    Icons.surround_sound,
                    AudioEngine.manualEcho,
                    0.0,
                    1.0,
                    Colors.deepPurpleAccent,
                    (val) => setState(() => AudioEngine.manualEcho = val)),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeonGlassCard({
    required Widget child,
    required Color neonColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        border: Border.all(color: neonColor.withValues(alpha: 0.6), width: 2),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: neonColor.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2),
          BoxShadow(
              color: neonColor.withValues(alpha: 0.1),
              blurRadius: 50,
              spreadRadius: 10),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }

  // 🎯 SİBER GÖRSEL: Yeni Nesil Cam (Glass) Kaydırma Paneli
  Widget _buildSiberSlider(
      String title,
      IconData icon,
      double value,
      double min,
      double max,
      Color accentColor,
      ValueChanged<double> onChanged) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: accentColor.withValues(alpha: 0.05),
                blurRadius: 15,
                spreadRadius: 2)
          ]),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(children: [
                Row(
                  children: [
                    Icon(icon, color: accentColor, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      // 🎯 SİBER KALKAN: Yatay taşmaları engeller
                      child: Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: accentColor.withValues(alpha: 0.5))),
                      child: Text('${value.toStringAsFixed(1)}x',
                          style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                Slider(
                  value: value,
                  min: min,
                  max: max,
                  activeColor: accentColor,
                  inactiveColor: Colors.white10,
                  onChanged: onChanged,
                )
              ]))),
    );
  }
}
