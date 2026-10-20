import 'package:flutter/material.dart';

class SiberEkolayzerSheet extends StatelessWidget {
  final dynamic themeColor;
  const SiberEkolayzerSheet({Key? key, this.themeColor}) : super(key: key);

  static void show(BuildContext context, {dynamic themeColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ekolayzer özellikleri kaldırıldı.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // EQ Kaldırıldı
  }
}
