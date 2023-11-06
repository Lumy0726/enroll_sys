///Shared library for enrollment system.
///Includes Shared classes like 'CourseInfo'
library;

export 'src/common_tools.dart';
export 'src/common_tools_non_io.dart'
  if (dart.library.io) 'src/common_tools_io.dart';
export 'src/course_info.dart'; //'CourseInfo' class

//EOF
