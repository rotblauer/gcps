import 'package:test/test.dart';
import 'package:gcps/main.dart';

void main() {
  test('secondsToPrettyDuration should work as expected', () {
    double value = 3669;
    var got = secondsToPrettyDuration(value);
    expect(got, '1h 1m 9s');

    value = 369;
    got = secondsToPrettyDuration(value);
    expect(got, '6m 9s');

    value = 420;
    got = secondsToPrettyDuration(value);
    expect(got, '7m 0s');

    value = 42;
    got = secondsToPrettyDuration(value);
    expect(got, '42s');
  });
}
