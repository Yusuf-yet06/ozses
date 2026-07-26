import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;

void main() async {
  // Let's try to initialize with different clients if possible
  final yt = YoutubeExplode();
  
  try {
    print('Fetching manifest...');
    var manifest = await yt.videos.streamsClient.getManifest('8s8m9rG_fSA');
    
    var streamInfo = manifest.audioOnly.withHighestBitrate();
    print('Stream URL: ${streamInfo.url}');
    
    print('Testing direct fetch with http.Client() (Default headers)...');
    var client = http.Client();
    var req = http.Request('GET', streamInfo.url);
    
    var res = await client.send(req);
    print('Status: ${res.statusCode}');
    
    if (res.statusCode == 403) {
      print('Got 403. Testing iOS User-Agent...');
      req = http.Request('GET', streamInfo.url);
      req.headers['User-Agent'] = 'com.google.ios.youtube/19.28.1 (iPhone14,5; U; CPU iOS 17_5_1 like Mac OS X)';
      res = await client.send(req);
      print('Status (iOS UA): ${res.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    yt.close();
  }
}
