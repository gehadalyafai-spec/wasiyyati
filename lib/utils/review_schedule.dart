import '../models/vault_data.dart';

/// Groups saved calendar dates only. No notifications or financial totals.
/// "Past due" describes the user's chosen date, not a legal conclusion.
class ReviewSchedule {
  const ReviewSchedule._({
    required this.overdue,
    required this.today,
    required this.upcoming,
    required this.later,
  });

  final List<VaultEntry> overdue;
  final List<VaultEntry> today;
  final List<VaultEntry> upcoming;
  final List<VaultEntry> later;

  int get total => overdue.length + today.length + upcoming.length + later.length;
  int get attentionCount => overdue.length + today.length + upcoming.length;
  bool get isEmpty => total == 0;

  static ReviewSchedule fromEntries(
    Iterable<VaultEntry> entries,
    DateTime now, {
    int upcomingDays = 7,
  }) {
    if (upcomingDays < 1) {
      throw ArgumentError.value(upcomingDays, 'upcomingDays');
    }

    final overdue = <VaultEntry>[];
    final today = <VaultEntry>[];
    final upcoming = <VaultEntry>[];
    final later = <VaultEntry>[];

    for (final entry in entries) {
      final due = entry.dueDate;
      if (entry.completed || due == null) {
        continue;
      }
      final days = calendarDayOffset(now, due);
      if (days < 0) {
        overdue.add(entry);
      } else if (days == 0) {
        today.add(entry);
      } else if (days <= upcomingDays) {
        upcoming.add(entry);
      } else {
        later.add(entry);
      }
    }

    int byDueDate(VaultEntry a, VaultEntry b) {
      final compared = a.dueDate!.compareTo(b.dueDate!);
      if (compared != 0) {
        return compared;
      }
      final updated = b.updatedAt.compareTo(a.updatedAt);
      return updated != 0 ? updated : a.id.compareTo(b.id);
    }

    for (final group in [overdue, today, upcoming, later]) {
      group.sort(byDueDate);
    }

    return ReviewSchedule._(
      overdue: List.unmodifiable(overdue),
      today: List.unmodifiable(today),
      upcoming: List.unmodifiable(upcoming),
      later: List.unmodifiable(later),
    );
  }
}

/// Compare calendar days, rather than 24-hour periods (robust across DST).
int calendarDayOffset(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;

String reviewRelativeLabel(DateTime due, DateTime today) {
  final days = calendarDayOffset(today, due);
  if (days == 0) {
    return 'اليوم';
  }
  if (days == 1) {
    return 'غدًا';
  }
  if (days == -1) {
    return 'منذ يوم';
  }
  if (days < 0) {
    return 'منذ ${-days} يوم';
  }
  return 'بعد $days يوم';
}
