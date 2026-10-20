import 'siber_web_downloader_stub.dart'
    if (dart.library.html) 'siber_web_downloader_web.dart';

void downloadWebFile(String url, String fileName) {
  triggerWebDownload(url, fileName);
}
