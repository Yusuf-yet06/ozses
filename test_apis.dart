import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final videoId = '8s8m9rG_fSA';
  
  final List<String> pipedInstances = [
    'https://pipedapi.kavin.rocks',
    'https://pipedapi.moomoo.me',
    'https://pipedapi.syncpundit.io',
    'https://api.piped.projectsegfau.lt',
    'https://pipedapi.smnz.de'
  ];
  
  for (var instance in pipedInstances) {
    try {
      print('Testing Piped: $instance...');
      var res = await http.get(Uri.parse('$instance/streams/$videoId')).timeout(Duration(seconds: 5));
      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        var url = data['audioStreams'][0]['url'];
        print('SUCCESS Piped: $url');
        return;
      }
    } catch (e) {
      print('Failed: $e');
    }
  }
  
  final List<String> invidiousInstances = [
    'https://inv.tux.pizza',
    'https://invidious.asir.dev',
    'https://invidious.io.lol',
    'https://invidious.slipfox.xyz',
    'https://inv.bp.projectsegfau.lt'
  ];
  
  for (var instance in invidiousInstances) {
    try {
      print('Testing Invidious: $instance...');
      var res = await http.get(Uri.parse('$instance/api/v1/videos/$videoId')).timeout(Duration(seconds: 5));
      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        var url = data['formatStreams'][0]['url'];
        print('SUCCESS Invidious: $url');
        return;
      }
    } catch (e) {
      print('Failed: $e');
    }
  }
}
