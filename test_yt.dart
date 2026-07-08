import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  var yt = YoutubeExplode();
  var manifest = await yt.videos.streamsClient.getManifest('jNQXAC9IVRw');
  for (var s in manifest.audioOnly) {
    print('${s.container.name} - ${s.size}');
  }
  yt.close();
}
