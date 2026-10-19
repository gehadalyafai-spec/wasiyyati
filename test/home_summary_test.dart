import 'package:flutter_test/flutter_test.dart';
import 'package:wasiyyati/models/vault_data.dart';
import 'package:wasiyyati/utils/home_summary.dart';

void main() {
  final moment = DateTime.utc(2026, 10, 20);
  VaultEntry record(String id, int days, {bool done = false}) =>
      VaultEntry(
        id: id,
        kind: EntryKind.owed,
        title: 'قيد $id',
        completed: done,
        createdAt: moment,
        updatedAt: moment.add(Duration(days: days)),
      );

  test('empty source gives clear zero counts and empty recent list', () {
    final value = HomeSummary.fromEntries(const <VaultEntry>[]);
    expect(value.total, 0);
    expect(value.pending, 0);
    expect(value.completed, 0);
    expect(value.isEmpty, isTrue);
    expect(value.recent, isEmpty);
  });

  test('counts represent records rather than amounts or currencies', () {
    final value = HomeSummary.fromEntries([
      record('a', 1),
      record('b', 2, done: true),
      record('c', 3),
    ]);
    expect(value.total, 3);
    expect(value.pending, 2);
    expect(value.completed, 1);
  });

  test('only the three most recently updated records are shown', () {
    final value = HomeSummary.fromEntries([
      record('oldest', 0),
      record('newest', 5),
      record('middle', 2),
      record('second', 4),
    ]);
    expect(value.recent.map((item) => item.id),
      ['newest', 'second', 'middle']);
  });

  test('ties are ordered deterministically and recent list is immutable', () {
    final value = HomeSummary.fromEntries([
      record('b', 0), record('a', 0),
    ]);
    expect(value.recent.map((item) => item.id), ['a', 'b']);
    expect(() => value.recent.clear(), throwsUnsupportedError);
  });

  test('recentLimit zero hides recent without changing totals', () {
    final value = HomeSummary.fromEntries([record('record', 0)],
      recentLimit: 0);
    expect(value.total, 1);
    expect(value.recent, isEmpty);
    expect(() => HomeSummary.fromEntries([record('x', 0)],
      recentLimit: -1), throwsArgumentError);
  });

  test('source entry list is not modified by sorting', () {
    final originals = [record('older', 0), record('newer', 2)];
    HomeSummary.fromEntries(originals);
    expect(originals.first.id, 'older');
  });
}
