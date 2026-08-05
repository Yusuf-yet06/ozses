import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../services/timer_service.dart';

class SleepTimerSheet extends StatefulWidget {
  final Color themeColor;

  const SleepTimerSheet({super.key, required this.themeColor});

  @override
  _SleepTimerSheetState createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends State<SleepTimerSheet> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: widget.themeColor.withValues(alpha: 0.5), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(color: widget.themeColor, borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 20),
            Text('KAPANIŞ PROTOKOLÜ', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, shadows: [Shadow(color: widget.themeColor, blurRadius: 10)])),
            const SizedBox(height: 10),
            const Text('Müzik otonom olarak ne zaman sonlandırılsın?', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            ValueListenableBuilder<int>(
              valueListenable: globalSleepTimer,
              builder: (context, remainingSeconds, child) {
                if (remainingSeconds > 0) {
                  return Column(
                    children: [
                      Text(
                        "Aktif Sayaç: ${remainingSeconds ~/ 60}:${(remainingSeconds % 60).toString().padLeft(2, '0')}",
                        style: TextStyle(color: widget.themeColor, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withValues(alpha: 0.3), side: const BorderSide(color: Colors.redAccent)),
                        onPressed: () {
                          startSleepTimer(0);
                        },
                        child: const Text('İPTAL ET', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  );
                } else {
                  return Wrap(
                    spacing: 15,
                    runSpacing: 15,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildTimerButton(15),
                      _buildTimerButton(30),
                      _buildTimerButton(45),
                      _buildTimerButton(60),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildTimerButton(int minutes) {
    return InkWell(
      onTap: () {
        startSleepTimer(minutes);
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: widget.themeColor.withValues(alpha: 0.1),
          border: Border.all(color: widget.themeColor.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text('$minutes', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const Text('DAKİKA', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
