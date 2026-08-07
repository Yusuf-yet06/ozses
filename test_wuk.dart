import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('\nTesting Cobalt v9 API on wuk.sh...');
  try {
    final cobaltReq = await HttpClient().postUrl(Uri.parse('https://co.wuk.sh/'));
    cobaltReq.headers.set('Accept', 'application/json');
    cobaltReq.headers.set('Content-Type', 'application/json');
    cobaltReq.write(jsonEncode({'url': 'https://www.youtube.com/watch?v=d0c-6o3x-nE', 'downloadMode': 'audio', 'audioFormat': 'mp3'}));
    final cobaltRes = await cobaltReq.close();
    final cobaltBody = await cobaltRes.transform(utf8.decoder).join();
    print('Cobalt Body: $cobaltBody');
  } catch(e) {
    print('Cobalt failed: $e');
  }
}
