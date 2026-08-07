import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  String videoId = 'd0c-6o3x-nE'; // Example ID
  try {
    final res = await HttpClient().getUrl(Uri.parse('https://pipedapi.smnz.de/search?q=k%C4%B1rk+%C3%A7eriyiz&filter=all'));
    final req = await res.close();
    final body = await req.transform(utf8.decoder).join();
    final data = jsonDecode(body);
    if (data['items'] != null && data['items'].isNotEmpty) {
      videoId = data['items'][0]['url'].replaceAll('/watch?v=', '');
      print('Found Video ID: $videoId (${data['items'][0]['title']})');
    }
  } catch(e) {}

  print('Video ID: $videoId');

  print('\nTesting Invidious API for stream...');
  try {
    final invReq = await HttpClient().getUrl(Uri.parse('https://vid.puffyan.us/api/v1/videos/$videoId'));
    final invRes = await invReq.close();
    final invBody = await invRes.transform(utf8.decoder).join();
    final invData = jsonDecode(invBody);
    
    if (invData['adaptiveFormats'] != null) {
      for (var s in invData['adaptiveFormats']) {
        if (s['type'].toString().contains('audio')) {
          print('Invidious Stream: type=${s['type']} url=${s['url'].toString().substring(0, 30)}...');
        }
      }
    }
  } catch(e) {
    print('Invidious failed: $e');
  }

  print('\nTesting Cobalt API...');
  try {
    final cobaltReq = await HttpClient().postUrl(Uri.parse('https://api.cobalt.tools/api/json'));
    cobaltReq.headers.set('Accept', 'application/json');
    cobaltReq.headers.set('Content-Type', 'application/json');
    cobaltReq.write(jsonEncode({'url': 'https://www.youtube.com/watch?v=$videoId', 'isAudioOnly': true, 'aFormat': 'mp3'}));
    final cobaltRes = await cobaltReq.close();
    final cobaltBody = await cobaltRes.transform(utf8.decoder).join();
    print('Cobalt Body: $cobaltBody');
  } catch(e) {
    print('Cobalt failed: $e');
  }

  print('\nTesting Vercel API...');
  try {
    final vReq = await HttpClient().getUrl(Uri.parse('https://ozses-832f9y4py-ozses.vercel.app/stream?id=$videoId'));
    final vRes = await vReq.close();
    final vBody = await vRes.transform(utf8.decoder).join();
    print('Vercel Body: $vBody');
  } catch(e) {
    print('Vercel failed: $e');
  }
}
