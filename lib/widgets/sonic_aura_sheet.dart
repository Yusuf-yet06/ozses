import 'package:flutter/material.dart';
import '../services/history_service.dart';
import 'dart:math' as math;

class SonicAuraSheet extends StatefulWidget {
  final Color themeColor;

  const SonicAuraSheet({super.key, required this.themeColor});

  @override
  State<SonicAuraSheet> createState() => _SonicAuraSheetState();
}

class _SonicAuraSheetState extends State<SonicAuraSheet> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Map<String, dynamic>? _auraData;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _loadAura();
  }

  Future<void> _loadAura() async {
    final aura = await HistoryService.getSonicAura();
    if (mounted) {
      setState(() => _auraData = aura);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_auraData == null) {
      return Container(color: Colors.black.withValues(alpha: 0.9), child: const Center(child: CircularProgressIndicator()));
    }

    final auraName = _auraData!['aura'] as String;
    final auraColor = Color(_auraData!['color'] as int);
    final auraDesc = _auraData!['desc'] as String;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: auraColor.withValues(alpha: 0.8), width: 3)),
        boxShadow: [
          BoxShadow(color: auraColor.withValues(alpha: 0.2), blurRadius: 40, spreadRadius: 10),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('SİBER SES İZİN', style: TextStyle(color: Colors.white54, fontSize: 16, letterSpacing: 3, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          
          // 3D Dönen Enerji Küresi İllüzyonu
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: _controller.value * 2 * math.pi,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            auraColor.withValues(alpha: 0.1),
                            auraColor.withValues(alpha: 0.8),
                            auraColor,
                            auraColor.withValues(alpha: 0.1),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(color: auraColor.withValues(alpha: 0.6), blurRadius: 60, spreadRadius: 20)
                        ],
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: -_controller.value * 2 * math.pi,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                    ),
                  ),
                  Icon(Icons.fingerprint, size: 80, color: Colors.white.withValues(alpha: 0.9)),
                ],
              );
            },
          ),
          
          const SizedBox(height: 50),
          Text(
            auraName.toUpperCase(),
            style: TextStyle(color: auraColor, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              auraDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: auraColor.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: auraColor)),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('TAMAM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
          )
        ],
      ),
    );
  }
}
