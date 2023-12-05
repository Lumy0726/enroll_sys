import 'package:enroll_sys/enroll_sys.dart';
import './enroll_sys_server.dart';
import './es_server_main.dart';

import 'dart:io';
import 'dart:async';
import 'dart:convert';

//'SessTime' class. holds 'id' and 'endTime', for session
//'token' will be key (like Map<String, SessTime>).
class SessTime {
  String id;
  DateTime endTime;
  SessTime(
    final String idParam,
    final DateTime endTimeParam
  ) :
    id = idParam,
    endTime = endTimeParam;
}

//'EsServerSess' class (Enrollment System Server Login Session)
//Actual processing of http request is here,
//  using 'EsServerSess.processHttpRequest(...)',
//  which is called by code in 'EsServer.onHttpRequest(...)'.
class EsServerSess {
  //'sessDuration'. Default duration is 10 minutes.
  static Duration sessDuration = const Duration(minutes: 10);
  //'curSessions' - token and 'SessTime' class.
  static final Map<String, SessTime> _curSessions = {};

  //'processHttpRequest' function
  //return value of the 'Future' should be http status code.
  //'jsonStringRet' should be empty when call this function.
  //'jsonStringRet' params '.first' would be json string for response,
  //  or 'jsonStringRet.isEmpty' is true.
  //If this function throws error,
  //  that will be handled in 'EsServer.onHttpRequest(...)',
  //  with response 'HttpStatus.internalServerError'.
  static Future<int> processHttpRequest(
    final HttpRequest request,
    final List<String> jsonStringRet
  ) async {
    //check&print information of request
    final cInfo = request.connectionInfo;
    print('http request from '
      '${cInfo?.remoteAddress.address}'
      ':${cInfo?.remotePort}');
    print('  URI: ${request.uri}');
    print('  METHOD: ${request.method}');
    if (request.method != "GET" &&
      request.method != "POST" &&
      request.method != "PUT" &&
      request.method != "DELETE"
    ) {
      final String reason = 'unsupported request method ${request.method}';
      print(reason);
      jsonStringRet.add(jsonEncode({'reason': reason}));
      return HttpStatus.methodNotAllowed;
    }
    final List<String> pathSegs = request.uri.pathSegments;
    final Map<String, String> qParams = request.uri.queryParameters;
    final bool isPathLogin = pathSegs.length == 1 && pathSegs[0] == 'login';

    //check login session
    String loginId = '';
    String loginToken = '';
    try {
      Cookie cookie = request.cookies.firstWhere((c) => c.name == 'token');
      loginToken = cookie.value;
      if (!isPathLogin) {
        String? ret = EsServerSess.checkSession(loginToken);
        if (ret == null) {
          jsonStringRet.add(jsonEncode({
            'reason' : 'Invalid login session'}));
          return HttpStatus.unauthorized;
        }
        else if (ret == '') {
          jsonStringRet.add(jsonEncode({
            'reason' : 'Login session timeout'}));
          return HttpStatus.unauthorized;
        }
        loginId = ret;
      }
    }
    on StateError {
      //CASE OF: no token in cookie
      //nothing here, keep (loginId=='')
    }

    //path check
    if (pathSegs.isNotEmpty && pathSegs[0] == 'test') {
      jsonStringRet.add(jsonEncode([pathSegs, qParams]));
      return HttpStatus.ok;
    }
    else if (pathSegs.length == 1 && pathSegs[0] == 'login') {
      //login or logout
      return await phrLogin(request, jsonStringRet, qParams, loginToken);
    }
    else if (pathSegs.length == 1 && pathSegs[0] == 'courses') {
      return await phrCourses(request, jsonStringRet, qParams, loginId);
    }
    else if (
      pathSegs.length == 2 &&
      pathSegs[0] == 'students'
    ) {
      return await phrStudentInfo(request, jsonStringRet, qParams,
        loginId, pathSegs[1]);
    }

    //unknown request.
    print('unknown request path');
    jsonStringRet.add(jsonEncode({'reason': 'unknown request path'}));
    return HttpStatus.notFound;
  }
  //'phrLogin' (Process Http Request /login) function.
  //Action is login or logout.
  //See also 'processHttpRequest' too.
  static Future<int> phrLogin(
    final HttpRequest request,
    final List<String> jsonStringRet,
    final Map<String, String> qParams,
    final String loginToken
  ) async {
    //request check
    if (qParams.isNotEmpty) {
      const String reason = 'Invalid rq: \'/login\' request with qParams';
      print(reason);
      jsonStringRet.add(jsonEncode({'reason': reason}));
      return HttpStatus.badRequest;
    }
    if (request.method != "PUT") {
      const String reason = 'Invalid rq: \'/login\' request only accepts '
        'PUT (UPDATE)';
      print(reason);
      jsonStringRet.add(jsonEncode({'reason': reason}));
      return HttpStatus.methodNotAllowed;
    }
    final dynamic rObjDyn = await utf8StreamList2JsonObj(request);
    if (!isMapStr(rObjDyn)) {
      print('Invalid rq: \'/login\' request, '
        'json request is corrupted');
      throw FormatException('json request is corrupted');
    }
    final requestInfo = rObjDyn as Map<String, dynamic>;

    //action (login or logout) check and do (login or logout)
    if (requestInfo['action'] == 'login') {
      //CASE OF: login action
      final Map<String, String> loginResult = doLogin(
        requestInfo['id'] ?? '',
        requestInfo['pw'] ?? ''
      );
      jsonStringRet.add(jsonEncode(loginResult));
      return HttpStatus.ok;
    }
    else if (requestInfo['action'] == 'logout') {
      //CASE OF: logout action
      if (loginToken == '') {
        const String reason = 'Invalid rq: \'/login\' with logout '
          'action request, needs login token';
        print(reason);
        jsonStringRet.add(jsonEncode({'reason': reason}));
        return HttpStatus.unauthorized;
      }
      final Map<String, String> loginResult = doLogout(
        rObjDyn['id'] ?? '',
        loginToken
      );
      jsonStringRet.add(jsonEncode(loginResult));
      return HttpStatus.ok;
    }
    //CASE OF: 'requestInfo['action']' is not login or logout
    print('Invalid rq: \'/login\' request, '
      'json request is corrupted');
    throw FormatException('json request is corrupted');
  }
  //'phrCourses' (Process Http Request /courses) function.
  //See also 'processHttpRequest' too.
  static Future<int> phrCourses(
    final HttpRequest request,
    final List<String> jsonStringRet,
    final Map<String, String> qParams,
    final String loginId
  ) async {
    //request check
    if (request.method != "GET") {
      const String reason = 'Invalid rq: \'courses\' request only accepts '
        'GET (READ)';
      print(reason);
      jsonStringRet.add(jsonEncode({'reason': reason}));
      return HttpStatus.methodNotAllowed;
    }
    if (loginId == '') {
      const String reason = 'Invalid rq: \'courses\' request needs login';
      print(reason);
      jsonStringRet.add(jsonEncode({'reason': reason}));
      return HttpStatus.unauthorized;
    }

    //response
    List<Map<String, CourseInfo>> coursesInfoOut = [];
    String result = EsServerMain.getCoursesInfo(qParams, coursesInfoOut);
    if (coursesInfoOut.isNotEmpty) {
      jsonStringRet.add(jsonEncode(coursesInfoOut.first));
      return HttpStatus.ok;
    }
    else {
      jsonStringRet.add(jsonEncode({'reason': result}));
      return HttpStatus.badRequest;
    }
  }
  //'phrStudentInfo' (Process Http Request /student/requestedId) function.
  //See also 'processHttpRequest' too.
  static Future<int> phrStudentInfo(
    final HttpRequest request,
    final List<String> jsonStringRet,
    final Map<String, String> qParams,
    final String loginId,
    final String requestedId
  ) async {
    //request check
    if (request.method != "GET") {
      const String reason = 'Invalid rq: \'/student/requestedId\' '
        'request only accepts GET (READ)';
      print(reason);
      jsonStringRet.add(jsonEncode({'reason': reason}));
      return HttpStatus.methodNotAllowed;
    }
    if (loginId == '') {
      const String reason = 'Invalid rq: \'/student/requestedId\' '
        'request needs login';
      print(reason);
      jsonStringRet.add(jsonEncode({'reason': reason}));
      return HttpStatus.unauthorized;
    }
    if (loginId != requestedId) {
      const String reason = 'Invalid rq: \'/student/requestedId\', '
        'cannot get information of user, '
        'with current login permission';
      print(reason);
      jsonStringRet.add(jsonEncode({'reason': reason}));
      return HttpStatus.unauthorized;
    }

    //response
    UserInfo? stuInfo = EsServerMain.getStuInfo(requestedId);
    if (stuInfo == null) {
      const String reason =
        'Error on processing rq: \'/student/requestedId\', '
        'user information deleted';
      print(reason);
      jsonStringRet.add(jsonEncode({'reason': reason}));
      return HttpStatus.notFound;
    }
    UserInfo stuInfoClone = UserInfo.clone(stuInfo);
    stuInfoClone.hashedPw = '';
    jsonStringRet.add(jsonEncode(stuInfoClone));
    return HttpStatus.ok;
  }

