
///'SPCType'. 'SearchParam' class's Compare Type.
///Equal, not equal, less than, greater than, less or equal, greater or equal,
///  include, not include, regular expression, not regex.
enum SPCType { eq, ne, lt, gt, le, ge, inc, ninc, regex, nregex, }

///'SPQType'. 'SearchParam' class's Query type.
///The way of add searching result.
///Multiply (and operation), add (or operation),
///  delayed multiply, delayed add.
///ex) A add B mul C delayedAdd D mul E delayedMul F==>
///  ( ((A or B) and C) or (D and E) ) and F.
enum SPQType { mul, add, delayMul, delayAdd, }

///'SearchParam' class.
///Key-value data structure for searching objects.
///And has other attributes like type,
///  for continuous searching or comparison types etc.
///
///The 'keyParam',
///  which has keyName and type attributes,
///  and is argument of constructor and 'fromStringParam' function,
///  has below format.
///
///  '${ignoreStr}${prefix}${keyName}${postfix}'.
///
///  'ignoreStr' can be empty String,
///    or any string that ends with '.' but has no other '.'.
///
///  'prefix' can be '', '+', ')(', ')+('.
///  Which is 'mul', 'add', 'delayMul', 'delayAdd' of 'SPQType' enum.
///
///  'postfix' can be ('' or '='), '!', '!>', '!<', '<', '>',
///    '*', '!*', '~', '!~'.
///  Which is 'eq', 'ne', 'lt', 'gt', 'le', 'ge',
///    'inc', 'ninc', 'regex', 'nregex' of 'SPCType' enum.
class SearchParam {
  //'key'. This has only key name.
  String key = '';
  //'availableKeys'. Should be '[[:alnum:]]+'.
  List<String> availableKeys = [];
  //'value'
  String value = '';
  //'cType'
  SPCType cType = SPCType.eq;
  //'qType'
  SPQType qType = SPQType.mul;

  //constructor
  SearchParam([final String keyParam = '', final String valueParam = '']) {
    if (keyParam != '') { fromStringParam(keyParam, valueParam); }
  }

  ///'fromStringParam' function.
  ///Converts 'key, value' String to 'SearchParam',
  ///  and save results to this object.
  ///Returned value will be result string,
  ///  'complete' for success, error string for error.
  ///For the error, 'this.key' will be empty string after this function.
  String fromStringParam(String keyParam, final String valueParam) {
    //parse 'keyParam'
    int idxDot = keyParam.indexOf('.');
    if (idxDot >= 0) { keyParam = keyParam.substring(idxDot + 1); }
    final RegExpMatch? match =
      RegExp(r'^(\W*)(\w*)(\W*)$')
        .firstMatch(keyParam);
    if (match == null) {
      key = ''; return 'InvalidKeyFormat';
    }
    final String? prefix = match[1];
    final String keyName = match[2] ?? '';
    final String? postfix = match[3];
    if (prefix == null || postfix == null) {
      key = ''; return 'InvalidKeyFormat';
    }
    if (prefix == '') { qType = SPQType.mul; }
    else if (prefix == '+') { qType = SPQType.add; }
    else if (prefix == ')(') { qType = SPQType.delayMul; }
    else if (prefix == ')+(') { qType = SPQType.delayAdd; }
    else {
      key = ''; return 'InvalidKeyFormat (wrong prefix)';
    }
    if (postfix == '') { cType = SPCType.eq; }
    else if (postfix == '=') { cType = SPCType.eq; }
    else if (postfix == '!') { cType = SPCType.ne; }
    else if (postfix == '!>') { cType = SPCType.lt; }
    else if (postfix == '!<') { cType = SPCType.gt; }
    else if (postfix == '<') { cType = SPCType.le; }
    else if (postfix == '>') { cType = SPCType.ge; }
    else if (postfix == '*') { cType = SPCType.inc; }
    else if (postfix == '!*') { cType = SPCType.ninc; }
    else if (postfix == '~') { cType = SPCType.regex; }
    else if (postfix == '!~') { cType = SPCType.nregex; }
    else {
      key = ''; return 'InvalidKeyFormat (wrong postfix)';
    }
    bool validKeyName = false;
    for (var availableKey in availableKeys) {
      if (keyName == availableKey) { validKeyName = true; break; }
    }
    if (!validKeyName) {
      key = ''; return 'InvalidKeyFormat (wrong key name)';
    }

    key = keyName;
    value = valueParam;
    return 'complete';
  }

