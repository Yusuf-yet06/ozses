import 'package:flutter/material.dart';
import '../services/playlist_service.dart';
import '../main.dart'; // 🎯 Küresel Zamanlayıcı motoru için eklendi

class PlaylistManagerDrawer extends StatefulWidget {
  final Color themeColor;
  final Function(String) onPlaylistSelected;
  final VoidCallback onPlaylistChanged;
  final VoidCallback onStartListening; // 🎤 Siber Komutan hattı

  const PlaylistManagerDrawer({
    super.key,
    required this.themeColor,
    required this.onPlaylistSelected,
    required this.onPlaylistChanged,
    required this.onStartListening,
  });

  @override
  State<PlaylistManagerDrawer> createState() => _PlaylistManagerDrawerState();
}

class _PlaylistManagerDrawerState extends State<PlaylistManagerDrawer> {
  String? _longPressedPlaylist;

  @override
  Widget build(BuildContext context) {
    final PlaylistService service = PlaylistService();

    return Container(
      color: Colors.black.withValues(alpha: 0.95),
      child: Column(
        children: [
          _buildProfileHeader(),

          // 2. Playlist Listesi (Kaydırılabilir Alan)
          Expanded(
            child: FutureBuilder<List<String>>(
              future: service.getAllPlaylistNames(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final names = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: names.length,
                  itemBuilder: (context, index) {
                    final pName = names[index];
                    final isDeleting = _longPressedPlaylist == pName;
                    final isFavoriteList = pName == 'Favorilerim';

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isDeleting
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: isDeleting
                            ? Border.all(
                                color: Colors.redAccent.withValues(alpha: 0.5))
                            : null,
                      ),
                      child: ListTile(
                        leading: Icon(Icons.folder_copy_outlined,
                            color: isFavoriteList
                                ? Colors.redAccent
                                : (isDeleting
                                    ? Colors.redAccent
                                    : widget.themeColor.withValues(alpha: 0.7))),
                        title: Text(pName,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14)),
                        onLongPress: isFavoriteList
                            ? null // 🎯 SİBER KALKAN: Favorilerim listesi silinemez!
                            : () => setState(() => _longPressedPlaylist =
                                isDeleting ? null : pName),
                        trailing: isDeleting
                            ? IconButton(
                                icon: const Icon(Icons.delete_forever,
                                    color: Colors.redAccent),
                                onPressed: () async {
                                  // 🎯 SİBER HAMLE: Kaza kurşununa karşı silme onayı
                                  bool? confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: Colors.grey[900],
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                      title: const Text('LİSTEYİ YOK ET',
                                          style: TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.bold)),
                                      content: Text(
                                          "'$pName' listesi ve içindeki mühürler tamamen silinecek. Emin misin usta?",
                                          style: const TextStyle(
                                              color: Colors.white70)),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('İptal',
                                              style: TextStyle(
                                                  color: Colors.white54)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent
                                                  .withValues(alpha: 0.8)),
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Sök At',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await service.deletePlaylist(pName);
                                    setState(() => _longPressedPlaylist = null);
                                    widget.onPlaylistChanged();
                                  }
                                },
                              )
                            : const Icon(Icons.chevron_right,
                                color: Colors.white24, size: 20),
                        onTap: () {
                          if (!isDeleting) widget.onPlaylistSelected(pName);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 3. SİBER KONTROL PANELİ (Alt Sabit Kısım)
          const Divider(color: Colors.white10),

          // --- SİBER KOMUTAN (MİKROFON) ---
          ListTile(
            leading: Icon(Icons.mic, color: widget.themeColor),
            title: const Text('SİBER KOMUTAN',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            subtitle: const Text('Sesli komutları aktif et',
                style: TextStyle(color: Colors.white54, fontSize: 10)),
            onTap: () {
              Navigator.pop(context);
              widget.onStartListening();
            },
          ),

          const Divider(color: Colors.white10),
          _buildSettingsFooter(),
        ],
      ),
    );
  }

  // YARDIMCI METODLAR (Header, Footer ve Dialoglar)

  Widget _buildProfileHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, widget.themeColor.withValues(alpha: 0.1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: widget.themeColor.withValues(alpha: 0.2),
            child: Icon(Icons.person, color: widget.themeColor, size: 40),
          ),
          const SizedBox(height: 10),
          const Text('ÖZSES V7 IMPERIUM',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5)),
          Text('Premium Üye',
              style: TextStyle(color: widget.themeColor, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildSettingsFooter() {
    return const Column(
      children: [
        ListTile(
          leading: Icon(Icons.info_outline, color: Colors.white54),
          title: Text('Versiyon v7.0.1',
              style: TextStyle(color: Colors.white24, fontSize: 11)),
        ),
        SizedBox(height: 10),
      ],
    );
  }
}
