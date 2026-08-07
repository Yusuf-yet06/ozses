import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('Testing cobalt.q0.is...');
  try {
    final cobaltReq = await HttpClient().postUrl(Uri.parse('https://cobalt.q0.is/'));
    cobaltReq.headers.set('Accept', 'application/json');
    cobaltReq.headers.set('Content-Type', 'application/json');
    cobaltReq.write(jsonEncode({'url': 'https://www.youtube.com/watch?v=d0c-6o3x-nE', 'downloadMode': 'audio'}));
    final cobaltRes = await cobaltReq.close();
    final cobaltBody = await cobaltRes.transform(utf8.decoder).join();
    print('Cobalt Body: $cobaltBody');
  } catch(e) {
    print('Cobalt failed: $e');
  }
}