  ///'toStringParam' function.
  ///Converts this object to '[key, value]' pair (Type 'List<String>').
  ///Size of returned list will be always 2.
  ///Returned string of the list can be empty string.
  List<String> toStringParam() {
    List<String> ret = [];
    String keyRet = key;
    switch (qType) {
      case SPQType.mul: break;
      case SPQType.add: keyRet = '+$keyRet'; break;
      case SPQType.delayMul: keyRet = ')($keyRet'; break;
      case SPQType.delayAdd: keyRet = ')+($keyRet'; break;
    }
    switch (cType) {
      case SPCType.eq: break;
      case SPCType.ne: keyRet = '$keyRet!'; break;
      case SPCType.lt: keyRet = '$keyRet!>'; break;
      case SPCType.gt: keyRet = '$keyRet!<'; break;
      case SPCType.le: keyRet = '$keyRet<'; break;
      case SPCType.ge: keyRet = '$keyRet>'; break;
      case SPCType.inc: keyRet = '$keyRet*'; break;
      case SPCType.ninc: keyRet = '$keyRet!*'; break;
      case SPCType.regex: keyRet = '$keyRet~'; break;
      case SPCType.nregex: keyRet = '$keyRet!~'; break;
    }
    ret.add(keyRet);
    ret.add(value);
    return ret;
  }
}

///'UserInfo' class.
///Contains user information, id, password(hashed), list of enrolled courses,
///and other things.
class UserInfo {
  String id;
  String idDecimal;
  String hashedPw;
  Set<String> enrollList = {};
  UserInfo(
    final String idParam,
    final String idDecimalParam,
    final String hashedPwParam
  ) :
    id = idParam,
    idDecimal = idDecimalParam,
    hashedPw = hashedPwParam;
  UserInfo.clone(
    final UserInfo obj
  ) :
    id = obj.id,
    idDecimal = obj.idDecimal,
    hashedPw = obj.hashedPw
  {
    enrollList = Set<String>.from(obj.enrollList);
  }

  //json conversion

  UserInfo.fromJson(final Map<String, dynamic> json) :
    id = json['id'],
    idDecimal = json['idDecimal'],
    hashedPw = json['hashedPw']
  {
    for (dynamic value in (json['enrollList'] as List<dynamic>)) {
      enrollList.add(value);
    }
  }
  Map<String, dynamic> toJson() =>
  {
    'id': id,
    'idDecimal': idDecimal,
    'hashedPw': hashedPw,
    'enrollList': List<String>.from(enrollList),
  };
}

///'UserInfoCDetail' class (User information + enrolled course detail).
///Extends 'UserInfo'.
///Purpose of this class is communication between client and server.
class UserInfoCDetail extends UserInfo {
  Map<String, CourseInfo> courseInfoMap = {};
  UserInfoCDetail(
    final String idParam,
    final String idDecimalParam,
    final String hashedPwParam
  ) :
    super(idParam, idDecimalParam, hashedPwParam) { ; }
  UserInfoCDetail.clone(
    final UserInfo obj
  ) :
    super.clone(obj)
  {
    if (obj is UserInfoCDetail) {
      for (var entry in obj.courseInfoMap.entries) {
        courseInfoMap[entry.key] = CourseInfo.clone(entry.value);
      }
    }
  }

  //json conversion

  UserInfoCDetail.fromJson(final Map<String, dynamic> json) :
    super.fromJson(json)
  {
    for (
      dynamic entry
      in (json['courseInfoMap'] as Map<String, dynamic>).entries
    ) {
      courseInfoMap[entry.key] = CourseInfo.fromJson(
        entry.value as Map<String, dynamic>
      );
      //courseInfoMap[entry.key] = entry.value;
    }
  }
  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> ret = super.toJson();
    ret['courseInfoMap'] = courseInfoMap;
    return ret;
  }
}

///'CourseTimeInfo' class
///Store time information about one courses, for one day -
///  what day (of the week), when to start, when to end.
class CourseTimeInfo {
  static const int MON = 10000000;
  static const int TUE = 20000000;
  static const int WED = 30000000;
  static const int THU = 40000000;
  static const int FRI = 50000000;
  static const int SAT = 60000000;
  static const int SUN = 70000000;
  int value;
  ///constructor 'CourseTimeInfo'
  ///'valueParam' - See 'CourseTimeInfo.format2Value'
  CourseTimeInfo(final int valueParam) : value = valueParam;
  CourseTimeInfo.clone(final CourseTimeInfo obj) : value = obj.value;

  //json conversion

  CourseTimeInfo.fromJson(final Map<String, dynamic> json) :
    value = json['value'];
  Map<String, dynamic> toJson() =>
  {
    'value': value,
  };


  //information value conversion

  static int format2Value(
    final int day,
    int startHour,
    int startMin,
    int endHour,
    int endMin
  ) {
    int ret = (day ~/ 10000000) * 10000000;
    startHour = startHour % 24;
    startMin = startMin % 60;
    endHour = endHour % 24;
    endMin = endMin % 60;
    ret += (startMin + startHour * 60) * 60 * 24;
    ret += endMin + endHour * 60;
    return ret;
  }
  static int value2Day(final int value) {
    return (value ~/ 10000000) * 10000000;
  }
  static int value2StartHour(final int value) {
    return ((value ~/ (60 * 24 * 60)) % 24) * 60 * 24 * 60;
  }
  static int value2StartMin(final int value) {
    return ((value ~/ (24 * 60)) % 60) * 24 * 60;
  }
  static int value2EndHour(final int value) {
    return ((value ~/ 60) % 24) * 60;
  }
  static int value2EndMin(final int value) {
    return value % 60;
  }

