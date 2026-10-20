import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/siber_theme_service.dart';
import '../services/subscription_manager.dart';

class SiberThemeSheet extends StatelessWidget {
  SiberThemeSheet({super.key});

    final List<Map<String, dynamic>> _themes = [
    {'name': 'Derin Mor', 'color': Colors.deepPurple, 'desc': 'Gizemli ve elit.'},
    {'name': 'Ateş Kırmızısı', 'color': Colors.redAccent, 'desc': 'Dinamik ve güçlü.'},
    {'name': 'Zümrüt Yeşili', 'color': Colors.greenAccent, 'desc': 'Canlı ve taze.'},
    {'name': 'Buzul Mavi', 'color': Colors.cyanAccent, 'desc': 'Soğuk ve odaklanmış.'},
    {'name': 'Güneş Patlaması', 'color': Colors.orangeAccent, 'desc': 'Enerjik ve canlı.'},
    {'name': 'Neon Pembe', 'color': Colors.pinkAccent, 'desc': 'Synthwave estetiği.'},
    {'name': 'Karanlık Turkuaz', 'color': Colors.tealAccent, 'desc': 'Derinlik ve huzur.'},
    {'name': 'Altın Vadi', 'color': Colors.amberAccent, 'desc': 'Zengin ve premium.'},
    {'name': 'Zehirli Sarmaşık', 'color': Colors.limeAccent, 'desc': 'Göz alıcı ve tehlikeli.'},
    {'name': 'Gece Mavisi', 'color': Colors.indigoAccent, 'desc': 'Ciddi ve karanlık.'},
    {'name': 'Saf Platin', 'color': Colors.white70, 'desc': 'Minimalist ve saf.'},
    {'name': 'Lav Akıntısı', 'color': Colors.deepOrangeAccent, 'desc': 'Yakıcı ve sıcak.'},
    {'name': 'Saf Zümrüt', 'color': const Color(0xFF00C853), 'desc': 'Asil ve göz alıcı zümrüt.'},
    {'name': 'Elektrik Menekşe', 'color': const Color(0xFF7C4DFF), 'desc': 'Modern menekşe zarafeti.'},
    {'name': 'Kutup Işıkları', 'color': const Color(0xFF1DE9B6), 'desc': 'Aurora parıltısı.'},
    {'name': 'Alevli Mercan', 'color': const Color(0xFFFF5252), 'desc': 'Çarpıcı neon mercan.'},
    {'name': 'Gece Yarısı', 'color': const Color(0xFF303F9F), 'desc': 'Kozmik derin uzay.'},
    {'name': 'Neon Sarı', 'color': const Color(0xFFFFEA00), 'desc': 'Yüksek kontrast ve enerji.'},
    {'name': 'Lavanta Sis', 'color': const Color(0xFFB388FF), 'desc': 'Rüya gibi fütüristik mor.'},
    {'name': 'Kızıl Gül', 'color': const Color(0xFFE91E63), 'desc': 'Canlı ve tutkulu fuşya.'},
    {'name': 'Koyu Safir', 'color': const Color(0xFF0288D1), 'desc': 'Derin okyanus mavisi.'},
    {'name': 'Krom Titanyum', 'color': const Color(0xFF90A4AE), 'desc': 'Metalik zırh estetiği.'},
    {'name': 'Vampir Kırmızı', 'color': const Color(0xFF880E4F), 'desc': 'Karanlık ve elit bordo.'},
    {'name': 'Karanlık Karbon', 'color': const Color(0xFF607D8B), 'desc': 'Ağırbaşlı endüstriyel grafit.'},
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: SiberThemeService.instance.currentThemeColor,
      builder: (context, currentColor, _) {
        final screenHeight = MediaQuery.of(context).size.height;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: screenHeight * 0.85,
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border(top: BorderSide(color: currentColor.withValues(alpha: 0.5), width: 1.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.palette_rounded, color: currentColor, size: 26),
                      const SizedBox(width: 10),
                      const Text(
                        'TEMA MERKEZİ',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Uygulamanın ana atmosferini belirle. Şarkı çalarken renkler müzik analizine göre dinamik olarak değişmeye devam eder.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: _themes.length,
                      itemBuilder: (context, index) {
                        final theme = _themes[index];
                        final isSelected = currentColor == (theme['color'] as Color);
                        
                        return InkWell(
                          onTap: () {
                            SiberThemeService.instance.updateBaseColor(theme['color']);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('${theme['name']} teması uygulandı!'),
                              backgroundColor: theme['color'],
                            ));
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? (theme['color'] as Color).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isSelected ? theme['color'] : Colors.white12,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: theme['color'],
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      if (isSelected) BoxShadow(color: theme['color'], blurRadius: 8, spreadRadius: 2),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    theme['name'],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white70,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
