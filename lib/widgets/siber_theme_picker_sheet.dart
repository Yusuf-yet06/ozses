import 'package:flutter/material.dart';
import '../services/siber_theme_service.dart';

/// 🎨 SİBER TEMA RENKİ SEÇİCİ
/// Profil ekranında tema rengini değiştirmeye yarar
class SiberThemePickerSheet extends StatefulWidget {
  final Color currentColor;
  final Function(Color) onColorChanged;

  const SiberThemePickerSheet({
    super.key,
    required this.currentColor,
    required this.onColorChanged,
  });

  @override
  State<SiberThemePickerSheet> createState() => _SiberThemePickerSheetState();
}

class _SiberThemePickerSheetState extends State<SiberThemePickerSheet> {
  late Color _selectedColor;

  // Önceden tanımlanmış siber tema paletleri
  static const List<_ThemePreset> _presets = [
    _ThemePreset('Siber Mavi', Color(0xFF00B4FF), Icons.water_drop_rounded),
    _ThemePreset('Neon Mor', Color(0xFF9C27B0), Icons.auto_awesome),
    _ThemePreset('Lazer Yeşil', Color(0xFF00E676), Icons.eco_rounded),
    _ThemePreset('Kızıl Ateş', Color(0xFFFF1744), Icons.local_fire_department),
    _ThemePreset('Altın', Color(0xFFFFD740), Icons.star_rounded),
    _ThemePreset('Magenta', Color(0xFFFF4081), Icons.favorite_rounded),
    _ThemePreset('Siyan', Color(0xFF00E5FF), Icons.waves_rounded),
    _ThemePreset('Turuncu', Color(0xFFFF6D00), Icons.flash_on),
    _ThemePreset('Nane', Color(0xFF69F0AE), Icons.spa_rounded),
    _ThemePreset('Kırmızı Biber', Color(0xFFD50000), Icons.whatshot_rounded),
    _ThemePreset('Gece Mavisi', Color(0xFF3D5AFE), Icons.nightlight_round),
    _ThemePreset('Elektrik', Color(0xFFE040FB), Icons.bolt_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.currentColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: _selectedColor.withOpacity(0.4), width: 1),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    color: _selectedColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2)),
              ),

              Row(
                children: [
                  Icon(Icons.palette_rounded, color: _selectedColor, size: 22),
                  const SizedBox(width: 10),
                  Text('AURA RENGİ SEÇ',
                      style: TextStyle(
                          color: _selectedColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.2)),
                  const Spacer(),
                  // Önizleme
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: _selectedColor.withOpacity(0.5), blurRadius: 12, spreadRadius: 2)],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Renk grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _presets.length,
                itemBuilder: (context, i) {
                  final preset = _presets[i];
                  final isSelected = _selectedColor.value == preset.color.value;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedColor = preset.color);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: preset.color.withOpacity(isSelected ? 0.2 : 0.07),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? preset.color : preset.color.withOpacity(0.2),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [BoxShadow(color: preset.color.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)] : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(preset.icon, color: preset.color, size: isSelected ? 26 : 22),
                          const SizedBox(height: 6),
                          Text(preset.name,
                              style: TextStyle(
                                  color: isSelected ? preset.color : Colors.white54,
                                  fontSize: 9,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                              textAlign: TextAlign.center,
                              maxLines: 2),
                          if (isSelected)
                            Icon(Icons.check_circle, color: preset.color, size: 14),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Uygula butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: const Text('AURA RENGINI MÜHÜRLE',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  onPressed: () {
                    SiberThemeService.instance.updateBaseColor(_selectedColor);
                    widget.onColorChanged(_selectedColor);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('🎨 Siber Aura Rengi Değiştirildi!'),
                      backgroundColor: _selectedColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePreset {
  final String name;
  final Color color;
  final IconData icon;
  const _ThemePreset(this.name, this.color, this.icon);
}
