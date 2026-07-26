import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_explode_dart/src/videos/youtube_api_client.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  var yt = YoutubeExplode();
  var videoId = 'IuIbOwXd0VQ'; // test video

  var clients = {
    'androidSdkless': YoutubeApiClient.androidSdkless,
    'android': YoutubeApiClient.android,
    'androidMusic': YoutubeApiClient.androidMusic,
    'androidVr': YoutubeApiClient.androidVr,
    'safari': YoutubeApiClient.safari,
    'tv': YoutubeApiClient.tv,
    'mweb': YoutubeApiClient.mweb,
    'ios': YoutubeApiClient.ios,
  };

  for (var entry in clients.entries) {
    var name = entry.key;
    var client = entry.value;
    print('\nTesting client: $name');
    try {
      var manifest = await yt.videos.streamsClient.getManifest(videoId, ytClients: [client]);
      var audio = manifest.audioOnly.withHighestBitrate();
      print('URL found: ${audio.url.toString().substring(0, 50)}...');

      // Test download
      var req = http.Request('GET', audio.url);
      req.headers['range'] = 'bytes=0-1024';
      var clientHttp = http.Client();
      var res = await clientHttp.send(req);
      print('Status Code: ${res.statusCode}');
      if (res.statusCode == 200 || res.statusCode == 206) {
        print('SUCCESS: Client $name works!');
      } else {
        print('FAILED: Client $name returned HTTP ${res.statusCode}');
      }
      clientHttp.close();
    } catch (e) {
      print('FAILED: Exception with $name: $e');
    }
  }
  yt.close();
}
