import 'ad_platform_interface.dart';
import 'ad_platform_stub.dart'
    if (dart.library.io) 'ad_platform_mobile.dart'
    if (dart.library.html) 'ad_platform_web.dart';

// Not: Windows için dart:io kullanıldığından yukarıdaki kural Windows'u da 'mobile.dart' a sokar.
// Bunu engellemek ve otonom bir yapı kurmak için ad_manager.dart içerisinde 
// Platform.isWindows kontrolü yaparak getAdPlatform() yerine manuel olarak 
// AdPlatformWindows'u tetikleyeceğiz, çünkü şartlı içe aktarmada OS (İşletim sistemi) bazlı 
// conditional import doğrudan desteklenmez, sadece library (io/html) bazlı desteklenir.
// O yüzden siber_ad_manager.dart sadece temel köprü görevini görecektir.

AdPlatform getUniversalAdPlatform() => getAdPlatform();
