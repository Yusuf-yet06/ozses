import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import '../main.dart'; // 🎯 audioHandler ana motoru
import '../services/audio_engine.dart'; // 🎯 Tempo ve hız kontrolü

class AudioSettingsScreen extends StatefulWidget {
  const AudioSettingsScreen({super.key});

  @override
  State<AudioSettingsScreen> createState() => _AudioSettingsScreenState();
}

class _AudioSettingsScreenState extends State<AudioSettingsScreen> {
  bool _isEqEnabled = false;
  bool _isBassBoostEnabled = false;
  double _bassBoostLevel = 0.0;
  double _tempo = 1.0;
  final bool _isAndroid = (!kIsWeb && Platform.isAndroid); // 🛡️ SİBER KALKAN

  @override
  void initState() {
    super.initState();
    _tempo = AudioEngine.manualTempo; // Motorun anlık hızını al
    if (_isAndroid) {
      _initEngineStates();
    }
  }

  void _initEngineStates() async {
    try {
      // Ekolayzır ve Bass önceden açıksa anahtarları doğru konuma getir
      _isEqEnabled = audioHandler.siberEqualizer.enabled;
      _isBassBoostEnabled = audioHandler.siberBassBooster.enabled;
      if (mounted) setState(() {});
    } catch (e) {
      print('Siber EQ Init Hatası: $e');
    }
  }

  Future<void> _toggleEq(bool val) async {
    if (!_isAndroid) return;
    setState(() => _isEqEnabled = val);
    await audioHandler.siberEqualizer.setEnabled(val);
  }

  Future<void> _toggleBass(bool val) async {
    if (!_isAndroid) return;
    setState(() => _isBassBoostEnabled = val);
    await audioHandler.siberBassBooster.setEnabled(val);
  }

  // 🎯 Frekans Değerlerini Mantıklı Formata Çevir (Örn: 15000 Hz -> 15.0k)
  String _formatFreq(double hz) {
    if (hz >= 1000) return '${(hz / 1000).toStringAsFixed(1)}k';
    return '${hz.toInt()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('SİBER DJ PANELİ',
            style: TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 2)),
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [Colors.cyanAccent.withValues(alpha: 0.1), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // --- 1. ZAMAN & PITCH BÜKÜCÜ (TEMPO) ---
                _buildGlassCard(
                  title: 'ZAMAN BÜKÜCÜ (TEMPO & PITCH)',
                  icon: Icons.speed,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Slowed',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                          Text('x${_tempo.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                          const Text('Nightcore',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                      Slider(
                        value: _tempo,
                        min: 0.5,
                        max: 2.0,
                        activeColor: Colors.cyanAccent,
                        inactiveColor: Colors.white10,
                        onChanged: (val) {
                          setState(() => _tempo = val);
                          AudioEngine.manualTempo =
                              val; // Otonom motor bunu saniyeler içinde sese yedirecek
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 🛡️ SİBER KALKAN: Eğer Windows'taysan DSP çökmesin diye donanım UI'ını gizler
                if (!_isAndroid)
                  const Expanded(
                    child: Center(
                      child: Text(
                          'Siber Donanım DSP (Ekolayzır ve Sub-Bass)\nyalnızca telefonlarda (Android) aktiftir.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38)),
                    ),
                  )
                else ...[
                  // --- 2. SUB-BASS MOTORU ---
                  _buildGlassCard(
                    title: 'SUB-BASS MOTORU',
                    icon: Icons.speaker,
                    trailing: Switch(
                      value: _isBassBoostEnabled,
                      activeThumbColor: Colors.orangeAccent,
                      onChanged: _toggleBass,
                    ),
                    child: Column(
                      children: [
                        Slider(
                          value: _bassBoostLevel,
                          min: 0.0,
                          max: 1.0,
                          activeColor: Colors.orangeAccent,
                          inactiveColor: Colors.white10,
                          onChanged: _isBassBoostEnabled
                              ? (val) {
                                  setState(() => _bassBoostLevel = val);
                                  // 🎯 SİBER ŞAMAR: Bass gücünü milibel (mB) cinsinden basıyoruz (1.0 = +10dB)
                                  audioHandler.siberBassBooster
                                      .setTargetGain(val * 1000.0);
                                }
                              : null,
                        ),
                        const Text('Derinlik Seviyesi',
                            style:
                                TextStyle(color: Colors.white38, fontSize: 10)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- 3. FREKANS MİMARİSİ (EQ) ---
                  _buildGlassCard(
                    title: 'FREKANS MİMARİSİ (EKOLAYZIR)',
                    icon: Icons.tune,
                    isExpanded: true,
                    trailing: Switch(
                      value: _isEqEnabled,
                      activeThumbColor: Colors.purpleAccent,
                      onChanged: _toggleEq,
                    ),
                    child: StreamBuilder<AndroidEqualizerParameters?>(
                      stream: audioHandler.siberEqualizer.parametersStream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data == null) {
                          return const Center(
                            child: Text(
                                'Siber DSP Beklemede...\n(Müzik çalarken uyanır)',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white30)),
                          );
                        }

                        final params = snapshot.data!;
                        return Opacity(
                          opacity: _isEqEnabled ? 1.0 : 0.4,
                          child: IgnorePointer(
                            ignoring: !_isEqEnabled,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: params.bands.map((band) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "${band.gain > 0 ? '+' : ''}${band.gain.toStringAsFixed(1)}",
                                      style: const TextStyle(
                                          color: Colors.purpleAccent,
                                          fontSize: 10),
                                    ),
                                    const SizedBox(height: 5),
                                    Expanded(
                                      child: RotatedBox(
                                        quarterTurns: 3, // Dikey Slider efekti
                                        child: Slider(
                                          value: band.gain,
                                          min: params.minDecibels,
                                          max: params.maxDecibels,
                                          activeColor: Colors.purpleAccent,
                                          inactiveColor: Colors.white10,
                                          onChanged: (val) {
                                            band.setGain(
                                                val); // 🎯 GERÇEK ZAMANLI SES BÜKÜCÜ
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _formatFreq(band.centerFrequency),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🎯 SİBER CAM KART TASARIMI
  Widget _buildGlassCard(
      {required String title,
      required IconData icon,
      Widget? trailing,
      required Widget child,
      bool isExpanded = false}) {
    Widget card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.05),
                blurRadius: 15,
                spreadRadius: 2)
          ]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Icon(icon, color: Colors.cyanAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1))
                ]),
                if (trailing != null) trailing
              ]),
              const Divider(color: Colors.white10, height: 20),
              isExpanded ? Expanded(child: child) : child
            ])),
      ),
    );
    return isExpanded ? Expanded(child: card) : card;
  }
}

extension on AndroidEqualizer {
  Stream<AndroidEqualizerParameters?>? get parametersStream => null;
}
