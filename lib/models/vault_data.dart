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

  bool get hasContent =>
      fullName.trim().isNotEmpty ||
      bequests.trim().isNotEmpty ||
      instructions.trim().isNotEmpty ||
      executorName.trim().isNotEmpty;

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

class VaultData {
  const VaultData({this.entries = const [], this.will = const WillDraft()});
  final List<VaultEntry> entries;
  final WillDraft will;

  Map<String, dynamic> toJson() => {
        'schema': 1,
        'entries': entries.map((e) => e.toJson()).toList(),
        'will': will.toJson(),
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
    );
  }
}
