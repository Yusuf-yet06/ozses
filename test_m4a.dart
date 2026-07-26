import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;

void main() async {
  final yt = YoutubeExplode();
  try {
    var manifest = await yt.videos.streamsClient.getManifest('8s8m9rG_fSA');
    
    // Get M4A (mp4 audio)
    var streamInfo = manifest.audioOnly.where((e) => e.container.name == 'mp4').first;
    print('Stream URL (M4A): ${streamInfo.url}');
    
    var client = http.Client();
    var req = http.Request('GET', streamInfo.url);
    req.headers['User-Agent'] = 'com.google.android.youtube/17.36.4 (Linux; U; Android 12; GB) gzip';
    
    var res = await client.send(req);
    print('Status (M4A Android UA): ${res.statusCode}');
    
    req = http.Request('GET', streamInfo.url);
    req.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)';
    res = await client.send(req);
    print('Status (M4A Windows UA): ${res.statusCode}');
    
  } catch (e) {
    print('Error: $e');
  } finally {
    yt.close();
  }
}
