import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import 'storage_service.dart';

class PlaylistController {
  final StorageService _storage = StorageService();
  bool isGlobalLibrary = true;
  String? currentPlaylistName;

  Future<List<SongModel>> loadTargetList() async {
    List<String> paths = [];

    if (isGlobalLibrary) {
      paths = await _storage.getPlaylist();
    } else if (currentPlaylistName != null) {
      // HAFIZADAKİ YENİ PLAYLİST KEYİ İLE ÇEKİYORUZ
      final prefs = await SharedPreferences.getInstance();
      paths = prefs.getStringList('playlist_$currentPlaylistName') ?? [];
    }

    return paths
        .map<SongModel>(
          (p) => SongModel(
            name: p.split('/').last.split('\\').last,
            path: p,
            title: '',
          ),
        )
        .toList();
  }
}
