import 'package:duvet/src/elements.dart' as elements;
import 'package:test/test.dart';

void main() {
  group('Duvet elements', () {
    test('Class names for coverage percentages', () {
      expect(elements.classNameForCoveragePercent(100, 'h', 'm', 'l'), 'h');
    });
  });
}
