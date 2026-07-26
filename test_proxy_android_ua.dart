import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;

void main() async {
  final yt = YoutubeExplode();
  try {
    print('Fetching manifest...');
    var manifest = await yt.videos.streamsClient.getManifest('8s8m9rG_fSA');
    var streamInfo = manifest.audioOnly.withHighestBitrate();
    print('Stream URL: ${streamInfo.url}');
    
    print('Testing direct fetch with http.Client() (WITH Android User-Agent)...');
    var client = http.Client();
    var req = http.Request('GET', streamInfo.url);
    req.headers['User-Agent'] = 'com.google.android.youtube/17.36.4 (Linux; U; Android 12; GB) gzip';
    
    var res = await client.send(req);
    print('Status: ${res.statusCode}');
    
    int bytes = 0;
    await for (var data in res.stream) {
      bytes += data.length;
      if (bytes > 100000) break; // test first 100kb
    }
    print('Downloaded $bytes bytes');
    
  } catch (e) {
    print('Error: $e');
  } finally {
    yt.close();
  }
}
