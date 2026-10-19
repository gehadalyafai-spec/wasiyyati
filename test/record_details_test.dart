import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:wasiyyati/models/vault_data.dart';
import 'package:wasiyyati/utils/record_details.dart';

void main() {
  final date = DateTime(2026, 10, 19);

  VaultEntry sample({
    EntryKind kind = EntryKind.owed,
    bool completed = false,
    DateTime? due,
  }) => VaultEntry(
    id: 'right-1', kind: kind, title: 'حق تجريبي',
    amount: 150.5, currencyCode: 'YER', dueDate: due,
    completed: completed, createdAt: date, updatedAt: date,
  );

  test('currency and due date roundtrip through existing vault schema', () {
    final original = VaultData(entries: [sample(due: DateTime(2026, 10, 20))]);
    final restored = VaultData.decode(original.encode());
    expect(restored.entries.single.currencyCode, 'YER');
    expect(restored.entries.single.amount, 150.5);
    expect(restored.entries.single.dueDate, DateTime(2026, 10, 20));
    expect(restored.toJson()['schema'], 1);
  });

  test('legacy encrypted records load without currency or due date', () {
    final old = sample().toJson()
      ..remove('currencyCode')
      ..remove('dueDate');
    final data = VaultData.decode(
      jsonEncode({'schema': 1, 'entries': [old], 'will': <String, dynamic>{}}),
    );
    expect(data.entries.single.currencyCode, isNull);
    expect(data.entries.single.dueDate, isNull);
  });

  test('changing settlement status keeps amount, currency and due date', () {
    final original = sample(due: DateTime(2026, 10, 20));
    final settled = original.copyWith(completed: true);
    expect(settled.completed, isTrue);
    expect(settled.amount, original.amount);
    expect(settled.currencyCode, original.currencyCode);
    expect(settled.dueDate, original.dueDate);
  });

  test('overdue notices exclude completed, non-financial and today', () {
    final now = DateTime(2026, 10, 20, 15);
    final yesterday = DateTime(2026, 10, 19);
    expect(isRecordOverdue(sample(due: yesterday), now), isTrue);
    expect(isRecordOverdue(sample(due: now), now), isFalse);
    expect(isRecordOverdue(sample(due: yesterday, completed: true), now), isFalse);
    expect(isRecordOverdue(sample(due: yesterday, kind: EntryKind.trust), now), isFalse);
  });

  test('currency labels do not invent denominations', () {
    expect(currencyDescription(null), 'العملة غير محددة');
    expect(currencyDescription('YER'), 'ريال يمني');
    expect(currencyDescription('XYZ'), 'XYZ');
    expect(formatRecordDate(DateTime(2026, 1, 2)), '2026/01/02');
  });
}
