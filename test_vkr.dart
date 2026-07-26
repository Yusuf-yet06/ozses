import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  try {
    var res = await http.get(Uri.parse('https://api.vkrdownloader.vercel.app/server?v=8s8m9rG_fSA'));
    print('Status: ${res.statusCode}');
    print('Body: ${res.body}');
  } catch (e) {
    print('Error: $e');
  }
}
