import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart'; // 🎯 SİBER HAMLE: Yeni Ses Motoru
import 'package:file_picker/file_picker.dart';
import 'package:ozses_v7/services/audio_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Hafıza için
import 'dart:io'; // 🎯 SİBER HAMLE: Platform Algılayıcı

void main() {
  runApp(const OzsesMusicApp());
}

// --- HAFIZA SERVİSİ (ÖZSES'İN HAFIZASI) ---
class StorageService {
  static const String _key = 'ozses_playlist_paths';

  Future<void> savePlaylist(List<String> paths) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, paths);
  }

  Future<List<String>> getPlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<List<String>> getSongsFromPlaylist(String s) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('playlist_$s') ?? [];
  }
}

class OzsesMusicApp extends StatelessWidget {
  const OzsesMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const MusicListScreen(),
    );
  }
}

class MusicListScreen extends StatefulWidget {
  const MusicListScreen({super.key});

  @override
  State<MusicListScreen> createState() => _MusicListScreenState();
}

class _MusicListScreenState extends State<MusicListScreen> {
  final AudioPlayer _player = AudioPlayer();
  final StorageService _storage = StorageService();
  String _currentSong = 'Müzik Seçilmedi';
  bool _isPlaying = false;
  List<PlatformFile> _playlist = [];

  bool? get kIsWeb => null;

  @override
  void initState() {
    super.initState();
    _loadSavedPlaylist(); // Uygulama açılınca hafızayı oku
  }

  // Hafızadaki müzikleri geri yükleyen fonksiyon
  Future<void> _loadSavedPlaylist() async {
    List<String> savedPaths = await _storage.getPlaylist();
    if (savedPaths.isNotEmpty) {
      setState(() {
        _playlist = savedPaths
            .map((path) => PlatformFile(
                  name: path
                      .split('\\')
                      .last
                      .split('/')
                      .last, // Dosya adını yoldan ayıkla
                  path: path,
                  size: 0,
                ))
            .toList();
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'mp3',
          'wav',
          'flac',
          'aac',
          'm4a',
          'ogg',
          'wma',
          'alac',
          'ape',
          'mp4',
          'opus',
          'weba',
          'm4r'
        ],
        allowMultiple: true,
      );

      if (result != null) {
        // 🛡️ SİBER KALKAN: Dosya yolu bozuk olanları (null) listeye sokma
        final validFiles = result.files.where((f) => f.path != null).toList();

        setState(() {
          _playlist = validFiles;
        });

        // HAFIZAYA KAYDET
        List<String> paths = validFiles.map((f) => f.path!).toList();
        await _storage.savePlaylist(paths);

        if (!mounted) {
          return; // 🛡️ SİBER KALKAN: Asenkron sonrası context güvenliği (94. Satır Hatasının Kesin Çözümü)
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${validFiles.length} şarkı hafızaya mühürlendi usta!')),
        );
      }
    } catch (e) {
      print('Siber Hata: FilePicker platformda çöktü usta! -> $e');
    }
  }

  Future<void> _playMusic(PlatformFile file) async {
    if (file.path != null) {
      try {
        // 🎯 SİBER KALKAN: Platformlar Arası Kusursuz Dosya Okuyucu
        await _player.setAudioSource(AudioSource.file(file.path!));
        await _player.play();
        setState(() {
          _currentSong = file.name;
          _isPlaying = true;
        });
      } catch (e) {
        print('Siber Hata: Oynatıcı platformda çöktü! -> $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ÖZSES V7 - MÜZİK MERKEZİ'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_to_photos),
            onPressed: _pickFiles,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPlayerHeader(),
          const Divider(height: 1, color: Colors.white24),
          Expanded(
            child: _playlist.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _playlist.length,
                    itemBuilder: (context, index) {
                      final file = _playlist[index];
                      final isSelected = _currentSong == file.name;
                      return ListTile(
                        leading: Icon(Icons.music_note,
                            color: isSelected
                                ? Colors.greenAccent
                                : Colors.white70),
                        title: Text(file.name,
                            style: TextStyle(
                                color: isSelected
                                    ? Colors.greenAccent
                                    : Colors.white)),
                        trailing: isSelected && _isPlaying
                            ? const Icon(Icons.equalizer,
                                color: Colors.greenAccent)
                            : const Icon(Icons.play_arrow_outlined),
                        onTap: () => _playMusic(file),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Player Header ve Empty State kısımları aynen korundu...
  Widget _buildPlayerHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white10,
      child: Column(
        children: [
          const Icon(Icons.music_video,
              size: 60, color: Colors.deepPurpleAccent),
          const SizedBox(height: 10),
          Text(_currentSong,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  icon:
                      const Icon(Icons.stop, size: 30, color: Colors.redAccent),
                  onPressed: () async {
                    await _player.stop();
                    setState(() => _isPlaying = false);
                  }),
              const SizedBox(width: 20),
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.deepPurpleAccent,
                child: IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white),
                  onPressed: () async {
                    if (_isPlaying) {
                      await _player.pause();
                    } else {
                      await _player.play();
                    }
                    setState(() => _isPlaying = !_isPlaying);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('Hafıza Boş. Müzik ekle gardaşım!'));
  }
}
