import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../services/audio_engine.dart';

class ListeningModeScreen extends StatefulWidget {
  const ListeningModeScreen({super.key});

  @override
  State<ListeningModeScreen> createState() => _ListeningModeScreenState();
}

class _ListeningModeScreenState extends State<ListeningModeScreen> {
  // Tema renklerini modlara göre ayarlayacağız
  Color _currentThemeColor = Colors.cyanAccent;

  @override
  void initState() {
    super.initState();
    _updateThemeColor();
  }

  void _updateThemeColor() {
    switch (AudioEngine.currentBioFrequency) {
      case 'Kapalı':
        _currentThemeColor = Colors.grey;
        break;
      case 'Rahatlama (Relax)':
        _currentThemeColor = Colors.tealAccent;
        break;
      case 'Yenilenme (Recovery)':
        _currentThemeColor = Colors.greenAccent;
        break;
      case 'Derin Odak (Focus)':
        _currentThemeColor = Colors.orangeAccent;
        break;
      case 'Derin Uyku (Sleep)':
        _currentThemeColor = Colors.deepPurpleAccent;
        break;
      default:
        _currentThemeColor = Colors.cyanAccent;
    }
  }

  void _setMode(String mode) {
    setState(() {
      AudioEngine.currentBioFrequency = mode;
      _updateThemeColor();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'DİNLEME MODU',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
            letterSpacing: 3,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Arka plan ambiyans efekti
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 1.5,
                colors: [
                  _currentThemeColor.withValues(alpha: 0.15),
                  Colors.black,
                ],
              ),
            ),
          ),
          
          // İçerik
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Zihninin Frekansını Seç',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Müziğin arka planında çalışan görünmez frekanslarla ruh halini yönlendir.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Mod Seçenekleri
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildModeCard(
                          title: 'Kapalı',
                          subtitle: 'Sadece saf müzik deneyimi',
                          modeName: 'Kapalı',
                          icon: Icons.music_note,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        _buildModeCard(
                          title: 'Rahatlama',
                          subtitle: 'Stresi azaltır, evrensel uyum sağlar',
                          modeName: 'Rahatlama (Relax)',
                          icon: Icons.spa,
                          color: Colors.tealAccent,
                        ),
                        const SizedBox(height: 16),
                        _buildModeCard(
                          title: 'Derin Odak',
                          subtitle: 'Dikkati artırır, zihni keskinleştirir',
                          modeName: 'Derin Odak (Focus)',
                          icon: Icons.center_focus_strong,
                          color: Colors.orangeAccent,
                        ),
                        const SizedBox(height: 16),
                        _buildModeCard(
                          title: 'Yenilenme',
                          subtitle: 'Hücreleri onarır, enerjiyi tazeler',
                          modeName: 'Yenilenme (Recovery)',
                          icon: Icons.healing,
                          color: Colors.greenAccent,
                        ),
                        const SizedBox(height: 16),
                        _buildModeCard(
                          title: 'Derin Uyku',
                          subtitle: 'Kaliteli ve kesintisiz dinlenme',
                          modeName: 'Derin Uyku (Sleep)',
                          icon: Icons.nights_stay,
                          color: Colors.deepPurpleAccent,
                        ),
                      ],
                    ),
                  ),
                  
                  // Görünmez Frekans Yoğunluğu (Sadece mod açıksa görünür)
                  AnimatedOpacity(
                    opacity: AudioEngine.currentBioFrequency != 'Kapalı' ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          'Etki Yoğunluğu (Bilinçaltı Seviyesi)',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.waves, color: _currentThemeColor.withValues(alpha: 0.5), size: 18),
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: _currentThemeColor,
                                  inactiveTrackColor: Colors.white12,
                                  thumbColor: _currentThemeColor,
                                  overlayColor: _currentThemeColor.withValues(alpha: 0.2),
                                  trackHeight: 4,
                                ),
                                child: Slider(
                                  value: AudioEngine.bioVolume,
                                  min: 0.01,
                                  max: 0.20,
                                  onChanged: AudioEngine.currentBioFrequency != 'Kapalı' 
                                    ? (val) {
                                        setState(() {
                                          AudioEngine.bioVolume = val;
                                        });
                                      } 
                                    : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required String modeName,
    required IconData icon,
    required Color color,
  }) {
    bool isSelected = AudioEngine.currentBioFrequency == modeName;
    
    return GestureDetector(
      onTap: () => _setMode(modeName),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.5) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: -5,
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? color : Colors.white54,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color,
                      blurRadius: 8,
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
