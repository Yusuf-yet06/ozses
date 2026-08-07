import 'dart:io';
import 'dart:convert';

void main() async {
  try {
    var res = await HttpClient().getUrl(Uri.parse('https://api.invidious.io/instances.json?sort_by=health'));
    var data = await (await res.close()).transform(utf8.decoder).join();
    var json = jsonDecode(data) as List;
    for(var i in json) {
      if(i[1]['type'] == 'https') {
        print(i[1]['uri']);
      }
    }
  } catch(e) {
    print(e);
  }
}
