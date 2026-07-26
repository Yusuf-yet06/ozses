import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final List<String> pipedInstances = [
    'https://pipedapi.kavin.rocks',
    'https://pipedapi.tokhmi.xyz',
    'https://pipedapi.syncpundit.io',
    'https://api.piped.privacydev.net'
  ];
  
  for (var instance in pipedInstances) {
    print('Trying ${instance}...');
    try {
      var res = await http.get(Uri.parse('${instance}/search?q=tarkan&filter=music_songs')).timeout(Duration(seconds: 5));
      print(res.statusCode);
      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        print(data['items'][0]);
        break;
      }
    } catch(e) {
      print(e);
    }
  }
}
