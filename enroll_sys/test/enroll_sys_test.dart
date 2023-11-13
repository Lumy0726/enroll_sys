import 'package:enroll_sys/enroll_sys.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final courseInfo = CourseInfo('');

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      expect(courseInfo.test, isTrue);
    });
  });
}

//EOF
