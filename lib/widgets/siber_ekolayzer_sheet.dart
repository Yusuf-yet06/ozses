import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../services/audio_engine.dart';
import '../main.dart'; // To access audioHandler

class SiberEkolayzerSheet extends StatefulWidget {
  final Color themeColor;

  const SiberEkolayzerSheet({Key? key, required this.themeColor})
      : super(key: key);

  @override
  _SiberEkolayzerSheetState createState() => _SiberEkolayzerSheetState();
}

class _SiberEkolayzerSheetState extends State<SiberEkolayzerSheet> {
  void _updateDSP() {
    setState(() {});
    audioHandler.applySiberDSP();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border:
              Border.all(color: widget.themeColor.withOpacity(0.5), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                  color: widget.themeColor,
                  borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 20),
            Text("SİBER EKOLAYZER",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(color: widget.themeColor, blurRadius: 10)
                    ])),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AudioEngine.getAllModes().map((mode) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.themeColor.withOpacity(0.2),
                        side: BorderSide(color: widget.themeColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        AudioEngine.applyPreset(mode);
                        _updateDSP();
                      },
                      child: Text(mode,
                          style: const TextStyle(color: Colors.white)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            _buildSlider("Bass Motoru", AudioEngine.manualBass, 0.5, 3.0, (val) {
              AudioEngine.manualBass = val;
              _updateDSP();
            }),
            _buildSlider("Tiz (Treble)", AudioEngine.manualTreble, 0.5, 3.0,
                (val) {
              AudioEngine.manualTreble = val;
              _updateDSP();
            }),
            _buildSlider("Vokal Berraklığı", AudioEngine.manualVocal, 0.5, 3.0,
                (val) {
              AudioEngine.manualVocal = val;
              _updateDSP();
            }),
            _buildSlider("Otonom Tempo", AudioEngine.manualTempo, 0.5, 2.0,
                (val) {
              AudioEngine.manualTempo = val;
              _updateDSP();
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ${value.toStringAsFixed(2)}x",
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: widget.themeColor,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            trackHeight: 2,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
