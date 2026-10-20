import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../utils/song_media_utils.dart';

/// 🎯 SİBER BULUT ARŞİV: Hesaba bağlı kütüphane senkronizasyonu
/// Spotify/YT Premium gibi — giriş yapınca arşivin her cihazda hazır.
class CloudLibraryService {
  static final CloudLibraryService _instance = CloudLibraryService._internal();
  factory CloudLibraryService() => _instance;
  CloudLibraryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🎯 SİBER KALKAN: Senkronizasyon Durumu (UI için Canlı Geri Bildirim)
  final ValueNotifier<bool> isSyncing = ValueNotifier<bool>(false);

  /// Kullanıcı giriş yapmış mı?
  bool get isUserLoggedIn => _auth.currentUser != null;

  /// Kullanıcının Firestore kütüphane koleksiyonu
  CollectionReference? get _libraryCollection {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid).collection('library');
  }

  // ═══════════════════════════════════════════════════════════════
  // 🚀 TEK ŞARKI İŞLEMLERİ
  // ═══════════════════════════════════════════════════════════════

  /// Tek şarkıyı bulut arşive ekler
  Future<void> addToCloudLibrary(SongModel song) async {
    if (!isUserLoggedIn || _libraryCollection == null) return;
    final videoId = song.videoId ?? extractVideoIdFromPath(song.path);
    if (videoId == null || videoId.isEmpty) return;

    try {
      await _libraryCollection!.doc(videoId).set({
        'title': song.title ?? song.name ?? 'Bilinmeyen',
        'artist': song.artist ?? '',
        'videoId': videoId,
        'artUrl': song.artUrl ?? '',
        'duration': song.duration ?? 0,
        'addedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('☁️ Bulut Arşiv: "${song.title}" başarıyla eklendi.');
    } catch (e) {
      print('⚠️ Bulut Arşiv Ekleme Hatası: $e');
    }
  }

  /// Tek şarkıyı bulut arşivden siler
  Future<void> removeFromCloudLibrary(String videoId) async {
    if (!isUserLoggedIn || _libraryCollection == null) return;
    if (videoId.isEmpty) return;

    try {
      await _libraryCollection!.doc(videoId).delete();
      print('☁️ Bulut Arşiv: "$videoId" silindi.');
    } catch (e) {
      print('⚠️ Bulut Arşiv Silme Hatası: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔄 SENKRONİZASYON
  // ═══════════════════════════════════════════════════════════════

  /// Giriş yapılınca çağrılır: Buluttaki arşivi çeker ve yerelle birleştirir
  Future<void> syncFromCloud() async {
    if (!isUserLoggedIn || _libraryCollection == null) {
      print('⚠️ Bulut Senkronizasyon: Kullanıcı giriş yapmamış.');
      return;
    }

    try {
      print('☁️ Bulut Arşiv Senkronizasyonu Başlatılıyor...');

      // 1. Buluttaki şarkıları çek
      final cloudSnapshot = await _libraryCollection!
          .orderBy('addedAt', descending: true)
          .get();

      final cloudSongs = <SongModel>[];
      for (var doc in cloudSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        cloudSongs.add(SongModel(
          title: data['title'],
          artist: data['artist'],
          videoId: data['videoId'] ?? doc.id,
          artUrl: data['artUrl'],
          duration: data['duration'],
          path: 'yt:${data['videoId'] ?? doc.id}', // Çevrimiçi oynatma yolu
        ));
      }

      // 2. Yerel kütüphaneyi yükle
      final localSongs = await loadGlobalLibrarySongs();

      // 3. Birleştir (merge): Yerel + Bulut, tekrarları videoId ile ele
      final mergedMap = <String, SongModel>{};

      // Önce yerel şarkıları ekle (dosya yolları korunsun)
      for (var song in localSongs) {
        final vid = song.videoId ?? extractVideoIdFromPath(song.path) ?? song.path ?? '';
        if (vid.isNotEmpty) mergedMap[vid] = song;
      }

      // Sonra bulut şarkılarını ekle (yerelde yoksa ekle)
      for (var song in cloudSongs) {
        final vid = song.videoId ?? '';
        if (vid.isNotEmpty && !mergedMap.containsKey(vid)) {
          mergedMap[vid] = song;
        }
      }

      // 4. Birleştirilmiş listeyi yerel'e kaydet
      final mergedList = mergedMap.values.toList();
      await saveGlobalLibrarySongs(mergedList);

      print('☁️ Bulut Senkronizasyon Tamamlandı: ${cloudSongs.length} bulut + ${localSongs.length} yerel = ${mergedList.length} toplam');
    } catch (e) {
      print('⚠️ Bulut Senkronizasyon Hatası: $e');
    }
  }

  /// Yerel arşivi buluta yükler (tam senkronizasyon)
  Future<void> syncToCloud() async {
    if (!isUserLoggedIn || _libraryCollection == null) return;

    try {
      print('☁️ Yerel Arşiv Buluta Yükleniyor...');
      final localSongs = await loadGlobalLibrarySongs();

      // Firestore batch yazma (performans)
      final batch = _firestore.batch();
      for (var song in localSongs) {
        final videoId = song.videoId ?? extractVideoIdFromPath(song.path);
        if (videoId == null || videoId.isEmpty) continue;

        batch.set(
          _libraryCollection!.doc(videoId),
          {
            'title': song.title ?? song.name ?? 'Bilinmeyen',
            'artist': song.artist ?? '',
            'videoId': videoId,
            'artUrl': song.artUrl ?? '',
            'duration': song.duration ?? 0,
            'addedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      print('☁️ Yerel Arşiv Buluta Yüklendi: ${localSongs.length} şarkı');
    } catch (e) {
      print('⚠️ Bulut Yükleme Hatası: $e');
    }
  }

  /// İki yönlü tam senkronizasyon (giriş yapılınca çağrılır)
  Future<void> fullSync() async {
    isSyncing.value = true;
    try {
      await syncFromCloud(); // Önce buluttan çek
      await syncPlaylistsFromCloud(); // Playlists buluttan çek
      await syncToCloud();   // Sonra yereli buluta yükle
      await syncPlaylistsToCloud(); // Playlists buluta yükle
      print('☁️ ✅ Tam Senkronizasyon Tamamlandı!');
    } finally {
      isSyncing.value = false;
    }
  }

  /// Bulut arşivdeki şarkı sayısını döner
  Future<int> getCloudLibraryCount() async {
    if (!isUserLoggedIn || _libraryCollection == null) return 0;
    try {
      final snapshot = await _libraryCollection!.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Şarkının bulut arşivde olup olmadığını kontrol eder
  Future<bool> isInCloudLibrary(String videoId) async {
    if (!isUserLoggedIn || _libraryCollection == null) return false;
    try {
      final doc = await _libraryCollection!.doc(videoId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 📂 ÖZEL LİSTE (PLAYLIST) SENKRONİZASYONU
  // ═══════════════════════════════════════════════════════════════
  CollectionReference? get _playlistCollection {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid).collection('playlists');
  }

  /// Yerel özel listeleri buluta yedekle
  Future<void> syncPlaylistsToCloud() async {
    if (!isUserLoggedIn || _playlistCollection == null) return;
    try {
      isSyncing.value = true;
      final prefs = await SharedPreferences.getInstance();
      List<String> playlistNames = prefs.getStringList('all_playlists') ?? [];
      
      final batch = _firestore.batch();
      for (var pName in playlistNames) {
        List<String> songs = prefs.getStringList('playlist_$pName') ?? [];
        batch.set(
          _playlistCollection!.doc(pName),
          {
            'name': pName,
            'songs': songs,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      print('☁️ Playlists Buluta Yüklendi: ${playlistNames.length} liste');
    } catch (e) {
      print('⚠️ Playlists Bulut Yükleme Hatası: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  /// Buluttaki özel listeleri yerele çek
  Future<void> syncPlaylistsFromCloud() async {
    if (!isUserLoggedIn || _playlistCollection == null) return;
    try {
      isSyncing.value = true;
      final prefs = await SharedPreferences.getInstance();
      final snapshot = await _playlistCollection!.get();
      
      List<String> localNames = prefs.getStringList('all_playlists') ?? [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final pName = data['name'] as String;
        final cloudSongs = List<String>.from(data['songs'] ?? []);
        
        if (!localNames.contains(pName)) {
          localNames.add(pName);
        }
        
        // Şarkıları birleştir
        List<String> localSongs = prefs.getStringList('playlist_$pName') ?? [];
        final mergedSongs = {...localSongs, ...cloudSongs}.toList();
        await prefs.setStringList('playlist_$pName', mergedSongs);
      }
      
      await prefs.setStringList('all_playlists', localNames);
      print('☁️ Playlists Buluttan Çekildi: ${snapshot.docs.length} liste');
    } catch (e) {
      print('⚠️ Playlists Bulut Çekme Hatası: $e');
    } finally {
      isSyncing.value = false;
    }
  }
}
