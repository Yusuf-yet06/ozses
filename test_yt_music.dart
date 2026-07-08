import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  var yt = YoutubeExplode();
  try {
    var manifest = await yt.videos.streamsClient.getManifest('dQw4w9WgXcQ');
    print('Basarili: ${manifest.audioOnly.length}');
  } catch(e) {
    print('Hata: $e');
  }
  yt.close();
}
