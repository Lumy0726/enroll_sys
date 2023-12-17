import 'package:enroll_sys/enroll_sys.dart';
import './enroll_sys_client.dart';

import 'dart:io';
import 'dart:async';
import 'dart:convert';

//'EsClientSess' class (Enrollment System Client Login Session)
//Actual http request code's entry point and processing result,
//  is here,
//  like login or get course,
//  using 'EsClient.handleHttp(...)'.
class EsClientSess {
  //values for '_conState'
  static const int ST_NON = 0;
  static const int ST_LOGINRQ = 1;
  static const int ST_LOGINED = 2;
  static const int ST_LOGOUTRQ = 3;
  //'_conState' (connection state) variable.
  static int _conState = ST_NON;
  //'_conState' (connection state) variable.
  static int get conState => _conState;
  //'loginId' - last tried login id, whether login success or not.
  static String loginId = '';
  static Map<String, String> cookiesMap = {};

  //'printErrorResponse' function.
  //This just parses response's content to json and print it.
  //General use case is printing detail for wrong response status code.
  //This never throws exception.
  static Future<void> printErrorResponse(
    final HttpClientResponse response
  ) async {
    try {
      dynamic obj = await utf8StreamList2JsonObj(response);
      if (obj != null) { EsClient.printMethod(obj); }
    }
    catch (e) {
      //do nothing
    }
  }

  //'doLogin' function.
  static Future<int> doLogin(
    final String idParam,
    final String pwParam
  ) async {
    if (_conState != ST_NON) {
      EsClient.printMethod('Cannot login, current state is not logout state');
      return 1;
    }
    _conState = ST_LOGINRQ;
    loginId = idParam;
    try {
      //login request
      final HttpClientResponse response = await EsClient.handleHttp(
        'UPDATE',
        '/login',
        jsonString: jsonEncode({
          'action': 'login',
          'id': idParam,
          'pw': pwHash(pwParam),
        }),
        timeoutD: EsClient.timeoutNetwork
      );
      //check response
      if (response.statusCode != HttpStatus.ok) {
        _conState = ST_NON;
        EsClient.printMethod('Error while login request, '
          'response code was (${response.statusCode})');
        printErrorResponse(response);
        return 2;
      }
      final dynamic rObjDyn = await utf8StreamList2JsonObj(response);
      if (!isMapStr(rObjDyn)) {
        throw const FormatException('json response is corrupted');
      }
      //call 'doLoginOnResult'
      return doLoginOnResult(rObjDyn as Map<String, dynamic>);
    }
    catch (e) {
      _conState = ST_NON;
      EsClient.printMethod('Error while login request, ($e)');
      return -1;
    }
  }
  //'doLoginOnResult' function.
  //check result of server response.
  //'result[...]' should be String type.
  static int doLoginOnResult(final Map<String, dynamic> result) {
    if (result['result'] != 'true') {
      EsClient.printMethod('login failed, (${result['resultStr']})');
      _conState = ST_NON;
      return 3;
    }
    //login complete
    EsClient.printMethod('login complete');
    cookiesMap.clear();
    for (var entry in result.entries) {
      cookiesMap[entry.key] = entry.value as String;
    }
    cookiesMap.remove('result');
    _conState = ST_LOGINED;
    return 0;
  }

  //'doLogout' function.
  static Future<int> doLogout() async {
    if (_conState != ST_LOGINED) {
      EsClient.printMethod('Cannot logout, current state is not login state');
      return 1;
    }
    _conState = ST_LOGOUTRQ;
    try {
      //logout request
      final HttpClientResponse response = await EsClient.handleHttp(
        'UPDATE',
        '/login',
        jsonString: jsonEncode({
          'action': 'logout',
          'id': loginId,
          //'pw': pwHash(pwParam),
        }),
        cookiesMap: cookiesMap,
        timeoutD: EsClient.timeoutNetwork
      );
      //check response
      if (response.statusCode != HttpStatus.ok) {
        _conState = ST_LOGINED;
        EsClient.printMethod('Error while logout request, '
          'response code was (${response.statusCode})');
        printErrorResponse(response);
        return 2;
      }
      final dynamic rObjDyn = await utf8StreamList2JsonObj(response);
      if (!isMapStr(rObjDyn)) {
        throw const FormatException('json response is corrupted');
      }
      //call 'doLogoutOnResult'
      return doLogoutOnResult(rObjDyn as Map<String, dynamic>);
    }
    catch (e) {
      _conState = ST_LOGINED;
      EsClient.printMethod('Error while logout request, ($e)');
      return -1;
    }
  }
  //'doLogoutOnResult' function.
  //check result of server response.
  //'result[...]' should be String type.
  static int doLogoutOnResult(final Map<String, dynamic> result) {
    if (result['result'] != 'true') {
      EsClient.printMethod('logout failed, (${result['resultStr']})');
      _conState = ST_LOGINED;
      return 3;
    }
    //logout complete
    EsClient.printMethod('logout complete, (${result['resultStr']})');
    cookiesMap.clear();
    _conState = ST_NON;
    return 0;
  }

