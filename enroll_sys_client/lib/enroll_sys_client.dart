
import 'package:enroll_sys/enroll_sys.dart';

import 'dart:io';
import 'dart:async';
import 'dart:convert';

//'EsClient' class (Enrollment System Client).
//
//NOTE: Due to UI handling,
//  all of the function in this class,
//  except some function that runs in another isolates(thread),
//  should be returned within short time,
//  or use 'await Future' within short period,
//  to prevent ANR.
class EsClient {
  static bool isClientRunning = false;
  static void start() {
    isClientRunning = true;
    Future(handleStdin);
  }


  //'handleStdin' function.
  //This handles 'stdin' input with async way.
  static Future<void> handleStdin() async {
    stdout.write('enter \'exit\' to exit\n');

    BrdStreamWithCancel<String> brdStdinWithCancel = BrdStreamWithCancel(
      stdin.transform(utf8.decoder).transform(const LineSplitter())
    );
    final Stream<String> stdinLine = brdStdinWithCancel.stream;

    //NOTE: Code "await for (String str in stdinLine)" has problem,
    //        that it is unable to break loop without stdinLine input,
    //        even with 'brdStdinWithCancel.cancelStream()'.
    //      Therefore this code uses timeout method.

    Future<String> fStr = readFirstFromBrdStream(stdinLine);
    String str = '';
    while (isClientRunning) {
      try {
        str = await fStr.timeout(Duration(seconds: 1));
        onStdinLine(str);
        if (str == 'exit') {
          isClientRunning = false;
        }
        else {
          fStr = readFirstFromBrdStream(stdinLine);
        }
      }
      on TimeoutException {
        stdout.write(';');//UI drawing (just print ';')
      }
      catch (e) {
        str = '';
        stdout.write('read stdin error, ($e)\n');
        isClientRunning = false;
      }
    }
    stdout.write('\n\'handleStdin\' exited\n');
    brdStdinWithCancel.cancelStream();
    try {
      str = await fStr.timeout(Duration());
    }
    on TimeoutException {
      stdout.write('Please type enter to terminate program\n');
    }
    catch (e) { str = ''; }
  }

  //
  static void onStdinLine(String cmd) {
    stdout.write(cmd);
    stdout.write('\n');
  }


  //
  int clientPort = 80;

  //'handleHttp' function.
  //This handles http(s) input with async way.
  static Future<void> handleHttp() async {
    ;
  }


  //constructor
  EsClient() { ; }
}



//
bool client_test() {
  return true;
}
//EOF
