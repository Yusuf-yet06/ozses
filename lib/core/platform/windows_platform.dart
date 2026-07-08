import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'siber_platform.dart';
import '../../services/ytdlp_service.dart';

class WindowsPlatform implements SiberPlatform {
  @override
  bool get supportsHardwareDSP => false;

  @override
  Future<Map<String, dynamic>> fetchKesfet({String? pageToken}) async {
    print("--- ÖZSES KEŞFET RADARI BAŞLATILIYOR (Masaüstü) ---");
    var yt = YoutubeExplode();
    var searchResults = await yt.search.search("en çok dinlenen popüler şarkılar official audio");
    var items = [];
    for (var video in searchResults) {
      items.add({
        "id": video.id.value,
        "title": video.title,
        "channel": video.author,
        "thumbnail": video.thumbnails.highResUrl,
      });
    }
    yt.close();
    return {"status": "basarili", "oneriler": items, "nextPageToken": ""};
  }

  @override
  Future<List<dynamic>> searchMusic(String query, {int limit = 15, int page = 1}) async {
    print("--- SİBER ARAMA BAŞLATILIYOR (Masaüstü) ---");
    var yt = YoutubeExplode();
    var searchResults = await yt.search.search(query + " official audio");
    var items = [];
    for (var video in searchResults.take(limit)) {
      items.add({
        "id": video.id.value,
        "title": video.title,
        "channel": video.author,
        "thumbnail": video.thumbnails.highResUrl,
      });
    }
    yt.close();
    return items;
  }

  @override
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/proxy/suggest?q=$query')).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['oneriler'] != null) {
          return List<String>.from(decoded['oneriler']);
        }
      }
    } catch (e) {
      print("Windows Proxy Suggestion Hatası: $e");
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> getStreamUrl(String videoId) async {
    try {
      // SİBER KALKAN: Native yt-dlp ile Windows üzerinde akış çöz
      String exePath = await YtDlpService().getExecutablePath();
      var process = await Process.run(exePath, [
        '-g', 
        '-f', 'bestaudio[ext=m4a]/bestaudio', 
        'https://www.youtube.com/watch?v=$videoId'
      ]);
      
      if (process.exitCode == 0 && process.stdout.toString().trim().isNotEmpty) {
        return {"status": "basarili", "stream_url": process.stdout.toString().trim()};
      } else {
        print("yt-dlp akış alma hatası: ${process.stderr}");
        
        // Fallback: YoutubeExplode
        var yt = YoutubeExplode();
        var manifest = await yt.videos.streamsClient.getManifest(videoId).timeout(const Duration(seconds: 10));
        var audioStreams = manifest.audioOnly.where((s) => s.container.name == 'mp4' || s.container.name == 'm4a');
        if (audioStreams.isEmpty) audioStreams = manifest.audioOnly;
        var streamInfo = audioStreams.withHighestBitrate();
        yt.close();
        return {"status": "basarili", "stream_url": streamInfo.url.toString()};
      }
    } catch (e) {
      print("Windows Desktop Stream URL Hatası: $e");
      return {"status": "hata", "mesaj": e.toString()};
    }
  }

  @override
  Future<String> getDownloadPath() async {
    String userHome = Platform.environment['USERPROFILE'] ?? '';
    return '$userHome\\Music\\OzsesDownloads';
  }

  @override
  Future<List<String>> scanMusicFolders() async {
    String userHome = Platform.environment['USERPROFILE'] ?? '';
    List<Directory> targetDirs = [
      Directory('$userHome\\Music'),
      Directory('$userHome\\Downloads')
    ];

    List<String> foundFiles = [];
    for (var dir in targetDirs) {
      if (dir.existsSync()) {
        try {
          var files = dir.listSync(recursive: true, followLinks: false);
          for (var file in files) {
            if (file is File && (file.path.endsWith('.mp3') || file.path.endsWith('.m4a'))) {
              foundFiles.add(file.path);
            }
          }
        } catch (e) {
          print("Dizin tarama yetki hatası (atlandı): $dir");
        }
      }
    }
    return foundFiles;
  }
}
