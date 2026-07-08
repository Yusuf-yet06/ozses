import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final instances = [
    'https://pipedapi.kavin.rocks',
    'https://pipedapi.lunar.icu',
    'https://pipedapi.adminforge.de',
    'https://pipedapi.astartes.nl',
    'https://pipedapi.smnz.de',
    'https://piped-api.garudalinux.org',
    'https://api.piped.projectsegfau.lt',
    'https://pipedapi.in.projectsegfau.lt',
    'https://pipedapi.us.projectsegfau.lt'
  ];

  for (var instance in instances) {
    try {
      final res = await http.get(Uri.parse('$instance/streams/dQw4w9WgXcQ')).timeout(Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['audioStreams'] != null && data['audioStreams'].isNotEmpty) {
          print('SUCCESS: $instance -> ${data['audioStreams'][0]['url']}');
          return;
        }
      }
    } catch (e) {
      // ignore
    }
  }
  print('ALL FAILED');
}
