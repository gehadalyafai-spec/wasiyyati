import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wasiyyati/models/vault_data.dart';
import 'package:wasiyyati/screens/will_screen.dart';
import 'package:wasiyyati/services/encrypted_vault.dart';
import 'package:wasiyyati/services/vault_controller.dart';

void main() {
  test('comparison ignores review time but detects modified content', () {
    final a = WillDraft(
      fullName: 'اسم', lastReviewed: DateTime.utc(2025),
    );
    final b = WillDraft(
      fullName: 'اسم', lastReviewed: DateTime.utc(2026),
    );
    expect(a.hasSameContent(b), isTrue);
    expect(a.hasSameContent(const WillDraft(fullName: 'اسم مختلف')), isFalse);
    expect(a.hasSameContent(const WillDraft(fullName: 'اسم', city: 'جدة')),
      isFalse);
  });

  testWidgets('editing toggles the unsaved-change indicator', (tester) async {
    final vault = VaultController(EncryptedVault());
    addTearDown(vault.dispose);
    final editorKey = GlobalKey<WillScreenState>();
    await tester.pumpWidget(MaterialApp(
      home: WillScreen(key: editorKey, controller: vault),
    ));
    expect(find.text('لا توجد تغييرات معلّقة'), findsOneWidget);
    expect(editorKey.currentState!.hasUnsavedChanges, isFalse);

    final field = find.byKey(const Key('will-full-name'));
    await tester.ensureVisible(field);
    await tester.enterText(field, 'اسم تجريبي');
    await tester.pump();
    expect(editorKey.currentState!.hasUnsavedChanges, isTrue);

    // Editing may scroll the ListView to keep the field visible. The status
    // is near the top and may be outside the lazily-built viewport.
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    scrollable.position.jumpTo(scrollable.position.minScrollExtent);
    await tester.pumpAndSettle();
    expect(find.text('تغييرات غير محفوظة'), findsOneWidget);
  });

  testWidgets('collapsing and reopening a chapter keeps draft text',
      (tester) async {
    final vault = VaultController(EncryptedVault());
    addTearDown(vault.dispose);
    await tester.pumpWidget(MaterialApp(home: WillScreen(controller: vault)));
    final field = find.byKey(const Key('will-full-name'));
    await tester.ensureVisible(field);
    await tester.enterText(field, 'نص باقٍ');
    final heading = find.byKey(const ValueKey('will-chapter-1'));
    await tester.ensureVisible(heading);
    await tester.tap(heading);
    await tester.pumpAndSettle();
    await tester.tap(heading);
    await tester.pumpAndSettle();
    expect(find.text('نص باقٍ'), findsOneWidget);
  });

  testWidgets('leave warning can cancel or discard unsaved edits', (tester) async {
    final vault = VaultController(EncryptedVault());
    addTearDown(vault.dispose);
    final key = GlobalKey<WillScreenState>();
    await tester.pumpWidget(MaterialApp(home: WillScreen(
      key: key, controller: vault,
    )));
    await tester.ensureVisible(find.byKey(const Key('will-full-name')));
    await tester.enterText(find.byKey(const Key('will-full-name')), 'نص غير محفوظ');
    await tester.pump();

    final cancelled = key.currentState!.confirmLeave();
    await tester.pumpAndSettle();
    expect(find.text('تغييرات لم تُحفظ'), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(await cancelled, isFalse);
    expect(key.currentState!.hasUnsavedChanges, isTrue);

    final discarded = key.currentState!.confirmLeave();
    await tester.pumpAndSettle();
    await tester.tap(find.text('تجاهل التعديلات'));
    await tester.pumpAndSettle();
    expect(await discarded, isTrue);
    expect(key.currentState!.hasUnsavedChanges, isFalse);
  });
}
