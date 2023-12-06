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
  //TODO need document
  //
  //NOTE: do not edit the returned object.
  //  The object can be actual data or copied data.
  static CourseInfo? getCourseInfoFromId(final String courseId) {
    return _courseInfoMap[courseId];
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
  ///Return: will be 'complete' if function completes well,
  ///  otherwise, will be error string.
  ///
  ///NOTE: do not edit the returned object (coursesInfoOut).
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
  static UserInfo? getStuInfo(
    final String id,
    [ final bool courseDetail = false]
  ) {
    UserInfo? ret = _stuInfoMap[id];
    if (ret != null && courseDetail) {
      UserInfoCDetail ret2 = UserInfoCDetail.clone(ret);
      for (var courseId in ret.enrollList) {
        CourseInfo? courseInfo = getCourseInfoFromId(courseId);
        if (courseInfo == null) {
          courseInfo = CourseInfo(courseId);
          courseInfo.courseName = 'No course information';
        }
        ret2.courseInfoMap[courseId] = courseInfo;
      }
      ret = ret2;
    }
    return ret;
  }
  //TODO need document
  //Returned value will be:
  //  'complete', 'alreadyEnrolled', 'alreadyCanceled',
  //  'noQuota', 'notValid', 'notExist'.
  static String handleEnrollmentRq(
    final UserInfo userInfo,
    final String enrollmentRqId,
    final bool cancelMode
  ) {
    if (!(cancelMode)){
      //CASE OF: enrollment mode.
      if (userInfo.enrollList.contains(enrollmentRqId)) {
        return 'alreadyEnrolled';
      }
      if (!(_courseInfoMap.containsKey(enrollmentRqId))) {
        return 'notExist';
      }
      //TODO: need to implement below condition statement (enrollmentRq).
      if (enrollmentRqId == 'cannotEnrollForThisUser') {
        return 'notValid';
      }
      //TODO: need to implement below condition statement (enrollmentRq).
      if (enrollmentRqId == 'noRemainedQuota') {
        return 'noQuota';
      }
      _stuInfoMap[userInfo.id]!.enrollList.add(enrollmentRqId);
      userInfo.enrollList.add(enrollmentRqId);
      return 'complete';
    }
    else {
      //CASE OF: cancel mode.
      if (!(userInfo.enrollList.contains(enrollmentRqId))) {
        return 'alreadyCanceled';
      }
      if (!(_courseInfoMap.containsKey(enrollmentRqId))) {
        return 'notExist';
      }
      _stuInfoMap[userInfo.id]!.enrollList.remove(enrollmentRqId);
      userInfo.enrollList.remove(enrollmentRqId);
      return 'complete';
    }
  }
  ///'getEnrolledCoursesInfo' function.
  ///Get 'CourseInfo' of enrolled courses, of target user.
  ///
  ///Param:
  ///
  ///  'requestedId' - id of user.
  ///
  ///  'courseInfoOut' - result 'Map<String, CourseInfo>' will be out here,
  ///    if function completes well (size of 'courseInfoOut' will be 1),
  ///    otherwise, size of 'courseInfoOut' will be 0.
  ///
  ///Return: will be 'complete' if function completes well,
  ///  otherwise, will be error string.
  ///
  ///NOTE: do not edit the returned object (coursesInfoOut).
  ///  The object can be actual data or copied data.
  static String getEnrolledCoursesInfo(
    final String requestedId,
    final List<Map<String, CourseInfo>> coursesInfoOut
  ) {
    Map<String, CourseInfo> courseInfoMap = {};
    UserInfo? userInfo = getStuInfo(requestedId);
    if (userInfo == null) {
      return 'No user of requested id';
    }
    for (var courseId in userInfo.enrollList) {
      CourseInfo? courseInfo = getCourseInfoFromId(courseId);
      if (courseInfo == null) {
        courseInfo = CourseInfo(courseId);
        courseInfo.courseName = 'No course information';
      }
      courseInfoMap[courseId] = courseInfo;
    }
    coursesInfoOut.add(courseInfoMap);
    return 'complete';
  }
  ///'enrollmentRqAndGet' function.
  ///Handle enrollment (or cancel) request using course id, of target user.
  ///And, get (query) 'CourseInfo' of enrolled courses, of target user.
  ///
  ///Param:
  ///
  ///  'requestedId' - id of user.
  ///
  ///  'courseInfoOut' - result 'Map<String, CourseInfo>' will be out here,
  ///    if the course query completes well
  ///      (size of 'courseInfoOut' will be 1),
  ///    otherwise, size of 'courseInfoOut' will be 0.
  ///
  ///  'enrollmentRqId' - target course id to be enrolled or canceled.
  ///
  ///  'cancelMode' - true for cancel mode.
  ///
  ///Return:
  ///  If the request is not valid itself (like no user id),
  ///    then the length of returned list will be not 2,
  ///    and 'returnedList[0]' will be error string (if exists).
  ///  Otherwise, the length of returned list will be 2,
  ///    'returnedList[0]' will be the result string of course query
  ///      ('complete' for no error, error string otherwise),
  ///    'returnedList[1]' will be the result string of,
  ///      enrollment (or cancel) request
  ///      (returned string of 'handleEnrollmentRq' function).
  ///
  ///NOTE: do not edit the returned object (coursesInfoOut).
  ///  The object can be actual data or copied data.
  static List<String> enrollmentRqAndGet(
    final String requestedId,
    final List<Map<String, CourseInfo>> coursesInfoOut,
    final String enrollmentRqId,
    [ final bool cancelMode = false ]
  ) {
    UserInfo? userInfo = getStuInfo(requestedId);
    if (userInfo == null) {
      return ['No user of requested id'];
    }
    String getResult = 'complete';
    String enrollmentResult = handleEnrollmentRq(
      userInfo, enrollmentRqId, cancelMode);
    try {
      Map<String, CourseInfo> courseInfoMap = {};
      for (var courseId in userInfo.enrollList) {
        CourseInfo? courseInfo = getCourseInfoFromId(courseId);
        if (courseInfo == null) {
          courseInfo = CourseInfo(courseId);
          courseInfo.courseName = 'No course information';
        }
        courseInfoMap[courseId] = courseInfo;
      }
      coursesInfoOut.add(courseInfoMap);
    }
    catch (e) {
      getResult = 'InternalServerError';
    }
    return [getResult, enrollmentResult];
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
