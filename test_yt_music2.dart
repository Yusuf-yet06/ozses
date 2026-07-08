import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  var yt = YoutubeExplode();
  try {
    // "Blinding Lights" by The Weeknd (Official Audio)
    var manifest = await yt.videos.streamsClient.getManifest('fHI8X4OXluQ');
    print('Basarili: ${manifest.audioOnly.length}');
  } catch(e) {
    print('Hata: $e');
  }
  yt.close();
}
