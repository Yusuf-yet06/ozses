import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ModeIndicator extends StatelessWidget {
  final bool isGlobalLibrary;
  final String playlistTitle;
  final Color themeColor;
  final VoidCallback onClose;

  const ModeIndicator({
    super.key,
    required this.isGlobalLibrary,
    required this.playlistTitle,
    required this.themeColor,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: themeColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isGlobalLibrary ? "ANA ARŞİV" : "LİSTE: $playlistTitle",
            style: TextStyle(
                color: themeColor, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          if (!isGlobalLibrary)
            GestureDetector(
              onTap: onClose,
              child: Icon(Icons.close_rounded, color: themeColor, size: 16),
            ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }
}
