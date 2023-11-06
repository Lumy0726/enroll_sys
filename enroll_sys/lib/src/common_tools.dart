///Shared library for enrollment system, common tools.
library;

import 'dart:async';

//class 'BrdStreamWithCancel'.
//
//This class receives 'Stream<T>' in the constructor,
//  and call 'asBroadcastStream' of it.
//You can get broadcasted stream with '.stream'.
//If you call '.cancelStream',
//  the underlying 'StreamSubscription' of 'Stream<T>',
//  would be canceeled.
//
//This is useful for streams like 'io.stdin',
//  because in order to prevent never-terminated program problem,
//  program must cancel the underlying 'StreamSubscription' of stdin,
//  after 'stdin.asBroadcastStream', before end of program.
//  See 'https://github.com/dart-lang/sdk/issues/45098' for related issues.
class BrdStreamWithCancel<T> {
  late Stream<T> _brdStream;
  bool _doCancel = false;
  BrdStreamWithCancel(Stream<T> inStream) : _brdStream = inStream {
    _brdStream = inStream.asBroadcastStream(
      onCancel: (subs) {
        if (_doCancel) subs.cancel();
      }
    );
  }
  Stream<T> get stream => _brdStream;
  void cancelStream() {
    _doCancel = true;
    _brdStream.listen(null).cancel();
  }
}

//Get current received elements from 'Stream<T>',
//  which is the broadcasted stream.
//If the stream is not broadcasted,
//  it is only possible to call this once,
//  because this function use '.listen' for stream.
Future<T> readFirstFromBrdStream<T>(final Stream<T> stream) async {
  final Completer<T> c = Completer<T>();
  StreamSubscription<T>? subs;
  subs = stream
    .listen((value) {
      if (!c.isCompleted) {
        subs!.cancel();
        c.complete(value);
      }
    });
  return c.future;
  //final value = await c.future;
  //subs.cancel();
  //return value;
}

//EOF
