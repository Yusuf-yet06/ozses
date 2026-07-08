import 'package:shared_preferences/shared_preferences.dart';

class PlaylistService {
  static const String _pListKey = 'all_playlists';

  // 1. TÜM LİSTE İSİMLERİNİ GETİR
  Future<List<String>> getAllPlaylistNames() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_pListKey) ?? [];
  }

  // 2. YENİ LİSTE OLUŞTUR
  Future<void> createPlaylist(String name) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> current = await getAllPlaylistNames();
    if (!current.contains(name)) {
      current.add(name);
      await prefs.setStringList(_pListKey, current);
    }
  }

  // 3. LİSTEYİ TAMAMEN SİL
  Future<void> deletePlaylist(String name) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> current = await getAllPlaylistNames();
    current.remove(name);
    await prefs.setStringList(_pListKey, current);
    await prefs.remove('playlist_$name');
  }

  // 4. LİSTEYE ŞARKI EKLE (Kritik Bölge - Mühürlendi)
  Future<void> addSongToPlaylist(String playlistName, String songPath) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'playlist_$playlistName';

    List<String> songs = prefs.getStringList(key) ?? [];

    if (!songs.contains(songPath)) {
      songs.add(songPath);
      bool success = await prefs.setStringList(key, songs);
      print(
          "Siber Aktarım Başarılı: $success | Liste: $playlistName | Şarkı: $songPath");
    } else {
      print("Bu şarkı zaten mühimmat deposunda (listede) mevcut!");
    }
  }

  // 5. ŞARKIYI LİSTEDEN SİL (Siber İmha)
  Future<void> removeSongFromPlaylist(
      String playlistName, String songPath) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'playlist_$playlistName';

    List<String> songs = prefs.getStringList(key) ?? [];
    songs.remove(songPath);
    await prefs.setStringList(key, songs);
    print("Şarkı listeden imha edildi: $playlistName");
  }
}
