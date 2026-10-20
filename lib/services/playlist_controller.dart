import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../utils/song_media_utils.dart';
import 'storage_service.dart';
import 'history_service.dart';
import 'offline_cache_service.dart';

class PlaylistController {
  final StorageService _storage = StorageService();
  bool isGlobalLibrary = true;
  String? currentPlaylistName;

  Future<List<SongModel>> loadTargetList() async {
    List<String> paths = [];
    final prefs = await SharedPreferences.getInstance();

    if (isGlobalLibrary) {
      paths = await _storage.getPlaylist();
    } else if (currentPlaylistName == '🔥 Zirvedekiler (On Repeat)' ||
        currentPlaylistName == '🔥 Zirvedekiler (Top 15)' ||
        currentPlaylistName == 'Zirvedekiler' ||
        (currentPlaylistName?.contains('Zirvedekiler') ?? false)) {
      // 🎯 SİBER OTONOM ZİRVE LİSTESİ (SADECE YEREL ARŞİV - KEŞFET KARIŞTIRILMAZ):
      // Yerel arşiv yollarını belirle (Keşfet stream linkleri kesinlikle elenir)
      final globalSongs = await loadGlobalLibrarySongs();
      final allStorageSongs = await _storage.getPlaylist();
      final cachedSongs = OfflineCacheService().cachedSongs;

      final Set<String> archivePaths = {
        ...globalSongs.map((s) => s.path).whereType<String>(),
        ...allStorageSongs,
        ...cachedSongs.map((s) => s.path).whereType<String>(),
      }.where((p) => isPlayableSongPath(p) && !p.startsWith('http') && !p.startsWith('stream:')).toSet();

      // Önce SharedPreferences'ta kayıtlı liste var mı ve arşivde mevcut mu bak
      final savedPaths = prefs.getStringList('playlist_$currentPlaylistName') ?? [];
      final validSaved = savedPaths.where((p) => archivePaths.contains(p)).toList();

      if (validSaved.isNotEmpty) {
        paths = validSaved;
      } else {
        // Canlı geçmişten sadece arşivde olanları çek (Genel bazlı en çok dinlenenler)
        final history = await HistoryService.getHistory();
        final archiveHistory = history.where((h) => archivePaths.contains(h.path)).toList();
        archiveHistory.sort((a, b) {
          if (b.playCount != a.playCount) {
            return b.playCount.compareTo(a.playCount);
          }
          return b.totalListenSeconds.compareTo(a.totalListenSeconds);
        });
        paths = archiveHistory
            .take(15)
            .map((h) => h.path)
            .toList();

        if (paths.isNotEmpty && currentPlaylistName != null) {
          await prefs.setStringList('playlist_$currentPlaylistName', paths);
        }
      }
    } else if (currentPlaylistName != null) {
      // HAFIZADAKİ YENİ PLAYLİST KEYİ İLE ÇEKİYORUZ
      paths = prefs.getStringList('playlist_$currentPlaylistName') ?? [];
    }

    final globalSongs = await loadGlobalLibrarySongs();
    final songMap = {for (var s in globalSongs) if (s.path != null) s.path!: s};

    return paths
        .map<SongModel>(
          (p) => songMap[p] ??
              SongModel(
                name: p.split('/').last.split('\\').last,
                path: p,
                title: p.split('/').last.split('\\').last,
              ),
        )
        .toList();
  }
}
