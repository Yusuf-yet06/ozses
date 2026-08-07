import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  String videoId = 'd0c-6o3x-nE'; 
  
  var instances = [
    'https://pipedapi.kavin.rocks',
    'https://pipedapi.smnz.de',
    'https://pipedapi.adminforge.de',
    'https://pipedapi.moomoo.me',
    'https://api.piped.projectsegfau.lt',
    'https://pipedapi.lunar.icu'
  ];
  
  for(var url in instances) {
    try {
      print('Testing $url...');
      final req = await HttpClient().getUrl(Uri.parse('$url/streams/$videoId'));
      final res = await req.close().timeout(Duration(seconds: 5));
      final body = await res.transform(utf8.decoder).join();
      if(res.statusCode == 200) {
        final data = jsonDecode(body);
        print('SUCCESS: $url (streams: ${data['audioStreams']?.length})');
      } else {
        print('FAILED: $url (Status ${res.statusCode}) - ${body.substring(0, body.length > 50 ? 50 : body.length)}');
      }
    } catch(e) {
      print('ERROR: $url - $e');
    }
  }
}
