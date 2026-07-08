import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  var yt = YoutubeExplode();
  try {
    print('Fetching manifest...');
    var manifest = await yt.videos.streamsClient.getManifest('dQw4w9WgXcQ');
    var streamInfo = manifest.audioOnly.withHighestBitrate();
    print('Success! Stream URL: ${streamInfo.url}');
  } catch (e) {
    print('Error: $e');
  } finally {
    yt.close();
  }
}
