import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;

void main() async {
  final yt = YoutubeExplode();
  try {
    print('Fetching manifest...');
    var manifest = await yt.videos.streamsClient.getManifest('8s8m9rG_fSA');
    var streamInfo = manifest.audioOnly.withHighestBitrate();
    print('Stream URL: ${streamInfo.url}');
    
    print('Testing direct fetch with http.Client() (No User-Agent)...');
    var client = http.Client();
    var req = http.Request('GET', streamInfo.url);
    var res = await client.send(req);
    print('Status: ${res.statusCode}');
    
  } catch (e) {
    print('Error: $e');
  } finally {
    yt.close();
  }
}
