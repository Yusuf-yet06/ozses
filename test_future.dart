
import 'dart:async';
Future<T> firstSuccessful<T>(Iterable<Future<T>> futures) {
  final completer = Completer<T>();
  int remaining = futures.length;
  List<Object> errors = [];
  
  if (remaining == 0) return Future.error('No futures provided');
  
  for (var future in futures) {
    future.then((value) {
      if (!completer.isCompleted) completer.complete(value);
    }).catchError((error) {
      errors.add(error);
      remaining--;
      if (remaining == 0 && !completer.isCompleted) {
        completer.completeError(Exception('All futures failed: '));
      }
    });
  }
  return completer.future;
}

void main() async {
  try {
    var res = await firstSuccessful([
      Future.error('Error 1').whenComplete(()=>print('E1 done')),
      Future.delayed(Duration(seconds: 1), () => 'Success!'),
      Future.error('Error 2').whenComplete(()=>print('E2 done')),
    ]);
    print('Result: ');
  } catch (e) {
    print('Catch: ');
  }
}
