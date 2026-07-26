import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  try {
    var res = await http.get(Uri.parse('https://pipedapi.kavin.rocks/search?q=tarkan&filter=all'));
    print(res.statusCode);
    var data = jsonDecode(res.body);
    print(data['items'][0]);
  } catch(e) {
    print(e);
  }
}
