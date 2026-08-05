import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ozses_v7/main.dart';
import 'package:ozses_v7/services/playlist_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final PlaylistService _playlistService = PlaylistService();
  Timer? _sleepTimer;
  int _remainingSeconds = 0;
  List<String> _playlists = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final playlistKeys =
        keys.where((key) => key.startsWith('playlist_')).toList();
    if (mounted) {
      setState(() {
        _playlists = playlistKeys
            .map((key) => key.substring('playlist_'.length))
            .toList();
      });
    }
  }

  void _startSleepTimer(int minutes) {
    if (_sleepTimer != null && _sleepTimer!.isActive) {
      _sleepTimer!.cancel();
    }
    if (mounted) {
      setState(() {
        _remainingSeconds = minutes * 60;
      });
    }

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        timer.cancel();
        audioHandler.stop();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Uyku zamanlayıcısı sona erdi, müzik durduruldu.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });

    Navigator.pop(context); // Dialog'u kapat
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$minutes dakika sonra müzik durdurulacak.'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
    );
  }

  void _showTimerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Uyku Zamanlayıcısı',
              style: TextStyle(color: Colors.cyanAccent)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [15, 30, 45, 60]
                .map((minutes) => ListTile(
                      title: Text('$minutes Dakika',
                          style: const TextStyle(color: Colors.white)),
                      onTap: () => _startSleepTimer(minutes),
                    ))
                .toList(),
          ),
          actions: [
            if (_remainingSeconds > 0)
              TextButton(
                onPressed: () {
                  _sleepTimer?.cancel();
                  if (mounted) setState(() => _remainingSeconds = 0);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Zamanlayıcı iptal edildi.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                },
                child: const Text('Zamanlayıcıyı İptal Et',
                    style: TextStyle(color: Colors.redAccent)),
              ),
          ],
        );
      },
    );
  }

  void _showCreatePlaylistDialog() {
    final TextEditingController tc = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Yeni Playlist Oluştur',
              style: TextStyle(color: Colors.cyanAccent)),
          content: TextField(
            controller: tc,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Playlist Adı',
              hintStyle: TextStyle(color: Colors.white38),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('İptal', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                final pName = tc.text.trim();
                if (pName.isNotEmpty) {
                  await _playlistService.addSongToPlaylist(
                      pName, 'placeholder');
                  await _playlistService.removeSongFromPlaylist(
                      pName, 'placeholder');
                  Navigator.pop(context);
                  _loadPlaylists();
                }
              },
              child: const Text('Oluştur'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('SİSTEM AYARLARI',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('Zamanlayıcı Oluşturucu'),
          Card(
            color: Colors.grey[900],
            child: ListTile(
              leading:
                  const Icon(Icons.timer_outlined, color: Colors.cyanAccent),
              title: const Text('Uyku Zamanlayıcısı',
                  style: TextStyle(color: Colors.white)),
              subtitle: Text(
                _remainingSeconds > 0
                    ? "Kalan Süre: ${(_remainingSeconds / 60).floor()}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}"
                    : 'Pasif',
                style: const TextStyle(color: Colors.white70),
              ),
              onTap: _showTimerDialog,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Oluşturucu'),
          Card(
            color: Colors.grey[900],
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.queue_music_outlined,
                      color: Colors.cyanAccent),
                  title: const Text('Aktif Olan Listeler',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text('${_playlists.length} adet playlist bulundu.',
                      style: const TextStyle(color: Colors.white70)),
                ),
                if (_playlists.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _playlists.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.queue_music,
                              color: Colors.white38, size: 20),
                          title: Text(_playlists[index],
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        );
                      },
                    ),
                  ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading:
                      const Icon(Icons.playlist_add, color: Colors.cyanAccent),
                  title: const Text('Yeni Liste Oluştur',
                      style: TextStyle(color: Colors.white)),
                  onTap: _showCreatePlaylistDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Siber Kalkan (Önbellek & Sorun Giderme)'),
          Card(
            color: Colors.grey[900],
            child: ListTile(
              leading: const Icon(Icons.cleaning_services, color: Colors.cyanAccent),
              title: const Text('Tüm Siber Önbelleği Temizle', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Eski trendleri, arama geçmişini ve bozuk akış linklerini siler. İndirme veya oynatma takılıyorsa bunu kullanın.', style: TextStyle(color: Colors.white70, fontSize: 12)),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('siber_trend_cache');
                await prefs.remove('siber_personal_artists');
                await prefs.remove('siber_personal_genres');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🧹 Siber Önbellek tamamen temizlendi! Lütfen uygulamayı yeniden başlatın.'), backgroundColor: Colors.green),
                );
              },
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.deepPurpleAccent,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
