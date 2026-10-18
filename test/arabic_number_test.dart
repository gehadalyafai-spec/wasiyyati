import 'package:flutter_test/flutter_test.dart';
import 'package:wasiyyati/utils/arabic_number.dart';

void main() {
  test('western and Arabic decimal digits are accepted', () {
    expect(parseMoneyInput('153.75'), 153.75);
    expect(parseMoneyInput('١٥٣٫٧٥'), 153.75);
    expect(parseMoneyInput('۱۵۳٫۷۵'), 153.75);
  });

  test('Arabic thousands separators can be normalized', () {
    expect(parseMoneyInput('١٬٢٣٤٫٥'), 1234.5);
    expect(parseMoneyInput('١ ٢٣٤٫٥'), 1234.5);
  });

  test('invalid amounts remain invalid rather than coerced', () {
    expect(parseMoneyInput('ليس رقمًا'), isNull);
    expect(parseMoneyInput('-١'), -1.0);
  });
}
