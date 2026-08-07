import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('Testing official Cobalt API...');
  try {
    final cobaltReq = await HttpClient().postUrl(Uri.parse('https://api.cobalt.tools/'));
    cobaltReq.headers.set('Accept', 'application/json');
    cobaltReq.headers.set('Content-Type', 'application/json');
    cobaltReq.write(jsonEncode({'url': 'https://www.youtube.com/watch?v=d0c-6o3x-nE', 'downloadMode': 'audio'}));
    final cobaltRes = await cobaltReq.close();
    final cobaltBody = await cobaltRes.transform(utf8.decoder).join();
    print('Cobalt Result: ${cobaltRes.statusCode} - $cobaltBody');
  } catch(e) {
    print('Cobalt failed: $e');
  }
}
