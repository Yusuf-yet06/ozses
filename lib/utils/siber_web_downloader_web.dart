import 'package:web/web.dart' as web;

void triggerWebDownload(String url, String fileName) {
  try {
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName
      ..target = '_blank'
      ..style.display = 'none';
    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
  } catch (e) {
    print('Web indirme tetikleme hatası: $e');
  }
}
