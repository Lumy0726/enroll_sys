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
class EsServerSess {
  //'sessDuration'. Default duration is 10 minutes.
  static Duration sessDuration = const Duration(minutes: 10);
  //'curSessions' - token and 'SessTime' class.
  static final Map<String, SessTime> _curSessions = {};

  //
  static Map<String, String> doLogin(
    final String idParam,
    final String pwParam
  ) {
    Map<String, String> ret = {};//would be return value
    UserInfo? userInfo = EsServerMain.userInfoMap[idParam];
    if (userInfo == null || userInfo.hashedPw != pwParam) {
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
  static bool checkSession(final String token) {
    final SessTime? sessTime = _curSessions[token];
    DateTime dateTime = DateTime.now();
    if (sessTime == null || sessTime.endTime.isBefore(dateTime)) {
      return false;
    }
    sessTime.endTime = dateTime.add(sessDuration);
    return true;
  }

  //constructor
  EsServerSess() {
    //nothing now
  }
}

//EOF
