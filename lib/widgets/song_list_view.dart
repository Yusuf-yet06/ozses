import 'package:flutter/material.dart';
import '../models/song_model.dart';
import 'package:share_plus/share_plus.dart';

class SongListView extends StatelessWidget {
  final List<SongModel> songs;
  final Color themeColor;
  final String currentSongName;
  final Set<SongModel> selectedSongs;
  final bool isSelectionMode;
  final Function(SongModel) onSongTap;
  final Function(SongModel) onSongLongPress;
  final VoidCallback onPickFiles;

  const SongListView({
    super.key,
    required this.songs,
    required this.themeColor,
    required this.currentSongName,
    required this.selectedSongs,
    required this.isSelectionMode,
    required this.onSongTap,
    required this.onSongLongPress,
    required this.onPickFiles,
  });

  // 🛡️ SİBER KALKAN: Şarkı adı null gelirse Text widget'ını çökertmemesi için güvenli çözüm
  String _getSafeSongName(SongModel song) {
    String n = song.name ?? '';
    if (n.isEmpty || n == 'Bilinmeyen Müzik') {
      final safePath = song.path ?? '';
      if (safePath.isNotEmpty && safePath != 'bilinmeyen_yol') {
        n = safePath.split('/').last.split('\\').last;
      } else {
        n = 'Bilinmeyen Müzik';
      }
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final safeName = _getSafeSongName(song);
        final isSelected = currentSongName == safeName;
        final isChecked = selectedSongs.contains(song);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isChecked
                ? themeColor.withOpacity(0.3)
                : (isSelected
                    ? themeColor.withOpacity(0.1)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            onLongPress: () => onSongLongPress(song),
            leading: isSelectionMode
                ? Checkbox(
                    value: isChecked,
                    activeColor: themeColor,
                    onChanged: (v) => onSongTap(song),
                  )
                : CircleAvatar(
                    backgroundColor: isSelected ? themeColor : Colors.white10,
                    child: Icon(Icons.music_note,
                        color: isSelected ? Colors.black : Colors.white),
                  ),
            title: Text(safeName,
                style:
                    TextStyle(color: isSelected ? themeColor : Colors.white)),
            trailing: isSelectionMode
                ? null
                : IconButton(
                    icon: Icon(Icons.share, color: Colors.white54),
                    onPressed: () {
                      Share.share("🎧 Şu an dinliyorum: $safeName\nÖZSES Müzik ile keşfettim!");
                    },
                  ),
            onTap: () => onSongTap(song),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: themeColor.withOpacity(0.2),
                    blurRadius: 50,
                    spreadRadius: 5)
              ],
            ),
            child: Icon(Icons.music_off_outlined,
                size: 80, color: themeColor.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          Text("ÖZSES V7 HENÜZ SESSİZ",
              style: TextStyle(
                  color: themeColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: onPickFiles,
            icon: const Icon(Icons.add),
            label: const Text("ŞİMDİ MÜZİK YÜKLE"),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor.withOpacity(0.1),
              foregroundColor: themeColor,
              side: BorderSide(color: themeColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }
}
