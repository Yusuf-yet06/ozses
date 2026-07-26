import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_explode_dart/src/videos/youtube_api_client.dart';

void main() async {
  var yt = YoutubeExplode();
  try {
    var searchClient = yt.search;
    var results = await searchClient.search('türkçe pop');
    print('Found: ' + results.length.toString());
    for (var video in results.take(3)) {
      print(video.title + " | " + video.id.value);
    }
  } catch (e) {
    print('Error: ' + e.toString());
  }
  yt.close();
}
