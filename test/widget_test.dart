import 'package:flutter_test/flutter_test.dart';
import 'package:ozses_v7/main.dart';
// Buradaki import ismini kendi proje adına göre kontrol et:

void main() {
  testWidgets('Özses Başlatma Testi', (WidgetTester tester) async {
    // Sadece uygulamanın açılıp açılmadığını kontrol eder
    await tester.pumpWidget(const OzsesMusicApp());
  });
}
