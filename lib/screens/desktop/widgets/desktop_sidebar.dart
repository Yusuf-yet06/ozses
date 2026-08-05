import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/siber_theme_service.dart';
import 'compact_desktop_profile.dart'; // Yeni oluşturduğumuz kompakt profil

class DesktopSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onMenuSelected;

  const DesktopSidebar({
    super.key,
    required this.selectedIndex,
    required this.onMenuSelected,
  });

  @override
  State<DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends State<DesktopSidebar> {
  bool _isProfileOpen = false;
  String _username = 'Siber Ajan';
  String _avatarUrl = 'https://robohash.org/siber_ajan.png?set=set3';

  @override
  void initState() {
    super.initState();
    _loadMiniProfile();
  }

  Future<void> _loadMiniProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('siber_username') ?? 'Siber Ajan';
    final avatar = prefs.getString('siber_avatar_url');

    if (mounted) {
      setState(() {
        _username = name;
        if (avatar != null && avatar.isNotEmpty) {
          _avatarUrl = avatar;
        } else {
          _avatarUrl = "https://robohash.org/${name.replaceAll(' ', '_')}?set=set3";
        }
      });
    }
  }

  Widget _buildMenuItem(IconData icon, String title, int index, Color themeColor) {
    bool isSelected = widget.selectedIndex == index;
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return MouseRegion(
          onEnter: (_) => setLocalState(() => isHovered = true),
          onExit: (_) => setLocalState(() => isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              widget.onMenuSelected(index);
              setState(() {
                _isProfileOpen = false; // Menüden bir şey seçilince profili kapat
              });
            },
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? themeColor.withValues(alpha: 0.1) 
                        : isHovered 
                            ? Colors.white.withValues(alpha: 0.05) 
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? themeColor.withValues(alpha: 0.3) 
                          : isHovered 
                              ? Colors.white.withValues(alpha: 0.1) 
                              : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.only(left: isHovered || isSelected ? 8.0 : 0.0),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          color: isSelected ? themeColor : isHovered ? Colors.white : Colors.white60,
                          size: 22,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          title,
                          style: TextStyle(
                            color: isSelected ? Colors.white : isHovered ? Colors.white : Colors.white60,
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w600 : isHovered ? FontWeight.w500 : FontWeight.w400,
                            shadows: isSelected
                                ? [Shadow(color: themeColor, blurRadius: 8)]
                                : [],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Glowing Active Indicator (Neon çizgi)
                if (isSelected)
                  Positioned(
                    left: 12,
                    top: 10,
                    bottom: 10,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: themeColor,
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: SiberThemeService.instance.currentThemeColor,
      builder: (context, themeColor, child) {
        return Container(
          width: 250,
          color: const Color(0xFF0F111A), // Çok koyu gri/lacivert
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-1.0, 0.0), // Soldan sağa kayarak gelsin
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
            child: _isProfileOpen
                ? CompactDesktopProfile(
                    key: const ValueKey('ProfileView'),
                    onClose: () {
                      setState(() {
                        _isProfileOpen = false;
                      });
                    },
                  )
                : _buildNavigationMenu(themeColor),
          ),
        );
      },
    );
  }

  Widget _buildNavigationMenu(Color themeColor) {
    return Column(
      key: const ValueKey('NavMenu'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),

        // Logo ve Başlık
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [themeColor, themeColor.withValues(alpha: 0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.music_note, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Özses',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),



        // Navigasyon Menüsü
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildMenuItem(Icons.home_outlined, 'Anasayfa', 0, themeColor),
              _buildMenuItem(Icons.explore_outlined, 'Keşfet', 1, themeColor),
              _buildMenuItem(Icons.library_music_outlined, 'Kütüphanem', 2, themeColor),
              _buildMenuItem(Icons.smart_toy_outlined, 'AI Modülü', 4, themeColor),
              _buildMenuItem(Icons.settings_outlined, 'Ayarlar', 5, themeColor),
            ],
          ),
        ),

        // En Altta Profil Butonu
        InkWell(
          onTap: () {
            setState(() {
              _isProfileOpen = true;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(_avatarUrl),
                  backgroundColor: themeColor.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
