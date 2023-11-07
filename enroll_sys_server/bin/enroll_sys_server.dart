import 'package:enroll_sys_server/enroll_sys_server.dart' as enroll_sys_server;
import 'package:enroll_sys/enroll_sys.dart';

void main(List<String> arguments) {
  print('enroll_sys_server.server_test(): ${enroll_sys_server.server_test()}');
  CourseInfo courseInfo  = CourseInfo();
  print('courseInfo.test: ${courseInfo.test}');

  enroll_sys_server.EsServer.start();
}

//EOF
