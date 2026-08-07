import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('Testing various Cobalt instances...');
  var instances = [
    'https://cobalt.kwiatektv.me',
    'https://co.eepy.today',
    'https://cobalt.pk11.me',
    'https://api.cobalt.is-cool.dev',
    'https://cobalt.pepegang.in.net'
  ];
  
  for(var url in instances) {
    try {
      print('Testing $url...');
      final req = await HttpClient().postUrl(Uri.parse('$url/'));
      req.headers.set('Accept', 'application/json');
      req.headers.set('Content-Type', 'application/json');
      req.write(jsonEncode({'url': 'https://www.youtube.com/watch?v=d0c-6o3x-nE', 'downloadMode': 'audio'}));
      final res = await req.close().timeout(Duration(seconds: 5));
      final body = await res.transform(utf8.decoder).join();
      print('Result ($url): ${res.statusCode} - ${body.substring(0, body.length > 50 ? 50 : body.length)}');
    } catch(e) {
      print('Failed ($url): $e');
    }
  }
}
