import re
import os

filepath = r'C:\Users\Admin\Documents\SQL Server Management Studio\OZSES_V7_IMPERIUM\lib\screens\home_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Redesign _buildSongTile
old_song_tile = """  Widget _buildSongTile(SongModel song, bool isSelected, Color themeColor) {
    // 🛡️ SİBER KALKAN: ListTile ve ValueKey için güvenli değerler
    final safePath = song.path ?? 'bilinmeyen_yol';
    final safeName = _getSafeSongName(song); // Siber İsim Çözücü kullanıldı
    final bool isFav = _favoritePaths.contains(safePath); // Bu şarkı favori mi?

    bool isDownloading = safePath.startsWith('downloading:');
    String videoId = isDownloading ? safePath.substring(12) : '';
    Map<String, dynamic>? dTask =
        isDownloading ? _downloadingTasks[videoId] : null;

    return Slidable("""

new_song_tile = """  Widget _buildSongTile(SongModel song, bool isSelected, Color themeColor) {
    final safePath = song.path ?? 'bilinmeyen_yol';
    final safeName = _getSafeSongName(song);
    final bool isFav = _favoritePaths.contains(safePath);

    bool isDownloading = safePath.startsWith('downloading:');
    String videoId = isDownloading ? safePath.substring(12) : '';
    Map<String, dynamic>? dTask = isDownloading ? _downloadingTasks[videoId] : null;

    return Slidable(
      key: ValueKey(safePath.isNotEmpty ? safePath : song.hashCode.toString()),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: isDownloading ? null : (context) => _deleteSong(song, safePath),
            backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
            icon: Icons.delete_sweep,
            label: 'Sök At',
          ),
        ],
      ),
      child: Opacity(
        opacity: isDownloading ? 0.4 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutExpo,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // 🎯 Daha geniş aralık, kart görünümü
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? [
                      themeColor.withValues(alpha: (0.2 * _neonScale).clamp(0.0, 1.0)),
                      Colors.black.withValues(alpha: 0.8),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.6),
                    ],
            ),
            borderRadius: BorderRadius.circular(20), // 🎯 Daha yuvarlak köşeler
            border: Border.all(
              color: isSelected
                  ? themeColor.withValues(alpha: (0.6 * _neonScale).clamp(0.0, 1.0))
                  : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 1.5 + (_neonScale > 1.0 ? _neonScale - 1.0 : 0) : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: themeColor.withValues(alpha: (0.2 * _neonScale).clamp(0.0, 1.0)),
                      blurRadius: 15 * _neonScale,
                      spreadRadius: 2 * _neonScale,
                    )
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10), // 🎯 Kalın buzlu cam
              child: InkWell(
                onTap: isDownloading ? null : () => _playSong(song),
                splashColor: themeColor.withValues(alpha: 0.3),
                highlightColor: themeColor.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // 🎯 SİBER KAPAK VEYA İKON ALANI
                      Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? themeColor.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isSelected
                                ? themeColor.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(color: themeColor.withValues(alpha: 0.3), blurRadius: 8)
                          ] : [],
                        ),
                        child: Center(
                          child: isSelected
                              ? SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: MiniEqVisualizer(
                                    themeColor: themeColor,
                                    isPlaying: _isPlaying,
                                  ),
                                )
                              : Icon(Icons.music_note_rounded,
                                  color: Colors.white.withValues(alpha: 0.6), size: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 🎯 ŞARKI BİLGİLERİ
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              safeName,
                              style: TextStyle(
                                color: isSelected ? themeColor : Colors.white,
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (isDownloading && dTask != null)
                              Text(
                                "📥 İniyor: ${dTask['percent']}  •  ${dTask['mb']}",
                                style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else
                              Text(
                                "Siber Arşiv • V7", // Yerel müzik olduğu için
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // 🎯 SEÇENEKLER (3 NOKTA)
                      if (!isDownloading)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded,
                              color: isSelected ? themeColor : Colors.white54),
                          color: Colors.black.withValues(alpha: 0.9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: themeColor.withValues(alpha: 0.5)),
                          ),
                          onSelected: (value) {
                            if (value == 'add_playlist') _showAddToPlaylistDialog(safePath);
                            else if (value == 'favorite') _toggleFavorite(song);
                            else if (value == 'delete') _deleteSong(song, safePath);
                            else if (value == 'play_next') _addSongToQueue(song, true);
                            else if (value == 'add_queue') _addSongToQueue(song, false);
                          },
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem(
                              value: 'favorite',
                              child: Row(
                                children: [
                                  Icon(isFav ? Icons.favorite : Icons.favorite_border_rounded,
                                      color: Colors.redAccent, size: 20),
                                  const SizedBox(width: 12),
                                  Text(isFav ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'play_next',
                              child: Row(
                                children: [
                                  Icon(Icons.skip_next_rounded, color: themeColor, size: 20),
                                  const SizedBox(width: 12),
                                  const Text('Sıradakini Çal', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'add_queue',
                              child: Row(
                                children: [
                                  Icon(Icons.queue_music_rounded, color: themeColor, size: 20),
                                  const SizedBox(width: 12),
                                  const Text('Kuyruğa Ekle', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'add_playlist',
                              child: Row(
                                children: [
                                  const Icon(Icons.playlist_add_rounded, color: Colors.cyanAccent, size: 20),
                                  const SizedBox(width: 12),
                                  const Text("Playlist'e Ekle", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 20),
                                  SizedBox(width: 12),
                                  Text('Sök At (Sil)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }"""

