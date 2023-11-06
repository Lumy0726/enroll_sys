import 'package:enroll_sys_client/enroll_sys_client.dart' as enroll_sys_client;
import 'package:enroll_sys/enroll_sys.dart';

import 'dart:io';
import 'dart:async';
import 'dart:convert';

bool isClientRunning = true;

void main(List<String> arguments) {
  print('enroll_sys_client.client_test(): ${enroll_sys_client.client_test()}');
  CourseInfo courseInfo = CourseInfo();
  print('courseInfo.test: ${courseInfo.test}');
  
  Future(uiMain);
}

//'uiMain' function.
//Before flutter UI implementation, this function virtually handle UI.
//  This means that this function should use 'await' periodically,
//  with 'await <Object>' in loop, to prevent ANR.
Future<void> uiMain() async {
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
      if (str == 'exit') {
        isClientRunning = false;
      }
      else {
        fStr = readFirstFromBrdStream(stdinLine);
      }
      stdout.write(str);
      stdout.write('\n');
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
  stdout.write('\n\'uiMain\' exited\n');
  brdStdinWithCancel.cancelStream();
  try {
    str = await fStr.timeout(Duration());
  }
  on TimeoutException {
    stdout.write('Please type enter to terminate program\n');
  }
  catch (e) { str = ''; }
}

//EOF
