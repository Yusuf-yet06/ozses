import 'siber_platform_stub.dart'
    if (dart.library.html) 'siber_platform_web.dart'
    if (dart.library.io) 'siber_platform_io.dart';

abstract class SiberPlatform {
  static SiberPlatform get instance => getPlatform();

  Future<Map<String, dynamic>> fetchKesfet({String? pageToken});
  Future<List<dynamic>> searchMusic(String query, {int limit = 15, int page = 1});
  Future<List<String>> getSearchSuggestions(String query);
  Future<Map<String, dynamic>> getStreamUrl(String videoId);
  Future<String> getDownloadPath();
  Future<List<String>> scanMusicFolders();
  bool get supportsHardwareDSP;
}
