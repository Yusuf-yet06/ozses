import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final videoId = '8s8m9rG_fSA';
  final List<String> cobaltInstances = [
    'https://api.cobalt.tools',
    'https://cobalt-api.kwiatekmateusz.pl',
    'https://co.wuk.sh'
  ];

  for (var instance in cobaltInstances) {
    try {
      print('Testing Cobalt: $instance...');
      var reqUrl = instance.contains('wuk.sh') ? '$instance/api/json' : '$instance/';
      var res = await http.post(
        Uri.parse(reqUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
        },
        body: jsonEncode({
          'url': 'https://www.youtube.com/watch?v=$videoId',
          'aFormat': 'mp3',
          'isAudioOnly': true,
        })
      ).timeout(Duration(seconds: 10));

      if (res.statusCode == 200 || res.statusCode == 307) {
        print('SUCCESS: ${res.body}');
      } else {
        print('Failed: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
