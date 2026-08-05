import 'package:flutter/material.dart';
import '../../../models/song_model.dart';
import '../../../utils/song_media_utils.dart';
import '../../../widgets/neon_search_bar.dart';
import '../../../main.dart'; // audioHandler

class DesktopHomeView extends StatefulWidget {
  final Color themeColor;

  const DesktopHomeView({super.key, required this.themeColor});

  @override
  State<DesktopHomeView> createState() => _DesktopHomeViewState();
}

class _DesktopHomeViewState extends State<DesktopHomeView> {
  String _searchQuery = '';
  int _sortMode = 0; // 0: Normal, 1: A-Z, 2: Z-A
  List<SongModel> _allSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final songs = await loadGlobalLibrarySongs();
    if (mounted) {
      setState(() {
        _allSongs = songs;
        _isLoading = false;
      });
    }
  }

  List<SongModel> get _filteredAndSortedSongs {
    List<SongModel> list = _allSongs.where((s) => (s.name ?? '').toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    
    if (_sortMode == 1) {
      list.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    } else if (_sortMode == 2) {
      list.sort((a, b) => (b.name ?? '').compareTo(a.name ?? ''));
    }
    
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final songs = _filteredAndSortedSongs;

    return Column(
      children: [
        // Arama ve Filtreleme Çubuğu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: NeonSearchBar(
                  themeColor: widget.themeColor,
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 12),
              // Silme (Temizle) Butonu
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  tooltip: 'Aramayı Temizle',
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                ),
              const SizedBox(width: 8),
              // Sıralama Butonu
              PopupMenuButton<int>(
                icon: Icon(Icons.sort_rounded, color: widget.themeColor),
                tooltip: 'Sıralama',
                color: const Color(0xFF1A1A24),
                onSelected: (val) {
                  setState(() {
                    _sortMode = val;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 0, child: Text('Varsayılan', style: TextStyle(color: Colors.white))),
                  const PopupMenuItem(value: 1, child: Text('A-Z', style: TextStyle(color: Colors.white))),
                  const PopupMenuItem(value: 2, child: Text('Z-A', style: TextStyle(color: Colors.white))),
                ],
              ),
            ],
          ),
        ),
        
        // Şarkı Listesi
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : songs.isEmpty
                  ? Center(
                      child: Text(
                        'Şarkı bulunamadı veya kütüphane boş.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: songs.length,
                      itemBuilder: (context, index) {
                        final song = songs[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.music_note, color: widget.themeColor),
                          ),
                          title: Text(song.name ?? 'Bilinmeyen Şarkı', style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('Siber Arşiv', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                          trailing: Icon(Icons.play_arrow_rounded, color: widget.themeColor),
                          onTap: () async {
                            if (song.path != null) {
                              final playable = songs.where((s) => s.path != null).toList();
                              final mediaItems = songsToMediaItems(playable);
                              final playIndex = playable.indexWhere((s) => s.path == song.path);
                              if (playIndex >= 0) {
                                await audioHandler.updateQueue(mediaItems);
                                await audioHandler.skipToQueueItem(playIndex);
                                await audioHandler.play();
                              }
                            }
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
