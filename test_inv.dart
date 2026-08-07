import 'dart:io';
import 'dart:convert';

void main() async {
  var videoId = 'd0c-6o3x-nE';
  var instances = [
    'https://invidious.f5.si',
    'https://invidious.nerdvpn.de',
    'https://inv.nadeko.net',
    'https://invidious.tiekoetter.com',
    'https://yt.chocolatemoo53.com',
    'https://inv.zoomerville.com'
  ];
  
  for(var inst in instances) {
    try {
      var url = '$inst/api/v1/videos/$videoId';
      var res = await HttpClient().getUrl(Uri.parse(url));
      var data = await (await res.close()).timeout(Duration(seconds: 10)).transform(utf8.decoder).join();
      var json = jsonDecode(data);
      if(json['adaptiveFormats'] != null) {
        var audio = json['adaptiveFormats'].firstWhere((f) => f['type'].contains('audio'), orElse: () => null);
        if(audio != null) {
          print('SUCCESS: $inst');
        } else {
          print('NO AUDIO: $inst');
        }
      } else {
        print('NO FORMATS: $inst');
      }
    } catch(e) {
      print('ERROR: $inst - $e');
    }
  }
}
