import 'package:flutter/material.dart';

class PlaybackModeControls extends StatelessWidget {
  final bool isShuffle;
  final int repeatMode; // 0: Kapalı, 1: Liste, 2: Tek Şarkı
  final Color themeColor;
  final VoidCallback onShuffleToggle;
  final VoidCallback onRepeatToggle;

  const PlaybackModeControls({
    super.key,
    required this.isShuffle,
    required this.repeatMode,
    required this.themeColor,
    required this.onShuffleToggle,
    required this.onRepeatToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // --- SHUFFLE (KARIŞTIR) BUTONU ---
        IconButton(
          icon: Icon(
            isShuffle ? Icons.shuffle : Icons.shuffle_outlined,
            color: isShuffle ? themeColor : Colors.white30,
            size: 20,
          ),
          onPressed: onShuffleToggle,
          tooltip: 'Karıştır',
        ),

        // --- REPEAT (TEKRAR) BUTONU ---
        IconButton(
          icon: Icon(
            _getRepeatIcon(),
            color: repeatMode > 0 ? themeColor : Colors.white30,
            size: 20,
          ),
          onPressed: onRepeatToggle,
          tooltip: 'Tekrar Modu',
        ),
      ],
    );
  }

  // Tekrar moduna göre ikon belirleme mantığı
  IconData _getRepeatIcon() {
    switch (repeatMode) {
      case 1:
        return Icons.repeat; // Liste tekrarı
      case 2:
        return Icons.repeat_one; // Tek şarkı tekrarı
      default:
        return Icons.repeat; // Kapalı (Silik ikon)
    }
  }
}
