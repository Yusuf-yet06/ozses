import 'package:flutter/material.dart';

class MiniEqVisualizer extends StatelessWidget {
  final bool isPlaying;
  final dynamic themeColor;
  const MiniEqVisualizer({Key? key, this.isPlaying = false, this.themeColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // EQ Kaldırıldı
  }
}
