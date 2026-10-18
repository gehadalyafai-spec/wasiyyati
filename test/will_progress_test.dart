import 'package:flutter_test/flutter_test.dart';
import 'package:wasiyyati/models/vault_data.dart';

void main() {
  test('empty draft reports zero filled text fields', () {
    const draft = WillDraft();
    expect(draft.filledFieldCount, 0);
    expect(WillDraft.editableFieldCount, 6);
  });

  test('whitespace does not count towards filled fields', () {
    const draft = WillDraft(
      fullName: '  ', city: 'جدة', bequests: '  مسودة  ');
    expect(draft.filledFieldCount, 2);
  });

  test('old schema 1 data still loads with derived progress', () {
    final payload = '{"schema":1,"entries":[],"will":'
        '{"fullName":"اسم للتجربة","bequests":"محتوى نصي"}}';
    final data = VaultData.decode(payload);
    expect(data.will.filledFieldCount, 2);
    expect(data.will.executorName, '');
  });
}
