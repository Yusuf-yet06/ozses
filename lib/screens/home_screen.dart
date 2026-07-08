// ignore_for_file: unused_local_variable

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart'; // 🎯 Hızlı favori okuması için
import 'package:http/http.dart'
    as http; // 🎯 SİBER HAMLE: Keşfetten gelenlerin plak kapağı için

import '../main.dart';
import '../models/song_model.dart';
import '../services/vibe_engine.dart';
import '../services/playlist_controller.dart';
import '../services/playlist_service.dart';
import '../services/ai_commander.dart';
import '../services/audio_handler.dart';
import '../services/services.dart'; // 🎯 SİBER KÖPRÜ (OzsesBridge İçin)
import '../services/storage_service.dart';
import '../widgets/auto_playlist_sheet.dart';
import '../widgets/sonic_aura_sheet.dart';
import '../services/audio_analysis_service.dart'; // 🎯 SİBER HAMLE: Gerçek Zamanlı Analiz
import '../services/file_picker_service.dart'; // 🎯 SİBER HAMLE: Dışarı çıkardığımız dosya seçici servisi
import '../services/id3_service.dart'; // 🎯 SİBER HAMLE: ID3 okuyucu servis
import '../services/timer_service.dart'; // 🎯 SİBER HAMLE: Uyku zamanlayıcısı servisi
import '../services/history_service.dart'; // 🎯 SİBER HAMLE: Geçmiş dinleme servisi

