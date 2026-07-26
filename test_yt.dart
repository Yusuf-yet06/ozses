import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  try {
    print('Fetching video...');
    var video = await yt.videos.get('8s8m9rG_fSA');
    print('Title: ${video.title}');
    print('Thumbnails: ${video.thumbnails.highResUrl}');
    
    print('Fetching manifest...');
    var manifest = await yt.videos.streamsClient.getManifest('8s8m9rG_fSA');
    var streamInfo = manifest.audioOnly.withHighestBitrate();
    print('Stream URL: ${streamInfo.url}');
  } catch (e) {
    print('Error: $e');
  } finally {
    yt.close();
  }
}
