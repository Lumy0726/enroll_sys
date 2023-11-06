import 'package:enroll_sys_client/enroll_sys_client.dart' as enroll_sys_client;
import 'package:enroll_sys/enroll_sys.dart';

import 'dart:io';
import 'dart:async';
import 'dart:convert';

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
  bool running = true;
  stdout.write('enter \'exit\' to exit\n');
  
  BrdStreamWithCancel<String> brdStdinWithCancel = BrdStreamWithCancel(
    stdin.transform(utf8.decoder).transform(const LineSplitter())
  );
  final Stream<String> stdinLine = brdStdinWithCancel.stream;
  Future<String> fStr = readFirstFromBrdStream(stdinLine);
  
  while (running) {
    try {
      String str = await fStr.timeout(Duration(seconds: 1));
      if (str == 'exit') { running = false; }
      else {
        stdout.write(str);
        stdout.write('\n');
        fStr = readFirstFromBrdStream(stdinLine);
      }
    }
    on TimeoutException {
      stdout.write(';');//UI drawing (just print ';')
    }
    catch (e) {
      stdout.write('read stdin error, ($e)\n');
      running = false;
    }
  }
  stdout.write('\n\'uiMain\' exited\n');
  brdStdinWithCancel.cancelStream();
}

//EOF
