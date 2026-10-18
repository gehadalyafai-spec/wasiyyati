import 'package:flutter_test/flutter_test.dart';
import 'package:wasiyyati/models/vault_data.dart';

void main() {
  test('encrypted payload source roundtrips all user values', () {
    final now = DateTime.utc(2026, 10, 19);
    final item = VaultEntry(
      id: 'sample', kind: EntryKind.receivable,
      title: 'حق مالي', party: 'شخص آخر', amount: 100.50,
      notes: 'ملاحظة', createdAt: now, updatedAt: now,
    );
    final source = VaultData(entries: [item], will: const WillDraft(fullName: 'اسم تجريبي'));
    final decoded = VaultData.decode(source.encode());
    expect(decoded.entries.single.title, 'حق مالي');
    expect(decoded.entries.single.amount, 100.50);
    expect(decoded.will.fullName, 'اسم تجريبي');
  });

  test('new empty will is not described as completed', () {
    expect(const WillDraft().hasContent, isFalse);
    expect(const WillDraft(bequests: 'محتوى').hasContent, isTrue);
  });

  test('unknown schema fails closed', () {
    expect(() => VaultData.decode('{"schema":99,"entries":[],"will":{}}'), throwsFormatException);
  });
}

// UI progress is a number of filled text fields, not legal validation.
