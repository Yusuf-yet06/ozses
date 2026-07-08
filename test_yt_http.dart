import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;

void main() async {
  var yt = YoutubeExplode();
  try {
    // "Blinding Lights" by The Weeknd (Official Audio)
    var manifest = await yt.videos.streamsClient.getManifest('fHI8X4OXluQ', ytClients: [YoutubeApiClient.ios]);
    var audioStreams = manifest.audioOnly.where((s) => s.container.name == 'mp4' || s.container.name == 'm4a');
    if (audioStreams.isEmpty) audioStreams = manifest.audioOnly;
    var streamInfo = audioStreams.withHighestBitrate();
    
    print('Stream URL: ${streamInfo.url}');
    
    var response = await http.head(streamInfo.url);
    print('HTTP Status: ${response.statusCode}');
  } catch(e) {
    print('Hata: $e');
  }
  yt.close();
}
