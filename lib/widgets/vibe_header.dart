import 'package:flutter/material.dart';

class VibeHeader extends StatelessWidget {
  final String currentSongName;
  final Color themeColor;
  final Duration position;
  final Duration duration;
  final bool isShuffle;
  final int repeatMode;
  final Function(double) onSeek;
  final VoidCallback onShuffleToggle;
  final VoidCallback onRepeatToggle;

  const VibeHeader({
    super.key,
    required this.currentSongName,
    required this.themeColor,
    required this.position,
    required this.duration,
    required this.isShuffle,
    required this.repeatMode,
    required this.onSeek,
    required this.onShuffleToggle,
    required this.onRepeatToggle,
    required void Function() onFocusToggle,
    required bool isFocusMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: themeColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: themeColor.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: -5)
        ],
      ),
      child: Column(
        children: [
          Text(currentSongName,
              style: TextStyle(color: themeColor, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Slider(
            activeColor: themeColor,
            inactiveColor: themeColor.withValues(alpha: 0.1),
            value: position.inSeconds.toDouble().clamp(
                0.0,
                duration.inSeconds.toDouble() > 0
                    ? duration.inSeconds.toDouble()
                    : 1.0),
            max: duration.inSeconds.toDouble() > 0
                ? duration.inSeconds.toDouble()
                : 1.0,
            onChanged: onSeek,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                  icon: Icon(isShuffle ? Icons.shuffle : Icons.shuffle_outlined,
                      color: isShuffle ? themeColor : Colors.white54),
                  onPressed: onShuffleToggle),
              IconButton(
                icon: Icon(
                    repeatMode == 2
                        ? Icons.repeat_one
                        : (repeatMode == 1
                            ? Icons.repeat
                            : Icons.repeat_outlined),
                    color: repeatMode > 0 ? themeColor : Colors.white54),
                onPressed: onRepeatToggle,
              ),
            ],
          )
        ],
      ),
    );
  }
}
