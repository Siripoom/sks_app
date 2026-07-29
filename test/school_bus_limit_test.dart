import 'package:flutter_test/flutter_test.dart';
import 'package:sks/models/school.dart';

void main() {
  group('School busLimit', () {
    test('keeps legacy schools unlimited when busLimit is missing', () {
      final school = School.fromMap('school_1', const {
        'name': 'Legacy School',
      });

      expect(school.busLimit, isNull);
    });

    test('reads and writes a configured non-negative limit', () {
      final school = School.fromMap('school_1', const {
        'name': 'Configured School',
        'busLimit': 5,
      });

      expect(school.busLimit, 5);
      expect(school.toMap()['busLimit'], 5);
    });

    test('treats invalid stored limits as legacy unlimited', () {
      final negative = School.fromMap('school_1', const {'busLimit': -1});
      final fractional = School.fromMap('school_2', const {'busLimit': 2.5});

      expect(negative.busLimit, isNull);
      expect(fractional.busLimit, isNull);
    });
  });
}
