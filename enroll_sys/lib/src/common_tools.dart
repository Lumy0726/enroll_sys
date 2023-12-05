///Shared library for enrollment system, common tools.
library;

import 'package:crypto/crypto.dart';

import 'dart:async';
import 'dart:convert';

///'mapIntersect' function. Intersect 'Map<K, V>' like 'Set'.
///
///The value of returned map, is the value of 'map1'.
Map<K, V> mapIntersect<K, V>(
  final Map<K, V> map1,
  final Map<K, V> map2
) {
  Map<K, V> ret = {};
  for (var entry in map1.entries) {
    if (map2.containsKey(entry.key)) {
      ret[entry.key] = entry.value;
    }
  }
  return ret;
}

///Converts 'Stream<List<int>>' to String (with utf8 format),
///and converts to 'dynamic' with json format.
///Exception can be thrown.
///Common use case is converting 'HttpRequest' or 'HttpClientRequest'.
Future<dynamic> utf8StreamList2JsonObj(final Stream<List<int>> stream) async {
  final String jsonStr = await utf8.decoder.bind(stream).join();
  return jsonDecode(jsonStr);
}

///class 'CancelableDelayed'.
///
///This is similar with 'Future.delayed',
///  but the 'Future' object can be accessed using '.future',
///  and '.cancel()' function cancels the desired computation.
///
///NOTE:
///  The '.future' will be completed with error,
///    with type 'String', with value 'canceled',
///    if desired computation is canceled.
class CancelableDelayed<T> {
  late Timer _timer;
  final FutureOr<T> Function() _compu;
  final Completer<T> _compl = Completer<T>();
  //
  Future<T> get future => _compl.future;
  //constructor. Similar with 'Future.delayed'
  CancelableDelayed(
    final Duration duration,
    final FutureOr<T> Function() computation
  ) :
    _compu = computation
  {
    _timer = Timer(duration, onTimer);
  }
  //'onTimer' function.
  //This function will be called later automatically, using 'Timer'.
  //But it is able to call this function manually.
  //Multiple calls of this function is safe.
  //  (after future completes, function do no-operation).
  void onTimer() {
    if (_compl.isCompleted) { return; }
    try {
      FutureOr<T> value = _compu();
      _compl.complete(value);
    }
    catch (e, st) {
      _compl.completeError(e, st);
    }
  }
  //'cancel' function.
  //Cancel the desired computation.
  //Multiple calls of this function is safe.
  //If desired computation isn't executed before,
  //  the '.future' will be completed with error,
  //  with type 'String', with value 'canceled',
  void cancel() {
    _timer.cancel();
    if (_compl.isCompleted) { return; }
    _compl.completeError('canceled');
  }
}

///class 'BrdStreamWithCancel'.
///
///This class receives 'Stream<T>' in the constructor,
///  and call 'asBroadcastStream' of it.
///
///You can get broadcasted stream with '.stream'.
///
///If you call '.cancelStream',
///  the underlying 'StreamSubscription' of 'Stream<T>',
///  would be canceeled.
///
///This is useful for streams like 'io.stdin',
///  because in order to prevent never-terminated program problem,
///  program must cancel the underlying 'StreamSubscription' of stdin,
///  after 'stdin.asBroadcastStream', before end of program.
///  See 'https://github.com/dart-lang/sdk/issues/45098' for related issues.
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

///Get current received elements from 'Stream<T>',
///  which is the broadcasted stream.
///
///If the stream is not broadcasted,
///  it is only possible to call this once,
///  because this function use '.listen' for stream.
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

///'loginHash' function.
///convert id and hashed password to hashed string, for login token.
String loginHash(String id, String hashedPw) {
  var bytes = utf8.encode(id + hashedPw);
  var digest = sha256.convert(bytes);
  return digest.toString();
}
///'pwHash' function.
///convert password to hashed string.
String pwHash(String pw) {
  const String prefix =
    'CShm9dch2yEDBF3qHW2aUwMpH0jasf6KdsfFFlBMSXN1vLnlliYPTISFYvbotFaCB2zv0y';
  var bytes = utf8.encode(prefix + pw);
  var digest = sha256.convert(bytes);
  return digest.toString();
}

