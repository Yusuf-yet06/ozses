import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/playlist_service.dart';

class PlaylistSelectorDialog extends StatelessWidget {
  final SongModel song;
  final Color themeColor;

  const PlaylistSelectorDialog(
      {super.key, required this.song, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    // Servis bağlantısını burada kuruyoruz
    final PlaylistService service = PlaylistService();

    return AlertDialog(
      backgroundColor: const Color(0xFF121212),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: themeColor.withValues(alpha: 0.3)),
      ),
      title: Text(
        'İmparatorluk Listesine Ekle',
        style: TextStyle(
            color: themeColor, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 250,
        child: FutureBuilder<List<String>>(
          // Tüm listeleri siber hızla çekiyoruz
          future: service.getAllPlaylistNames(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(color: themeColor));
            }

            final names = snapshot.data ?? [];

            if (names.isEmpty) {
              return const Center(
                child: Text(
                  'Henüz bir liste oluşturmadın gardaşım.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                ),
              );
            }

            return ListView.separated(
              itemCount: names.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Colors.white10, height: 1),
              itemBuilder: (context, index) {
                final playlistName = names[index];
                return ListTile(
                  leading: Icon(Icons.playlist_add, color: themeColor),
                  title: Text(playlistName,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14)),
                  onTap: () async {
                    print(
                        'Siber Aktarım Başladı: ${song.name} -> $playlistName');

                    // Şarkıyı listeye mühürle
                    await service.addSongToPlaylist(
                        playlistName,
                        song.path ??
                            'bilinmeyen_yol'); // 🛡️ Null-Safety Kalkanı

                    if (context.mounted) {
                      Navigator.pop(context); // Diyaloğu kapat
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: themeColor,
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                              "${song.name} başarıyla '$playlistName' listesine eklendi!"),
                        ),
                      );
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
