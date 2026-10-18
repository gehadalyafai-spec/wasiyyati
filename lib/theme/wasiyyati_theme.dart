import 'package:flutter/material.dart';

/// Colors are deliberately derived from the "Living Document" art direction.
/// Avoid generic saturated Islamic-green gradients: paper, ink and copper are
/// the primary visual metaphor.
abstract final class WasiyyatiColors {
  static const canvas = Color(0xFFF5F0E7);
  static const paper = Color(0xFFFFFCF6);
  static const ink = Color(0xFF203A36);
  static const secondaryInk = Color(0xFF51665C);
  static const copper = Color(0xFFA87958);
  static const rule = Color(0xFFDED8C9);
  static const sage = Color(0xFFE8EDE4);
  static const positive = Color(0xFF3B6D62);
  static const warning = Color(0xFF925640);
}

ThemeData buildWasiyyatiTheme() {
  // Do not download fonts at app launch: private documents must remain usable
  // without network access. The document heading uses a system serif fallback.
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: WasiyyatiColors.ink,
      primary: WasiyyatiColors.ink,
      secondary: WasiyyatiColors.copper,
      surface: WasiyyatiColors.canvas,
    ),
    scaffoldBackgroundColor: WasiyyatiColors.canvas,
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: WasiyyatiColors.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: WasiyyatiColors.ink,
      titleTextStyle: TextStyle(color: WasiyyatiColors.ink, fontSize: 18,
          fontWeight: FontWeight.w800),
    ),
    textTheme: base.textTheme.apply(bodyColor: WasiyyatiColors.ink, displayColor: WasiyyatiColors.ink),
    dividerColor: WasiyyatiColors.rule,
    cardTheme: const CardThemeData(
      elevation: 0,
      color: WasiyyatiColors.paper,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: WasiyyatiColors.paper,
      selectedColor: WasiyyatiColors.ink,
      secondarySelectedColor: WasiyyatiColors.ink,
      labelStyle: const TextStyle(color: WasiyyatiColors.ink),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: const BorderSide(color: WasiyyatiColors.rule),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: WasiyyatiColors.paper,
      floatingLabelStyle: const TextStyle(color: WasiyyatiColors.ink),
      hintStyle: const TextStyle(color: WasiyyatiColors.secondaryInk),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: WasiyyatiColors.rule),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: WasiyyatiColors.copper, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: WasiyyatiColors.warning),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: WasiyyatiColors.warning, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
      backgroundColor: WasiyyatiColors.ink,
      foregroundColor: WasiyyatiColors.paper,
      minimumSize: const Size.fromHeight(54),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    )),
  );
}
