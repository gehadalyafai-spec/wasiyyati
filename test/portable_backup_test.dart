import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wasiyyati/models/vault_data.dart';
import 'package:wasiyyati/services/portable_backup.dart';

void main() {
  const password = 'strong backup passphrase 2026';
  final sample = VaultData(
    entries: [
      VaultEntry(
        id: 'test-1', kind: EntryKind.owed, title: 'سلفة موثقة',
        amount: 120.5, party: 'جهة تجريبية',
        createdAt: DateTime.utc(2026, 10, 19),
        updatedAt: DateTime.utc(2026, 10, 19),
      ),
    ],
    will: const WillDraft(fullName: 'اسم تجريبي', instructions: 'مسودة تجريبية'),
  );

  test('encrypted backup round-trips the unchanged schema', () async {
    final encoded = await PortableBackup.create(sample, password);
    expect(encoded, contains('"format":1'));
    expect(encoded, isNot(contains('مسودة تجريبية')));
    expect(encoded, isNot(contains('سلفة موثقة')));
    final imported = await PortableBackup.restore(encoded, password);
    expect(imported.encode(), sample.encode());
  });

  test('every backup uses fresh salt and nonce', () async {
    final first = jsonDecode(await PortableBackup.create(sample, password));
    final second = jsonDecode(await PortableBackup.create(sample, password));
    expect(first['salt'], isNot(second['salt']));
    expect(first['nonce'], isNot(second['nonce']));
  });

  test('incorrect password does not decrypt', () async {
    final encoded = await PortableBackup.create(sample, password);
    await expectLater(
      PortableBackup.restore(encoded, 'incorrect password 123'),
      throwsA(isA<FormatException>()),
    );
  });

  test('tampering is detected before importing', () async {
    final encoded = await PortableBackup.create(sample, password);
    final changed = jsonDecode(encoded) as Map<String, dynamic>;
    final bytes = base64Decode(changed['cipher'] as String);
    bytes[0] ^= 1;
    changed['cipher'] = base64Encode(bytes);
    await expectLater(
      PortableBackup.restore(jsonEncode(changed), password),
      throwsA(isA<FormatException>()),
    );
  });

  test('unsupported version is rejected', () async {
    final encoded = await PortableBackup.create(sample, password);
    final changed = jsonDecode(encoded) as Map<String, dynamic>;
    changed['format'] = 99;
    await expectLater(
      PortableBackup.restore(jsonEncode(changed), password),
      throwsA(isA<FormatException>()),
    );
  });

  test('weak passwords are refused at export', () async {
    await expectLater(
      PortableBackup.create(sample, 'short'),
      throwsA(isA<FormatException>()),
    );
  });
}