  void format2Set(
    final int day,
    final int startHour,
    final int startMin,
    final int endHour,
    final int endMin
  ) {
    value = CourseTimeInfo.format2Value(
      day, startHour, startMin, endHour, endMin);
  }
  int get day => CourseTimeInfo.value2Day(value);
  int get startHour => CourseTimeInfo.value2StartHour(value);
  int get startMin => CourseTimeInfo.value2StartMin(value);
  int get endHour => CourseTimeInfo.value2EndHour(value);
  int get endMin => CourseTimeInfo.value2EndMin(value);
}

///'CourseSearchP extends SearchParam' class (Course search param).
///Key-value data structure for searching 'CourseInfo'.
///And has other attributes like type, for searching.
class CourseSearchP extends SearchParam {
  //constructor
  CourseSearchP([final String keyParam = '', final String valueParam = '']) :
    super(keyParam, valueParam)
  {
    availableKeys = [
      'id',
      'courseName',
      'infoTimes',
      'proName',
      'locationStr',
      'groupStr',
      'etc',
    ];
  }
}

///'CourseInfo' class
class CourseInfo {
  //id of course, like 'ABC000C03'.
  String id;
  //The name of course.
  String courseName = '';
  //Course time information.
  List<CourseTimeInfo> infoTimes = [];
  //Name of the professor.
  String proName = '';
  //Location, String.
  String locationStr = '';
  //Group name of course, String.
  String groupStr = '';
  //Extra information, String.
  String etc = '';

  //constructor
  CourseInfo(String idParam) : id = idParam;
  CourseInfo.clone(
    final CourseInfo obj
  ) :
    id = obj.id,
    courseName = obj.courseName,
    proName = obj.proName,
    locationStr = obj.locationStr,
    groupStr = obj.groupStr,
    etc = obj.etc
  {
    for (var value in obj.infoTimes) {
      infoTimes.add(CourseTimeInfo.clone(value));
    }
  }

  //json conversion

  CourseInfo.fromJson(final Map<String, dynamic> json) :
    id = json['id'],
    courseName = json['courseName'],
    proName = json['proName'],
    locationStr = json['locationStr'],
    groupStr = json['groupStr'],
    etc = json['etc']
  {
    for (dynamic value in (json['infoTimes'] as List<dynamic>)) {
      infoTimes.add(CourseTimeInfo.fromJson(value as Map<String, dynamic>));
    }
  }
  Map<String, dynamic> toJson() =>
  {
    'id': id,
    'courseName': courseName,
    'infoTimes': infoTimes,
    'proName': proName,
    'locationStr': locationStr,
    'groupStr': groupStr,
    'etc': etc,
  };

  //'isTargetOfSearch'. for searching filter.
  bool isTargetOfSearch(final CourseSearchP searchParam) {

    if (
      searchParam.key == 'id' ||
      searchParam.key == 'courseName' ||
      searchParam.key == 'proName' ||
      searchParam.key == 'locationStr' ||
      searchParam.key == 'groupStr' ||
      searchParam.key == 'etc'
    ) {
      //CASE OF: searching is for string.
      String targetV = '';
      String searchV = searchParam.value.toLowerCase();
      RegExpMatch? match;
      if (searchParam.key == 'id') { targetV = id; }
      else if (searchParam.key == 'courseName') { targetV = courseName; }
      else if (searchParam.key == 'proName') { targetV = proName; }
      else if (searchParam.key == 'locationStr') { targetV = locationStr; }
      else if (searchParam.key == 'groupStr') { targetV = groupStr; }
      else if (searchParam.key == 'etc') { targetV = etc; }
      targetV = targetV.toLowerCase();
      switch(searchParam.cType) { // switch: start
        case SPCType.eq: return targetV.compareTo(searchV) == 0;
        case SPCType.ne: return targetV.compareTo(searchV) != 0;
        case SPCType.lt: return targetV.compareTo(searchV) < 0;
        case SPCType.gt: return targetV.compareTo(searchV) > 0;
        case SPCType.le: return targetV.compareTo(searchV) <= 0;
        case SPCType.ge: return targetV.compareTo(searchV) >= 0;
        case SPCType.inc: return targetV.contains(searchV);
        case SPCType.ninc: return !(targetV.contains(searchV));
        case SPCType.regex:
        case SPCType.nregex:
          match = RegExp(searchV).firstMatch(targetV);
          if (match == null) {
            return searchParam.cType == SPCType.nregex;
          }
          else {
            return searchParam.cType == SPCType.regex;
          }
      } // switch: end
    }
    else if (searchParam.key == 'infoTimes') {
      //TODO need to implement this.
      return false;
    }

    return false;
  }

  bool get test => true;
}

//EOF
