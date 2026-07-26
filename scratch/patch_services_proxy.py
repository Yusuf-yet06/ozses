import os

path = r'lib\services\services.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# I want to find the section between:
# "// 🚀 SİBER HAMLE: YoutubeExplode -> Piped zinciri"
# and
# "if (finalStreamUrl != null) {"

start_marker = "// 🚀 SİBER HAMLE: YoutubeExplode -> Piped zinciri"
end_marker = "if (finalStreamUrl != null) {"

start_idx = content.find(start_marker)
end_idx = content.find(end_marker)

if start_idx != -1 and end_idx != -1:
    new_section = """// 🚀 SİBER HAMLE: Merkezsiz Yerel Motor (YoutubeExplode) -> Ghost -> Cobalt zinciri
        try {
          var yt = YoutubeExplode();
          Uri? finalStreamUrl;
          bool usedYoutubeExplode = false;
          dynamic ytStreamInfo;
          bool isRenderStream = false;

          // 🎯 1. SIRADA: YoutubeExplode (Yerel Motor - IP Ban yemez)
          print('🎯 Proxy: YoutubeExplode (Yerel Motor) Devrede...');
          try {
            var manifest = await yt.videos.streamsClient.getManifest(videoId, ytClients: [YoutubeApiClient.androidVr, YoutubeApiClient.androidSdkless, YoutubeApiClient.android]);
            var audioStreamList = manifest.audioOnly.where((s) => s.container.name == 'mp4' || s.audioCodec.contains('mp4a')).toList();
            ytStreamInfo = audioStreamList.isNotEmpty ? audioStreamList.reduce((a, b) => a.bitrate.bitsPerSecond > b.bitrate.bitsPerSecond ? a : b) : manifest.audioOnly.withHighestBitrate();
            finalStreamUrl = ytStreamInfo.url;
            usedYoutubeExplode = true;
          } catch (ytEx) {
            print('⚠️ YoutubeExplode Hatası: $ytEx');
          }

          // 🥈 2. SIRADA: Emergent Ghost Stream API (Hayalet Proxy)
          if (finalStreamUrl == null) {
            try {
              print('🎯 Proxy: Emergent Ghost Stream API deneniyor...');
              final ghostRes = await http.post(
                Uri.parse('https://ghost-stream-api.preview.emergentagent.com/api/stream'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({"video_id": videoId, "quality": "high"})
              ).timeout(const Duration(seconds: 20));
              
              if (ghostRes.statusCode == 200) {
                final data = jsonDecode(ghostRes.body);
                if (data['stream_url'] != null) {
                  finalStreamUrl = Uri.parse(data['stream_url'].toString());
                  print('✅ Emergent Ghost Stream Başarılı!');
                }
              }
            } catch (ghostEx) {
              print('⚠️ Ghost Stream API Hatası: $ghostEx');
            }
          }

          """
    content = content[:start_idx] + new_section + content[end_idx:]

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("services.dart proxy chain patched!")
