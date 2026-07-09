import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/ozses_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- SİBER DEĞİŞKENLER ---
  double _energyScale = 1.0;
  Color _neonColor = Colors.cyanAccent;
  bool _isAutonomous = true;
  double _threshold = 50.0;
  String _activeSubMode = 'OFF'; // FOCUS, SLEEP, OFF
  
  final OzsesService _ozsesService = OzsesService();
  Timer? _liveTimer;

  @override
  void initState() {
    super.initState();
    // CANLI NABIZ: 100ms'de bir Victus'u sorgula
    _liveTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _syncLiveData();
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel(); // Ekran kapanınca siber hattı kes
    super.dispose();
  }

  // Victus'tan gelen anlık verileri ekrana yansıtır
  void _syncLiveData() async {
    final data = await _ozsesService.fetchLiveData();
    if (data != null && data['status'] == 'ACTIVE' && mounted) {
      setState(() {
        _energyScale = data['neon_scale'] ?? 1.0;
        _threshold = (data['dominant_hz'] as num).toDouble();
        // Python'dan gelen RGB renklerini mühürle
        _neonColor = Color.fromARGB(
          255, 
          data['color_r'] ?? 0, 
          data['color_g'] ?? 255, 
          data['color_b'] ?? 255
        );
      });
    } else if (mounted) {
      setState(() => _energyScale = 1.0);
    }
  }

  // Ayarları ve Gizli Modları Victus'a bildirir
  void _saveSettings() async {
    await _ozsesService.updateBrainSettings(
      _isAutonomous, 
      _threshold, 
      subMode: _activeSubMode
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('VİCTUS KONTROL MERKEZİ', 
          style: TextStyle(letterSpacing: 1.5, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          // 1. NEON GLASS ANALİZ KARTI (Canlı Titreşim)
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              transform: Matrix4.identity()..scale(_energyScale),
              child: _buildNeonGlassCard(
                neonColor: _neonColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 40),
                  child: Column(
                    children: [
                      const Icon(Icons.waves, color: Colors.white, size: 45),
                      const SizedBox(height: 10),
                      Text(
                        '${_threshold.toInt()} Hz',
                        style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const Text('CANLI ANALİZ', 
                        style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
          _buildSectionTitle('SİSTEM KONFİGÜRASYONU'),
          
          // 2. OTONOM MOD ŞALTERİ
          SwitchListTile(
            title: const Text('Otonom Analiz Modu', style: TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: const Text('Ritim ve saate göre otomatik renk yönetimi', 
              style: TextStyle(color: Colors.white30, fontSize: 11)),
            activeThumbColor: Colors.cyanAccent,
            value: _isAutonomous,
            onChanged: (val) {
              setState(() => _isAutonomous = val);
              _saveSettings();
            },
          ),

          // 3. HASSASİYET SLIDER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Manuel Eşik: ${_threshold.toInt()}', 
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Slider(
                  value: _threshold,
                  min: 0, max: 100,
                  activeColor: _neonColor,
                  onChanged: _isAutonomous ? null : (val) {
                    setState(() => _threshold = val);
                  },
                  onChangeEnd: (val) => _saveSettings(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          _buildSectionTitle('SİBER FREKANS KATMANI (GİZLİ)'),
          const SizedBox(height: 15),

          // 4. ODAK VE UYKU BUTONLARI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSubliminalButton('ODAK', 'FOCUS', Icons.bolt, Colors.blueAccent),
              _buildSubliminalButton('UYKU', 'SLEEP', Icons.nightlight_round, Colors.deepPurpleAccent),
            ],
          ),
        ],
      ),
    );
  }

  // --- YARDIMCI WIDGETLAR ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  Widget _buildSubliminalButton(String label, String mode, IconData icon, Color color) {
    bool isActive = _activeSubMode == mode;
    return InkWell(
      onTap: () {
        setState(() => _activeSubMode = isActive ? 'OFF' : mode);
        _saveSettings();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isActive ? color : Colors.white10, width: 1.5),
          boxShadow: isActive ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10)] : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? color : Colors.white30, size: 20),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.white30, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildNeonGlassCard({required Widget child, required Color neonColor}) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: neonColor.withValues(alpha: 0.2), blurRadius: 40, spreadRadius: 5)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: neonColor.withValues(alpha: 0.4), width: 1.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}