  //
  static Map<String, String> doLogin(
    final String idParam,
    final String pwParam
  ) {
    Map<String, String> ret = {};//would be return value
    UserInfo? stuInfo = EsServerMain.getStuInfo(idParam);
    if (stuInfo == null || stuInfo.hashedPw != pwParam) {
      ret['result'] = 'false';
      ret['resultStr'] = 'Incorrect UserId or Password';
      return ret;
    }
    final DateTime dateTime = DateTime.now();
    final String token = loginHash(idParam, pwParam + dateTime.toString());
    final SessTime sessTime = SessTime(
      idParam,
      dateTime.add(sessDuration)
    );
    _curSessions[token] = sessTime;
    ret['result'] = 'true';
    ret['token'] = token;
    //return
    return ret;
  }
  //
  static Map<String, String> doLogout(
    final String requestedId,
    final String token
  ) {
    Map<String, String> ret = {};//would be return value
    final SessTime? sessTime = _curSessions[token];
    if (sessTime == null) {
      ret['result'] = 'true';
      ret['resultStr'] = 'Already logout-ed or invalid token';
      return ret;
    }
    if (sessTime.id != requestedId) {
      const String reason = 'Invalid rq: current login id and'
        'requested logout id is different';
      ret['result'] = 'false';
      ret['resultStr'] = reason;
      return ret;
    }
    _curSessions.remove(token);
    ret['result'] = 'true';
    ret['resultStr'] = 'Logout complete';
    return ret;
  }

  //Check token's session and update session end time.
  //return value is null, for wrong token or no session.
  //return value is empty string, for session timeout.
  static String? checkSession(final String token) {
    final SessTime? sessTime = _curSessions[token];
    if (sessTime == null) { return null; }
    DateTime dateTime = DateTime.now();
    if (sessTime.endTime.isBefore(dateTime)) {
      return '';
    }
    sessTime.endTime = dateTime.add(sessDuration);
    return sessTime.id;
  }

  //constructor
  EsServerSess() {
    //nothing now
  }
}

//EOF
