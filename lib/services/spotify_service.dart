import 'dart:convert';
import 'package:http/http.dart' as http;

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
        
        String formatDuration(int ms) {
          int seconds = (ms / 1000).round();
          int min = seconds ~/ 60;
          int sec = seconds % 60;
          return '$min:${sec.toString().padLeft(2, '0')}';
        }

        String thumbnail = '';
        if (track['album'] != null && track['album']['images'] != null && track['album']['images'].isNotEmpty) {
          thumbnail = track['album']['images'][0]['url'];
        }

        return {
          'id': 'spotify:$artistName - $title',
          'title': title,
          'channel': artistName,
          'thumbnail': thumbnail,
          'duration': formatDuration(durationMs),
        };
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
        
        String formatDuration(int ms) {
          int seconds = (ms / 1000).round();
          int min = seconds ~/ 60;
          int sec = seconds % 60;
          return '$min:${sec.toString().padLeft(2, '0')}';
        }

        String thumbnail = '';
        if (track['album'] != null && track['album']['images'] != null && track['album']['images'].isNotEmpty) {
          thumbnail = track['album']['images'][0]['url'];
        }

        return {
          'id': 'spotify:$artistName - $title',
          'title': title,
          'channel': artistName,
          'thumbnail': thumbnail,
          'duration': formatDuration(durationMs),
        };
      } catch (e) {
        print('Spotify Parse Error: $e');
        return null;
      }
    }).where((item) => item != null).cast<Map<String, dynamic>>().toList();
  }
}
