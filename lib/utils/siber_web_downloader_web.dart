import 'dart:html' as html;

void triggerWebDownload(String url, String fileName) {
  try {
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..target = '_blank'
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
  } catch (e) {
    print('Web indirme tetikleme hatası: $e');
  }
}
