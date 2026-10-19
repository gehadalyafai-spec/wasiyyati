import '../models/vault_data.dart';

/// Only presents saved currency codes; it never guesses or converts a currency.
const supportedRecordCurrencies = <String, String>{
  'SAR': 'ريال سعودي',
  'YER': 'ريال يمني',
  'USD': 'دولار أمريكي',
  'AED': 'درهم إماراتي',
  'EUR': 'يورو',
  'QAR': 'ريال قطري',
  'KWD': 'دينار كويتي',
  'OMR': 'ريال عماني',
  'BHD': 'دينار بحريني',
  'EGP': 'جنيه مصري',
};

String currencyDescription(String? code) {
  if (code == null || code.trim().isEmpty) {
    return 'العملة غير محددة';
  }
  return supportedRecordCurrencies[code] ?? code;
}

String formatRecordDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}/$month/$day';
}

/// An expired due date is informative only, not a legal finding.
bool isRecordOverdue(VaultEntry entry, DateTime today) {
  final due = entry.dueDate;
  if (due == null || entry.completed ||
      (entry.kind != EntryKind.owed && entry.kind != EntryKind.receivable)) {
    return false;
  }
  final dueDay = DateTime(due.year, due.month, due.day);
  final currentDay = DateTime(today.year, today.month, today.day);
  return dueDay.isBefore(currentDay);
}
