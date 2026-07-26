import os
import re

# --- MOBILE PLATFORM ---
path = r'lib\core\platform\mobile_platform.dart'
with open(path, 'r', encoding='utf-8') as f:
    mobile_code = f.read()

# 1. Fix _AsyncMutex catchError
mobile_code = mobile_code.replace(
    "_last = next.whenComplete(() => Future.delayed(const Duration(milliseconds: 1000))).catchError((_) {});",
    "_last = next.whenComplete(() => Future.delayed(const Duration(milliseconds: 1000))).then((_) => null).catchError((_) => null);"
)

# 2. Fix fetchKesfet
old_kesfet = """  @override
  Future<Map<String, dynamic>> fetchKesfet({String? pageToken}) async {
    print('--- ÖZSES KEŞFET RADARI BAŞLATILIYOR (RENDER BACKEND) ---');
    final List<String> discoveryTerms = [
      'türkçe pop en çok dinlenenler official audio',
      'haftanın trend şarkıları',
      'yeni çıkan şarkılar 2026',
      'hit şarkılar karışık Türkçe',
      'viral türkçe şarkılar',
      'arabesk rap en çok dinlenenler',
      'akustik performans Türkçe',
    ];
    discoveryTerms.shuffle();
    String query = discoveryTerms.first;
    
    try {
      final response = await http.get(
        Uri.parse('https://ozses.onrender.com/search?q=${Uri.encodeComponent(query)}')
      ).timeout(const Duration(seconds: 45)); // Render uyanması (cold start) için 45 sn
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'basarili' && data['oneriler'] != null) {
          return {'status': 'basarili', 'oneriler': data['oneriler'], 'nextPageToken': ''};
        }
      }
    } catch (e) {
      print('❌ Siber Backend Keşfet Hatası: $e');
    }
    return {'status': 'hata', 'oneriler': [], 'nextPageToken': ''};
  }"""

new_kesfet = """  @override
  Future<Map<String, dynamic>> fetchKesfet({String? pageToken}) async {
    print('--- ÖZSES KEŞFET RADARI BAŞLATILIYOR (YEREL OTONOM) ---');
    final List<String> discoveryTerms = [
      'türkçe pop en çok dinlenenler official audio',
      'haftanın trend şarkıları',
      'yeni çıkan şarkılar 2026',
      'hit şarkılar karışık Türkçe',
      'viral türkçe şarkılar',
      'arabesk rap en çok dinlenenler',
      'akustik performans Türkçe',
    ];
    discoveryTerms.shuffle();
    String query = discoveryTerms.first;
    
    try {
      return await _ytMutex.run(() async {
        var searchResults = await _yt.search.search(query).timeout(const Duration(seconds: 15));
        var items = [];
        for (var video in searchResults.take(15)) {
          items.add({
            'id': video.id.value,
            'title': video.title,
            'channel': video.author,
            'thumbnail': video.thumbnails.highResUrl,
          });
        }
        if (items.isNotEmpty) {
          return {'status': 'basarili', 'oneriler': items, 'nextPageToken': ''};
        }
        return {'status': 'hata', 'oneriler': [], 'nextPageToken': ''};
      });
    } catch (e) {
      print('🚀 Siber Yerel Keşfet Hatası: $e');
    }
    return {'status': 'hata', 'oneriler': [], 'nextPageToken': ''};
  }"""

mobile_code = mobile_code.replace(old_kesfet, new_kesfet)

# 3. Fix searchMusic
old_search = """  @override
  Future<List<dynamic>> searchMusic(String query, {int limit = 15, int page = 1}) async {
    print('--- SİBER ARAMA BAŞLATILIYOR (RENDER BACKEND) ---');
    try {
      final response = await http.get(
        Uri.parse('https://ozses.onrender.com/search?q=${Uri.encodeComponent(query)}')
      ).timeout(const Duration(seconds: 45)); // Render uyanması (cold start) için 45 sn
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'basarili' && data['oneriler'] != null) {
          return data['oneriler'];
        }
      }
    } catch (e) {
      print('❌ Siber Backend Arama Hatası: $e');
    }
    return [];
  }"""

new_search = """  @override
  Future<List<dynamic>> searchMusic(String query, {int limit = 15, int page = 1}) async {
    print('--- SİBER ARAMA BAŞLATILIYOR (YEREL OTONOM) ---');
    try {
      return await _ytMutex.run(() async {
        var searchResults = await _yt.search.search(query).timeout(const Duration(seconds: 15));
        var items = [];
        for (var video in searchResults.take(limit)) {
          items.add({
            'id': video.id.value,
            'title': video.title,
            'channel': video.author,
            'thumbnail': video.thumbnails.highResUrl,
          });
        }
        return items;
      });
    } catch (e) {
      print('🚀 Siber Yerel Arama Hatası: $e');
    }
    return [];
  }"""

mobile_code = mobile_code.replace(old_search, new_search)

with open(path, 'w', encoding='utf-8') as f:
    f.write(mobile_code)

# --- SERVICES.DART ---
path = r'lib\services\services.dart'
with open(path, 'r', encoding='utf-8') as f:
    svc_code = f.read()

# 1. Fix getRadio
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

svc_code = svc_code.replace(old_radio, new_radio)

# 2. Fix the stream resolution proxy chain
# We will use regex to find everything from `// 🚀 SİBER HAMLE: HttpClient ile 403` down to the `if (finalStreamUrl == null) { throw Exception` block

pattern = r"(?s)// 🚀 SİBER HAMLE: HttpClient ile 403.*?if \(finalStreamUrl == null\) \{\s*throw Exception\('Tüm akış motorları.*?'\);\s*\}"

new_proxy = """// 🚀 SİBER HAMLE: Merkezsiz Akış Çözücü
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
          
          if (finalStreamUrl == null) {
             throw Exception('Tüm akış motorları (YoutubeExplode + Ghost) çöktü!');
          }"""

svc_code = re.sub(pattern, new_proxy, svc_code)

with open(path, 'w', encoding='utf-8') as f:
    f.write(svc_code)

print("Patch applied successfully.")
