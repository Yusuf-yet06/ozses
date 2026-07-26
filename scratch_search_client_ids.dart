import 'dart:io';

void main() {
  final dir = Directory('C:\\Users\\Admin\\Documents\\SQL Server Management Studio\\OZSES_V7_IMPERIUM');
  final out = File('C:\\Users\\Admin\\.gemini\\antigravity\\brain\\5b31f714-776d-40d0-91c5-7ffa77312fdb\\scratch\\client_ids.txt');
  final sink = out.openWrite();
  
  void searchDir(Directory d) {
    try {
      for (var entity in d.listSync()) {
        if (entity is Directory) {
          if (!entity.path.contains('.git') && !entity.path.contains('build') && !entity.path.contains('.dart_tool')) {
            searchDir(entity);
          }
        } else if (entity is File) {
          if (entity.path.endsWith('.json') || entity.path.endsWith('.plist') || entity.path.endsWith('.dart') || entity.path.endsWith('.html')) {
            try {
              final content = entity.readAsStringSync();
              if (content.contains('533526268311') || content.contains('661550093863')) {
                sink.writeln('Found in ${entity.path}');
                var lines = content.split('\n');
                for (int i=0; i<lines.length; i++) {
                  if (lines[i].contains('533526268311') || lines[i].contains('661550093863') || lines[i].contains('client_id')) {
                    sink.writeln('  Line ${i+1}: ${lines[i].trim()}');
                  }
                }
              }
            } catch(e) {}
          }
        }
      }
    } catch(e) {}
  }
  
  searchDir(dir);
  sink.close();
}
