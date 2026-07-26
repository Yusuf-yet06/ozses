import os

path = r'lib\services\services.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# PATCH 1: getRadio
old_radio = """  // 🎯 SİBER HAMLE: Otonom Radyo Motoru (YouTube Music Up Next)
  Future<List<dynamic>> getRadio(String videoId) async {
    try {
      print('📻 Siber Radyo İstek Gönderiliyor: $videoId');
      final response = await http.get(
        Uri.parse('https://ozses.onrender.com/radio?id=$videoId'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'basarili' && data['oneriler'] != null) {
          return data['oneriler'] as List<dynamic>;
        }
      }
      print('⚠️ Siber Radyo Yanıt Hatası: ${response.statusCode}');
    } catch (e) {
      print('Siber Radyo Hatası: $e');
    }
    return [];
  }"""

new_radio = """  // 🚀 SİBER HAMLE: Otonom Radyo Motoru (YouTube Music Up Next)
  Future<List<dynamic>> getRadio(String videoId) async {
    try {
      print('📻 Siber Radyo İstek Gönderiliyor (YEREL OTONOM): $videoId');
      var yt = YoutubeExplode();
      var v = await yt.videos.get(videoId);
      var related = await yt.videos.getRelatedVideos(v).timeout(const Duration(seconds: 15));
      var items = [];
      if (related != null) {
        for (var video in related.take(15)) {
          items.add({
            'id': video.id.value,
            'title': video.title,
            'channel': video.author,
            'thumbnail': video.thumbnails.highResUrl,
          });
        }
      }
      yt.close();
      return items;
    } catch (e) {
      print('🚀 Siber Radyo Hatası: $e');
    }
    return [];
  }"""

content = content.replace(old_radio, new_radio)


# PATCH 2: stream proxy
old_proxy = """        // 🚀 SİBER HAMLE: Render Backend (yt-dlp) → YoutubeExplode → Piped zinciri
        try {
          var yt = YoutubeExplode();
          Uri? finalStreamUrl;
          bool usedYoutubeExplode = false;
          dynamic ytStreamInfo;
          bool isRenderStream = false;

          // 🥇 1. SIRADA: Render Backend /stream (yt-dlp - en güvenilir)
          try {
            print('🎯 Proxy: Render Backend (yt-dlp) deneniyor...');
            final renderRes = await http.get(
              Uri.parse('https://ozses.onrender.com/stream?id=$videoId'),
            ).timeout(const Duration(seconds: 40)); // 40 saniye cold-start bekle
            
            print('🎯 Proxy: Render Backend Cevap Kodu: ${renderRes.statusCode}');
            if (renderRes.statusCode == 200) {
              final data = jsonDecode(renderRes.body);
              if (data['stream_url'] != null) {
                finalStreamUrl = Uri.parse(data['stream_url'].toString());
                isRenderStream = true;
                print('✅ Render Backend Stream Başarılı!');
              }
            } else {
              print('⚠️ Render Backend Hatası: ${renderRes.body}');
            }
          } catch (renderEx) {
            print('⚠️ Render Backend uyku modunda (cold start) veya hata: $renderEx');
          }

          // 🥈 2. SIRADA: Emergent Ghost Stream API (Hayalet Proxy)
          if (finalStreamUrl == null) {
            try {
              print('🎯 Proxy: Emergent Ghost Stream API deneniyor...');"""

new_proxy = """        // 🚀 SİBER HAMLE: YoutubeExplode -> Piped zinciri
        try {
          var yt = YoutubeExplode();
          Uri? finalStreamUrl;
          bool usedYoutubeExplode = false;
          dynamic ytStreamInfo;
          bool isRenderStream = false;

          // 🎯 1. SIRADA: YoutubeExplode (Yerel Motor)
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
              print('🎯 Proxy: Emergent Ghost Stream API deneniyor...');"""

old_proxy_2 = """          // 🥉 2. SIRADA: YoutubeExplode (Render uyurken yedek)
          if (finalStreamUrl == null) {
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
          }"""

content = content.replace(old_proxy, new_proxy)
content = content.replace(old_proxy_2, "")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("services.dart proxy chain patched properly!")
