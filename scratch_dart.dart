import 'dart:io';

void main() {
  var file = File('lib/screens/discover_screen.dart');
  var lines = file.readAsLinesSync();
  var out = File('scratch_out.txt');
  var outSink = out.openWrite();
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('_showGuestModeDialog')) {
      int startLine = i + 1;
      outSink.writeln('Found at line $startLine: ${lines[i]}');
    }
  }
  outSink.close();
}
