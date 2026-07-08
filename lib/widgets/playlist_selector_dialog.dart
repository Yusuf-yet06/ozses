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
    final service = PlaylistService();

    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text("Listeye Ekle",
          style: TextStyle(color: themeColor, fontSize: 16)),
      content: SizedBox(
        width: double.maxFinite,
        height: 200,
        child: FutureBuilder<List<String>>(
          future: service.getAllPlaylistNames(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final names = snapshot.data!;
            return ListView.builder(
              itemCount: names.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(names[index],
                    style: const TextStyle(color: Colors.white70)),
                onTap: () async {
                  await service.addSongToPlaylist(
                      names[index], song.path ?? 'bilinmeyen_yol');

                  if (!context.mounted)
                    return; // 🛡️ SİBER KALKAN: Ekran hala açık mı kontrolü
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            "${song.name ?? 'Bilinmeyen Müzik'} listeye eklendi")),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
