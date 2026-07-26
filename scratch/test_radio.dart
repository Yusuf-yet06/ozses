import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  var yt = YoutubeExplode();
  try {
    var related = await yt.videos.getRelatedVideos(VideoId('jWh-7JGuxTo'));
    if (related != null) {
      print('Found ' + related.length.toString() + ' related videos');
      for (var v in related.take(2)) {
        print(v.title + ' | ' + v.id.value);
      }
    } else {
        print("Related videos null");
    }
  } catch(e) {
    print(e);
  }
  yt.close();
}