start_idx = content.find(old_song_tile)
if start_idx != -1:
    end_idx = content.find("  void _showPlaylistSelectorBottomSheet(Color themeColor) async {", start_idx)
    content = content[:start_idx] + new_song_tile + "\n\n" + content[end_idx:]
    print("Replaced _buildSongTile successfully.")
else:
    print("Could not find _buildSongTile")


# 2. Replace _showIntelligenceBottomSheet with _showCyberStudioBottomSheet
old_intelligence = "  // 🎯 SİBER HAMLE: Kişisel İstihbarat ve Analiz Paneli (Bottom Sheet)"

new_cyber_studio = """  // 🎯 SİBER HAMLE: Siber Ses Stüdyosu (Efekt ve EQ Merkezi)
  void _showCyberStudioBottomSheet(Color themeColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.60,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(top: BorderSide(color: themeColor.withValues(alpha: 0.5), width: 2)),
            boxShadow: [
              BoxShadow(color: themeColor.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 5)
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.graphic_eq_rounded, color: themeColor, size: 28),
                      const SizedBox(width: 10),
                      Text('SİBER SES STÜDYOSU',
                          style: TextStyle(
                              color: themeColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  // Gelişmiş Efekt Kartları
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildStudioCard(
                          title: '3D Siber Akustik',
                          subtitle: 'Mekansal ses derinliği ve geniş sahne efekti.',
                          icon: Icons.threed_rotation,
                          color: Colors.cyanAccent,
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('3D Akustik Motoru başlatılıyor... (Yakında)')));
                          }
                        ),
                        const SizedBox(height: 15),
                        _buildStudioCard(
                          title: 'Deep Bass Boost',
                          subtitle: 'Sub-bass frekanslarını otonom olarak güçlendirir.',
                          icon: Icons.speaker,
                          color: Colors.orangeAccent,
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Siber Bass Motoru devrede! (Yakında)')));
                          }
                        ),
                        const SizedBox(height: 15),
                        _buildStudioCard(
                          title: 'Vokal Ayrıştırıcı',
                          subtitle: 'Yapay zeka ile sadece vokalleri (karaoke) öne çıkarır.',
                          icon: Icons.mic_external_on,
                          color: Colors.purpleAccent,
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yapay Zeka Vokal Analizi yapılıyor... (Yakında)')));
                          }
                        ),
                        const SizedBox(height: 15),
                        _buildStudioCard(
                          title: 'Manuel Ekolayzer',
                          subtitle: 'Frekansları kendi zevkine göre hassas ayarla.',
                          icon: Icons.tune_rounded,
                          color: themeColor,
                          onTap: () {
                            Navigator.pop(context);
                            // Ekolayzer paneli açılabilir
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manuel EQ Paneli açılıyor...')));
                          }
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudioCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white24)
          ],
        ),
      ),
    );
  }
"""

start_idx = content.find(old_intelligence)
if start_idx != -1:
    end_idx = content.find("  // 🎯 SİBER HAMLE: Profesyonel Şahsi Keşfet (Yapay Zeka Destekli Öneri Motoru)", start_idx)
    content = content[:start_idx] + new_cyber_studio + "\n\n" + content[end_idx:]
    print("Replaced _showIntelligenceBottomSheet successfully.")
else:
    print("Could not find _showIntelligenceBottomSheet")

# 3. Rename call from _showIntelligenceBottomSheet to _showCyberStudioBottomSheet inside Drawer
content = content.replace("_showIntelligenceBottomSheet(themeColor)", "_showCyberStudioBottomSheet(themeColor)")
content = content.replace("label: 'KİŞİSEL İSTİHBARAT',", "label: 'SİBER SES STÜDYOSU',")
content = content.replace("label: 'DİNLEME GEÇMİŞİ',", "label: 'SİBER SES STÜDYOSU',\n                          themeColor: themeColor,\n                          onPressed: () => _showCyberStudioBottomSheet(themeColor),\n                        ),\n                        _buildNeonButton(\n                          icon: Icons.history,\n                          label: 'DİNLEME GEÇMİŞİ',")


with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done patching.")
