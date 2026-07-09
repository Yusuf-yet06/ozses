import re

path = r'C:\Users\Admin\Documents\SQL Server Management Studio\OZSES_V7_IMPERIUM\lib\services\services.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# We want to replace the block that gets manifest and streamInfo.
old_block = """        try {
          var yt = YoutubeExplode();
          var manifest = await yt.videos.streamsClient.getManifest(videoId);
          var audioStreamList = manifest.audioOnly.where((s) => s.container.name == 'mp4' || s.audioCodec.contains('mp4a')).toList();
          var streamInfo = audioStreamList.isNotEmpty ? audioStreamList.reduce((a, b) => a.bitrate.bitsPerSecond > b.bitrate.bitsPerSecond ? a : b) : manifest.audioOnly.withHighestBitrate();
          
          var reqHeaders = <String, String>{};"""

new_block = """        try {
          var yt = YoutubeExplode();
          Uri? finalStreamUrl;
          
          try {
            var manifest = await yt.videos.streamsClient.getManifest(videoId);
            var audioStreamList = manifest.audioOnly.where((s) => s.container.name == 'mp4' || s.audioCodec.contains('mp4a')).toList();
            var streamInfo = audioStreamList.isNotEmpty ? audioStreamList.reduce((a, b) => a.bitrate.bitsPerSecond > b.bitrate.bitsPerSecond ? a : b) : manifest.audioOnly.withHighestBitrate();
            finalStreamUrl = streamInfo.url;
          } catch (ytEx) {
            print('⚠️ YoutubeExplode Rate Limit: $ytEx');
            print('🔄 SİBER KALKAN: Piped Yedek (Fallback) Devrede...');
            
            final List<String> pipedInstances = [
              'https://api.piped.private.coffee',
              'https://pipedapi.kavin.rocks',
              'https://api.piped.privacydev.net',
              'https://piped-api.lunar.icu',
              'https://pipedapi.smnz.de'
            ];
            
            for (var instance in pipedInstances) {
              try {
                final response = await http.get(Uri.parse('$instance/streams/$videoId')).timeout(const Duration(seconds: 4));
                if (response.statusCode == 200) {
                  final data = jsonDecode(response.body);
                  if (data['audioStreams'] != null && (data['audioStreams'] as List).isNotEmpty) {
                    var audioStreams = data['audioStreams'] as List;
                    var bestStream = audioStreams.firstWhere(
                      (s) => s['format'] == 'M4A',
                      orElse: () => audioStreams.first,
                    );
                    finalStreamUrl = Uri.parse(bestStream['url'].toString());
                    print('✅ Piped Fallback Başarılı: $instance');
                    break;
                  }
                }
              } catch (_) {}
            }
          }
          
          if (finalStreamUrl == null) {
            throw Exception('Tüm akış motorları (YoutubeExplode + Piped) çöktü!');
          }
          
          var reqHeaders = <String, String>{};"""

# Also we need to replace streamInfo.url with finalStreamUrl
old_request_block = """          var client = http.Client();
          var streamRequest = http.Request('GET', streamInfo.url);"""

new_request_block = """          var client = http.Client();
          var streamRequest = http.Request('GET', finalStreamUrl);"""

if old_block in content:
    content = content.replace(old_block, new_block)
    content = content.replace(old_request_block, new_request_block)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Patch applied successfully.")
else:
    print("Error: Could not find the old block to replace.")
