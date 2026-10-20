import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../services/playlist_service.dart';
import '../../../utils/song_media_utils.dart';
import '../../../utils/search_utils.dart';
import '../../../models/song_model.dart';
import '../../../widgets/neon_search_bar.dart';
import 'desktop_home_view.dart';

class DesktopLibraryView extends StatefulWidget {
  final Color themeColor;

  const DesktopLibraryView({super.key, required this.themeColor});

  @override
  State<DesktopLibraryView> createState() => _DesktopLibraryViewState();
}

class _DesktopLibraryViewState extends State<DesktopLibraryView> {
  final PlaylistService _playlistService = PlaylistService();
  List<String> _playlists = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final playlists = await _playlistService.getAllPlaylistNames();
    if (mounted) {
      setState(() {
        _playlists = playlists;
        _isLoading = false;
      });
    }
  }

  // --- MÜHÜRLEME VE DİYALOGLAR ---
  void _showPlaylistTypeSelectionDialog(BuildContext context, Color themeColor) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 450,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: themeColor.withValues(alpha: 0.5), width: 2),
              boxShadow: [
                BoxShadow(color: themeColor.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5)
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.library_add, color: themeColor, size: 28),
                          const SizedBox(width: 10),
                          Text('YENİ LİSTE OLUŞTUR', style: TextStyle(color: themeColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        ],
                      ),
                      const SizedBox(height: 25),
                      _buildSelectionTile(
                        context: context,
                        title: 'Manuel Oluştur',
                        subtitle: 'Boş bir liste açıp şarkıları tek tek ekleyin.',
                        icon: Icons.edit_rounded,
                        color: Colors.cyanAccent,
                        onTap: () {
                          Navigator.pop(context);
                          _showCreateDialog(context, themeColor);
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildSelectionTile(
                        context: context,
                        title: 'Akıllı Mix (Otonom)',
                        subtitle: 'Ruh halinize ve müzik türüne göre otomatik liste hazırlasın.',
                        icon: Icons.auto_awesome_rounded,
                        color: Colors.orangeAccent,
                        onTap: () {
                          Navigator.pop(context);
                          _showOfflineAutoPlaylistDialog(context, themeColor);
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildSelectionTile(
                        context: context,
                        title: 'Sanatçıya Özel Otonom Liste',
                        subtitle: 'Kütüphanenizdeki bir sanatçının solo ve düet parçalarından liste üretir.',
                        icon: Icons.mic_external_on_rounded,
                        color: Colors.pinkAccent,
                        onTap: () {
                          Navigator.pop(context);
                          _showArtistAutoPlaylistDialog(context, themeColor);
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectionTile({required BuildContext context, required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, Color themeColor) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 450,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: themeColor.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(color: themeColor.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5)
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note_rounded, color: themeColor, size: 30),
                        const SizedBox(width: 10),
                        Text('YENİ PLAYLİST', style: TextStyle(color: themeColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Form(
                      key: formKey,
                      child: TextFormField(
                        controller: controller,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Liste adı...',
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: themeColor, width: 2),
                          ),
                        ),
                        validator: (value) => value!.trim().isEmpty ? 'Boş bırakılamaz' : null,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('İPTAL', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 15),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final newName = controller.text.trim();
                              final existingPlaylists = await _playlistService.getAllPlaylistNames();
                              if (existingPlaylists.contains(newName)) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.error_outline, color: Colors.white),
                                          const SizedBox(width: 10),
                                          Expanded(child: Text("Siber Hata: '$newName' adında bir liste zaten mühürlenmiş usta!", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                        ],
                                      ),
                                      backgroundColor: Colors.redAccent.shade700,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      margin: const EdgeInsets.all(10),
                                    ),
                                  );
                                }
                              } else {
                                await _playlistService.createPlaylist(newName);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  _loadPlaylists();
                                }
                              }
                            }
                          },
                          child: const Text('Oluştur', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showOfflineAutoPlaylistDialog(BuildContext context, Color themeColor) {
    final List<Map<String, dynamic>> moods = [
      {'name': 'Melankolik', 'icon': Icons.water_drop, 'color': Colors.blueAccent},
      {'name': 'Efkârlı', 'icon': Icons.smoke_free, 'color': Colors.grey},
      {'name': 'Enerjik', 'icon': Icons.local_fire_department, 'color': Colors.orangeAccent},
      {'name': 'Kopmalık', 'icon': Icons.celebration, 'color': Colors.amberAccent},
      {'name': 'Rahatlatıcı', 'icon': Icons.spa, 'color': Colors.tealAccent},
      {'name': 'Odaklanma', 'icon': Icons.psychology_alt, 'color': Colors.green},
      {'name': 'Motivasyon', 'icon': Icons.fitness_center, 'color': Colors.red},
      {'name': 'Nostaljik', 'icon': Icons.history_toggle_off, 'color': Colors.brown},
      {'name': 'İsyankâr', 'icon': Icons.bolt, 'color': Colors.deepPurpleAccent},
      {'name': 'Uyku Öncesi', 'icon': Icons.nights_stay, 'color': Colors.indigo},
    ];
    
    final List<Map<String, dynamic>> genres = [
      {'name': 'Türkçe Pop', 'icon': Icons.star, 'color': Colors.pinkAccent},
      {'name': 'Yabancı Pop', 'icon': Icons.public, 'color': Colors.lightBlueAccent},
      {'name': 'Arabesk', 'icon': Icons.local_drink, 'color': Colors.purpleAccent},
      {'name': 'Rap / Sokak', 'icon': Icons.sports_kabaddi, 'color': Colors.redAccent},
      {'name': 'Rock / Metal', 'icon': Icons.album, 'color': Colors.blueGrey},
      {'name': 'Anadolu Rock', 'icon': Icons.landscape, 'color': Colors.orange},
      {'name': 'Türkü', 'icon': Icons.music_video, 'color': Colors.brown},
      {'name': 'Akustik', 'icon': Icons.music_note, 'color': Colors.lime},
      {'name': 'Elektronik', 'icon': Icons.graphic_eq, 'color': Colors.cyanAccent},
      {'name': 'Klasik Müzik', 'icon': Icons.piano, 'color': Colors.amber},
    ];

    int selectedMoodIndex = 0;
    int selectedGenreIndex = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 500,
                height: 450,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: themeColor.withValues(alpha: 0.5), width: 2),
                  boxShadow: [
                    BoxShadow(color: themeColor.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 5)
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 15, bottom: 15),
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, color: themeColor, size: 28),
                            const SizedBox(width: 10),
                            Text('SİBER ZEKÂ OTONOM', style: TextStyle(color: themeColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text('Ruh hali ve Müzik Türünü çevirerek seç', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(child: Center(child: Text("RUH HALİ", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 14)))),
                              Expanded(child: Center(child: Text("MÜZİK TÜRÜ", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 14)))),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: themeColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ListWheelScrollView.useDelegate(
                                        itemExtent: 50,
                                        physics: const FixedExtentScrollPhysics(),
                                        diameterRatio: 1.5,
                                        onSelectedItemChanged: (index) {
                                          setStateDialog(() {
                                            selectedMoodIndex = index;
                                          });
                                        },
                                        childDelegate: ListWheelChildBuilderDelegate(
                                          childCount: moods.length,
                                          builder: (context, index) {
                                            final item = moods[index];
                                            final isSelected = index == selectedMoodIndex;
                                            return AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              alignment: Alignment.center,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(item['icon'], color: isSelected ? item['color'] : Colors.white24, size: isSelected ? 18 : 14),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      item['name'],
                                                      style: TextStyle(
                                                        color: isSelected ? Colors.white : Colors.white38,
                                                        fontSize: isSelected ? 16 : 13,
                                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: ListWheelScrollView.useDelegate(
                                        itemExtent: 50,
                                        physics: const FixedExtentScrollPhysics(),
                                        diameterRatio: 1.5,
                                        onSelectedItemChanged: (index) {
                                          setStateDialog(() {
                                            selectedGenreIndex = index;
                                          });
                                        },
                                        childDelegate: ListWheelChildBuilderDelegate(
                                          childCount: genres.length,
                                          builder: (context, index) {
                                            final item = genres[index];
                                            final isSelected = index == selectedGenreIndex;
                                            return AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              alignment: Alignment.center,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(item['icon'], color: isSelected ? item['color'] : Colors.white24, size: isSelected ? 18 : 14),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      item['name'],
                                                      style: TextStyle(
                                                        color: isSelected ? Colors.white : Colors.white38,
                                                        fontSize: isSelected ? 16 : 13,
                                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 10,
                              shadowColor: themeColor.withValues(alpha: 0.5),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              final selection = "${moods[selectedMoodIndex]['name']} - ${genres[selectedGenreIndex]['name']}";
                              _handleOfflineAutoPlaylist(selection, themeColor);
                            },
                            child: const Text('Otonom Listeyi Başlat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  void _showArtistAutoPlaylistDialog(BuildContext context, Color themeColor) async {
    final List<SongModel> globalSongs = await loadGlobalLibrarySongs();
    if (!context.mounted) return;
    if (globalSongs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Kütüphanenizde henüz şarkı bulunmuyor!'),
        backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
      ));
      return;
    }

    final Map<String, int> artistCounts = {};
    for (var song in globalSongs) {
      String rawArtist = (song.artist ?? '').trim();
      if (rawArtist.isEmpty || rawArtist.toLowerCase() == '<unknown>' || rawArtist.toLowerCase() == 'unknown') {
        if (song.title != null && song.title!.contains(' - ')) {
          rawArtist = song.title!.split(' - ')[0].trim();
        }
      }
      if (rawArtist.isNotEmpty && rawArtist.toLowerCase() != '<unknown>' && rawArtist.toLowerCase() != 'unknown') {
        final parts = rawArtist.split(RegExp(r'\s*(,|&|x|/|\+|feat\.?|ft\.?|ile)\s*', caseSensitive: false));
        for (var p in parts) {
          final trimmed = p.trim();
          if (trimmed.length > 1 && trimmed.toLowerCase() != 'feat' && trimmed.toLowerCase() != 'ft') {
            artistCounts[trimmed] = (artistCounts[trimmed] ?? 0) + 1;
          }
        }
      }
    }

    final sortedArtists = artistCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final TextEditingController searchCtrl = TextEditingController();
    bool includeSolo = true;
    bool includeDuet = true;
    String selectedArtist = sortedArtists.isNotEmpty ? sortedArtists.first.key : '';
    if (selectedArtist.isNotEmpty) {
      searchCtrl.text = selectedArtist;
    }

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final query = searchCtrl.text.trim().toLowerCase();
            final filteredArtists = query.isEmpty
                ? sortedArtists.take(16).toList()
                : sortedArtists
                    .where((e) => e.key.toLowerCase().contains(query))
                    .take(16)
                    .toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: 520,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border(top: BorderSide(color: Colors.pinkAccent.withValues(alpha: 0.6), width: 2)),
                  boxShadow: [
                    BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.15), blurRadius: 30, spreadRadius: 4),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 15, bottom: 12),
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mic_external_on_rounded, color: Colors.pinkAccent, size: 26),
                            SizedBox(width: 10),
                            Text(
                              'SANATÇI OTONOM MOTORU',
                              style: TextStyle(
                                color: Colors.pinkAccent,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Center(
                          child: Text(
                            'Kütüphanendeki sanatçının solo ve düet parçalarını otonom derle',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
                            ),
                            child: TextField(
                              controller: searchCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              onChanged: (val) {
                                setSheetState(() {
                                  selectedArtist = val.trim();
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Sanatçı adı ara veya yazın...',
                                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                                prefixIcon: const Icon(Icons.search_rounded, color: Colors.pinkAccent, size: 20),
                                suffixIcon: searchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                                        onPressed: () {
                                          setSheetState(() {
                                            searchCtrl.clear();
                                            selectedArtist = '';
                                          });
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'KÜTÜPHANENDEN ÖNERİLENLER',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: filteredArtists.isEmpty
                                ? Center(
                                    child: Text(
                                      searchCtrl.text.trim().isNotEmpty
                                          ? '"${searchCtrl.text.trim()}" için özel arama yapılacak'
                                          : 'Kütüphanede sanatçı bulunamadı',
                                      style: const TextStyle(color: Colors.white38, fontSize: 13),
                                    ),
                                  )
                                : SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: filteredArtists.map((entry) {
                                        final isSel = selectedArtist.toLowerCase() == entry.key.toLowerCase();
                                        return InkWell(
                                          onTap: () {
                                            setSheetState(() {
                                              selectedArtist = entry.key;
                                              searchCtrl.text = entry.key;
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(20),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                            decoration: BoxDecoration(
                                              color: isSel
                                                  ? Colors.pinkAccent.withValues(alpha: 0.25)
                                                  : Colors.white.withValues(alpha: 0.05),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: isSel
                                                    ? Colors.pinkAccent
                                                    : Colors.white.withValues(alpha: 0.15),
                                                width: isSel ? 1.5 : 1,
                                              ),
                                              boxShadow: isSel
                                                  ? [
                                                      BoxShadow(
                                                        color: Colors.pinkAccent.withValues(alpha: 0.3),
                                                        blurRadius: 8,
                                                      )
                                                    ]
                                                  : null,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.person_rounded,
                                                  size: 14,
                                                  color: isSel ? Colors.pinkAccent : Colors.white70,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  entry.key,
                                                  style: TextStyle(
                                                    color: isSel ? Colors.white : Colors.white70,
                                                    fontSize: 12,
                                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: isSel
                                                        ? Colors.pinkAccent.withValues(alpha: 0.6)
                                                        : Colors.white12,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    '${entry.value}',
                                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    if (!includeSolo && !includeDuet) return;
                                    setSheetState(() {
                                      includeSolo = !includeSolo;
                                      if (!includeSolo && !includeDuet) includeDuet = true;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: includeSolo ? Colors.cyanAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: includeSolo ? Colors.cyanAccent : Colors.white24),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(includeSolo ? Icons.check_circle_rounded : Icons.radio_button_unchecked, color: includeSolo ? Colors.cyanAccent : Colors.white38, size: 16),
                                        const SizedBox(width: 6),
                                        const Text('👑 Solo Eserler', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    if (!includeSolo && !includeDuet) return;
                                    setSheetState(() {
                                      includeDuet = !includeDuet;
                                      if (!includeSolo && !includeDuet) includeSolo = true;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: includeDuet ? Colors.purpleAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: includeDuet ? Colors.purpleAccent : Colors.white24),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(includeDuet ? Icons.check_circle_rounded : Icons.radio_button_unchecked, color: includeDuet ? Colors.purpleAccent : Colors.white38, size: 16),
                                        const SizedBox(width: 6),
                                        const Text('🤝 Düet & Feat', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedArtist.isNotEmpty ? Colors.pinkAccent : Colors.white12,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: selectedArtist.isNotEmpty ? 8 : 0,
                              shadowColor: Colors.pinkAccent.withValues(alpha: 0.5),
                            ),
                            onPressed: selectedArtist.isNotEmpty
                                ? () {
                                    Navigator.pop(context);
                                    _handleArtistAutoPlaylist(
                                      selectedArtist,
                                      includeSolo,
                                      includeDuet,
                                      themeColor,
                                    );
                                  }
                                : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.rocket_launch_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  selectedArtist.isNotEmpty
                                      ? '"$selectedArtist" Otonom Listesini Başlat'
                                      : 'Sanatçı Seçin',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleArtistAutoPlaylist(
    String artistQuery,
    bool includeSolo,
    bool includeDuet,
    Color themeColor,
  ) async {
    final List<SongModel> globalSongs = await loadGlobalLibrarySongs();
    if (globalSongs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Hata: Cihazınızda hiç şarkı yok!'),
          backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
        ));
      }
      return;
    }

    final cleanQuery = artistQuery.trim();
    if (cleanQuery.isEmpty) return;

    final escaped = RegExp.escape(cleanQuery);
    final artistRegex = RegExp(r'(^|[\s\(\[\-\_\,\.\&])' + escaped + r'($|[\s\)\]\-\_\,\.\&])', caseSensitive: false);
    final duetRegex = RegExp(r'\b(feat\.?|ft\.?|&|x|\+|ile|düet|duet)\b', caseSensitive: false);

    List<SongModel> soloMatches = [];
    List<SongModel> duetMatches = [];

    for (var song in globalSongs) {
      final title = (song.title ?? '').trim();
      final artist = (song.artist ?? '').trim();
      final name = (song.name ?? '').trim();
      final combined = '$title $artist $name';

      final isMatch = artistRegex.hasMatch(combined) || combined.toLowerCase().contains(cleanQuery.toLowerCase());
      if (isMatch) {
        final isDuet = duetRegex.hasMatch(combined);
        if (isDuet) {
          duetMatches.add(song);
        } else {
          soloMatches.add(song);
        }
      }
    }

    List<SongModel> finalSongs = [];
    if (includeSolo) finalSongs.addAll(soloMatches);
    if (includeDuet) finalSongs.addAll(duetMatches);

    if (finalSongs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('⚠️ Kütüphanenizde "$cleanQuery" sanatçısına ait parça bulunamadı.'),
          backgroundColor: Colors.amber.shade900,
        ));
      }
      return;
    }

    final pName = '$cleanQuery Otonom';
    final existingPlaylists = await _playlistService.getAllPlaylistNames();
    if (!existingPlaylists.contains(pName)) {
      await _playlistService.createPlaylist(pName);
    }
    for (var song in finalSongs) {
      if (song.path != null) {
        await _playlistService.addSongToPlaylist(pName, song.path!);
      }
    }

    if (mounted) {
      _loadPlaylists();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('🎙️ "$cleanQuery" Otonom Listesi hazırlandı (${finalSongs.length} şarkı: ${soloMatches.length} solo, ${duetMatches.length} düet)!'),
        backgroundColor: Colors.pinkAccent.withValues(alpha: 0.85),
        duration: const Duration(seconds: 4),
      ));
    }
  }

  void _handleOfflineAutoPlaylist(String selection, Color themeColor) async {
    final List<SongModel> globalSongs = await loadGlobalLibrarySongs();
    if (globalSongs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Siber Hata: Cihazınızda hiç şarkı yok!'),
          backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
        ));
      }
      return;
    }

    final keyword = selection.toLowerCase().split(' ')[0];
    List<SongModel> filteredSongs = globalSongs.where((song) {
      return (song.title?.toLowerCase().contains(keyword) ?? false) || (song.artist?.toLowerCase().contains(keyword) ?? false);
    }).toList();

    if (filteredSongs.isEmpty) {
      filteredSongs = List.from(globalSongs)..shuffle();
      filteredSongs = filteredSongs.take(15).toList();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Akıllı Mix: '$selection' için kütüphanenizden uygun şarkılar harmanlandı!"),
          backgroundColor: themeColor.withValues(alpha: 0.8),
        ));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('🎵 Çevrimdışı Otonom Liste hazır! Çalınmaya başlanıyor...'),
          backgroundColor: themeColor.withValues(alpha: 0.8),
        ));
      }
    }

    final pName = '$selection Mix';
    final existingPlaylists = await _playlistService.getAllPlaylistNames();
    if (!existingPlaylists.contains(pName)) {
      await _playlistService.createPlaylist(pName);
    }
    for (var song in filteredSongs) {
      if (song.path != null) {
        await _playlistService.addSongToPlaylist(pName, song.path!);
      }
    }

    if (mounted) {
      _loadPlaylists();
    }
  }

  Widget _buildLibraryCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: gradient.last.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> filteredPlaylists = _playlists.where((p) => SearchUtils.matchesText(p, _searchQuery)).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
        // Playlist Oluştur ve Favorilerim Kartları
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              _buildLibraryCard(
                title: 'Playlist Oluştur',
                icon: Icons.add_box,
                color: Colors.white,
                gradient: [Colors.grey.shade800, Colors.grey.shade900],
                onTap: () {
                  _showPlaylistTypeSelectionDialog(context, widget.themeColor);
                },
              ),
              const SizedBox(width: 16),
              _buildLibraryCard(
                title: 'Favorilerim',
                icon: Icons.favorite,
                color: Colors.white,
                gradient: [Colors.deepPurpleAccent, Colors.purple],
                onTap: () async {
                  final exists = await _playlistService.getAllPlaylistNames();
                  if (!exists.contains('Favorilerim')) {
                    await _playlistService.createPlaylist('Favorilerim');
                    _loadPlaylists();
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Favorilerim listesi açılıyor...'), backgroundColor: widget.themeColor),
                    );
                  }
                },
              ),
            ],
          ),
        ),

        // Üst Arama ve Oluşturma Barı
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: NeonSearchBar(
                  themeColor: widget.themeColor,
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5))
                ),
                child: IconButton(
                  icon: const Icon(Icons.add_rounded, color: Colors.cyanAccent),
                  tooltip: 'Yeni Playlist Oluştur',
                  onPressed: () {
                    _showPlaylistTypeSelectionDialog(context, widget.themeColor);
                  },
                ),
              )
            ],
          ),
        ),
        
        // Playlist Listesi
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredPlaylists.isEmpty
                  ? Center(
                      child: Text(
                        'Henüz playlist oluşturmadın veya bulunamadı.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: filteredPlaylists.length,
                      itemBuilder: (context, index) {
                        final pName = filteredPlaylists[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                pName == 'Favorilerim' ? Icons.favorite : Icons.queue_music_rounded, 
                                color: pName == 'Favorilerim' ? Colors.redAccent : widget.themeColor, 
                                size: 24
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  pName,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (pName != 'Favorilerim')
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  tooltip: 'Sil',
                                  onPressed: () async {
                                    await _playlistService.deletePlaylist(pName);
                                    _loadPlaylists();
                                  },
                                ),
                              Icon(Icons.arrow_forward_ios_rounded, color: widget.themeColor, size: 18),
                            ],
                          ),
                        );
                      },
                    ),
        ), // Expanded (playlist list)
            ],
          ), // Column
        ), // Expanded (flex: 4)
        const VerticalDivider(width: 1, color: Colors.white24),
        Expanded(
          flex: 6,
          child: DesktopHomeView(themeColor: widget.themeColor),
        ),
      ],
    );
  }
}
