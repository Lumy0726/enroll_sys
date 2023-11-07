import 'package:enroll_sys/enroll_sys.dart';

import 'dart:io';
import 'dart:async';
import 'dart:convert';

//'EsServer' class (Enrollment System Server).
class EsServer {
  static bool isServerRunning = false;
  static void start() {
    isServerRunning = true;
    Future(handleStdin);
  }


  //'handleStdin' function.
  //This handles 'stdin' input with async way.
  //This virtually handles user input and UI drawing,
  //  before flutter implementation.
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
    while (isServerRunning) {
      try {
        str = await fStr.timeout(Duration(seconds: 1));
        onStdinLine(str);
        if (str == 'exit') {
          isServerRunning = false;
        }
        else {
          fStr = readFirstFromBrdStream(stdinLine);
        }
      }
      on TimeoutException {
        str = '';
      }
      catch (e) {
        str = '';
        stdout.write('read stdin error, ($e)\n');
        isServerRunning = false;
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
  int serverPort = 80;

  //'handleHttp' function.
  //This handles http(s) input with async way.
  static Future<void> handleHttp() async {
    ;
  }


  //constructor
  EsServer() { ; }
}



//
bool server_test() {
  return true;
}
//EOF
