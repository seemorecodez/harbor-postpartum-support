import 'package:flutter/material.dart';

abstract final class HarborColors {
  static const ink = Color(0xFF302B35);
  static const plum = Color(0xFF704A69);
  static const plumDark = Color(0xFF55344F);
  static const rose = Color(0xFFC77B86);
  static const blush = Color(0xFFF7E9E5);
  static const clay = Color(0xFFB75D4A);
  static const cream = Color(0xFFFFFBF7);
  static const sage = Color(0xFF53746A);
  static const mist = Color(0xFFEAF1EE);
  static const line = Color(0xFFE5DAD7);
}

ThemeData harborTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: HarborColors.plum,
    brightness: Brightness.light,
    primary: HarborColors.plum,
    secondary: HarborColors.rose,
    tertiary: HarborColors.sage,
    surface: HarborColors.cream,
    error: HarborColors.clay,
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'HarborSans',
    colorScheme: scheme,
    scaffoldBackgroundColor: HarborColors.cream,
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontSize: 38,
        height: 1.08,
        fontWeight: FontWeight.w700,
        color: HarborColors.ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        height: 1.15,
        fontWeight: FontWeight.w700,
        color: HarborColors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 21,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: HarborColors.ink,
      ),
      bodyLarge: TextStyle(fontSize: 17, height: 1.5, color: HarborColors.ink),
      bodyMedium: TextStyle(
        fontSize: 15,
        height: 1.45,
        color: HarborColors.ink,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: HarborColors.cream,
      foregroundColor: HarborColors.ink,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: HarborColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: HarborColors.line),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: HarborColors.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
  );
}
