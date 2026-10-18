/// Normalizes Arabic-Indic and Eastern Arabic digits for money input.
/// This helper does not infer a currency or convert currencies.
String normalizeMoneyInput(String input) {
  const western = '0123456789';
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const eastern = '۰۱۲۳۴۵۶۷۸۹';
  final buffer = StringBuffer();
  for (final rune in input.trim().runes) {
    final symbol = String.fromCharCode(rune);
    final arabicPosition = arabic.indexOf(symbol);
    final easternPosition = eastern.indexOf(symbol);
    if (arabicPosition >= 0) {
      buffer.write(western[arabicPosition]);
    } else if (easternPosition >= 0) {
      buffer.write(western[easternPosition]);
    } else if (symbol == '٫' || symbol == ',') {
      buffer.write('.');
    } else if (symbol == '٬' || symbol == ' ' || symbol == ' ') {
      // Grouping separators, including non-breaking spaces.
      continue;
    } else {
      buffer.write(symbol);
    }
  }
  return buffer.toString();
}

double? parseMoneyInput(String input) =>
    double.tryParse(normalizeMoneyInput(input));
