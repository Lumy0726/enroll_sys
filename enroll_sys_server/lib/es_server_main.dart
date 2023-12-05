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
  static final Map<String, UserInfo> _stuInfoMap = {};
  static final Map<String, CourseInfo> _courseInfoMap = {};

  //TODO need document
  //
  //NOTE: do not edit the returned object.
  //  The object can be actual data or copied data.
  static Map<String, CourseInfo> getAllCoursesInfo() {
    return _courseInfoMap;
  }
  ///'getCoursesInfo' function.
  ///Get 'CourseInfo' using querys (key and value).
  ///
  ///Param:
  ///
  ///  'qParams' - should holds querys key and value. Can be empty.
  ///
  ///  'courseInfoOut' - result 'Map<String, CourseInfo>' will be out here,
  ///    if function completes well (size of 'courseInfoOut' will be 1),
  ///    otherwise, size of 'courseInfoOut' will be 0.
  ///
  ///Return: will be 'compelete' if function compeletes well,
  ///  otherwise, will be error string.
  ///
  ///NOTE: do not edit the returned object.
  ///  The object can be actual data or copied data.
  static String getCoursesInfo(
    final Map<String, String> qParams,
    final List<Map<String, CourseInfo>> coursesInfoOut
  ) {
    //TODO: improve searching algorithm (or apply 'Hive').
    String ret = 'complete';
    print('getCoursesInfo: qParams=($qParams)');

    //convert 'qParams' to 'searchParams'
    List<CourseSearchP> searchParams = [];
    for (var ent in qParams.entries) {
      searchParams.add(CourseSearchP());
      String conversionRet =
        searchParams.last.fromStringParam(ent.key, ent.value);
      if (conversionRet != 'complete') { return conversionRet; }
    }

    //searching.
    if (searchParams.isEmpty) {
      //CASE OF: no search params.
      //  Get all courses.
      coursesInfoOut.add(getAllCoursesInfo()); return ret;
    }
    Map<String, CourseInfo>
      curSearchRet = {},
      curDelayedSearchRet = {};
    bool delayedOpIsAdd = true;
    searchParams.first.qType = SPQType.add;
    //LOOP_SEARCHP: for all 'CourseSearchP' in 'searchParams'
    for (CourseSearchP searchP in searchParams) {
      //For all 'searchP'.
      if (
        searchP.qType == SPQType.delayAdd ||
        searchP.qType == SPQType.delayMul
      ) {
        //CASE OF: 'delayed' operation.
        //  Intersect or union 'curSearchRet' to 'curDelayedSearchRet'.
        if (delayedOpIsAdd) {
          curDelayedSearchRet.addAll(curSearchRet);
        }
        else {
          curDelayedSearchRet = mapIntersect(
            curDelayedSearchRet, curSearchRet
          );
        }
        if (searchP.qType == SPQType.delayAdd) { delayedOpIsAdd = true; }
        else { delayedOpIsAdd = false; }
        curSearchRet = {};
      }
      //
      switch (searchP.qType) {
        case SPQType.add:
        case SPQType.delayAdd:
        case SPQType.delayMul:
          //CASE OF: need 'add' operation ('or' operation).
          for (var entry in _courseInfoMap.entries) {
            if (entry.value.isTargetOfSearch(searchP)) {
              curSearchRet[entry.key] = entry.value;
            }
          }
          break;
        case SPQType.mul:
          //CASE OF: need 'mul' operation ('and' operation).
          curSearchRet.removeWhere(
            (key, value) => !(value.isTargetOfSearch(searchP))
          );
          break;
      }
    } // LOOP_SEARCHP: END
    //Intersect or union 'curSearchRet' to 'curDelayedSearchRet'.
    if (delayedOpIsAdd) {
      curDelayedSearchRet.addAll(curSearchRet);
    }
    else {
      curDelayedSearchRet = mapIntersect(
        curDelayedSearchRet, curSearchRet
      );
    }

    //return
    coursesInfoOut.add(curDelayedSearchRet);
    return ret;
  }
  //TODO need document
  //
  //NOTE: do not edit the returned object.
  //  The object can be actual data or copied data.
  static Map<String, UserInfo> getAllStuInfo() {
    return _stuInfoMap;
  }
  //TODO need document
  //
  //NOTE: do not edit the returned object.
  //  The object can be actual data or copied data.
  static UserInfo? getStuInfo(final String id) {
    return _stuInfoMap[id];
  }

  //TODO need document
  static String queryCoursesParam(
    final Map<String, String> qParams,
    final List<int> resultOut
  ) {
    String ret = 'complete';
    return ret;
  }



  //inflate data, for test
  static void testInflateData() {
    CourseInfo tInfo = CourseInfo('');
    //
    for (int i = 0; i < 5; i++) {
      _stuInfoMap['user$i'] = UserInfo(
        'user$i',
        '230000111$i',
        pwHash('user$i')
      );
    }
    //
    _stuInfoMap['user1']?.enrollList.add('course1111');
    _stuInfoMap['user1']?.enrollList.add('course3333');
    _stuInfoMap['user2']?.enrollList.add('course2222');
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
    _courseInfoMap[tInfo.id] = tInfo;
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
    _courseInfoMap[tInfo.id] = tInfo;
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
    _courseInfoMap[tInfo.id] = tInfo;
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
    _courseInfoMap[tInfo.id] = tInfo;
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
    _courseInfoMap[tInfo.id] = tInfo;
  }



  //constructor
  EsServerMain() {
    //nothing now
  }
}

//EOF
