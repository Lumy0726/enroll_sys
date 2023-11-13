
///'UserInfo' class
///Contains user information, id, password(hashed), list of enrolled courses
class UserInfo {
  String id;
  String hashedPw;
  UserInfo(
    final String idParam,
    final String hashedPwParam
  ) :
    id = idParam,
    hashedPw = hashedPwParam;

  //json conversion

  UserInfo.fromJson(final Map<String, dynamic> json) :
    id = json['id'],
    hashedPw = json['hashedPw'];
  Map<String, dynamic> toJson() =>
  {
    'id': id,
    'hashedPw': hashedPw,
  };
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
  int get startMin =>  CourseTimeInfo.value2StartMin(value);
  int get endHour => CourseTimeInfo.value2EndHour(value);
  int get endMin => CourseTimeInfo.value2EndMin(value);
}

///'CourseInfo' class
class CourseInfo {
  String id;
  List<CourseTimeInfo> infoTimes = [];
  String proName = '';
  String locationStr = '';
  String groupStr = '';
  String etc = '';
  CourseInfo(String idParam) : id = idParam;

  //json conversion

  CourseInfo.fromJson(final Map<String, dynamic> json) :
    id = json['id'],
    proName = json['proName'],
    locationStr = json['locationStr'],
    etc = json['etc']
  {
    if (json['infoTimes'] is List) {
      for (dynamic value in json['infoTimes']) {
        infoTimes.add(CourseTimeInfo.fromJson(value));
      }
    }
  }
  Map<String, dynamic> toJson() =>
  {
    'id': id,
    'infoTimes': infoTimes,
    'proName': proName,
    'locationStr': locationStr,
    'groupStr': groupStr,
    'etc': etc,
  };



  bool get test => true;
}

//EOF
