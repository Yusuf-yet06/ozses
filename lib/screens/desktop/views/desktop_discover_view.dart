import 'package:flutter/material.dart';
import '../../../services/siber_theme_service.dart';
import '../../discover_screen.dart';
import '../../profile_screen.dart';
import 'desktop_home_view.dart';
import 'desktop_library_view.dart';

class DesktopDiscoverView extends StatelessWidget {
  final int selectedIndex;

  const DesktopDiscoverView({
    super.key,
    required this.selectedIndex,
  });

  Widget _buildContentTitle(String title, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text(
        title,
        style: TextStyle(
          color: themeColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildHorizontalCards(Color themeColor) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          final titles = ['Lo-Fi Study Beats', 'Derin Kodlama Akışı', 'Gece Modu - Ambient', 'Odak Odası', 'Siber Mix'];
          final subtitles = ['Chillwave', 'Coding Rhythms', 'Ambient', 'Focus', 'Electronic'];
          
          return Container(
            width: 160,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      // image: DecorationImage(image: AssetImage('...'), fit: BoxFit.cover),
                    ),
                    child: Center(
                      child: Icon(Icons.music_note, color: themeColor, size: 40),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titles[index % titles.length],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitles[index % subtitles.length],
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerticalList(Color themeColor) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: 10,
      itemBuilder: (context, index) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.play_arrow_rounded, color: themeColor),
          ),
          title: const Text('Şarkı Adı Yükleniyor...', style: TextStyle(color: Colors.white)),
          subtitle: Text('Sanatçı', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          trailing: Text('3:45', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: SiberThemeService.instance.currentThemeColor,
      builder: (context, themeColor, child) {
        // Hangi menü seçiliyse ona göre başlık göster
        String pageTitle = 'Ferah Odak Alanı';
        if (selectedIndex == 0) pageTitle = 'Anasayfa';
        if (selectedIndex == 1) pageTitle = 'Keşfet';
        if (selectedIndex == 2) pageTitle = 'Kütüphanem';
        if (selectedIndex == 3) pageTitle = 'Çalma Listeleri';
        if (selectedIndex == 4) pageTitle = 'AI Modülü';

        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContentTitle(pageTitle, themeColor),
              
              if (selectedIndex == 0) ...[
                // Anasayfa (İndirilenler / Kütüphane)
                Expanded(
                  child: DesktopHomeView(themeColor: themeColor),
                ),
              ] else if (selectedIndex == 1) ...[
                // Keşfet (Siber Klon)
                Expanded(
                  child: DiscoverScreen(
                    themeColor: themeColor,
                    isPersonalMode: false,
                  ),
                ),
              ] else if (selectedIndex == 2) ...[
                Expanded(
                  child: DesktopLibraryView(themeColor: themeColor),
                ),
              ] else if (selectedIndex == 5) ...[
                // Ayarlar (Profil Ekranı)
                const Expanded(
                  child: ProfileScreen(),
                ),
              ] else ...[
                // Diğer bölümler
                Expanded(
                  child: Center(
                    child: Text(
                      '$pageTitle İçeriği Yakında Siber Ağa Eklenecek',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ]
            ],
          ),
        );
        },
      );
    }
  }
