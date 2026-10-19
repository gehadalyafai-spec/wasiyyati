import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wasiyyati/models/vault_data.dart';
import 'package:wasiyyati/screens/home_screen.dart';
import 'package:wasiyyati/screens/review_screen.dart';
import 'package:wasiyyati/services/encrypted_vault.dart';
import 'package:wasiyyati/services/vault_controller.dart';
import 'package:wasiyyati/theme/wasiyyati_theme.dart';

class _DemoVaultController extends VaultController {
  _DemoVaultController(this._savedEntries) : super(EncryptedVault());
  final List<VaultEntry> _savedEntries;

  @override
  List<VaultEntry> get entries => List.unmodifiable(_savedEntries);

  @override
  int countFor(EntryKind kind) =>
      _savedEntries.where((entry) => entry.kind == kind).length;
}

void main() {
  final now = DateTime.now();
  VaultEntry record(String id, DateTime due, {bool completed = false}) =>
      VaultEntry(
        id: id,
        title: 'موعد $id',
        kind: EntryKind.owed,
        dueDate: due,
        completed: completed,
        createdAt: now,
        updatedAt: now,
      );

  testWidgets('home summary opens the review schedule', (tester) async {
    final controller = _DemoVaultController([
      record('past', DateTime(now.year, now.month, now.day - 1)),
    ]);
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: buildWasiyyatiTheme(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: HomeScreen(controller: controller)),
      ),
    ));

    final summary = find.byKey(const Key('home-review-digest'));
    // The quick overview above this card can push it outside the ListView's
    // lazily built viewport. Scroll until it is built before accessing it.
    final homeScrollable = find.descendant(
      of: find.byKey(const Key('home-scroll')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      summary,
      150,
      scrollable: homeScrollable,
    );
    await tester.ensureVisible(summary);
    await tester.pumpAndSettle();
    expect(summary, findsOneWidget);
    await tester.tap(summary);
    await tester.pumpAndSettle();

    // Check navigation and the actual overdue summary, not just tap handling.
    expect(find.byType(ReviewScreen), findsOneWidget);
    expect(find.text('متابعة المواعيد'), findsOneWidget);
    expect(find.text('فات موعدها: 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('review schedule shows empty state when no dates exist',
      (tester) async {
    final controller = _DemoVaultController([]);
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: buildWasiyyatiTheme(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: ReviewScreen(controller: controller),
      ),
    ));
    await tester.pump();
    expect(find.text('فات موعدها: 0'), findsOneWidget);
    expect(find.byKey(const Key('review-list')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('review summary excludes settled records', (tester) async {
    final controller = _DemoVaultController([
      record('settled', DateTime(now.year, now.month, now.day - 1),
          completed: true),
    ]);
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: buildWasiyyatiTheme(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: ReviewScreen(controller: controller),
      ),
    ));
    await tester.pump();
    expect(find.text('فات موعدها: 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
