import 'dart:convert';

enum EntryKind {
  owed('عليّ', 'ديون عليّ'),
  receivable('لي', 'حقوق لي'),
  trust('أمانة', 'أمانات'),
  asset('ممتلك', 'ممتلكاتي');

  const EntryKind(this.label, this.plural);
  final String label;
  final String plural;
}

class VaultEntry {
  const VaultEntry({
    required this.id,
    required this.kind,
    required this.title,
    this.party = '',
    this.amount,
    this.currencyCode,
    this.dueDate,
    this.notes = '',
    this.completed = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final EntryKind kind;
  final String title;
  final String party;
  final double? amount;
  /// Optional, explicit ISO-like currency code. Legacy records leave it unset.
  final String? currencyCode;
  /// Optional local calendar date for payment or review.
  final DateTime? dueDate;
  final String notes;
  final bool completed;
  final DateTime createdAt;
  final DateTime updatedAt;

  VaultEntry copyWith({bool? completed}) => VaultEntry(
        id: id,
        kind: kind,
        title: title,
        party: party,
        amount: amount,
        currencyCode: currencyCode,
        dueDate: dueDate,
        notes: notes,
        completed: completed ?? this.completed,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'title': title,
        'party': party,
        'amount': amount,
        'currencyCode': currencyCode,
        'dueDate': dueDate?.toIso8601String(),
        'notes': notes,
        'completed': completed,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory VaultEntry.fromJson(Map<String, dynamic> json) => VaultEntry(
        id: json['id'] as String,
        kind: EntryKind.values.firstWhere((e) => e.name == json['kind']),
        title: json['title'] as String? ?? '',
        party: json['party'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble(),
        currencyCode: json['currencyCode'] as String?,
        dueDate: DateTime.tryParse(json['dueDate'] as String? ?? ''),
        notes: json['notes'] as String? ?? '',
        completed: json['completed'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class WillDraft {
  const WillDraft({
    this.fullName = '',
    this.city = '',
    this.executorName = '',
    this.executorContact = '',
    this.bequests = '',
    this.instructions = '',
    this.lastReviewed,
  });
  final String fullName;
  final String city;
  final String executorName;
  final String executorContact;
  final String bequests;
  final String instructions;
  final DateTime? lastReviewed;

  bool get hasContent => filledFieldCount > 0;

  /// Compare editable contents only, ignoring the last saved timestamp.
  bool hasSameContent(WillDraft other) =>
      fullName == other.fullName &&
      city == other.city &&
      executorName == other.executorName &&
      executorContact == other.executorContact &&
      bequests == other.bequests &&
      instructions == other.instructions;

  /// Number of fields containing text; this is NOT legal or religious validity.
  int get filledFieldCount => [
        fullName, city, executorName, executorContact, bequests, instructions,
      ].where((value) => value.trim().isNotEmpty).length;

  static const int editableFieldCount = 6;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'city': city,
        'executorName': executorName,
        'executorContact': executorContact,
        'bequests': bequests,
        'instructions': instructions,
        'lastReviewed': lastReviewed?.toIso8601String(),
      };

  factory WillDraft.fromJson(Map<String, dynamic> json) => WillDraft(
        fullName: json['fullName'] as String? ?? '',
        city: json['city'] as String? ?? '',
        executorName: json['executorName'] as String? ?? '',
        executorContact: json['executorContact'] as String? ?? '',
        bequests: json['bequests'] as String? ?? '',
        instructions: json['instructions'] as String? ?? '',
        lastReviewed: DateTime.tryParse(json['lastReviewed'] as String? ?? ''),
      );
}

/// A private, encrypted snapshot of a previously saved will draft.
/// This is a personal revision, not a witnessed or formally valid will.
class WillRevision {
  const WillRevision({
    required this.id,
    required this.savedAt,
    required this.draft,
  });

  final String id;
  final DateTime savedAt;
  final WillDraft draft;

  Map<String, dynamic> toJson() => {
        'id': id,
        'savedAt': savedAt.toIso8601String(),
        'draft': draft.toJson(),
      };

  factory WillRevision.fromJson(Map<String, dynamic> json) => WillRevision(
        id: json['id'] as String,
        savedAt: DateTime.parse(json['savedAt'] as String),
        draft: WillDraft.fromJson(json['draft'] as Map<String, dynamic>),
      );
}

/// Keeps only older *different* drafts. The current draft is stored separately.
/// Capturing a revision happens when that draft is replaced, not on every edit.
class WillRevisionPolicy {
  const WillRevisionPolicy._();
  static const maxRevisions = 20;

  static List<WillRevision> capture({
    required WillDraft previous,
    required WillDraft next,
    required List<WillRevision> existing,
    required String revisionId,
    required DateTime savedAt,
  }) {
    if (previous.hasSameContent(next) || !previous.hasContent) {
      return List<WillRevision>.unmodifiable(existing);
    }
    return List<WillRevision>.unmodifiable([
      WillRevision(id: revisionId, savedAt: savedAt, draft: previous),
      ...existing,
    ].take(maxRevisions));
  }
}

class VaultData {
  const VaultData({
    this.entries = const [],
    this.will = const WillDraft(),
    this.revisions = const [],
  });
  final List<VaultEntry> entries;
  final WillDraft will;
  final List<WillRevision> revisions;

  Map<String, dynamic> toJson() => {
        'schema': 1,
        'entries': entries.map((e) => e.toJson()).toList(),
        'will': will.toJson(),
        'revisions': revisions.map((revision) => revision.toJson()).toList(),
      };

  String encode() => jsonEncode(toJson());

  factory VaultData.decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> || decoded['schema'] != 1) {
      throw const FormatException('إصدار بيانات غير مدعوم');
    }
    return VaultData(
      entries: (decoded['entries'] as List<dynamic>)
          .map((e) => VaultEntry.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      will: WillDraft.fromJson(decoded['will'] as Map<String, dynamic>),
      // Optional so encrypted schema-1 vaults and older portable backups load.
      revisions: List<WillRevision>.unmodifiable(
        ((decoded['revisions'] as List<dynamic>?) ?? const [])
            .map((item) => WillRevision.fromJson(item as Map<String, dynamic>))
            .take(WillRevisionPolicy.maxRevisions),
      ),
    );
  }
}
