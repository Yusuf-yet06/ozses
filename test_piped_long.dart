import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final videoId = '8s8m9rG_fSA';
  
  final List<String> pipedInstances = [
    'https://pipedapi.kavin.rocks',
    'https://api.piped.projectsegfau.lt',
    'https://pipedapi.smnz.de'
  ];
  
  for (var instance in pipedInstances) {
    try {
      print('Testing Piped: $instance...');
      var res = await http.get(Uri.parse('$instance/streams/$videoId')).timeout(Duration(seconds: 20));
      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        if (data['audioStreams'] != null && data['audioStreams'].isNotEmpty) {
          var url = data['audioStreams'][0]['url'];
          print('SUCCESS Piped: $url');
          
          // Test if URL actually streams
          var streamReq = await http.head(Uri.parse(url));
          print('Stream HEAD: ${streamReq.statusCode}');
        } else {
          print('No audioStreams in response');
        }
      } else {
        print('Failed Piped: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      print('Failed: $e');
    }
  }
}
