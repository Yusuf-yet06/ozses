import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  var yt = YoutubeExplode();
  try {
    var v = await yt.videos.get('jWh-7JGuxTo');
    var related = await yt.videos.getRelatedVideos(v);
    if (related != null) {
      print('Found ' + related.length.toString() + ' related videos');
      for (var vid in related.take(2)) {
        print(vid.title + ' | ' + vid.id.value);
      }
    } else {
        print("Related videos null");
    }
  } catch(e) {
    print(e);
  }
  yt.close();
}
