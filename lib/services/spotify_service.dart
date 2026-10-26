import 'dart:convert';
import 'package:http/http.dart' as http;
import 'radar_filter.dart';

class SpotifyService {
  static final SpotifyService _instance = SpotifyService._internal();
  static SpotifyService get instance => _instance;

  SpotifyService._internal();

  final String _clientId = '79ffd576689b4f6797d5ba0490672c8f';
  final String _clientSecret = 'b7fb21f31cd1491681911a7946bb6df9';
  
  String? _accessToken;
  DateTime? _tokenExpiration;

  // SİBER OTONOM TOKEN ÜRETİCİ
  Future<String> _getToken() async {
    if (_accessToken != null && _tokenExpiration != null && DateTime.now().isBefore(_tokenExpiration!)) {
      return _accessToken!;
    }

    final String basicAuth = base64Encode(utf8.encode('$_clientId:$_clientSecret'));
    
    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Authorization': 'Basic $basicAuth',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'client_credentials',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _accessToken = data['access_token'];
      _tokenExpiration = DateTime.now().add(Duration(seconds: data['expires_in'] - 60)); // 1 dk erken yenile
      print('✅ [SPOTIFY] Siber Token Alındı!');
      return _accessToken!;
    } else {
      throw Exception('Spotify Token alınamadı: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getTop50Turkey() async {
    final token = await _getToken();
    // Top 50 Türkiye Playlist ID
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/playlists/37i9dQZEVXbIVYVbnw9YK5/tracks?limit=50'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return _parseTracks(json.decode(response.body)['items']);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getNewReleases() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/browse/new-releases?country=TR&limit=20'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final albums = json.decode(response.body)['albums']['items'] as List;
      return albums.map((item) {
        String artistName = item['artists'][0]['name'];
        String title = item['name'];
        return {
          'id': 'spotify:$artistName - $title',
          'title': title,
          'channel': artistName,
          'thumbnail': item['images'].isNotEmpty ? item['images'][0]['url'] : '',
          'duration': '3:00', // Varsayılan süre
        };
      }).toList();
    }
    return [];
  }

