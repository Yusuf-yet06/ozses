import 'dart:io';

void searchDir(Directory dir) {
  for (var entity in dir.listSync()) {
    if (entity is Directory) {
      if (!entity.path.contains('build') && !entity.path.contains('.dart_tool') && !entity.path.contains('.git')) {
        searchDir(entity);
      }
    } else if (entity is File) {
      if (entity.path.endsWith('.dart') || entity.path.endsWith('.py')) {
        try {
          final content = entity.readAsStringSync();
          if (content.contains('Açık bir şarkı yok')) {
            print('EXACT MATCH Found in: ' + entity.path);
          }
        } catch (e) {}
      }
    }
  }
}

void main() {
  searchDir(Directory('.'));
}
