import 'package:flutter_test/flutter_test.dart';
import 'package:wasiyyati/models/vault_data.dart';
import 'package:wasiyyati/services/encrypted_vault.dart';
import 'package:wasiyyati/services/vault_controller.dart';

class _TestEncryptedVault extends EncryptedVault {
  VaultData data = const VaultData();
  int writeCount = 0;

  @override
  Future<VaultData> load() async => data;

  @override
  Future<void> save(VaultData next) async {
    data = next;
    writeCount++;
  }
}

void main() {
  test('schema 1 without revision field remains compatible', () {
    final old = VaultData.decode(
      '{"schema":1,"entries":[],"will":{"fullName":"مثال"}}',
    );
    expect(old.will.fullName, 'مثال');
    expect(old.revisions, isEmpty);
  });

  test('revisions roundtrip inside encrypted payload source', () {
    final point = DateTime.utc(2026, 10, 19, 9, 45);
    final original = VaultData(
      will: const WillDraft(fullName: 'صياغة جديدة'),
      revisions: [
        WillRevision(
          id: 'rev-1',
          savedAt: point,
          draft: const WillDraft(fullName: 'صياغة سابقة', bequests: 'نص تجريبي'),
        ),
      ],
    );
    final decoded = VaultData.decode(original.encode());
    expect(decoded.revisions.single.id, 'rev-1');
    expect(decoded.revisions.single.savedAt, point);
    expect(decoded.revisions.single.draft.bequests, 'نص تجريبي');
    expect(decoded.will.fullName, 'صياغة جديدة');
  });

  test('unchanged content does not generate another revision', () {
    const saved = WillDraft(fullName: 'مثال');
    final revisions = WillRevisionPolicy.capture(
      previous: saved,
      next: const WillDraft(fullName: 'مثال', lastReviewed: null),
      existing: const [],
      revisionId: 'ignored',
      savedAt: DateTime.utc(2026, 10, 19),
    );
    expect(revisions, isEmpty);
  });

  test('empty initial draft is not archived and city-only draft counts', () {
    const current = WillDraft(city: 'صنعاء');
    expect(current.hasContent, isTrue);
    expect(WillRevisionPolicy.capture(
      previous: const WillDraft(), next: current,
      existing: const [], revisionId: 'initial',
      savedAt: DateTime.utc(2026, 10, 19),
    ), isEmpty);
  });

  test('revision policy keeps only newest twenty drafts', () {
    final timestamp = DateTime.utc(2026, 10, 19);
    var revisions = <WillRevision>[];
    for (var i = 0; i < 27; i++) {
      revisions = WillRevisionPolicy.capture(
        previous: WillDraft(fullName: 'Old $i'),
        next: WillDraft(fullName: 'Next $i'),
        existing: revisions,
        revisionId: 'id-$i',
        savedAt: timestamp,
      );
    }
    expect(revisions.length, 20);
    expect(revisions.first.id, 'id-26');
    expect(revisions.last.id, 'id-7');
  });

  test('saving and restoring preserves rights and current draft in history', () async {
    final memory = _TestEncryptedVault();
    final controller = VaultController(memory);
    await controller.initialize();
    final now = DateTime.utc(2026, 10, 19);
    final entry = VaultEntry(
      id: 'right-1', kind: EntryKind.owed, title: 'حق تجريبي',
      createdAt: now, updatedAt: now,
    );
    await controller.saveEntry(entry);
    await controller.saveWill(const WillDraft(fullName: 'الأولى'));
    expect(controller.revisions, isEmpty);
    final writes = memory.writeCount;
    await controller.saveWill(const WillDraft(fullName: 'الأولى'));
    expect(memory.writeCount, writes);

    await controller.saveWill(const WillDraft(fullName: 'الثانية'));
    expect(controller.revisions, hasLength(1));
    expect(controller.revisions.single.draft.fullName, 'الأولى');
    await controller.changeCompleted(entry, true);
    expect(controller.revisions, hasLength(1));
    final versionId = controller.revisions.single.id;
    await controller.restoreWillRevision(versionId);
    expect(controller.will.fullName, 'الأولى');
    expect(controller.revisions.first.draft.fullName, 'الثانية');
    expect(controller.entries.single.completed, isTrue);
    expect(memory.data.revisions.length, 2);
    controller.dispose();
  });
}
