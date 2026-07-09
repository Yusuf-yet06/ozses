import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class PlaylistSheet extends StatelessWidget {
  final StorageService storage;
  final Function(String) onPlaylistSelected;
  final Color themeColor;

  const PlaylistSheet({
    super.key,
    required this.storage,
    required this.onPlaylistSelected,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        border: Border.all(color: themeColor.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 20),
          Text('PLAYLISTLERİN',
              style: TextStyle(
                  color: themeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const SizedBox(height: 10),
          FutureBuilder<List<String>>(
            future: storage.getPlaylistNames(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Henüz liste yok gardaşım.',
                        style: TextStyle(color: Colors.white54)));
              }
              return Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: Icon(Icons.playlist_play, color: themeColor),
                    title: Text(snapshot.data![index],
                        style: const TextStyle(color: Colors.white)),
                    onTap: () => onPlaylistSelected(snapshot.data![index]),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

extension on StorageService {
  // ignore: body_might_complete_normally_nullable
  Future<List<String>>? getPlaylistNames() {}
}
