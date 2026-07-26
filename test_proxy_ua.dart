import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;

void main() async {
  final yt = YoutubeExplode();
  try {
    print('Fetching manifest...');
    var manifest = await yt.videos.streamsClient.getManifest('8s8m9rG_fSA');
    var streamInfo = manifest.audioOnly.withHighestBitrate();
    print('Stream URL: ${streamInfo.url}');
    
    print('Testing direct fetch with http.Client() (WITH Chrome User-Agent)...');
    var client = http.Client();
    var req = http.Request('GET', streamInfo.url);
    req.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36';
    req.headers['Accept'] = '*/*';
    req.headers['Connection'] = 'keep-alive';
    
    var res = await client.send(req);
    print('Status: ${res.statusCode}');
    
  } catch (e) {
    print('Error: $e');
  } finally {
    yt.close();
  }
}
