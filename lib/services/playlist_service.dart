import 'package:shared_preferences/shared_preferences.dart';

class PlaylistService {
  static const String _pListKey = 'all_playlists';

  // 1. TÜM LİSTE İSİMLERİNİ GETİR (Favorilerim ve Zirvedekiler kalıcıdır)
  Future<List<String>> getAllPlaylistNames() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_pListKey) ?? [];
    bool changed = false;
    if (!list.contains('Favorilerim')) {
      list.insert(0, 'Favorilerim');
      changed = true;
    }
    // Temizlik: Eski çift "On Repeat" listesini kaldır ve tekil "Zirvedekiler (Top 15)" olarak sabitle
    if (list.contains('🔥 Zirvedekiler (On Repeat)')) {
      list.remove('🔥 Zirvedekiler (On Repeat)');
      changed = true;
    }
    if (!list.contains('🔥 Zirvedekiler (Top 15)')) {
      list.insert(list.contains('Favorilerim') ? 1 : 0, '🔥 Zirvedekiler (Top 15)');
      changed = true;
    }
    if (changed) {
      await prefs.setStringList(_pListKey, list);
    }
    return list;
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

  // 3. LİSTEYİ TAMAMEN SİL (Favorilerim ve Zirvedekiler silinemez)
  Future<void> deletePlaylist(String name) async {
    if (name == 'Favorilerim' || name.contains('Zirvedekiler')) return;
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
          'Siber Aktarım Başarılı: $success | Liste: $playlistName | Şarkı: $songPath');
    } else {
      print('Bu şarkı zaten mühimmat deposunda (listede) mevcut!');
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
    print('Şarkı listeden imha edildi: $playlistName');
  }
}