import '../utils/song_media_utils.dart';
import '../widgets/bottom_player_bar.dart';
import '../widgets/mode_indicator.dart';
import '../widgets/neon_search_bar.dart';
import '../widgets/mini_eq_visualizer.dart'; // 🎯 SİBER HAMLE: Yeni Ritim Widget'ı
import '../widgets/full_screen_player.dart'; // 🎯 SİBER HAMLE: Tam Ekran Oynatıcı Mührü
import '../services/settings_service.dart'; // 🎯 SİBER KARARGAH PANELİ BAĞLANTISI
import '../services/audio_engine.dart'; // 🎯 SİBER GÖRSEL AYARLAR İÇİN
import 'profile_screen.dart'; // 🎯 SİBER PROFİL BAĞLANTISI
import 'discover_screen.dart'; // 🎯 YOUTUBE MUSIC SİBER KLONU BAĞLANTISI
import 'listening_mode_screen.dart'; // 🎯 SİBER DİNLEME MODU BAĞLANTISI
import '../widgets/siber_sesli_komut_sheet.dart'; // 🎙️ SESLİ KOMUT


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PlaylistController _playlistController = PlaylistController();
  final PlaylistService _playlistService = PlaylistService();
  final AICommander _commander = AICommander();
  final AudioAnalysisService _audioAnalysisService =
      AudioAnalysisService(); // 🎯 SİBER BEYİN

  bool _isPlaying = false;
  bool _isBuffering = false; // 🎯 SİBER HAMLE: Sonsuz Buffer (Yükleme) Kilidi
  String _currentSongName = 'Müzik Seçilmedi';
  String _currentArtist = 'Victus V7'; // 🎯 Sanatçı bilgisi
  Uint8List? _currentCoverBytes; // 🎯 Kapak resmi hafızası
  List<SongModel> _playlist = [];
  List<SongModel> _emergentPlaylist = [];
  bool _isEmergentMode = false;
  String _searchQuery = '';
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  bool _isHandlerReady = false;
  int _repeatMode = 0;
  bool _isShuffle = false;
  Set<String> _favoritePaths = {}; // 🎯 Favori müziklerin hafızası
  int _sortMode = 0; // 🎯 Siber Sıralama Modu (0: Normal, 1: A-Z, 2: Z-A)
  String _lastRecordedSongId = ''; // 🎯 Siber Geçmiş kontrol mührü
  String _currentProcessedId =
      ''; // 🎯 Titremeyi (Flicker) engelleyen kimlik mührü
  double _neonScale = 1.0; // 🎯 SİBER RİTİM ÇARPAN
  String _waveType = "Analiz Bekleniyor..."; // 🎯 SİBER RUH HALİ
  String _topHistorySongName =
      "Zirve Bekleniyor..."; // 🎯 SİBER HAMLE: Zirve Müzik
  String _topHistorySongPath = "";

  StreamSubscription? _mediaItemSub;
  StreamSubscription? _playbackStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription?
      _analysisSub; // 🎯 SİBER HAMLE: Analiz motoru için abonelik mührü
  Map<String, Map<String, dynamic>> _downloadingTasks = {};
  Map<String, Timer> _downloadTimers = {};

  @override
  void initState() {
    super.initState();
    _checkHandlerAndInit();
  }

  Future<void> _checkHandlerAndInit() async {
    // 🛡️ SİBER KALKAN: audioHandler zaten main.dart içinde runApp'ten önce mühürlendi.
    // Gereksiz null kontrolünü ve bekleme döngüsünü söküp attık!
    if (mounted) {
      setState(() => _isHandlerReady = true);
      await _initFavorites(); // 🎯 SİBER HAMLE: Favorileri Yükle
      await _loadTopStats(); // 🎯 SİBER HAMLE: Zirvedeki Şarkıyı Bul
      _loadInitialPlaylist();
      _initAI();
      _listenToAudioHandler();

      // 🎯 SİBER HAMLE: Canlı Frekans Analizini Otonom Başlat
      _analysisSub = _audioAnalysisService.getAnalysisStream().listen((data) {
        if (mounted && _isPlaying) {
          setState(() {
            _neonScale = data.neonScale;
            _waveType = data.waveType;
          });
        }
      });
    }
  }

  // 🎯 SİBER HAMLE: En Çok Dinlenen Zirve Şarkıyı Analiz Et
  Future<void> _loadTopStats() async {
    try {
      final historyList = await HistoryService.getHistory();
      if (historyList.isNotEmpty && mounted) {
        historyList.sort(
            (a, b) => b.totalListenSeconds.compareTo(a.totalListenSeconds));
        setState(() {
          _topHistorySongName = historyList.first.name
              .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '')
              .trim();
          if (_topHistorySongName.isEmpty)
            _topHistorySongName = "Bilinmeyen Müzik";
          _topHistorySongPath = historyList.first.path;
        });
      } else if (mounted) {
        setState(() => _topHistorySongName = "Henüz Veri Yok");
      }
    } catch (e) {
      print("Siber İstatistik Hatası: $e");
    }
  }

  // 🎯 SİBER HAMLE: Favoriler Altyapısı
  Future<void> _initFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoritePaths = (prefs.getStringList('favorites') ?? []).toSet();
    });
    final names = await _playlistService.getAllPlaylistNames();
    if (!names.contains('Favorilerim')) {
      await _playlistService.createPlaylist('Favorilerim');
    }
  }

  Future<void> _toggleFavorite(SongModel song) async {
    final safePath = song.path ?? 'bilinmeyen_yol';
    if (safePath == 'bilinmeyen_yol') return;
    final prefs = await SharedPreferences.getInstance();
    bool isFav = _favoritePaths.contains(safePath);
    if (isFav) {
      _favoritePaths.remove(safePath);
      await _playlistService.removeSongFromPlaylist('Favorilerim', safePath);
    } else {
      _favoritePaths.add(safePath);
      await _playlistService.addSongToPlaylist('Favorilerim', safePath);
    }
    await prefs.setStringList('favorites', _favoritePaths.toList());
    if (mounted) setState(() {});
  }

  void _listenToAudioHandler() {
    _mediaItemSub = audioHandler.mediaItem.listen((item) {
      if (item != null) {
        bool isNewSong = _currentProcessedId != item.id;

        if (mounted) {
          setState(() {
            _currentSongName = item.title;
            _currentArtist = item.artist ?? "Victus V7";
            _dur = item.duration ?? Duration.zero;
          });
        }

        // SADECE şarkı fiziksel olarak değiştiğinde ID3 yükle ve kapağı sıfırla
        if (isNewSong) {
          _currentProcessedId = item.id;
          if (mounted) {
            setState(() {
              _currentCoverBytes = null;
            });
          }

          // 🎯 SİBER HAMLE: Çevrimiçi Şarkı (Keşfet Kuyruğu) ise artUri Kullan (Plak Kapağı)
          _loadCoverForMediaItem(item);
        }

        // 🎯 SİBER GEÇMİŞ MÜHRÜ
        if (item.id != 'bilinmeyen_yol') {
          if (_lastRecordedSongId != item.id) {
            _lastRecordedSongId = item.id;
            HistoryService.recordPlay(item.id, item.title)
                .then((_) => _loadTopStats());
          }
          if (item.duration != null && item.duration!.inSeconds > 0) {
            HistoryService.updateDuration(item.id, item.duration!.inSeconds);
          }
        }
      }
    });

    _playbackStateSub = audioHandler.playbackState.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          // 🎯 SİBER HAMLE: Slider titremesini (jitter) önlemek için _pos = state.position; söküldü!
          // StreamBuilder otonom olarak pozisyonu akıcı şekilde yönetecek.

          // 🎯 SİBER KALKAN: Sonsuz Yükleme Dairesi (Buffer Lock) Kökten Çözüldü!
          _isBuffering =
              state.processingState == AudioProcessingState.buffering ||
                  state.processingState == AudioProcessingState.loading;

          if (state.processingState == AudioProcessingState.ready ||
              state.processingState == AudioProcessingState.completed ||
              state.processingState == AudioProcessingState.idle ||
              state.processingState == AudioProcessingState.error) {
            // Motor hazırsa veya boşta/hatadaysa yüklemeyi kesinlikle durdur! 
            _isBuffering = false;
          }
        });
      }
    });

    // 🎯 SİBER HAMLE: Şarkı çalarken saniye saniye ilerlemesini (slider için) otonom dinliyoruz
    _positionSub = AudioService.position.listen((position) {
      if (mounted) {
        _pos =
            position; // 🎯 SİBER HAMLE: Toptan setState Kapatıldı! UI kilitlenmesi bitti.
      }
    });
  }

  @override
  void dispose() {
    _mediaItemSub?.cancel();
    _playbackStateSub?.cancel();
    _positionSub?.cancel();
    _analysisSub
        ?.cancel(); // 🎯 SİBER KALKAN: Bellek sızıntısını (Memory Leak) önle!
    for (var timer in _downloadTimers.values) {
      timer.cancel();
    }
    _downloadTimers.clear();
    super.dispose();
  }

  Future<void> _initAI() async => await _commander.initCommander();
  Future<void> _loadInitialPlaylist() async => _toggleLibraryView(null);

  void _loadCoverForMediaItem(MediaItem item) {
    final uri = artUriForMediaId(
      item.id,
      videoId: item.extras?['videoId']?.toString(),
      existing: item.artUri,
    );

    if (uri != null) {
      http.get(uri).then((response) {
        if (response.statusCode == 200 &&
            mounted &&
            _currentProcessedId == item.id) {
          setState(() => _currentCoverBytes = response.bodyBytes);
        }
      }).catchError((_) {});
      return;
    }

    if (item.id.startsWith('downloading:') || item.id == 'bilinmeyen_yol') {
      return;
    }

    ID3Service.extractTags(item.id).then((tags) {
      if (!mounted || _currentProcessedId != item.id) return;
      setState(() {
        _currentCoverBytes = ID3Service.getCoverBytes(tags);
        final extractedArtist = tags['Artist'];
        if (extractedArtist != null &&
            extractedArtist.toString().trim().isNotEmpty) {
          _currentArtist = extractedArtist;
        }
        final extractedTitle = tags['Title'];
        if (extractedTitle != null &&
            extractedTitle.toString().trim().isNotEmpty) {
          _currentSongName = extractedTitle;
        }
      });
    });
  }

  Future<void> _toggleLibraryView(String? playlistName) async {
    if (mounted) setState(() => _isEmergentMode = false);
    if (playlistName == null) {
      _playlistController.isGlobalLibrary = true;
      _playlistController.currentPlaylistName = null;
    } else {
      _playlistController.isGlobalLibrary = false;
      _playlistController.currentPlaylistName = playlistName;
    }
    final newList = await _playlistController.loadTargetList();
    // ignore: unnecessary_null_comparison
    if (newList != null && mounted) {
      // 🎯 SİBER HAMLE: Uygulama kapansa bile listeyi hatırlayan Ana Arşiv Hafızası
      final globalSongs = await loadGlobalLibrarySongs();

      List<SongModel> mergedList = List.from(newList);
      for (var gs in globalSongs) {
        if (!mergedList.any((s) => s.path == gs.path)) {
          mergedList.add(gs);
        }
      }

      setState(() {
        _playlist = mergedList;
        _searchQuery = '';
      });
    }
  }

  // 🎯 SİBER HAMLE: Arka Planda Şarkı İndirme Radarı (% ve MB Göstergesi İçin)
  void _handleDownloadStart(String videoId, String title) {
    if (!mounted) return;

    final dummyPath = 'downloading:$videoId';

    setState(() {
      _playlist.insert(0,
          SongModel(name: title, path: dummyPath, duration: 0, title: title));
      _downloadingTasks[videoId] = {'percent': '0%', 'mb': '0.0 / 0.0 MB'};
    });

    _downloadTimers[videoId] =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      final status = await OzsesBridge().getDownloadStatus(videoId);

      if (!mounted) {
        timer.cancel();
        return;
      }

      if (status['status'] == 'basarili') {
        timer.cancel();
        _downloadTimers.remove(videoId);

        final filePath = status['file_path']?.toString();
        if (filePath == null || !File(filePath).existsSync()) {
          setState(() {
            _downloadingTasks.remove(videoId);
            _playlist.removeWhere((s) => s.path == dummyPath);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("❌ $title indirildi ama dosya bulunamadı!"),
              backgroundColor: Colors.redAccent,
            ));
          }
          return;
        }

        // 🎯 SİBER KALKAN: Eğer Android emülatörü kullanıyorsak ve şarkı PC'ye (Siber Beyin) indiyse HTTP akışı üzerinden çekeceğiz!
        String playPath = filePath;
        if (!kIsWeb && Platform.isAndroid && filePath.contains('siber_arsiv')) {
          final fileName = filePath.split('/').last.split('\\').last;
          final encodedFileName = Uri.encodeComponent(fileName);

          // 🎯 SİBER UYARI: Eğer uygulamayı GERÇEK BİR TELEFONDA test ediyorsan,
          // SİBER HAMLE: Artık gerçek cihazlara/sistemlere geçiyoruz!
          // Bilgisayarının (sunucunun) yerel IP adresini (örn: "192.168.1.55") buraya gir.
          String siberIP =
              "10.0.2.2"; // 🎯 BURAYI GERÇEK IP İLE DEĞİŞTİR (Örn: "192.168.1.55")
          playPath = "http://$siberIP:8000/arsiv/$encodedFileName";
        }

        if (_playlistController.currentPlaylistName != null) {
          await _playlistService.addSongToPlaylist(
            _playlistController.currentPlaylistName!,
            playPath,
          );
        }
        final thumbUrl = 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
        final newSong = SongModel(
          name: title,
          path: playPath,
          duration: 0,
          title: title,
          videoId: videoId,
          artUrl: thumbUrl,
        );

        await addToGlobalLibrary(newSong);

        setState(() {
          _downloadingTasks.remove(videoId);
          int idx = _playlist.indexWhere((s) => s.path == dummyPath);
          if (idx != -1) {
            _playlist[idx] = newSong;
          } else {
            _playlist.insert(0, newSong);
          }
        });

        if (!_isEmergentMode) {
          final mediaItems = songsToMediaItems(_playlist);
          await audioHandler.updateQueue(mediaItems);
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("✅ $title başarıyla arşive mühürlendi!"),
          backgroundColor: Colors.greenAccent,
        ));
      } else if (status['status'] == 'hata') {
        timer.cancel();
        _downloadTimers.remove(videoId);
        setState(() {
          _downloadingTasks.remove(videoId);
          _playlist.removeWhere((s) => s.path == dummyPath);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("❌ $title indirilemedi!"),
          backgroundColor: Colors.redAccent,
        ));
      } else if (status['status'] == 'indiriliyor') {
        setState(() {
          _downloadingTasks[videoId] = {
            'percent': status['percent'] ?? '0%',
            'mb': '${status['downloaded_mb']} / ${status['total_mb']} MB'
          };
        });
      } else if (status['status'] == 'converting') {
        setState(() {
          _downloadingTasks[videoId] = {
            'percent': '100%',
            'mb': 'Dönüştürülüyor...'
          };
        });
      }
    });
  }

  // 🎯 SİBER HAMLE 1: Çoklu Dosya Seçme ve Müzik Yükleme (Tam Otonom)
  Future<void> _scanFolderForMusic() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Siber Tarayıcı cihazınızı müzikler için tarıyor (MYT Mantığı)..."),
            backgroundColor: Colors.deepPurpleAccent,
          ),
        );
      }
      List<String> foundPaths = await StorageService().autoScanMusicFolder();

      if (foundPaths.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Siber Yükleme: ${foundPaths.length} müzik dosyası mühürleniyor..."),
              backgroundColor: Colors.deepPurpleAccent,
            ),
          );
        }

        // 🎯 SİBER OTO-KAYIT: Şarkılar seçildiğinde aktif listeye (arşive) otonom kaydet
        if (_playlistController.currentPlaylistName != null) {
          for (var path in foundPaths) {
            await _playlistService.addSongToPlaylist(
              _playlistController.currentPlaylistName!,
              path,
            );
          }

          // 🎯 Listeyi tazeleyip, şarkıları tüm kuyrukla beraber motorun içine mühürle
          final newList = await _playlistController.loadTargetList();
          if (newList != null && mounted) {
            setState(() {
              _playlist = newList;
              _searchQuery = '';
            });
            // Yeni şarkıyı bulup DEV listeyle beraber çal
            if (newList.isNotEmpty) {
              final addedSong = newList.firstWhere(
                  (s) => s.path == foundPaths.first,
                  orElse: () => newList.last);
              await _playSong(addedSong);
            }
          }
        } else {
          // 🎯 SİBER HAMLE: Eğer arşiv seçili değilse, geçici kuyruğa ekle
          for (var path in foundPaths) {
            final newSong = SongModel(
                name: path.split('/').last.split('\\').last,
                path: path,
                duration: 0,
                title: '');
            _playlist.add(newSong);
          }

          if (mounted) setState(() {});

          final mediaItems = _playlist
              .map((s) => MediaItem(
                    id: s.path ?? 'bilinmeyen_yol',
                    album: "ÖZSES Arşivi",
                    title: _getSafeSongName(s),
                    artist: "Victus V7",
                    duration: Duration(milliseconds: s.duration ?? 0),
                  ))
              .toList();

          await audioHandler.updateQueue(mediaItems);
          await audioHandler
              .skipToQueueItem(_playlist.length - foundPaths.length);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "${foundPaths.length} Adet Müzik Yüklendi ve Mühürlendi!"),
              backgroundColor: Colors.greenAccent,
            ),
          );
        }
      }
    } catch (e) {
      print("Siber Hata: Tarama Çıktı -> $e");
    }
  }

  // 🎯 SİBER YAPAY ZEKA: Otonom Playlist Sınıflandırıcı
  Future<void> _generateAIPlaylists(Color themeColor) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.auto_awesome, color: Colors.amber),
              SizedBox(width: 10),
              Text("Siber Zeka arşivi analiz ediyor..."),
            ],
          ),
          backgroundColor: themeColor.withOpacity(0.9),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // 1. Kütüphanedeki tüm şarkıları çek (Global Arşiv)
    final prefs = await SharedPreferences.getInstance();
    List<String> allSongPaths = prefs.getStringList('all_songs') ?? [];
    if (allSongPaths.isEmpty) {
       allSongPaths = _playlist.map((e) => e.path ?? "").where((e) => e.isNotEmpty).toList();
    }

    // Kategoriler ve onlara ait listeler
    Map<String, List<String>> generatedLists = {
      "Siber Mix: Rap & Hiphop": [],
      "Siber Mix: Deep Bass & EDM": [],
      "Siber Mix: Melankolik": [],
      "Siber Mix: Türkçe Pop": [],
    };

    // Anahtar kelime sözlüğü
    final rapKeywords = ["rap", "hiphop", "ceza", "sagopa", "ezhel", "khontkar", "defkhan", "ben fero", "şehinşah", "beat", "drill", "uzi", "cakal", "reckol", "sansar", "hidra"];
    final bassKeywords = ["bass", "remix", "edm", "trap", "dj", "club", "mix", "k-391", "alan walker", "slowed", "reverb", "phonk", "electronic"];
    final melankolikKeywords = ["slow", "akustik", "cover", "duygusal", "aşk", "hüzün", "melankolik", "yavaş", "sad", "lofi"];
    final popKeywords = ["pop", "tarkan", "murat boz", "hadise", "edis", "zeynep", "hit", "türkçe pop", "gülşen"];

    for (String path in allSongPaths) {
      if (path.isEmpty || path == 'bilinmeyen_yol') continue;
      String fileName = path.split('/').last.split('\\').last.toLowerCase();

      bool added = false;
      
      // Rap kontrolü
      if (rapKeywords.any((k) => fileName.contains(k))) {
        generatedLists["Siber Mix: Rap & Hiphop"]!.add(path);
        added = true;
      }
      // Bass kontrolü
      if (bassKeywords.any((k) => fileName.contains(k))) {
        generatedLists["Siber Mix: Deep Bass & EDM"]!.add(path);
        added = true;
      }
      // Melankolik kontrolü
      if (melankolikKeywords.any((k) => fileName.contains(k))) {
        generatedLists["Siber Mix: Melankolik"]!.add(path);
        added = true;
      }
      // Pop kontrolü
      if (popKeywords.any((k) => fileName.contains(k))) {
        generatedLists["Siber Mix: Türkçe Pop"]!.add(path);
        added = true;
      }
    }

    // 3. Veritabanına Yaz
    int totalGenerated = 0;
    for (var entry in generatedLists.entries) {
      if (entry.value.isNotEmpty) {
        await _playlistService.createPlaylist(entry.key);
        for (String songPath in entry.value) {
          await _playlistService.addSongToPlaylist(entry.key, songPath);
        }
        totalGenerated++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Otonom Analiz Tamamlandı! $totalGenerated adet akıllı liste oluşturuldu."),
          backgroundColor: Colors.greenAccent.shade700,
        ),
      );
      Navigator.pop(context); // Çekmeceyi kapat ki listeleri görsün
    }
  }



  String _getSafeSongName(SongModel song) => safeSongTitle(song);

  Future<void> _playSong(SongModel song) async {
    if (!isPlayableSongPath(song.path)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu şarkı henüz hazır değil veya dosya bulunamadı.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return;
    }

    final targetList = _isEmergentMode ? _emergentPlaylist : _playlist;
    final playable =
        targetList.where((s) => isPlayableSongPath(s.path)).toList();
    final mediaItems = songsToMediaItems(playable);
    final index = playable.indexWhere((s) => s.path == song.path);
    if (index < 0) return;

    await audioHandler.updateQueue(mediaItems);
    await audioHandler.skipToQueueItem(index);
  }

  @override
  Widget build(BuildContext context) { final _themeColor = Theme.of(context).colorScheme.primary;
    if (!_isHandlerReady) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    // 🎯 SİBER GÖRSEL UYUM: Şarkı adına göre değil, analiz edilen RUH HALİNE göre renk mühürle!
    final vibe = VibeEngine.getPackageByMode(_waveType);
    List<SongModel> displayList = _isEmergentMode
        ? List<SongModel>.from(_emergentPlaylist)
        : _playlist.where(
            (s) {
              // 🛡️ SİBER KALKAN: Şarkı adı boşsa dosya yolunu kullan
              final safeName = _getSafeSongName(s).toLowerCase();
              final safeQuery = _searchQuery.toLowerCase();
              return safeName.contains(safeQuery);
            },
          ).toList();

    // 🎯 SİBER HAMLE: Otonom Sıralama Modeli
    if (_sortMode == 1) {
      displayList
          .sort((a, b) => _getSafeSongName(a).compareTo(_getSafeSongName(b)));
    } else if (_sortMode == 2) {
      displayList
          .sort((a, b) => _getSafeSongName(b).compareTo(_getSafeSongName(a)));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      drawer: Drawer(
        elevation: 0,
        backgroundColor: Colors.transparent, // 🎯 SİBER CAM EFEKTİ İÇİN ŞEFFAF
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75), // Biraz daha saydam
            border: Border(
                right: BorderSide(
                    color: vibe.themeColor.withOpacity(0.4), width: 2.0)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // 🎯 SİBER PROFİL (PREMİUM ÜYE)
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.white10,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: const Text('Premium Üye',
                        style: TextStyle(
                            color: Colors.amber, fontWeight: FontWeight.bold)),
                    subtitle: Text('Siber Karargah',
                        style: TextStyle(color: vibe.themeColor, fontSize: 12)),
                    onTap: () {
                      Navigator.pop(context); // Çekmeceyi kapat
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ProfileScreen()));
                    },
                  ),
                  const Divider(color: Colors.white24),

                  // 💎 YENİ: ÇİFTE KEŞFET RADARI
                  _buildDiscoveryPanel(vibe.themeColor),
                  const SizedBox(height: 15),


                  
                  // 🎯 KÜTÜPHANEM ANA BAŞLIĞI
                  Text(
                    "KÜTÜPHANEM",
                    style: TextStyle(
                      color: vibe.themeColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.0,
                      shadows: [Shadow(color: vibe.themeColor, blurRadius: 10)],
                    ),
                  ),
                  const SizedBox(height: 20),



                  // 🎯 SİBER İSTATİSTİK KARTLARI (Ruh Hali & Zirve Müzik)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        _buildSiberStatCard(
                          title: "ANLIK RUH HALİ",
                          value: _waveType,
                          icon: Icons.psychology,
                          color: vibe.themeColor,
                        ),
                        const SizedBox(width: 10),
                        _buildSiberStatCard(
                          title: "ZİRVE FREKANS",
                          value: _topHistorySongName,
                          icon: Icons.local_fire_department,
                          color: Colors.orangeAccent,
                          onTap: () {
                            if (_topHistorySongPath.isNotEmpty) {
                              Navigator.pop(context); // Çekmeceyi kapat
                              final s = SongModel(
                                  name: _topHistorySongName,
                                  path: _topHistorySongPath,
                                  duration: 0,
                                  title: _topHistorySongName);
                              if (!_playlist
                                  .any((x) => x.path == _topHistorySongPath)) {
                                setState(() => _playlist.insert(0, s));
                              }
                              _playSong(s);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 🎯 SİBER KOMUTA MERKEZİ (Ayarlar)
                  _buildSiberPanel(vibe.themeColor),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          NeonWaveBackground(
            isPlaying: _isPlaying,
            themeColor: vibe.themeColor,
            neonScale: _neonScale, // 🎯 GERÇEK RİTİM BAĞLANTISI
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(vibe.themeColor),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ModeIndicator(
                          isGlobalLibrary: _isEmergentMode
                              ? false
                              : _playlistController.isGlobalLibrary,
                          playlistTitle: _isEmergentMode
                              ? "SİBER OTONOM"
                              : (_playlistController.currentPlaylistName ??
                                  "Arşiv"),
                          themeColor: vibe.themeColor,
                          onClose: () => _isEmergentMode
                              ? setState(() => _isEmergentMode = false)
                              : _toggleLibraryView(null),
                        ),
                      ),
                      if (_isEmergentMode)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: IconButton(
                            icon: Icon(Icons.save, color: vibe.themeColor),
                            tooltip: "Otonom Listeyi Mühürle",
                            onPressed: () => _saveEmergentPlaylist(vibe.themeColor),
                          ),
                        ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () =>
                            _showPlaylistSelectorBottomSheet(vibe.themeColor),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: vibe.themeColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: vibe.themeColor.withOpacity(0.5),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: vibe.themeColor.withOpacity(0.2),
                                  blurRadius: 10)
                            ],
                          ),
                          child: Icon(Icons.music_note,
                              color: vibe.themeColor, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: NeonSearchBar(
                        themeColor: vibe.themeColor,
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    PopupMenuButton<int>(
                      icon: Icon(Icons.sort, color: vibe.themeColor),
                      color: Colors.grey[900],
                      tooltip: "Siber Sıralama",
                      onSelected: (val) => setState(() => _sortMode = val),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 0,
                            child: Text("Sırayı Bozma",
                                style: TextStyle(color: Colors.white))),
                        const PopupMenuItem(
                            value: 1,
                            child: Text("A'dan Z'ye",
                                style: TextStyle(color: Colors.white))),
                        const PopupMenuItem(
                            value: 2,
                            child: Text("Z'den A'ya",
                                style: TextStyle(color: Colors.white))),
                      ],
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(
                        milliseconds: 120), // 🎯 SİBER RİTİM: Akıcı geçiş
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.black
                            .withOpacity(0.35), // Daha zarif saydamlık
                        borderRadius:
                            BorderRadius.circular(25), // Yuvarlatma arttı
                        border: Border.all(
                            color: vibe.themeColor.withOpacity(
                                (0.25 * _neonScale).clamp(0.0, 1.0)),
                            width: 1.5 +
                                (_neonScale > 1.0 ? (_neonScale - 1.0) : 0)),
                        boxShadow: [
                          BoxShadow(
                              color: vibe.themeColor.withOpacity(
                                  (0.08 * _neonScale).clamp(0.0, 1.0)),
                              blurRadius: 20 * _neonScale,
                              spreadRadius: 2 +
                                  (5 *
                                      (_neonScale > 1.0
                                          ? _neonScale - 1.0
                                          : 0)))
                        ]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(
                            sigmaX: 12, sigmaY: 12), // Cam pürüzsüzleşti
                        child: _searchQuery.isNotEmpty
                            ? ListView.builder(
                                padding: const EdgeInsets.only(bottom: 110),
                                itemCount: displayList.length,
                                itemBuilder: (context, index) {
                                  final song = displayList[index];
                                  // 🎯 SİBER KALKAN: İsme göre değil, dosya yoluna (Parmak izine) göre eşleştirme!
                                  bool isSelected = _currentProcessedId ==
                                      (song.path ?? 'bilinmeyen_yol');
                                  return _buildSongTile(
                                      song, isSelected, vibe.themeColor);
                                },
                              )
                            : ReorderableListView.builder(
                                padding: const EdgeInsets.only(bottom: 110),
                                itemCount: displayList.length,
                                proxyDecorator: (child, index, animation) =>
                                    Material(
                                        color: Colors.transparent,
                                        child: child),
                                onReorder: (oldIndex, newIndex) {
                                  if (newIndex > oldIndex) newIndex -= 1;
                                  setState(() {
                                    _sortMode =
                                        0; // 🎯 SİBER HAMLE: Manuel sıralama yapıldığında oto-sıralamayı kapat!
                                    final item = displayList.removeAt(oldIndex);
                                    displayList.insert(newIndex, item);
                                    if (_isEmergentMode) {
                                      _emergentPlaylist = displayList;
                                    } else {
                                      _playlist = displayList;
                                    }
                                  });
                                  final mediaItems = displayList
                                      .map((s) => MediaItem(
                                            id: s.path ?? 'bilinmeyen_yol',
                                            album: "ÖZSES Arşivi",
                                            title: _getSafeSongName(s),
                                            artist: "Victus V7",
                                            duration: Duration(milliseconds: s.duration ?? 0),
                                          ))
                                      .toList();
                                  audioHandler.updateQueue(mediaItems);
                                },
                                itemBuilder: (context, index) {
                                  final song = displayList[index];
                                  // 🎯 SİBER KALKAN: Kaydırılabilir listede de Parmak İziyle eşleştirme!
                                  bool isSelected = _currentProcessedId ==
                                      (song.path ?? 'bilinmeyen_yol');
                                  return _buildSongTile(
                                      song, isSelected, vibe.themeColor);
                                },
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_currentSongName != 'Müzik Seçilmedi')
            Builder(builder: (context) {
              final currentList =
                  _isEmergentMode ? _emergentPlaylist : _playlist;
              final currentSong = currentList.firstWhere(
                  (s) => _getSafeSongName(s) == _currentSongName,
                  orElse: () => SongModel(
                      name: '',
                      path: 'bilinmeyen_yol',
                      duration: 0,
                      title: ''));
              final isCurrentFav = _favoritePaths.contains(currentSong.path);
              return Positioned(
                bottom: 15,
                left: 15,
                right: 15,
                child: AnimatedContainer(
                  duration: const Duration(
                      milliseconds: 120), // 🎯 SİBER RİTİM MOTORU
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                          color: vibe.themeColor
                              .withOpacity((0.6 * _neonScale).clamp(0.0, 1.0)),
                          width: 1.5 +
                              (_neonScale > 1.0 ? (_neonScale - 1.0) * 2 : 0)),
                      boxShadow: [
                        BoxShadow(
                            color: vibe.themeColor.withOpacity(
                                (0.3 * _neonScale).clamp(0.0, 1.0)),
                            blurRadius: 20 * _neonScale,
                            spreadRadius: 2 +
                                (8 * (_neonScale > 1.0 ? _neonScale - 1.0 : 0)))
                      ]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: StreamBuilder<Duration>(
                        // 🎯 YUSUF USTA HAMLESİ: StreamBuilder ile kasmayan Slider
                        stream: AudioService.position,
                        builder: (context, posSnapshot) {
                          final currentPos = posSnapshot.data ?? _pos;
                          return BottomPlayerBar(
                            songName: _currentSongName,
                            artistName: _currentArtist,
                            coverBytes: _currentCoverBytes,
                            themeColor: vibe.themeColor,
                            position: currentPos,
                            duration: _dur,
                            isPlaying: _isPlaying,
                            isBuffering: _isBuffering,
                            isShuffle: _isShuffle,
                            isFavorite: isCurrentFav,
                            onFavoriteToggle: () =>
                                _toggleFavorite(currentSong),
                            trailingAccessory: MiniEqVisualizer(
                              themeColor: vibe.themeColor,
                              isPlaying: _isPlaying,
                            ),
                            repeatMode: _repeatMode,
                            onPlayPause: () => _isPlaying
                                ? audioHandler.pause()
                                : audioHandler.play(),
                            onNext: () => audioHandler.skipToNext(),
                            onPrevious: () => audioHandler.skipToPrevious(),
                            onSeek: (v) =>
                                audioHandler.seek(Duration(seconds: v.toInt())),
                            onShuffleToggle: () {
                              setState(() => _isShuffle = !_isShuffle);
                              audioHandler.setShuffleMode(_isShuffle
                                  ? AudioServiceShuffleMode.all
                                  : AudioServiceShuffleMode.none);
                            },
                            onRepeatToggle: () {
                              int nextMode = (_repeatMode + 1) % 3;
                              setState(() => _repeatMode = nextMode);
                              if (nextMode == 1) {
                                audioHandler
                                    .setRepeatMode(AudioServiceRepeatMode.one);
                              } else if (nextMode == 2) {
                                audioHandler
                                    .setRepeatMode(AudioServiceRepeatMode.all);
                              } else {
                                audioHandler
                                    .setRepeatMode(AudioServiceRepeatMode.none);
                              }
                            },
                            onExpand: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => FullScreenPlayer(
                                  themeColor: vibe.themeColor,
                                  checkIsFavorite: (path) =>
                                      _favoritePaths.contains(path),
                                  onToggleFavorite: (path) {
                                    final song = _playlist.firstWhere(
                                        (s) => s.path == path,
                                        orElse: () => SongModel(
                                            name: '',
                                            path: path,
                                            duration: 0,
                                            title: ''));
                                    if (song.path != 'bilinmeyen_yol')
                                      _toggleFavorite(song);
                                  },
                                  onAddToPlaylist: (path) =>
                                      _showAddToPlaylistDialog(path),
                                  onDelete: (path) {
                                    final song = _playlist.firstWhere(
                                        (s) => s.path == path,
                                        orElse: () => SongModel(
                                            name: '',
                                            path: path,
                                            duration: 0,
                                            title: ''));
                                    if (song.path != 'bilinmeyen_yol') {
                                      _deleteSong(song, path);
                                      Navigator.pop(context);
                                    }
                                  },
                                  onAddQueue: (path, playNext) {
                                    final song = _playlist.firstWhere(
                                        (s) => s.path == path,
                                        orElse: () => SongModel(
                                            name: '',
                                            path: path,
                                            duration: 0,
                                            title: ''));
                                    if (song.path != 'bilinmeyen_yol')
                                      _addSongToQueue(song, playNext);
                                  },
                                ),
                              );
                            },
                            onShowQueue: () =>
                                _showQueueBottomSheet(vibe.themeColor),
                            onClose: () {
                              audioHandler.stop();
                              setState(
                                  () => _currentSongName = 'Müzik Seçilmedi');
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            })
        ],
      ),
    );
  }

  // --- Widget Fonksiyonları ---

  // 🎯 SİBER HAMLE: Çifte Keşfet (Radar) Paneli
  Widget _buildDiscoveryPanel(Color themeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: themeColor.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                iconColor: themeColor,
                collapsedIconColor: Colors.white70,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.15),
                      shape: BoxShape.circle),
                  child: Icon(Icons.radar, color: themeColor, size: 20),
                ),
                title: const Text(
                  "KEŞFET",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8.0),
                    child: Column(
                      children: [
                        _buildNeonButton(
                          icon: Icons.travel_explore,
                          label: "ŞAHSİ KEŞFET",
                          themeColor: Colors.purpleAccent,
                          onPressed: () => _launchPersonalDiscover(themeColor),
                        ),
                        _buildNeonButton(
                          icon: Icons.new_releases,
                          label: "GENEL KEŞFET",
                          themeColor: Colors.cyanAccent,
                          onPressed: () => _scanNewRecruits(themeColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSiberPanel(Color themeColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5), // Buzul Cam Etkisi
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: themeColor.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                iconColor: themeColor,
                collapsedIconColor: Colors.white70,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.15),
                      shape: BoxShape.circle),
                  child: Icon(Icons.settings, color: themeColor, size: 20),
                ),
                title: const Text(
                  "ARAÇLAR VE AYARLAR",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8.0),
                    child: Column(
                      children: [
                        _buildNeonButton(
                          icon: Icons.waves,
                          label: "DİNLEME MODU",
                          themeColor: themeColor,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ListeningModeScreen(),
                              ),
                            );
                          },
                        ),

                        _buildNeonButton(
                          icon: Icons.folder_special,
                          label: "CİHAZDAN MÜZİK EKLE",
                          themeColor: themeColor,
                          onPressed: _scanFolderForMusic,
                        ),
                        // 🎯 SİBER HAMLE: Otonom Yapay Zeka Butonu
                        _buildNeonButton(
                          icon: Icons.auto_fix_high,
                          label: "YAPAY ZEKA LİSTELERİ YAP",
                          themeColor: Colors.amber, // Zeka olduğunu belli eden altın renk
                          onPressed: () => _generateAIPlaylists(themeColor),
                        ),
                        _buildNeonButton(
                          icon: Icons.timer_outlined,
                          label: "UYKU ZAMANLAYICI",
                          themeColor: themeColor,
                          onPressed: () =>
                              _showTimerDialog(context, themeColor),
                        ),


                        _buildNeonButton(
                          icon: Icons.history,
                          label: "DİNLEME GEÇMİŞİ",
                          themeColor: themeColor,
                          onPressed: () => _showHistoryBottomSheet(themeColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🎯 SİBER HAMLE: Playlist Oluşturma Tipi Seçim Ekranı
  void _showPlaylistTypeSelectionDialog(BuildContext context, Color themeColor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: themeColor, width: 2),
          ),
          title: Row(
            children: [
              Icon(Icons.library_add, color: themeColor),
              const SizedBox(width: 10),
              const Text("Yeni Playlist Tipi", style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.cyanAccent, size: 28),
                title: const Text("Manuel Oluştur", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text("Boş bir liste açıp şarkıları tek tek ekleyin.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                tileColor: Colors.black45,
                onTap: () {
                  Navigator.pop(context);
                  _showCreateDialog(context, themeColor);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.auto_awesome, color: Colors.orangeAccent, size: 28),
                title: const Text("Siber Zeka (Otonom)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text("Ruh halinize ve müzik türüne göre otomatik liste hazırlasın.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                tileColor: Colors.black45,
                onTap: () {
                  Navigator.pop(context);
                  _showOfflineAutoPlaylistDialog(context, themeColor);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 🎯 SİBER HAMLE: Çevrimdışı Kütüphane İçin Hızlı Otomatik Liste Menüsü
  void _showOfflineAutoPlaylistDialog(BuildContext context, Color themeColor) {
    final List<Map<String, dynamic>> moods = [
      {"name": "Melankolik", "icon": Icons.water_drop, "color": Colors.blueAccent},
      {"name": "Efkârlı", "icon": Icons.smoke_free, "color": Colors.grey},
      {"name": "Enerjik", "icon": Icons.local_fire_department, "color": Colors.orangeAccent},
      {"name": "Kopmalık", "icon": Icons.celebration, "color": Colors.amberAccent},
      {"name": "Rahatlatıcı", "icon": Icons.spa, "color": Colors.tealAccent},
      {"name": "Odaklanma", "icon": Icons.psychology_alt, "color": Colors.green},
      {"name": "Motivasyon", "icon": Icons.fitness_center, "color": Colors.red},
      {"name": "Nostaljik", "icon": Icons.history_toggle_off, "color": Colors.brown},
      {"name": "İsyankâr", "icon": Icons.bolt, "color": Colors.deepPurpleAccent},
      {"name": "Uyku Öncesi", "icon": Icons.nights_stay, "color": Colors.indigo},
    ];

    final List<Map<String, dynamic>> genres = [
      {"name": "Türkçe Pop", "icon": Icons.star, "color": Colors.pinkAccent},
      {"name": "Yabancı Pop", "icon": Icons.public, "color": Colors.lightBlueAccent},
      {"name": "Arabesk", "icon": Icons.local_drink, "color": Colors.purpleAccent},
      {"name": "Sokak Ritmi (Rap)", "icon": Icons.sports_kabaddi, "color": Colors.redAccent},
      {"name": "Rock & Metal", "icon": Icons.album, "color": Colors.blueGrey},
      {"name": "Anadolu Rock", "icon": Icons.landscape, "color": Colors.orange},
      {"name": "Türkü", "icon": Icons.music_video, "color": Colors.brown},
      {"name": "Akustik", "icon": Icons.music_note, "color": Colors.lime},
      {"name": "Elektronik / EDM", "icon": Icons.graphic_eq, "color": Colors.cyanAccent},
      {"name": "Klasik Müzik", "icon": Icons.piano, "color": Colors.amber},
    ];

    Widget buildSection(String title, List<Map<String, dynamic>> items, IconData titleIcon) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(titleIcon, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              return ActionChip(
                backgroundColor: Colors.black45,
                side: BorderSide(color: item["color"].withOpacity(0.5)),
                avatar: Icon(item["icon"], color: item["color"], size: 16),
                label: Text(item["name"], style: const TextStyle(color: Colors.white, fontSize: 13)),
                onPressed: () {
                  Navigator.pop(context);
                  _handleOfflineAutoPlaylist(item["name"], themeColor);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: themeColor, width: 2),
          ),
          title: Row(
            children: [
              Icon(Icons.auto_awesome, color: themeColor),
              const SizedBox(width: 10),
              const Text("Siber Liste Oluştur", style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSection("Ruh Haline Göre", moods, Icons.psychology),
                  buildSection("Müzik Türüne Göre", genres, Icons.album),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNeonButton({
    required IconData icon,
    required String label,
    required Color themeColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: themeColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter:
              ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Hafif cam efekti
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              splashColor: themeColor.withOpacity(0.2),
              highlightColor: themeColor.withOpacity(0.1),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    Icon(icon, color: themeColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: themeColor.withOpacity(0.6), size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  // 🎯 SİBER HAMLE: Çevrimdışı (İndirilenler) İçin Otonom Liste Motoru
  // 🎯 SİBER HAMLE: Çevrimdışı (İndirilenler) İçin Otonom Liste Motoru
  void _handleOfflineAutoPlaylist(String selection, Color themeColor) {
    if (_playlist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text("Siber Hata: Cihazınızda hiç şarkı yok!"),
        backgroundColor: Colors.redAccent.withOpacity(0.8),
      ));
      return;
    }

    // Basit bir isme göre filtreleme yapıyoruz (Gerçek Zeka entegrasyonu ileride yerel dosyalara inebilir)
    final keyword = selection.toLowerCase().split(' ')[0]; // Örn: 'Türkçe Pop' -> 'türkçe', 'Melankolik' -> 'melankolik'
    List<SongModel> filteredSongs = _playlist.where((song) {
      return (song.title?.toLowerCase().contains(keyword) ?? false) || (song.artist?.toLowerCase().contains(keyword) ?? false);
    }).toList();

    // Eğer tam eşleşme bulunamazsa (örn: 'Parti' kelimesi geçmiyorsa), tüm şarkıları karıştırıp hissi vermek için ilk 10'unu al
    if (filteredSongs.isEmpty) {
      filteredSongs = List.from(_playlist)..shuffle();
      filteredSongs = filteredSongs.take(15).toList();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Siber Zeka: '$selection' için çevrimdışı arşivinizden uygun şarkılar harmanlandı!"),
        backgroundColor: themeColor.withOpacity(0.8),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text("🎵 Çevrimdışı Otonom Liste hazır! Çalınmaya başlanıyor..."),
        backgroundColor: themeColor.withOpacity(0.8),
      ));
    }

    setState(() {
      _emergentPlaylist = filteredSongs;
      _isEmergentMode = true;
      _waveType = selection; // Otonom hissini artırmak için dalga modunu seçime eşitle
    });

    // Seçilen şarkıları sırayla çal
    _playSong(filteredSongs[0]);
  }

  // 🎯 SİBER HAMLE: Otonom Listeyi Kalıcı Olarak Mühürleme (Kaydetme)
  void _saveEmergentPlaylist(Color themeColor) {
    if (_emergentPlaylist.isEmpty) return;
    
    final TextEditingController tc = TextEditingController(text: "$_waveType Mix");
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: themeColor.withOpacity(0.5)),
          ),
          title: Text("OTONOM LİSTEYİ MÜHÜRLE",
              style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: tc,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Bir liste adı girin...",
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepPurple)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return "Liste adı boş olamaz!";
                if (!RegExp(r'^[a-zA-Z0-9 ğüşöçİĞÜŞÖÇ]+$').hasMatch(value)) return "Özel karakter kullanılamaz!";
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor.withOpacity(0.5),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final pName = tc.text.trim();
                  if (pName.isNotEmpty) {
                    await _playlistService.createPlaylist(pName);
                    for (var song in _emergentPlaylist) {
                      if (song.path != null) {
                        await _playlistService.addSongToPlaylist(pName, song.path!);
                      }
                    }
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Siber Başarı: '$pName' başarıyla mühürlendi!"),
                        backgroundColor: Colors.greenAccent,
                      ));
                      setState(() {
                        _isEmergentMode = false;
                      });
                      await _toggleLibraryView(pName);
                    }
                  }
                }
              },
              child: const Text("Mühürle", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSiberStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 1),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(Color themeColor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ÖZSES V7",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      shadows: [Shadow(color: themeColor, blurRadius: 10)]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // 🎯 SİBER YAPAY ZEKA: Anlık ruh hali burada!
                Text(
                  "Ruh Hali: $_waveType",
                  style: TextStyle(
                    color: themeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // 🎯 SİBER HAMLE: Canlı Geri Sayım Göstergesi (Sadece aktifse görünür)
          ValueListenableBuilder<int>(
            valueListenable: globalSleepTimer,
            builder: (context, remainingSeconds, child) {
              if (remainingSeconds <= 0) return const SizedBox.shrink();
              final minutes = (remainingSeconds / 60).floor();
              final seconds = remainingSeconds % 60;
              return Container(
                margin: const EdgeInsets.only(right: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.redAccent.withOpacity(0.8), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.15),
                      blurRadius: 25,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Row(
                      children: [
                        const Icon(Icons.timer,
                            color: Colors.redAccent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}",
                          style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // 🎙️ SESLİ KOMUT BUTONU
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.mic_rounded, color: themeColor, size: 26),
              tooltip: 'Sesli Komut',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => SiberSesliKomutSheet(
                    themeColor: themeColor,
                    onSearchCommand: (query) {
                      setState(() => _searchQuery = query);
                    },
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.psychology, color: themeColor, size: 28),
            tooltip: "Kişisel İstihbarat Raporu",
            onPressed: () => _showIntelligenceBottomSheet(themeColor),
          ),
        ],
      ),
    );
  }

  // 🎯 SİBER HAMLE: Şarkıyı Özel Playlist'e Mühürleme Ekranı
  void _showAddToPlaylistDialog(String songPath) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController tc = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.deepPurpleAccent, width: 1),
          ),
          title: const Text(
            "PLAYLİST'E MÜHÜRLE",
            style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: TextFormField(
                controller: tc,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Var olan bir liste adı girin...",
                  hintStyle: TextStyle(color: Colors.white38),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.deepPurple)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.cyanAccent)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Liste adı boş olamaz usta!";
                  }
                  if (!RegExp(r'^[a-zA-Z0-9 ğüşöçİĞÜŞÖÇ]+$').hasMatch(value)) {
                    return "Özel karakter kullanılamaz!";
                  }
                  return null;
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("İptal", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent.withOpacity(0.5),
                side: const BorderSide(color: Colors.cyanAccent),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final pName = tc.text.trim();
                  if (pName.isNotEmpty) {
                    // 🛡️ SİBER KALKAN: Sadece var olan listelere eklemeye izin ver!
                    final existingPlaylists =
                        await _playlistService.getAllPlaylistNames();
                    if (!existingPlaylists.contains(pName)) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "Siber Hata: '$pName' adında mühürlü bir liste yok!"),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                      return;
                    }

                    await _playlistService.addSongToPlaylist(pName, songPath);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "Müzik başarıyla '$pName' listesine mühürlendi!"),
                          backgroundColor: Colors.greenAccent,
                        ),
                      );
                    }
                  }
                }
              },
              child:
                  const Text("Mühürle", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // 🎯 SİBER HAMLE: Şarkı Silme Operasyonu (Hem kaydırarak hem 3 noktadan)
  Future<void> _deleteSong(SongModel song, String safePath) async {
    // 1. UI'dan anında yok et (Hız için)
    setState(() {
      _playlist.remove(song);
      if (_isEmergentMode) _emergentPlaylist.remove(song);
    });

    // 🎯 SİBER HAMLE: Oynatıcı kuyruğundan da otonom sök at!
    final queueItems = audioHandler.queue.value;
    for (var item in queueItems) {
      if (item.id == safePath) {
        audioHandler.removeQueueItem(item);
      }
    }

    // 2. Arka planda mühürleri sök (Eğer bir playlist içindeysek)
    if (_playlistController.currentPlaylistName != null) {
      await _playlistService.removeSongFromPlaylist(
        _playlistController.currentPlaylistName!,
        safePath,
      );
    }

    // 🎯 SİBER HAMLE: Şarkı silinince kalıcı arşivden de kaldır
    final globalSongs = await loadGlobalLibrarySongs();
    globalSongs.removeWhere((s) => s.path == safePath);
    await saveGlobalLibrarySongs(globalSongs);
    try {
      final file = File(safePath);
      if (await file.exists()) await file.delete();
      final lrcFile = File(safePath.replaceAll(RegExp(r'\.[^.]+$'), '.lrc'));
      if (await lrcFile.exists()) await lrcFile.delete();
    } catch (e) {}

    if (!mounted) return; // 🛡️ SİBER KALKAN: Güvenli çıkış
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${_getSafeSongName(song)} sistemden söküldü!"),
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 🎯 SİBER HAMLE: Şarkıyı Aktif Kuyruğa (Play Next / Add to Queue) Ekleme
  Future<void> _addSongToQueue(SongModel song, bool playNext) async {
    final safePath = song.path ?? 'bilinmeyen_yol';
    if (safePath == 'bilinmeyen_yol') return;

    final mediaItem = MediaItem(
      id: safePath,
      album: "ÖZSES Arşivi",
      title: _getSafeSongName(song),
      artist: "Victus V7",
    );

    if (playNext) {
      // Sıradakine ekle (Mevcut indexin 1 fazlası)
      int nextIndex = (audioHandler.playbackState.value.queueIndex ?? 0) + 1;
      await audioHandler.insertQueueItem(nextIndex, mediaItem);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("${mediaItem.title} sıradakine mühürlendi!"),
            backgroundColor: Colors.cyanAccent,
            duration: const Duration(seconds: 1)));
      }
    } else {
      // En sona ekle
      await audioHandler.addQueueItem(mediaItem);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("${mediaItem.title} kuyruğun sonuna mühürlendi!"),
            backgroundColor: Colors.greenAccent,
            duration: const Duration(seconds: 1)));
      }
    }
  }

  Widget _buildSongTile(SongModel song, bool isSelected, Color themeColor) {
    // 🛡️ SİBER KALKAN: ListTile ve ValueKey için güvenli değerler
    final safePath = song.path ?? 'bilinmeyen_yol';
    final safeName = _getSafeSongName(song); // Siber İsim Çözücü kullanıldı
    final bool isFav = _favoritePaths.contains(safePath); // Bu şarkı favori mi?

    bool isDownloading = safePath.startsWith('downloading:');
    String videoId = isDownloading ? safePath.substring(12) : '';
    Map<String, dynamic>? dTask =
        isDownloading ? _downloadingTasks[videoId] : null;

    return Slidable(
      key: ValueKey(safePath.isNotEmpty ? safePath : song.hashCode.toString()),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed:
                isDownloading ? null : (context) => _deleteSong(song, safePath),
            backgroundColor: Colors.redAccent.withOpacity(0.8),
            icon: Icons.delete,
            label: 'Sök At',
          ),
        ],
      ),
      child: Opacity(
        opacity:
            isDownloading ? 0.4 : 1.0, // 🎯 Şarkı inerken mat görüntü (%40)
        child: AnimatedContainer(
          duration: const Duration(
              milliseconds: 120), // 🎯 SİBER RİTİM: Şarkı kartı nefes alır
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: isSelected
              ? BoxDecoration(
                  color: themeColor
                      .withOpacity((0.08 * _neonScale).clamp(0.0, 1.0)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: themeColor
                          .withOpacity((0.8 * _neonScale).clamp(0.0, 1.0)),
                      width: 1.5 + (_neonScale > 1.0 ? _neonScale - 1.0 : 0)),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor
                          .withOpacity((0.3 * _neonScale).clamp(0.0, 1.0)),
                      blurRadius: 12 * _neonScale,
                      spreadRadius:
                          1 + (3 * (_neonScale > 1.0 ? _neonScale - 1.0 : 0)),
                    ),
                    BoxShadow(
                      // Şarkı kartından taşan dalga
                      color: themeColor
                          .withOpacity((0.15 * _neonScale).clamp(0.0, 1.0)),
                      blurRadius: 25 * _neonScale,
                      spreadRadius: 8 * _neonScale,
                    ),
                  ],
                )
              : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: isSelected
                  ? ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8)
                  : ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: InkWell(
                onTap: isDownloading ? null : () => _playSong(song),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      isSelected
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: MiniEqVisualizer(
                                themeColor: themeColor,
                                isPlaying: _isPlaying,
                              ),
                            )
                          : const Icon(Icons.music_note, color: Colors.white24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              safeName,
                              style: TextStyle(
                                color: isSelected ? themeColor : Colors.white,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isDownloading && dTask != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  "📥 İniyor: ${dTask['percent']}  •  ${dTask['mb']}",
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!isDownloading)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert,
                              color: isSelected ? themeColor : Colors.white54),
                          color: Colors.grey[900],
                          onSelected: (value) {
                            if (value == 'add_playlist') {
                              _showAddToPlaylistDialog(safePath);
                            } else if (value == 'favorite') {
                              _toggleFavorite(song);
                            } else if (value == 'delete') {
                              _deleteSong(song, safePath);
                            } else if (value == 'play_next') {
                              _addSongToQueue(song, true);
                            } else if (value == 'add_queue') {
                              _addSongToQueue(song, false);
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem(
                              value: 'favorite',
                              child: Row(
                                children: [
                                  Icon(
                                      isFav
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: Colors.redAccent,
                                      size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                      isFav
                                          ? "Favorilerden Çıkar"
                                          : "Favorilere Ekle",
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 13)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'play_next',
                              child: Row(
                                children: [
                                  Icon(Icons.queue_play_next,
                                      color: Colors.cyanAccent, size: 20),
                                  SizedBox(width: 8),
                                  Text("Sıradakini Çal",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 13)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'add_queue',
                              child: Row(
                                children: [
                                  Icon(Icons.playlist_add_circle,
                                      color: Colors.greenAccent, size: 20),
                                  SizedBox(width: 8),
                                  Text("Kuyruğa Ekle",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 13)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'add_playlist',
                              child: Row(
                                children: [
                                  Icon(Icons.playlist_add,
                                      color: Colors.cyanAccent, size: 20),
                                  SizedBox(width: 8),
                                  Text("Playlist'e Ekle",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 13)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline,
                                      color: Colors.redAccent, size: 20),
                                  SizedBox(width: 8),
                                  Text("Sök At (Sil)",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ), // 🎯 SİBER KALKAN: Opacity kapanış mührü
      ),
    );
  }

  // 🎯 SİBER HAMLE: Otonom Playlist Seçici Paneli
  void _showPlaylistSelectorBottomSheet(Color themeColor) async {
    final playlists = await _playlistService.getAllPlaylistNames();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: themeColor.withOpacity(0.5), width: 1),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 5),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10)),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.library_music, color: themeColor, size: 24),
                        const SizedBox(width: 8),
                        Text("SİBER PLAYLİSTLER",
                            style: TextStyle(
                                color: themeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1.2)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          color: Colors.cyanAccent),
                      tooltip: "Yeni Playlist Oluştur",
                      onPressed: () {
                        Navigator.pop(context);
                        _showPlaylistTypeSelectionDialog(context, themeColor);
                      },
                    )
                  ],
                ),
              ),
              const Divider(color: Colors.white10),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: Icon(Icons.all_inclusive, color: themeColor),
                      title: const Text("Ana Arşiv (Tüm Müzikler)",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      trailing:
                          _playlistController.currentPlaylistName == null &&
                                  !_isEmergentMode
                              ? Icon(Icons.check_circle, color: themeColor)
                              : null,
                      onTap: () {
                        Navigator.pop(context);
                        _toggleLibraryView(null);
                      },
                    ),
                    const Divider(color: Colors.white10),
                    ...playlists.map((pName) {
                      final isCurrent =
                          _playlistController.currentPlaylistName == pName &&
                              !_isEmergentMode;
                      return ListTile(
                        leading: Icon(Icons.queue_music,
                            color: isCurrent ? themeColor : Colors.white54),
                        title: Text(pName,
                            style: TextStyle(
                                color: isCurrent ? themeColor : Colors.white,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                        trailing: isCurrent
                            ? Icon(Icons.check_circle, color: themeColor)
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          _toggleLibraryView(pName);
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- DİALOG METOTLARI (Ayarlar Paneli İçin) ---
  void _showTimerDialog(BuildContext context, Color themeColor) {
    final TextEditingController tc = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: themeColor.withOpacity(0.5)),
        ),
        title: Text("UYKU ZAMANLAYICI",
            style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _timerOption(context, "15 Dakika", 15, themeColor),
              _timerOption(context, "30 Dakika", 30, themeColor),
              _timerOption(context, "60 Dakika", 60, themeColor),
              const Divider(color: Colors.white24),
              TextField(
                controller: tc,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Manuel dakika girin...",
                  hintStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: themeColor.withOpacity(0.5))),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: themeColor)),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.play_circle_fill, color: themeColor),
                    onPressed: () {
                      final int? minutes = int.tryParse(tc.text);
                      if (minutes != null && minutes > 0) {
                        startSleepTimer(minutes);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  "Sistem $minutes dakika sonra mühürlenecek."),
                              backgroundColor: themeColor),
                        );
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _timerOption(context, "İptal Et", 0, themeColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timerOption(
      BuildContext context, String title, int minutes, Color themeColor) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        startSleepTimer(minutes);
        if (minutes > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Sistem $minutes dakika sonra mühürlenecek."),
                backgroundColor: themeColor),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Zamanlayıcı iptal edildi."),
                backgroundColor: Colors.redAccent),
          );
        }
        Navigator.pop(context);
      },
    );
  }

  void _showCreateDialog(BuildContext context, Color themeColor) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: themeColor.withOpacity(0.5)),
        ),
        title: Text("Yeni Playlist", style: TextStyle(color: themeColor)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Liste adı...",
                hintStyle: const TextStyle(color: Colors.white30),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: themeColor)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty)
                  return "Liste adı boş olamaz usta!";
                if (!RegExp(r'^[a-zA-Z0-9 ğüşöçİĞÜŞÖÇ]+$').hasMatch(value)) {
                  return "Özel karakter kullanılamaz!";
                }
                return null;
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newName = controller.text.trim();
                final existingPlaylists =
                    await _playlistService.getAllPlaylistNames();
                if (existingPlaylists.contains(newName)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "Siber Hata: '$newName' adında bir liste zaten mühürlenmiş usta!"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                await _playlistService.createPlaylist(newName);
                if (context.mounted) {
                  Navigator.pop(context);
                  _toggleLibraryView(
                      newName); // 🎯 Yeni oluşturulan listeye otonom geçiş yap
                }
              }
            },
            child: Text("Oluştur", style: TextStyle(color: themeColor)),
          ),
        ],
      ),
    );
  }

  // 🎯 SİBER HAMLE: Alttan Açılan Kuyruk Paneli (Bottom Sheet)
  void _showQueueBottomSheet(Color themeColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: themeColor.withOpacity(0.5), width: 1),
      ),
      builder: (context) {
        return StreamBuilder<List<MediaItem>>(
          stream: audioHandler.queue,
          builder: (context, snapshot) {
            final queue = snapshot.data ?? [];
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 5),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.queue_music, color: themeColor, size: 20),
                      const SizedBox(width: 8),
                      Text("ÇALMA KUYRUĞU (${queue.length})",
                          style: TextStyle(
                              color: themeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10),
                if (queue.isEmpty)
                  const Expanded(
                      child: Center(
                          child: Text("Kuyruk boş usta!",
                              style: TextStyle(color: Colors.white54))))
                else
                  Expanded(
                    child: StreamBuilder<PlaybackState>(
                        stream: audioHandler.playbackState,
                        builder: (context, stateSnapshot) {
                          final currentIndex =
                              stateSnapshot.data?.queueIndex ?? -1;
                          return ReorderableListView.builder(
                            itemCount: queue.length,
                            proxyDecorator: (child, index, animation) =>
                                Material(
                                    color: Colors.transparent, child: child),
                            onReorder: (oldIndex, newIndex) {
                              if (newIndex > oldIndex) newIndex -= 1;
                              audioHandler.moveQueueItem(oldIndex, newIndex);
                            },
                            itemBuilder: (context, index) {
                              final item = queue[index];
                              final isPlaying = index == currentIndex;
                              return ListTile(
                                key: ValueKey(item
                                    .hashCode), // 🛡️ SİBER KALKAN: Reorder için eşsiz mühür şart
                                leading: isPlaying
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: MiniEqVisualizer(
                                          themeColor: themeColor,
                                          isPlaying:
                                              _isPlaying, // Şarkı durursa animasyon da dursun
                                        ),
                                      )
                                    : const Icon(Icons.music_note,
                                        color: Colors.white24),
                                title: Text(item.title,
                                    style: TextStyle(
                                        color: isPlaying
                                            ? themeColor
                                            : Colors.white,
                                        fontSize: 13,
                                        fontWeight: isPlaying
                                            ? FontWeight.bold
                                            : FontWeight.normal),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(item.artist ?? "Bilinmeyen",
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 11)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: Colors.redAccent, size: 20),
                                  onPressed: () =>
                                      audioHandler.removeQueueItem(item),
                                ),
                                onTap: () {
                                  audioHandler.skipToQueueItem(index);
                                  audioHandler.play();
                                },
                              );
                            },
                          );
                        }),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // 🎯 SİBER HAMLE: Alttan Açılan Geçmiş (History) Paneli
  void _showHistoryBottomSheet(Color themeColor) async {
    final historyList = await HistoryService.getHistory();
    if (!mounted) return;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.black.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: themeColor.withOpacity(0.5), width: 1),
        ),
        builder: (context) {
          return StatefulBuilder(builder: (context, setModalState) {
            return SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 5),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.history, color: themeColor, size: 24),
                            const SizedBox(width: 8),
                            Text("DİNLEME GEÇMİŞİ",
                                style: TextStyle(
                                    color: themeColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    letterSpacing: 1.2)),
                          ],
                        ),
                        IconButton(
                            icon: const Icon(Icons.delete_sweep,
                                color: Colors.redAccent),
                            tooltip: "Geçmişi Sök At",
                            onPressed: () async {
                              await HistoryService.clearHistory();
                              setModalState(() => historyList.clear());
                            })
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  if (historyList.isEmpty)
                    const Expanded(
                        child: Center(
                            child: Text("Siber geçmiş tertemiz usta!",
                                style: TextStyle(color: Colors.white54))))
                  else
                    Expanded(
                      child: ListView.builder(
                          itemCount: historyList.length,
                          itemBuilder: (context, index) {
                            final item = historyList[index];
                            final mins = item.totalListenSeconds ~/ 60;
                            final secs = item.totalListenSeconds % 60;
                            return ListTile(
                              leading: Icon(Icons.music_note,
                                  color: themeColor.withOpacity(0.6)),
                              title: Text(item.name,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                  "${item.playCount} Kez Mühürlendi • Toplam: $mins Dk $secs Sn",
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 11)),
                              onTap: () {
                                Navigator.pop(context);
                                final s = SongModel(
                                    name: item.name,
                                    path: item.path,
                                    duration: 0,
                                    title: item.name);
                                if (!_playlist
                                    .any((x) => x.path == item.path)) {
                                  setState(() => _playlist.insert(0, s));
                                }
                                _playSong(s);
                              },
                            );
                          }),
                    )
                ]));
          });
        });
  }

  // 🎯 SİBER HAMLE: Şarkı Adından Ruh Hali Analizi (Geçici/Emaneten)
  String _analyzeSongMoodFromName(String name) {
    final n = name.toLowerCase();
    // Efkarlı / Hüzünlü
    if (n.contains('aşk') ||
        n.contains('sevda') ||
        n.contains('gitti') ||
        n.contains('ayrılık') ||
        n.contains('hüzün') ||
        n.contains('acı') ||
        n.contains('kalp')) {
      return "Melankolik";
    }
    // Hareketli / Enerjik
    if (n.contains('dans') ||
        n.contains('party') ||
        n.contains('club') ||
        n.contains('enerji') ||
        n.contains('hadi') ||
        n.contains('kop')) {
      return "Enerjik";
    }
    // Rap / Sokak
    if (n.contains('sokak') ||
        n.contains('mahalle') ||
        n.contains('trap') ||
        n.contains('drill') ||
        n.contains('rap')) {
      return "Sokak Ritmi";
    }
    // Sakin / Akustik
    if (n.contains('akustik') ||
        n.contains('unplugged') ||
        n.contains('yavaş') ||
        n.contains('sakin') ||
        n.contains('slow')) {
      return "Akustik";
    }
    return "Dengeli";
  }

  // 🎯 SİBER HAMLE: Kişisel İstihbarat ve Analiz Paneli (Bottom Sheet)
  void _showIntelligenceBottomSheet(Color themeColor) async {
    final historyList = await HistoryService.getHistory();

    // İstihbarat Verilerini Hesapla
    int totalSeconds = 0;
    for (var item in historyList) {
      totalSeconds += item.totalListenSeconds;
    }
    int totalMinutes = totalSeconds ~/ 60;
    int totalHours = totalMinutes ~/ 60;

    // Ruh Hali Analizi
    final Map<String, int> moodDurations = {};
    for (var item in historyList) {
      final mood = _analyzeSongMoodFromName(item.name);
      moodDurations[mood] =
          (moodDurations[mood] ?? 0) + item.totalListenSeconds;
    }
    final sortedMoods = moodDurations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Rütbe Sistemi
    String rank = "Acemi Dinleyici";
    IconData rankIcon = Icons.star_border;
    Color rankColor = Colors.white54;

    if (totalHours >= 300) {
      rank = "ÖZSES VETERANI";
      rankIcon = Icons.local_police;
      rankColor = Colors.redAccent;
    } else if (totalHours >= 150) {
      rank = "Kıdemli Komutan";
      rankIcon = Icons.military_tech;
      rankColor = Colors.orangeAccent;
    } else if (totalHours >= 75) {
      rank = "Usta Analist";
      rankIcon = Icons.star;
      rankColor = Colors.cyanAccent;
    } else if (totalHours >= 25) {
      rank = "Saha Operatörü";
      rankIcon = Icons.star_half;
      rankColor = Colors.greenAccent;
    } else if (totalHours >= 5) {
      rank = "Çırak Taktisyen";
      rankIcon = Icons.star_outline;
      rankColor = Colors.lightBlueAccent;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Cam efekti için şeffaf
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(
                top: BorderSide(color: themeColor.withOpacity(0.5), width: 2)),
            boxShadow: [
              BoxShadow(
                  color: themeColor.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5)
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: SingleChildScrollView(
                // 🎨 PİXEL HATASI DÜZELTMESİ: Taşmaları önleyen siber zırh
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 20),
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.insights, color: themeColor, size: 28),
                        const SizedBox(width: 10),
                        Flexible(
                          // 🎯 SİBER KALKAN: Yazı yanlardan taşarsa hata vermesin diye esnek mühür
                          child: Text("KİŞİSEL İSTİHBARAT RAPORU",
                              style: TextStyle(
                                  color: themeColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // 🎯 RÜTBE KARTI
                    _buildIntelligenceCard(
                      title: "MEVCUT RÜTBE",
                      value: rank,
                      icon: rankIcon,
                      color: rankColor,
                      subtitle: "Sonraki rütbe için müzik dinlemeye devam et.",
                    ),

                    // 🎯 OTONOM DURUM KARTI
                    _buildIntelligenceCard(
                      title: "SİBER RUH HALİ",
                      value: _waveType,
                      icon: Icons.psychology,
                      color: themeColor,
                      subtitle:
                          "Yapay zeka anlık dinleme modunuzu analiz ediyor.",
                    ),

                    // 🎯 İSTATİSTİK KARTLARI (RUH HALİNE GÖRE)
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 20.0, top: 20, bottom: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.data_usage,
                              color: Colors.white54, size: 18),
                          const SizedBox(width: 8),
                          Text("TOPLAM VERİ ANALİZİ",
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2)),
                        ],
                      ),
                    ),
                    if (sortedMoods.isEmpty)
                      _buildIntelligenceCard(
                        title: "TOPLAM SÜRE",
                        value: "Veri Yok",
                        icon: Icons.hourglass_empty,
                        color: Colors.grey,
                        subtitle: "Henüz dinleme geçmişi kaydedilmemiş.",
                      )
                    else
                      ...sortedMoods.map((moodEntry) {
                        final moodName = moodEntry.key;
                        final moodSeconds = moodEntry.value;
                        final moodMinutes = moodSeconds ~/ 60;
                        final moodHours = moodMinutes ~/ 60;
                        return _buildIntelligenceCard(
                          title: moodName.toUpperCase(),
                          value: "$moodHours Saat ${moodMinutes % 60} Dk",
                          icon: _getIconForMood(moodName),
                          color: _getColorForMood(moodName),
                          subtitle: "Bu ruh halinde dinlenen toplam süre.",
                        );
                      }).toList(),

                    Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Text("Siber Beyin Otonom İzleme Sistemi Aktif.",
                          style: TextStyle(
                              color: Colors.white30,
                              fontSize: 11,
                              fontStyle: FontStyle.italic)),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForMood(String mood) {
    switch (mood) {
      case "Melankolik":
        return Icons.sentiment_very_dissatisfied;
      case "Enerjik":
        return Icons.local_fire_department;
      case "Sokak Ritmi":
        return Icons.sports_kabaddi;
      case "Akustik":
        return Icons.music_note;
      default:
        return Icons.balance;
    }
  }

  Color _getColorForMood(String mood) {
    switch (mood) {
      case "Melankolik":
        return Colors.blueAccent;
      case "Enerjik":
        return Colors.orangeAccent;
      case "Sokak Ritmi":
        return Colors.redAccent;
      case "Akustik":
        return Colors.greenAccent;
      default:
        return Colors.purpleAccent;
    }
  }

  // 🎯 İSTİHBARAT KARTI TASARIM MOTORU
  Widget _buildIntelligenceCard(
      {required String title,
      required String value,
      required IconData icon,
      required Color color,
      required String subtitle}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style:
                        const TextStyle(color: Colors.white30, fontSize: 10)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // 🎯 SİBER HAMLE: Profesyonel Şahsi Keşfet (Yapay Zeka Destekli Öneri Motoru)
  void _scanDarkZone(Color themeColor) async {
    // 1. Siber Radar Görseli
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.radar, color: Colors.purpleAccent),
            const SizedBox(width: 10),
            const Expanded(
                child: Text(
                    "Yapay Zeka Analizi: Dinleme geçmişin ve günün saati taranıyor...")),
          ],
        ),
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.purpleAccent, width: 1)),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      // 2. İstihbarat Verilerini Topla (Geçmiş)
      final historyList = await HistoryService.getHistory();
      final historyMap = {
        for (var item in historyList) item.path: item.playCount
      };

      // 3. Kullanıcının Favori Ruh Halini Belirle (Dinleme Süresine Göre)
      final Map<String, int> moodDurations = {};
      for (var item in historyList) {
        final mood = _analyzeSongMoodFromName(item.name);
        moodDurations[mood] =
            (moodDurations[mood] ?? 0) + item.totalListenSeconds;
      }

      String favoriteMood = "Dengeli";
      if (moodDurations.isNotEmpty) {
        favoriteMood = moodDurations.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      // 4. Günün Saatine Göre Psikolojik Mod Belirle
      final int currentHour = DateTime.now().hour;
      String timeMood = "Dengeli";
      if (currentHour >= 6 && currentHour < 12) {
        timeMood = "Enerjik"; // Sabah
      } else if (currentHour >= 12 && currentHour < 18) {
        timeMood = "Sokak Ritmi"; // Öğle
      } else if (currentHour >= 18 && currentHour < 23) {
        timeMood = "Akustik"; // Akşam
      } else {
        timeMood = "Melankolik"; // Gece
      }

      // 5. Arşivdeki Tüm Müzikleri Çek
      final bool wasGlobal = _playlistController.isGlobalLibrary;
      final String? previousPlaylist = _playlistController.currentPlaylistName;

      _playlistController.isGlobalLibrary = true;
      _playlistController.currentPlaylistName = null;
      final allSongs = await _playlistController.loadTargetList();

      _playlistController.isGlobalLibrary = wasGlobal;
      _playlistController.currentPlaylistName = previousPlaylist;

      if (allSongs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Kütüphane boş usta! Önce sisteme müzik mühürle."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      // 6. PROFESYONEL SKORLAMA (ÖNERİ) ALGORİTMASI
      List<Map<String, dynamic>> scoredSongs = [];
      for (var song in allSongs) {
        final path = song.path ?? 'bilinmeyen_yol';
        if (path == 'bilinmeyen_yol') continue;

        double score = 0;
        final playCount = historyMap[path] ?? 0;
        final songMood = _analyzeSongMoodFromName(song.name ?? '');

        // Kriter A: Unutulmuşluk Seviyesi (En önemli etken, çünkü "Keşfet")
        if (playCount == 0) {
          score += 100; // Karanlık bölge, hiç açılmamış
        } else if (playCount < 3) {
          score += 60; // Çok az dinlenmiş
        } else if (playCount < 10) {
          score += 20; // Normal
        } else {
          score -=
              (playCount * 2); // Zaten çok dinlenen şarkıları keşfete koyma
        }

        // Kriter B: Kişisel Zevk (Kullanıcının en çok dinlediği ruh hali)
        if (songMood == favoriteMood) {
          score += 40;
        }

        // Kriter C: Günün Saatine Uyum (Biyolojik Ritme Göre)
        if (songMood == timeMood) {
          score += 30;
        }

        // Kriter D: Rastgelelik (Aynı şarkılar gelmesin diye tuzlama)
        score += (math.Random().nextInt(20));

        scoredSongs.add({'song': song, 'score': score});
      }

      // Skorlara göre listeyi büyükten küçüğe sırala
      scoredSongs.sort(
          (a, b) => (b['score'] as double).compareTo(a['score'] as double));

      // En iyi 25 şarkıyı seç (Şahsi Mix)
      List<SongModel> personalDiscoverList =
          scoredSongs.take(25).map((e) => e['song'] as SongModel).toList();

      await Future.delayed(const Duration(milliseconds: 2500)); // Analiz hissi

      if (mounted && personalDiscoverList.isNotEmpty) {
        setState(() {
          _emergentPlaylist = personalDiscoverList;
          _isEmergentMode = true; // SİBER OTONOM modunda aç
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "🎵 Şahsi Mix Hazır! Favori modun: $favoriteMood. En iyi ${personalDiscoverList.length} öneri yüklendi."),
            backgroundColor: Colors.greenAccent.withOpacity(0.8),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Siber Hata: Şahsi Keşfet çöktü -> $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // 🎯 SİBER HAMLE: Yeni Mühimmat Taraması (Taze Müzikler) Tetikleyicisi
  void _scanNewRecruits(Color themeColor) async {
    // 🚀 SİBER ROKET: Artık alt panel değil, direkt YouTube Music Klonu Ana Sayfasına geçiyoruz!
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiscoverScreen(
          themeColor: themeColor,
          onDownloadStart: _handleDownloadStart,
        ),
      ),
    );
  }

  // 🎯 SİBER HAMLE: Tek Seferlik Şahsi Keşfet Anketi
  void _showPersonalSurveyDialog(Color themeColor) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> availableGenres = [
      "Türkçe Rap",
      "Arabesk",
      "Akustik",
      "Deep House",
      "Pop",
      "Rock",
      "Türkü",
      "R&B",
      "Özgün Müzik",
      "Slow"
    ];
    List<String> selectedGenres =
        prefs.getStringList('siber_personal_genres') ?? [];
    TextEditingController artistController = TextEditingController(
        text: prefs.getString('siber_personal_artists') ?? "");

    if (!mounted) return;

    showDialog(
        context: context,
        barrierDismissible: false, // İlk seferlik zorunlu
        builder: (context) {
          return StatefulBuilder(builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: themeColor.withOpacity(0.5)),
              ),
              title: Text("İLK GİRİŞ: ŞAHSİ KEŞFET PROFİLİ",
                  style: TextStyle(
                      color: themeColor, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        "Siber yapay zekanın seni tanıması için dinlediğin müzik türlerini seç (Maks 4):",
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableGenres.map((genre) {
                        final isSelected = selectedGenres.contains(genre);
                        return ChoiceChip(
                          label: Text(genre,
                              style: TextStyle(
                                  color:
                                      isSelected ? Colors.black : Colors.white,
                                  fontSize: 11)),
                          selected: isSelected,
                          selectedColor: themeColor,
                          backgroundColor: Colors.black45,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                if (selectedGenres.length < 4)
                                  selectedGenres.add(genre);
                              } else {
                                selectedGenres.remove(genre);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text("Favori Sanatçıların (Virgülle ayırarak yaz):",
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: artistController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Örn: Sagopa, Müslüm, Ceza...",
                        hintStyle: const TextStyle(color: Colors.white30),
                        enabledBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: themeColor.withOpacity(0.5))),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: themeColor)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("İptal",
                      style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                  onPressed: () async {
                    if (selectedGenres.isEmpty &&
                        artistController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            "Yapay zekanın seni tanıması için en az 1 tür seçmeli veya 1 sanatçı yazmalısın!"),
                        backgroundColor: Colors.redAccent,
                      ));
                      return;
                    }

                    // Verileri mühürle
                    await prefs.setStringList(
                        'siber_personal_genres', selectedGenres);
                    await prefs.setString(
                        'siber_personal_artists', artistController.text.trim());

                    if (context.mounted) {
                      Navigator.pop(context); // Dialogu kapat
                      _launchPersonalDiscover(
                          themeColor); // Şahsi Keşfete Fırla!
                    }
                  },
                  child: const Text("Mühürle & Keşfete Git",
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          });
        });
  }

  // 🎯 SİBER HAMLE: Şahsi Keşfeti Otonom Başlatıcı
  Future<void> _launchPersonalDiscover(Color themeColor) async {
    final prefs = await SharedPreferences.getInstance();
    final genres = prefs.getStringList('siber_personal_genres') ?? [];
    final artists = prefs.getString('siber_personal_artists') ?? "";

    // Eğer kullanıcı daha önce sistemi doldurmadıysa (ilk tık)
    if (genres.isEmpty && artists.isEmpty) {
      _showPersonalSurveyDialog(themeColor);
    } else {
      // Profil zaten mühürlüyse hiç sormadan direkt Şahsi Keşfet'e gir (Normal Keşfet Gibi)
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DiscoverScreen(
            themeColor: themeColor,
            isPersonalMode: true,
            onDownloadStart: _handleDownloadStart,
          ),
        ),
      );
    }
  }
}

