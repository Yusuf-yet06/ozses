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
    if (!isUserLoggedIn) {
      print('⚠️ Bulut Senkronizasyon: Aktif oturum yok.');
      return;
    }
    isSyncing.value = true;
    try {
      // 1. Buluttaki tüm verileri yerele çek ve birleştir
      await syncFromCloud(); // Kütüphaneyi çek
      await syncPlaylistsFromCloud(); // Özel çalma listelerini çek
      await syncPreferencesFromCloud(); // Sabitlenen kanalları, türleri, favorileri çek

      // 2. Yereldeki güncel verileri buluta yükle
      await syncToCloud(); // Kütüphaneyi buluta yükle
      await syncPlaylistsToCloud(); // Çalma listelerini buluta yükle
      await syncPreferencesToCloud(); // Tercihleri ve kanalları buluta yükle

      print('🚀 👑 Tam Siber Hesap Hafızası Eşitlendi (Kütüphane, Listeler, Kanallar, Favoriler)!');
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

  // ═══════════════════════════════════════════════════════════════
  // ⚡ SİBER TERCİH & FREKANS HAFIZASI (Sabit Kanallar & Türler & Favoriler)
  // ═══════════════════════════════════════════════════════════════
  DocumentReference? get _preferencesDoc {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid).collection('settings').doc('preferences');
  }

  /// Sabitlenen kanalları, kişisel sanatçıları, türleri ve favorileri buluta yedekler
  Future<void> syncPreferencesToCloud() async {
    if (!isUserLoggedIn || _preferencesDoc == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final pinnedArtists = prefs.getStringList('siber_pinned_artists') ?? [];
      final personalGenres = prefs.getStringList('siber_personal_genres') ?? [];
      final personalArtists = prefs.getString('siber_personal_artists') ?? '';
      final favorites = prefs.getStringList('favorites') ?? [];
      final rankExp = prefs.getInt('siber_rank_exp') ?? 0;
      final totalListens = prefs.getInt('siber_total_listens') ?? 0;

      await _preferencesDoc!.set({
        'pinnedArtists': pinnedArtists,
        'personalGenres': personalGenres,
        'personalArtists': personalArtists,
        'favorites': favorites,
        'rankExp': rankExp,
        'totalListens': totalListens,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('⚡ Siber Tercihler, Kanallar ve Favoriler Buluta Mühürlendi!');
    } catch (e) {
      print('⚠️ Tercih Bulut Yedekleme Hatası: ');
    }
  }

  /// Buluttaki tercihleri (sabitlenen kanallar, türler, sanatçılar, favoriler) yerele çeker
  Future<void> syncPreferencesFromCloud() async {
    if (!isUserLoggedIn || _preferencesDoc == null) return;
    try {
      final doc = await _preferencesDoc!.get();
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final prefs = await SharedPreferences.getInstance();

      final cloudPinned = List<String>.from(data['pinnedArtists'] ?? []);
      if (cloudPinned.isNotEmpty) {
        final localPinned = prefs.getStringList('siber_pinned_artists') ?? [];
        final merged = {...localPinned, ...cloudPinned}.toList();
        await prefs.setStringList('siber_pinned_artists', merged);
      }

      final cloudGenres = List<String>.from(data['personalGenres'] ?? []);
      if (cloudGenres.isNotEmpty) {
        await prefs.setStringList('siber_personal_genres', cloudGenres);
      }

      final cloudArtists = data['personalArtists'] as String?;
      if (cloudArtists != null && cloudArtists.isNotEmpty) {
        await prefs.setString('siber_personal_artists', cloudArtists);
      }

      final cloudFavs = List<String>.from(data['favorites'] ?? []);
      if (cloudFavs.isNotEmpty) {
        final localFavs = prefs.getStringList('favorites') ?? [];
        final mergedFavs = {...localFavs, ...cloudFavs}.toList();
        await prefs.setStringList('favorites', mergedFavs);
      }

      final cloudRankExp = data['rankExp'] as int?;
      if (cloudRankExp != null) {
        final localRankExp = prefs.getInt('siber_rank_exp') ?? 0;
        if (cloudRankExp > localRankExp) {
          await prefs.setInt('siber_rank_exp', cloudRankExp);
        }
      }

      final cloudTotalListens = data['totalListens'] as int?;
      if (cloudTotalListens != null) {
        final localTotalListens = prefs.getInt('siber_total_listens') ?? 0;
        if (cloudTotalListens > localTotalListens) {
          await prefs.setInt('siber_total_listens', cloudTotalListens);
        }
      }

      print('⚡ Siber Tercihler Buluttan Başarıyla Çekildi ve Mühürlendi!');
    } catch (e) {
      print('⚠️ Tercih Bulut Çekme Hatası: ');
    }
  }

}
