import 'package:flutter/material.dart';
import '../services/siber_theme_service.dart';

class ImperiumDrawer extends StatelessWidget {
  final Color themeColor;

  const ImperiumDrawer({super.key, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [themeColor.withValues(alpha: 0.2), Colors.black],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Text('ÖZSES\nIMPERIUM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: themeColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
            ),
          ),
          ListTile(
            leading: Icon(Icons.person, color: themeColor),
            title: const Text('Profil ve Ayarlar',
                style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.workspace_premium, color: themeColor),
            title: const Text("Premium'a Geç",
                style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),

          const Divider(color: Colors.white12, indent: 16, endIndent: 16),

          // 🍃 SADE MOD / ⚡ ŞATAFATLI SİBER MOD GEÇİŞ ANAHTARI
          ValueListenableBuilder<bool>(
            valueListenable: SiberThemeService.instance.isMinimalMode,
            builder: (context, isMinimal, _) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isMinimal
                      ? const Color(0xFF181818)
                      : themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isMinimal ? Colors.white12 : themeColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: SwitchListTile(
                  secondary: Icon(
                    isMinimal ? Icons.eco_rounded : Icons.bolt_rounded,
                    color: isMinimal ? Colors.white70 : themeColor,
                  ),
                  title: Text(
                    isMinimal ? 'Sade Mod' : 'İmperium Modu',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    isMinimal
                        ? 'Düz, sade ve batarya dostu arayüz'
                        : 'Görsel efektler ve parlak tema aktif',
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  value: !isMinimal,
                  activeColor: themeColor,
                  onChanged: (val) {
                    SiberThemeService.instance.setMinimalMode(!val);
                  },
                ),
              );
            },
          ),

          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('v7.0.0 Alpha',
                style: TextStyle(color: Colors.white24, fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
