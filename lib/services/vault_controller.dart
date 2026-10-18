import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/vault_data.dart';
import 'encrypted_vault.dart';

class VaultController extends ChangeNotifier {
  VaultController(this._repo);
  final EncryptedVault _repo;
  VaultData _data = const VaultData();
  bool _ready = false;
  String? _error;
  Future<void> _queue = Future<void>.value();

  bool get ready => _ready;
  String? get error => _error;
  List<VaultEntry> get entries => List.unmodifiable(_data.entries);
  WillDraft get will => _data.will;
  VaultData get snapshot => _data;
  int countFor(EntryKind kind) => _data.entries.where((e) => e.kind == kind).length;

  Future<void> initialize() async {
    try {
      _data = await _repo.load();
      _ready = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  String newId() {
    final random = Random.secure();
    final salt = List<int>.generate(8, (_) => random.nextInt(256));
    return '${DateTime.now().microsecondsSinceEpoch}-${salt.map((v) => v.toRadixString(16).padLeft(2, '0')).join()}';
  }

  Future<void> saveEntry(VaultEntry entry) => _commit(() {
        final next = List<VaultEntry>.of(_data.entries);
        final existing = next.indexWhere((e) => e.id == entry.id);
        if (existing < 0) {
          next.insert(0, entry);
        } else {
          next[existing] = entry;
        }
        return VaultData(entries: next, will: _data.will);
      });

  Future<void> removeEntry(String id) => _commit(() => VaultData(
        entries: _data.entries.where((e) => e.id != id).toList(),
        will: _data.will,
      ));

  Future<void> changeCompleted(VaultEntry entry, bool completed) =>
      saveEntry(entry.copyWith(completed: completed));

  Future<void> saveWill(WillDraft draft) => _commit(
        () => VaultData(entries: _data.entries, will: draft),
      );

  // Replaces local state only after successful authenticated decryption,
  // explicit user confirmation, and a complete encrypted disk write.
  Future<void> replaceFromBackup(VaultData restored) => _commit(() => restored);

  // Serializes edits; the in-memory state changes only after a successful disk write.
  Future<void> _commit(VaultData Function() change) {
    final operation = _queue.then((_) async {
      if (!_ready) throw StateError('الخزنة غير جاهزة');
      final newData = change();
      await _repo.save(newData);
      _data = newData;
      notifyListeners();
    });
    _queue = operation.catchError((Object _) {});
    return operation;
  }
}