// 🌊 NEON WAVE GÖRSELLEŞTİRİCİ
class NeonWaveBackground extends StatefulWidget {
  final bool isPlaying;
  final Color themeColor;
  final double neonScale;
  const NeonWaveBackground({
    super.key,
    required this.isPlaying,
    required this.themeColor,
    this.neonScale = 1.0,
  });

  @override
  State<NeonWaveBackground> createState() => _NeonWaveBackgroundState();
}

class _NeonWaveBackgroundState extends State<NeonWaveBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) { final _themeColor = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 🛡️ SİBER KALKAN: Çizim alanını tüm ekrana zorla yay ki boyut (NaN) hatası yok olsun!
        return SizedBox.expand(
          child: CustomPaint(
            painter: WavePainter(
              progress: _controller.value,
              isPlaying: widget.isPlaying,
              color: widget.themeColor,
              neonScale: widget.neonScale,
            ),
          ),
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final Color color;
  final double neonScale;
  WavePainter({
    required this.progress,
    required this.isPlaying,
    required this.color,
    required this.neonScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 🛡️ SİBER KALKAN: Ekran boyutları henüz çizilmemişse NaN (geçersiz sayı) hatasını kökünden engelle!
    if (size.width <= 0 || size.height <= 0) return;

    // 🎯 SİBER KALKAN: Eğer görsel efektler kapalıysa ve mod Dark (Karanlık) ise direkt çık
    if (!AudioEngine.visualEffectsEnabled && AudioEngine.darkMode == 1) return;

    bool isOcean =
        AudioEngine.visualEffectsEnabled && AudioEngine.visualMode == 1;
    bool isNight =
        !AudioEngine.visualEffectsEnabled && AudioEngine.darkMode == 0;

    final paint = Paint()
      ..color = isNight
          ? Colors.white.withOpacity(0.05)
          : color.withOpacity(isOcean ? 0.15 : 0.3)
      ..style = isOcean ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = isOcean ? 0.0 : 3.0
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isOcean ? 30 : 15);

    final path = Path();
    final double amplitude =
        (isPlaying ? 35.0 : 8.0) * neonScale; // 🎯 GERÇEK RİTİM SIÇRAMASI!
    final double wavelength = size.width / 1.3;
    final double baseHeight = size.height *
        0.55; // 🎯 SİBER HAMLE: Dalgaları alt çubuğun arkasından kurtarıp ekranın ortasına taşıdık!

    if (wavelength <= 0) return; // Siber Güvenlik

    if (isOcean) {
      path.moveTo(0, size.height);
      path.lineTo(0, baseHeight);
    } else {
      path.moveTo(0, baseHeight);
    }

    for (double x = 0; x <= size.width; x++) {
      double y = baseHeight +
          math.sin((x / wavelength) + (progress * math.pi * 2)) * amplitude;

      // Çift dalga etkisi (Okyanus) veya Çok hafif dalga (Night)
      if (isOcean) {
        y += math.cos((x / (wavelength * 0.8)) - (progress * math.pi * 1.5)) *
            (amplitude * 0.5);
      } else if (isNight) {
        y = size.height *
                0.70 + // 🎯 Night modunu da görünür alana yukarı çektik
            math.sin((x / wavelength) + (progress * math.pi)) *
                (amplitude * 0.2); // Çok hafif
      }

      // 🛡️ SİBER KALKAN: Trigonometrik hesaplamada saçmalama olursa Android motorunun çökmesini engelle
      if (y.isNaN || y.isInfinite) continue;

      path.lineTo(x, y);
    }

    if (isOcean) {
      path.lineTo(size.width, size.height);
      path.close();
    }
    canvas.drawPath(path, paint);

    // 🎯 SİBER ÇİZGİSEL MOD: Altından geçen otonom ince ritim hattı
    if (AudioEngine.visualEffectsEnabled &&
        AudioEngine.visualMode == 0 &&
        !isOcean &&
        !isNight) {
      final paint2 = Paint()
        ..color = color.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final path2 = Path();
      path2.moveTo(0, baseHeight);
      for (double x = 0; x <= size.width; x++) {
        double y = baseHeight +
            math.sin((x / wavelength) + (progress * math.pi * 2.2)) *
                (amplitude * 0.8);
        if (y.isNaN || y.isInfinite) continue;
        path2.lineTo(x, y);
      }
      canvas.drawPath(path2, paint2);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