  //'getCourse' function.
  //get list of course (with query params) from server.
  static Future<dynamic> getCourse(
    final String params
  ) async {
    if (_conState != ST_LOGINED) {
      EsClient.printMethod('Please login to get courses');
      return 1;
    }
    try {
      final Map<String, String> qParams = {};
      if (params.isNotEmpty) {
        final List<String> argv = splitExceptEscaped(params, r'\', '&');
        int idx = argv.length;
        int decimalLength = 0; // decimal number length of 'argv.length'.
        while (idx != 0) { decimalLength++; idx = idx ~/ 10; }
        for (var str in argv) {
          List<String> keyAndValue = splitExceptEscaped(str, r'\', '=');
          if (keyAndValue.length != 2) {
            EsClient.printMethod('wrong key=value pair, ($str)');
          }
          else {
            //NOTE: because 'qParams' is 'Map' type,
            //  and program should keep all query params and order,
            //  below code adds integer index to the key string.
            qParams[
              '${idx.toString().padLeft(decimalLength, '0')}.'
              '${escapeStr(keyAndValue[0], r'\')}'
            ] = escapeStr(keyAndValue[1], r'\');
            idx++;
          }
        }
      }
      EsClient.printMethod('qParams=($qParams)');
      //get course request
      final HttpClientResponse response = await EsClient.handleHttp(
        'GET',
        '/courses',
        cookiesMap: cookiesMap,
        queryParameters: qParams,
        timeoutD: EsClient.timeoutNetwork
      );
      //check response
      if (response.statusCode != HttpStatus.ok) {
        EsClient.printMethod('Error while get course request, '
          'response code was (${response.statusCode})');
        printErrorResponse(response);
        return 2;
      }
      final dynamic rObjDyn = await utf8StreamList2JsonObj(response);
      return rObjDyn;
      //EsClient.printMethod(
        //const JsonEncoder.withIndent('  ').convert(rObjDyn));
      //return 0;
    }
    catch (e) {
      EsClient.printMethod('Error while get course request, ($e)');
      return -1;
    }
  }

  //'getCourseEnrolled' function.
  //get list of enrolled course from server.
  static Future<dynamic> getCourseEnrolled() async {
    if (_conState != ST_LOGINED) {
      EsClient.printMethod('Please login to get courses');
      return 1;
    }
    try {
      //get course request
      final HttpClientResponse response = await EsClient.handleHttp(
        'GET',
        '/students/$loginId/courses',
        cookiesMap: cookiesMap,
        timeoutD: EsClient.timeoutNetwork
      );
      //check response
      if (response.statusCode != HttpStatus.ok) {
        EsClient.printMethod('Error while get course enrolled request, '
          'response code was (${response.statusCode})');
        printErrorResponse(response);
        return 2;
      }
      final dynamic rObjDyn = await utf8StreamList2JsonObj(response);
      return rObjDyn;
    }
    catch (e) {
      EsClient.printMethod('Error while get course enrolled request, ($e)');
      return -1;
    }
  }

  //'enrollCourse' function.
  //request enrollment to the server (or cancel request).
  static Future<dynamic> enrollCourse(
    final String enrollmentRqId,
    [ final bool cancelMode = false ]
  ) async {
    if (_conState != ST_LOGINED) {
      EsClient.printMethod('Please login to get courses');
      return 1;
    }
    try {
      final String typeStr =
        (cancelMode ? 'enrollmentCancelId' : 'enrollmentRqId');
      final Map<String, String> qParams = {typeStr : enrollmentRqId};
      //get course request
      final HttpClientResponse response = await EsClient.handleHttp(
        'UPDATE',
        '/students/$loginId/courses',
        cookiesMap: cookiesMap,
        queryParameters: qParams,
        timeoutD: EsClient.timeoutNetwork
      );
      //check response
      if (response.statusCode != HttpStatus.ok) {
        EsClient.printMethod('Error while put course enrolled request, '
          'response code was (${response.statusCode})');
        printErrorResponse(response);
        return 2;
      }
      final dynamic rObjDyn = await utf8StreamList2JsonObj(response);
      return rObjDyn;
    }
    catch (e) {
      EsClient.printMethod('Error while put course enrolled request, ($e)');
      return -1;
    }
  }

  //'cancelCourse' function.
  //request enrollment cancel to the server.
  static Future<dynamic> cancelCourse(
    final String enrollmentRqId
  ) async {
    return enrollCourse(enrollmentRqId, true);
  }

  //'getMyinfo' function.
  //get current login-ed user information from server.
  static Future<dynamic> getMyinfo([final bool courseDetail = false ]) async {
    if (_conState != ST_LOGINED) {
      EsClient.printMethod('Please login to get user information');
      return 1;
    }
    try {
      final Map<String, String> qParams = {};
      if (courseDetail) {
        qParams['courseDetail'] = 'true';
      }
      //get user information request
      final HttpClientResponse response = await EsClient.handleHttp(
        'GET',
        '/students/$loginId',
        cookiesMap: cookiesMap,
        queryParameters: qParams,
        timeoutD: EsClient.timeoutNetwork
      );
      //check response
      if (response.statusCode != HttpStatus.ok) {
        EsClient.printMethod('Error while get user information request, '
          'response code was (${response.statusCode})');
        printErrorResponse(response);
        return 2;
      }
      final dynamic rObjDyn = await utf8StreamList2JsonObj(response);
      return rObjDyn;
    }
    catch (e) {
      EsClient.printMethod('Error while get user information request, ($e)');
      return -1;
    }
  }


  //constructor
  EsClientSess() {
    //nothing now
  }
}

//EOF
