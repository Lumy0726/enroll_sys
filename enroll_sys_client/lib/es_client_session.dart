import 'package:enroll_sys/enroll_sys.dart';
import './enroll_sys_client.dart';

import 'dart:io';
import 'dart:async';
import 'dart:convert';

//'EsClientSess' class (Enrollment System Client Login Session)
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
  //
  static Map<String, String> cookiesMap = {};

  //'doLogin' function.
  static Future<int> doLogin(
    final String idParam,
    final String pwParam
  ) async {
    if (_conState != ST_NON) {
      print('Cannot login, current state is not logout state');
      return 1;
    }
    _conState = ST_LOGINRQ;
    try {
      //login request
      final HttpClientResponse response = await EsClient.handleHttp(
        'UPDATE',
        '/login',
        jsonString: jsonEncode({
          'id': idParam,
          'pw': pwHash(pwParam),
        }),
        timeoutD: EsClient.timeoutNetwork
      );
      //check response
      if (response.statusCode != HttpStatus.ok) {
        _conState = ST_NON;
        print('Error while login request, '
          'response code was (${response.statusCode})');
        return 2;
      }
      final String jsonStr = await utf8.decoder.bind(response).join();
      final dynamic rObjDyn = jsonDecode(jsonStr);
      if (!isMapStr(rObjDyn)) {
        throw FormatException('json response is corrupted');
      }
      //call 'doLoginOnResult'
      return doLoginOnResult(rObjDyn as Map<String, dynamic>);
    }
    catch (e) {
      _conState = ST_NON;
      print('Error while login request, ($e)');
      return -1;
    }
  }
  //'doLoginOnResult' function.
  //check result of server response.
  //'result[...]' should be String type.
  static int doLoginOnResult(final Map<String, dynamic> result) {
    if (result['result'] != 'true') {
      print('login failed, (${result['resultStr']})');
      _conState = ST_NON;
      return 3;
    }
    //login complete
    print('login complete');
    cookiesMap.clear();
    for (var entry in result.entries) {
      cookiesMap[entry.key] = entry.value as String;
    }
    cookiesMap.remove('result');
    _conState = ST_LOGINED;
    return 0;
  }

  //'getCourse' function.
  //get list of course (with query params) from server.
  static Future<int> getCourse(
    final String params
  ) async {
    if (_conState != ST_LOGINED) {
      print('Please login to get courses');
      return 1;
    }
    try {
      final Map<String, String> qParams = {};
      if (params.isNotEmpty) {
        final List<String> argv = splitExceptEscaped(params, '&', '\\');
        for (var str in argv) {
          List<String> keyAndValue = splitExceptEscaped(str, '=', '\\');
          if (keyAndValue.length != 2) {
            print('wrong key=value pair, ($str)');
          }
          else {
            qParams[keyAndValue[0]] = keyAndValue[1];
          }
        }
      }
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
        print('Error while get course request, '
          'response code was (${response.statusCode})');
        return 2;
      }
      final String jsonStr = await utf8.decoder.bind(response).join();
      //TODO need implement below
      print(jsonDecode(jsonStr));
      return 0;
    }
    catch (e) {
      print('Error while get course request, ($e)');
      return -1;
    }
  }


  //constructor
  EsClientSess() {
    //nothing now
  }
}

//EOF
