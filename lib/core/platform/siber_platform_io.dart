import 'dart:io';
import 'siber_platform.dart';
import 'mobile_platform.dart';
import 'windows_platform.dart';

SiberPlatform getPlatform() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return WindowsPlatform();
  } else if (Platform.isAndroid || Platform.isIOS) {
    return MobilePlatform();
  }
  throw UnsupportedError('Bu native platform henüz Siber Kalkan tarafından desteklenmiyor.');
}
