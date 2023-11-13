///Shared library for enrollment system, common tools.
library;

import 'package:crypto/crypto.dart';

import 'dart:async';
import 'dart:convert';

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
  Stream<T> _brdStream;
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
    if (!_doCancel) {
      _doCancel = true;
      _brdStream.listen(null).cancel();
    }
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

//'loginHash' function.
//convert id and hashed password to hashed string, for login token.
String loginHash(String id, String hashedPw) {
  var bytes = utf8.encode(id + hashedPw);
  var digest = sha256.convert(bytes);
  return digest.toString();
}
//'pwHash' function.
//convert password to hashed string
String pwHash(String pw) {
  const String prefix =
    'CShm9dch2yEDBF3qHW2aUwMpH0jasf6KdsfFFlBMSXN1vLnlliYPTISFYvbotFaCB2zv0y';
  var bytes = utf8.encode(prefix + pw);
  var digest = sha256.convert(bytes);
  return digest.toString();
}

//check if 'inObj' is 'Map<String, dynamic>',
//  and every value is 'String'
bool isMapStr(dynamic inObj) {
  if (inObj is! Map<String, dynamic>) { return false; }
  for (dynamic value in inObj.values) {
    if (value is! String) { return false; }
  }
  return true;
}

//split 'str' with 'spChar', but consider escaping char 'esChar'
//'str' should not have NULL char ('\x00').
//'spChar' and 'esChar' should have ONE UTF-16 char unit.
List<String> splitExceptEscaped(
  final String str,
  final String spChar,
  final String esChar
) {
  final List<int> strList = str.runes.toList();
  int prevCharCode = 0, charCode = 0;
  int spCode = spChar.runes.toList().first;
  int esCode = esChar.runes.toList().first;
  //converts 'spCode' to 0, except escaped char.
  for (int idx = 0; idx < strList.length; idx++) {
    charCode = strList[idx];
    if (prevCharCode == esCode && charCode == esCode) {
      //CASE OF: char 'esCode', previous char 'esCode'
      prevCharCode = 0; continue;
    }
    if (prevCharCode != esCode && charCode == spCode) {
      //CASE OF: char 'spCode', without previous escape char
      prevCharCode = 0; strList[idx] = 0; continue;
    }
    prevCharCode = charCode;
  }
  //make string and split
  return String.fromCharCodes(strList).split(
    RegExp('\x00+', caseSensitive: false)
  );
}

//EOF
