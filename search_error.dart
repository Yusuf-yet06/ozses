import 'dart:io';

void main() {
  final dir = Directory('lib');
  for (var entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      if (content.contains('Açık bir şarkı yok') || content.contains('veriler yüklenmedi')) {
        print('Found in: \${entity.path}');
      }
    }
  }
}
