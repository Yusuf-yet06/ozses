import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  try {
    var manifest = await yt.videos.streamsClient.getManifest('8s8m9rG_fSA');
    var streamInfo = manifest.audioOnly.withHighestBitrate();
    
    // Instead of getting the URL, let's use yt.videos.streamsClient.get(streamInfo)
    print('Testing yt.videos.streamsClient.get(streamInfo)...');
    var stream = yt.videos.streamsClient.get(streamInfo);
    
    int bytes = 0;
    await for (var data in stream) {
      bytes += data.length;
      if (bytes > 100000) break; // just test first 100kb
    }
    print('Successfully downloaded $bytes bytes through YoutubeExplode directly!');
  } catch (e) {
    print('Error: $e');
  } finally {
    yt.close();
  }
}
