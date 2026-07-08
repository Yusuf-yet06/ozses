import 'dart:ui';
import 'package:flutter/material.dart';

class NeonGlassCard extends StatelessWidget {
  final Widget child;
  final Color neonColor;

  NeonGlassCard({required this.child, this.neonColor = Colors.cyanAccent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: neonColor.withOpacity(0.2), blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Buzlu cam efekti
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1), // Yarı şeffaf katman
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}