  /// 💿 SANATÇININ SAF ALBÜMLERİNİ ÇEKER (Şahsi Keşfet Sanatçı Mix Üst Vitrini İçin)
  Future<List<Map<String, dynamic>>> getArtistAlbums(
    String artistName, {
    int limit = 3,
  }) async {
    try {
      final token = await _getToken();
      final artistSearchRes = await http.get(
        Uri.parse(
          'https://api.spotify.com/v1/search?q=${Uri.encodeComponent(artistName.trim())}&type=artist&market=TR&limit=1',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (artistSearchRes.statusCode != 200) return [];

      final artistsItems =
          json.decode(artistSearchRes.body)['artists']?['items'] as List?;
      if (artistsItems == null || artistsItems.isEmpty) return [];

      final artistObj = artistsItems.first;
      final String artistId = artistObj['id']?.toString() ?? '';
      final String resolvedArtistName =
          artistObj['name']?.toString() ?? artistName;
      if (artistId.isEmpty) return [];

      // Önce tam albümleri, yeterli değilse EP/single albümlerini dahil et
      final albumsRes = await http.get(
        Uri.parse(
          'https://api.spotify.com/v1/artists/$artistId/albums?include_groups=album,single&market=TR&limit=12',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (albumsRes.statusCode != 200) return [];

      final rawAlbums = json.decode(albumsRes.body)['items'] as List? ?? [];
      final List<Map<String, dynamic>> pureAlbums = [];
      final Set<String> seenNames = {};

      // Çok parçalı saf albümlere öncelik ver
      final sortedRaw = List<dynamic>.from(rawAlbums)
        ..sort((a, b) {
          final aTracks = (a['total_tracks'] ?? 1) as int;
          final bTracks = (b['total_tracks'] ?? 1) as int;
          return bTracks.compareTo(aTracks);
        });

      for (final alb in sortedRaw) {
        if (pureAlbums.length >= limit) break;
        final String name = (alb['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        final String normName = SiberStreamFilterEngine.normalizeTr(name);
        if (seenNames.contains(normName)) continue;
        seenNames.add(normName);

        final images = alb['images'] as List? ?? [];
        final String coverUrl =
            images.isNotEmpty ? (images[0]['url']?.toString() ?? '') : '';
        final String releaseDate = (alb['release_date'] ?? '').toString();
        final String year = releaseDate.length >= 4
            ? releaseDate.substring(0, 4)
            : releaseDate;
        final int totalTracks = (alb['total_tracks'] ?? 1) as int;

        pureAlbums.add({
          'albumId': alb['id']?.toString() ?? '',
          'title': name,
          'artist': resolvedArtistName,
          'thumbnail': coverUrl,
          'year': year,
          'totalTracks': totalTracks,
          'albumType': totalTracks > 1 ? 'Albüm ($totalTracks Parça)' : 'Single / EP',
        });
      }

      return pureAlbums;
    } catch (e) {
      print('Spotify Albüm Çekme Hatası ($artistName): $e');
      return [];
    }
  }

  /// 💿 SEÇİLEN ALBÜMÜN İÇİNDEKİ ŞARKILARI ÇEKER
  Future<List<Map<String, dynamic>>> getAlbumTracks(
    String albumId, {
    String fallbackThumbnail = '',
    String fallbackArtist = '',
  }) async {
    try {
      if (albumId.isEmpty) return [];
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/albums/$albumId/tracks?market=TR&limit=25'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) return [];

      final items = json.decode(response.body)['items'] as List? ?? [];
      final List<Map<String, dynamic>> tracks = [];

      for (final track in items) {
        if (track == null) continue;
        final String artistName =
            (track['artists'] != null && (track['artists'] as List).isNotEmpty)
                ? track['artists'][0]['name'].toString()
                : (fallbackArtist.isNotEmpty ? fallbackArtist : 'Bilinmeyen');
        final String title = (track['name'] ?? 'Bilinmeyen').toString();
        final int durationMs = (track['duration_ms'] ?? 180000) as int;
        final int seconds = (durationMs / 1000).round();
        if (seconds > 0 && seconds < SiberStreamFilterEngine.minFullTrackSeconds) {
          continue; // İntro / skit / short parçaları ele
        }
        final int min = seconds ~/ 60;
        final int sec = seconds % 60;
        final String formattedDur = '$min:${sec.toString().padLeft(2, '0')}';

        final trackMap = {
          'id': 'spotify:$artistName - $title',
          'videoId': 'spotify:$artistName - $title',
          'title': title,
          'channel': artistName,
          'thumbnail': fallbackThumbnail,
          'duration': formattedDur,
        };
        if (!SiberStreamFilterEngine.isShortOrTeaserTrack(trackMap)) {
          tracks.add(trackMap);
        }
      }
      return tracks;
    } catch (e) {
      print('Spotify Albüm Parçaları Hatası ($albumId): $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFeaturedPlaylists() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/browse/featured-playlists?country=TR&limit=10'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final playlists = json.decode(response.body)['playlists']['items'] as List;
      return playlists.map((item) {
        return {
          'id': item['id'], // playlist id
          'title': item['name'],
          'thumbnail': item['images'].isNotEmpty ? item['images'][0]['url'] : '',
          'description': item['description']
        };
      }).toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getPlaylistTracks(String playlistId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/tracks?limit=30'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return _parseTracks(json.decode(response.body)['items']);
    }
    return [];
  }
  
  Future<List<Map<String, dynamic>>> searchTracks(String query) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/search?q=${Uri.encodeComponent(query)}&type=track&market=TR&limit=20'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return _parseTracksFromItems(json.decode(response.body)['tracks']['items']);
    }
    return [];
  }

  List<Map<String, dynamic>> _parseTracks(List items) {
    return items.map((item) {
      try {
        final track = item['track'];
        if (track == null) return null;
        
        String artistName = (track['artists'] != null && track['artists'].isNotEmpty) ? track['artists'][0]['name'] : 'Bilinmeyen';
        String title = track['name'] ?? 'Bilinmeyen';
        int durationMs = track['duration_ms'] ?? 0;
        int seconds = (durationMs / 1000).round();
        if (seconds > 0 && seconds < SiberStreamFilterEngine.minFullTrackSeconds) {
          return null; // 75sn altı skit/short elemesi
        }
        
        String formatDuration(int secTotal) {
          int min = secTotal ~/ 60;
          int sec = secTotal % 60;
          return '$min:${sec.toString().padLeft(2, '0')}';
        }

        String thumbnail = '';
        if (track['album'] != null && track['album']['images'] != null && track['album']['images'].isNotEmpty) {
          thumbnail = track['album']['images'][0]['url'];
        }

        final map = {
          'id': 'spotify:$artistName - $title',
          'videoId': 'spotify:$artistName - $title',
          'title': title,
          'channel': artistName,
          'thumbnail': thumbnail,
          'duration': formatDuration(seconds),
        };
        if (SiberStreamFilterEngine.isShortOrTeaserTrack(map)) return null;
        return map;
      } catch (e) {
        print('Spotify Parse Error: $e');
        return null;
      }
    }).where((item) => item != null).cast<Map<String, dynamic>>().toList();
  }

  List<Map<String, dynamic>> _parseTracksFromItems(List tracks) {
    return tracks.map((track) {
      try {
        if (track == null) return null;
        
        String artistName = (track['artists'] != null && track['artists'].isNotEmpty) ? track['artists'][0]['name'] : 'Bilinmeyen';
        String title = track['name'] ?? 'Bilinmeyen';
        int durationMs = track['duration_ms'] ?? 0;
        int seconds = (durationMs / 1000).round();
        if (seconds > 0 && seconds < SiberStreamFilterEngine.minFullTrackSeconds) {
          return null; // 75sn altı skit/short elemesi
        }
        
        String formatDuration(int secTotal) {
          int min = secTotal ~/ 60;
          int sec = secTotal % 60;
          return '$min:${sec.toString().padLeft(2, '0')}';
        }

        String thumbnail = '';
        if (track['album'] != null && track['album']['images'] != null && track['album']['images'].isNotEmpty) {
          thumbnail = track['album']['images'][0]['url'];
        }

        final map = {
          'id': 'spotify:$artistName - $title',
          'videoId': 'spotify:$artistName - $title',
          'title': title,
          'channel': artistName,
          'thumbnail': thumbnail,
          'duration': formatDuration(seconds),
        };
        if (SiberStreamFilterEngine.isShortOrTeaserTrack(map)) return null;
        return map;
      } catch (e) {
        print('Spotify Parse Error: $e');
        return null;
      }
    }).where((item) => item != null).cast<Map<String, dynamic>>().toList();
  }
}
