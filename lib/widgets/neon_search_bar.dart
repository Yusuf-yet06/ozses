import 'package:flutter/material.dart';

class NeonSearchBar extends StatelessWidget {
  final Color themeColor;
  final Function(String) onChanged;

  const NeonSearchBar(
      {super.key, required this.themeColor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'İmparatorlukta Ara...',
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: Icon(Icons.search, color: themeColor),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
