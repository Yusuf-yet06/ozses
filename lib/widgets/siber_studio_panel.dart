import 'package:flutter/material.dart';

class SiberStudioPanel extends StatelessWidget {
  final dynamic themeColor;
  const SiberStudioPanel({Key? key, this.themeColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Siber Stüdyo Kaldırıldı',
        style: TextStyle(color: Colors.white54, fontSize: 16),
      ),
    );
  }
}
