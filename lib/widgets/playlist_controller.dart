import 'package:ozses_v7/services/storage_service.dart' show StorageService;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';

class PlaylistController {
  final StorageService _storage = StorageService();
  bool isGlobalLibrary = true;
  String? currentPlaylistName;

  Future<List<SongModel>> loadTargetList() async {
    List<String> paths = [];
    final prefs = await SharedPreferences.getInstance();

    if (isGlobalLibrary) {
      // 1. ANA ARŞİVİ GETİR (Tüm şarkılar)
      paths = await _storage.getPlaylist();
      print(
        "[+] Siber Ana Arşiv (Global Library) tarandı, ${paths.length} mühimmat bulundu.",
      );
    } else if (currentPlaylistName != null) {
      // 2. PLAYLIST'İ HAFIZADAN ÇEK (Kritik nokta burası!)
      // Biz PlaylistService'de 'playlist_$playlistName' olarak kaydettik.
      final String key = 'playlist_$currentPlaylistName';
      paths = prefs.getStringList(key) ?? [];
      print(
        "[+] Siber Playlist Kontrolü: $key sektöründen ${paths.length} özel mühimmat çekildi.",
      );
    }

    // Yolları SongModel listesine çevir
    return paths
        .map(
          (p) => SongModel(
            name: p.split('/').last.split('\\').last,
            path: p,
            title: '',
          ),
        )
        .toList();
  }
}
