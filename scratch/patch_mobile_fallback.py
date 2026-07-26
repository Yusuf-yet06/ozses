import os
import re

path = r'lib\core\platform\mobile_platform.dart'
with open(path, 'r', encoding='utf-8') as f:
    mobile_code = f.read()

# Fix searchMusic to have Piped Fallback
old_search = """  @override
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
      print('🔄 SİBER KALKAN: Piped Arama Fallback Devrede...');
      final List<String> pipedInstances = [
        'https://pipedapi.kavin.rocks',
        'https://pipedapi.moomoo.me',
        'https://api.piped.projectsegfau.lt'
      ];
      for (var instance in pipedInstances) {
        try {
          final res = await http.get(Uri.parse('$instance/search?q=${Uri.encodeComponent(query)}&filter=all')).timeout(const Duration(seconds: 10));
          if (res.statusCode == 200) {
             final data = jsonDecode(res.body);
             var items = [];
             for (var item in data['items']) {
               if (item['type'] == 'stream') {
                 items.add({
                    'id': item['url'].replaceAll('/watch?v=', ''),
                    'title': item['title'],
                    'channel': item['uploaderName'],
                    'thumbnail': item['thumbnail']
                 });
               }
             }
             if (items.isNotEmpty) return items;
          }
        } catch (ex) {
          print('⚠️ Piped Arama Hatası ($instance): $ex');
        }
      }
    }
    return [];
  }"""

mobile_code = mobile_code.replace(old_search, new_search)

# Fix fetchKesfet to have Piped Fallback
old_kesfet = """  @override
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
      print('🔄 SİBER KALKAN: Piped Keşfet Fallback Devrede...');
      final List<String> pipedInstances = [
        'https://pipedapi.kavin.rocks',
        'https://pipedapi.moomoo.me',
        'https://api.piped.projectsegfau.lt'
      ];
      for (var instance in pipedInstances) {
        try {
          final res = await http.get(Uri.parse('$instance/search?q=${Uri.encodeComponent(query)}&filter=all')).timeout(const Duration(seconds: 10));
          if (res.statusCode == 200) {
             final data = jsonDecode(res.body);
             var items = [];
             for (var item in data['items']) {
               if (item['type'] == 'stream') {
                 items.add({
                    'id': item['url'].replaceAll('/watch?v=', ''),
                    'title': item['title'],
                    'channel': item['uploaderName'],
                    'thumbnail': item['thumbnail']
                 });
               }
             }
             if (items.isNotEmpty) {
               return {'status': 'basarili', 'oneriler': items, 'nextPageToken': ''};
             }
          }
        } catch (ex) {
          print('⚠️ Piped Keşfet Hatası ($instance): $ex');
        }
      }
    }
    return {'status': 'hata', 'oneriler': [], 'nextPageToken': ''};
  }"""

mobile_code = mobile_code.replace(old_kesfet, new_kesfet)

with open(path, 'w', encoding='utf-8') as f:
    f.write(mobile_code)

print("Mobile platform patched with Piped search fallback.")
