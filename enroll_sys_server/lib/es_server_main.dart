import 'package:enroll_sys/enroll_sys.dart';
import './enroll_sys_server.dart';
import './es_server_session.dart';

import 'dart:io';
import 'dart:async';
import 'dart:convert';


///'EsServerMain' class (Enrollment System Server Main program).
///
///this holds major data of server, like user information, course list.
///
///this handles major operations of server,
///likes searching courses or handling enrollment request.
class EsServerMain {
  static Map<String, UserInfo> stuInfoMap = {};
  static Map<String, CourseInfo> courseInfoMap = {};




  //inflate data, for test
  static void testInflateData() {
    CourseInfo tInfo = CourseInfo('');
    //
    for (int i = 0; i < 5; i++) {
      stuInfoMap['user$i'] = UserInfo(
        'user$i',
        '230000111$i',
        pwHash('user$i')
      );
    }
    //
    stuInfoMap['user1']?.enrollList.add('course1111');
    stuInfoMap['user1']?.enrollList.add('course3333');
    stuInfoMap['user2']?.enrollList.add('course2222');
    //
    tInfo = CourseInfo('course1111');
    tInfo.infoTimes.add(CourseTimeInfo(CourseTimeInfo.format2Value(
      CourseTimeInfo.MON,
      10, 30, 11, 45
    )));
    tInfo.courseName = 'course1111';
    tInfo.proName = '김교수';
    tInfo.locationStr = 'SomeLocation 103';
    tInfo.groupStr = 'department-A';
    courseInfoMap[tInfo.id] = tInfo;
    //
    tInfo = CourseInfo('course2222');
    tInfo.infoTimes.add(CourseTimeInfo(CourseTimeInfo.format2Value(
      CourseTimeInfo.MON,
      10, 30, 11, 45
    )));
    tInfo.courseName = 'course2222';
    tInfo.proName = 'professor2222';
    tInfo.locationStr = 'SomeLocation 205';
    tInfo.groupStr = 'department-B';
    courseInfoMap[tInfo.id] = tInfo;
    //
    tInfo = CourseInfo('course3333');
    tInfo.infoTimes.add(CourseTimeInfo(CourseTimeInfo.format2Value(
      CourseTimeInfo.MON,
      10, 30, 11, 45
    )));
    tInfo.courseName = 'course3333';
    tInfo.proName = 'professor3333';
    tInfo.locationStr = 'SomeLocation 109';
    tInfo.groupStr = 'department-C';
    courseInfoMap[tInfo.id] = tInfo;
    //
    tInfo = CourseInfo('course4444');
    tInfo.infoTimes.add(CourseTimeInfo(CourseTimeInfo.format2Value(
      CourseTimeInfo.MON,
      10, 30, 11, 45
    )));
    tInfo.courseName = 'course4444';
    tInfo.proName = 'professor4444';
    tInfo.locationStr = 'SomeLocation 110';
    tInfo.groupStr = 'department-A';
    courseInfoMap[tInfo.id] = tInfo;
    //
    tInfo = CourseInfo('course5555');
    tInfo.infoTimes.add(CourseTimeInfo(CourseTimeInfo.format2Value(
      CourseTimeInfo.MON,
      10, 30, 11, 45
    )));
    tInfo.courseName = 'course5555';
    tInfo.proName = 'professor5555';
    tInfo.locationStr = 'SomeLocation 301';
    tInfo.groupStr = 'department-B';
    courseInfoMap[tInfo.id] = tInfo;
  }



  //constructor
  EsServerMain() {
    //nothing now
  }
}

//EOF
