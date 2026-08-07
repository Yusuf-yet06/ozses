import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  String videoId = 'd0c-6o3x-nE'; 
  print('\nTesting Piped on adminforge...');
  try {
    final res = await HttpClient().getUrl(Uri.parse('https://pipedapi.adminforge.de/streams/$videoId'));
    final req = await res.close();
    final body = await req.transform(utf8.decoder).join();
    final data = jsonDecode(body);
    print('Piped Streams: ${data['audioStreams']?.length}');
    if (data['audioStreams'] != null) {
      for(var s in data['audioStreams']) print(s['mimeType']);
    }
  } catch(e) { print(e); }

  print('\nTesting Invidious on lunar...');
  try {
    final res = await HttpClient().getUrl(Uri.parse('https://invidious.lunar.icu/api/v1/videos/$videoId'));
    final req = await res.close();
    final body = await req.transform(utf8.decoder).join();
    final data = jsonDecode(body);
    print('Invidious adaptiveFormats: ${data['adaptiveFormats']?.length}');
    if (data['adaptiveFormats'] != null) {
      for(var s in data['adaptiveFormats']) print(s['type']);
    }
  } catch(e) { print(e); }
}
