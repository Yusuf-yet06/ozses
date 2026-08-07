import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<void> main() async {
  var yt = YoutubeExplode();
  try {
    var manifest = await yt.videos.streamsClient.getManifest('d0c-6o3x-nE');
    for(var s in manifest.audioOnly) {
      print('YT Stream: container=${s.container.name} codec=${s.audioCodec} url=${s.url.toString().substring(0,60)}...');
    }
  } catch(e) {
    print('YoutubeExplode failed: $e');
  }
  yt.close();
}