///check if 'inObj' is 'Map<String, dynamic>',
///  and every value is 'String'.
bool isMapStr(dynamic inObj) {
  if (inObj is! Map<String, dynamic>) { return false; }
  for (dynamic value in inObj.values) {
    if (value is! String) { return false; }
  }
  return true;
}

///Split 'str' with 'spChar', but consider escaping char 'esChar'
///'str', 'spChar', 'esChar' should not have NULL char ('\x00').
///'spChar' and 'esChar' should have ONE UTF-16 char unit.
List<String> splitExceptEscaped(
  final String str,
  final String esChar,
  final String spChar
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

///Escape 'targetChar' target char(s), using escaping char 'esChar',
///  to 'newChar' new char(s),
///  means that escaping char will be removed and target char will be changed.
///
///'str', 'targetChar', 'newChar', 'esChar' should not have NULL char ('\x00').
///'targetChar' should have UTF-16 char unit list of target char(s).
///'newChar' should have UTF-16 char unit list of target char(s).
///'esChar' should have one UTF-16 char unit.
///
///If the index of specific target char in 'targetChar',
///  exceeds the index of last char in 'newChar',
///  then the specific target char will not be changed,
///  but the escaping char will be removed.
///
///If 'targetChar' is empty string,
///  then the all char will be escaped,
///  and 'newChar' will be ignored.
///
///ex) escapeStr(r'1234,\1\2\3\4,\\1\\2\\3\\4', r'\', r'13', r'2') ==>
///      r'1234,2\23\4,\\1\\2\\3\\4'.
///ex) escapeStr(r'1234,\1\2\3\4,\\1\\2\\3\\4', r'\', r'13\') ==>
///      r'1234,1\23\4,\1\2\3\4'.
///ex) escapeStr(r'1234,\1\2\3\4,\\1\\2\\3\\4', r'\') ==>
///      r'1234,1234,\1\2\3\4'.
String escapeStr(
  final String str,
  final String esChar,
  [ final String targetChar = '',
  final String newChar = '' ]
) {
  //
  final List<int> strList = str.runes.toList();
  int esCode = esChar.runes.toList().first;
  final List<int> targetCodes = targetChar.runes.toList();
  final List<int> newCodes = newChar.runes.toList();
  bool allCharMode = targetCodes.isEmpty;
  //
  int prevCharCode = 0, charCode = 0;
  int idx1 = 0, idx2 = 0;
  //converts 'esCode' char before 'targetCodes' to NULL char,
  //  and converts' targetCodes' char to 'newCodes' char,
  //  if that 'targetCodes' should be escaped.
  for (; idx1 < strList.length; idx1++) {
    //for all 'idx1' - index of 'strList'.
    charCode = strList[idx1];
    if (prevCharCode == esCode) {
      //CASE OF: previous char 'esCode'.
      if (allCharMode) {
        //CASE OF: 'allCharMode'.
        //change escaping char to NULL char (will be removed later).
        strList[idx1 - 1] = 0;
      }
      else {
        idx2 = targetCodes.indexOf(charCode);
        if (idx2 >= 0) {
          //CASE OF: 'targetCodes' has 'charCode'.
          //change escaping char to NULL char (will be removed later).
          strList[idx1 - 1] = 0;
          if (idx2 < newCodes.length) {
            //CASE OF: target 'charCode' has specific new char from 'newCodes'.
            strList[idx1] = newCodes[idx2];
          }
        }
      }
      //'charCode' itself can't be escaping char,
      //  because it is escaping target, whether or not it is 'targetCodes'.
      //Therefore 'prevCharCode' should be NULL char for the next loop.
      prevCharCode = 0;
    }
    else {
      prevCharCode = charCode;
    }
  }
  //remove NULL char from 'strList'.
  idx1 = 0; idx2 = 0;
  for (; idx1 < strList.length; idx1++) {
    //for all 'idx1' - previous (source) string index.
    //for all 'idx2' - new (destination) string index.
    if (strList[idx1] != 0) {
      if (idx1 != idx2) { strList[idx2] = strList[idx1]; }
      idx2++;
    }
  }
  //make string and return
  return String.fromCharCodes(strList.sublist(0, idx2));
}

///EOF
