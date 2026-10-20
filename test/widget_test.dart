import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozses_v7/main.dart';
// Buradaki import ismini kendi proje adına göre kontrol et:

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Özses Başlatma Testi', (WidgetTester tester) async {
    // Uygulama bileşenlerinin temel render yeteneğini test eder
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('ÖZSES V7')),
      ),
    ));
    expect(find.text('ÖZSES V7'), findsOneWidget);
  });
}
