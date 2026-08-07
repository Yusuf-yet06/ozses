import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  String videoId = 'd0c-6o3x-nE'; 
  
  var instances = [
    'https://piped.video/api/streams/$videoId',
    'https://pipedapi.drgns.space/streams/$videoId',
    'https://pipedapi.tokhmi.xyz/streams/$videoId',
    'https://api.piped.privacy.com.de/streams/$videoId',
    'https://pipedapi.syncpundit.io/streams/$videoId',
    'https://pipedapi.privacydev.net/streams/$videoId'
  ];
  
  for(var url in instances) {
    try {
      print('Testing $url...');
      final req = await HttpClient().getUrl(Uri.parse(url));
      final res = await req.close().timeout(Duration(seconds: 5));
      final body = await res.transform(utf8.decoder).join();
      if(res.statusCode == 200) {
        print('SUCCESS: $url');
      } else {
        print('FAILED: $url (Status ${res.statusCode}) - ${body.substring(0, body.length > 50 ? 50 : body.length)}');
      }
    } catch(e) {
      print('ERROR: $url - $e');
    }
  }
}
