import 'package:flutter_test/flutter_test.dart';
import 'package:wasiyyati/models/vault_data.dart';
import 'package:wasiyyati/utils/review_schedule.dart';

void main() {
  final now = DateTime(2026, 10, 20, 23, 10);
  VaultEntry entry(
    String id, {
    DateTime? due,
    bool completed = false,
    EntryKind kind = EntryKind.owed,
  }) => VaultEntry(
    id: id,
    title: id,
    kind: kind,
    completed: completed,
    dueDate: due,
    createdAt: now,
    updatedAt: now,
  );

  test('separates overdue, today, coming 7 days and later', () {
    final summary = ReviewSchedule.fromEntries([
      entry('due-later', due: DateTime(2026, 11, 1)),
      entry('done', due: DateTime(2026, 10, 18), completed: true),
      entry('due-soon', due: DateTime(2026, 10, 27)),
      entry('missing-date'),
      entry('due-past', due: DateTime(2026, 10, 19)),
      entry('due-today', due: DateTime(2026, 10, 20)),
      entry('due-tomorrow', due: DateTime(2026, 10, 21)),
    ], now);
    expect(summary.overdue.map((e) => e.id), ['due-past']);
    expect(summary.today.map((e) => e.id), ['due-today']);
    expect(summary.upcoming.map((e) => e.id), [
      'due-tomorrow', 'due-soon',
    ]);
    expect(summary.later.map((e) => e.id), ['due-later']);
    expect(summary.total, 5);
    expect(summary.attentionCount, 4);
  });

  test('all kinds with review dates appear without assuming a debt', () {
    final summary = ReviewSchedule.fromEntries([
      entry('trust', kind: EntryKind.trust, due: DateTime(2026, 10, 19)),
      entry('asset', kind: EntryKind.asset, due: DateTime(2026, 10, 21)),
      entry('receivable', kind: EntryKind.receivable,
        due: DateTime(2026, 10, 20)),
    ], now);
    expect(summary.overdue.single.kind, EntryKind.trust);
    expect(summary.upcoming.single.kind, EntryKind.asset);
    expect(summary.today.single.kind, EntryKind.receivable);
  });

  test('calendar-day comparisons ignore time of day and handle year boundary', () {
    expect(calendarDayOffset(DateTime(2026, 12, 31, 23, 59),
      DateTime(2027, 1, 1)), 1);
    expect(calendarDayOffset(DateTime(2026, 10, 20, 1),
      DateTime(2026, 10, 20, 23, 50)), 0);
    expect(reviewRelativeLabel(DateTime(2026, 10, 21), now), 'غدًا');
    expect(reviewRelativeLabel(DateTime(2026, 10, 19), now), 'منذ يوم');
  });

  test('results are sorted and immutable', () {
    final summary = ReviewSchedule.fromEntries([
      entry('later', due: DateTime(2026, 10, 19, 18)),
      entry('earlier', due: DateTime(2026, 10, 18)),
    ], now);
    expect(summary.overdue.map((e) => e.id), ['earlier', 'later']);
    expect(() => summary.overdue.clear(), throwsUnsupportedError);
  });

  test('older records without dates never show as upcoming', () {
    final summary = ReviewSchedule.fromEntries([
      entry('legacy'),
      entry('settled', due: DateTime(2026, 10, 19), completed: true),
    ], now);
    expect(summary.isEmpty, isTrue);
    expect(summary.attentionCount, 0);
  });
}
