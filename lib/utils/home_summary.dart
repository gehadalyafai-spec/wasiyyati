import '../models/vault_data.dart';

/// A non-financial snapshot for the document's home page.
/// Counts represent entries, never money or legal completion.
class HomeSummary {
  const HomeSummary._({
    required this.total,
    required this.pending,
    required this.completed,
    required this.recent,
  });

  final int total;
  final int pending;
  final int completed;
  final List<VaultEntry> recent;

  factory HomeSummary.fromEntries(
    Iterable<VaultEntry> entries, {
    int recentLimit = 3,
  }) {
    if (recentLimit < 0) {
      throw ArgumentError.value(recentLimit, 'recentLimit');
    }
    final records = List<VaultEntry>.of(entries);
    records.sort((a, b) {
      final byDate = b.updatedAt.compareTo(a.updatedAt);
      return byDate == 0 ? a.id.compareTo(b.id) : byDate;
    });
    final complete = records.where((entry) => entry.completed).length;
    return HomeSummary._(
      total: records.length,
      pending: records.length - complete,
      completed: complete,
      recent: List<VaultEntry>.unmodifiable(records.take(recentLimit)),
    );
  }

  bool get isEmpty => total == 0;
}
