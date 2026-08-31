import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'accessibility.dart';

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

ThemeData harborTheme() => _harborTheme(highContrast: false);

ThemeData harborHighContrastTheme() => _harborTheme(highContrast: true);

ThemeData _harborTheme({required bool highContrast}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: HarborColors.plum,
    brightness: Brightness.light,
    primary: HarborColors.plum,
    secondary: HarborColors.rose,
    tertiary: HarborColors.sage,
    surface: highContrast ? Colors.white : HarborColors.cream,
    error: HarborColors.clay,
    contrastLevel: highContrast ? 1 : 0,
  );
  final background = highContrast ? Colors.white : HarborColors.cream;
  final textColor = highContrast ? Colors.black : HarborColors.ink;
  final borderColor = highContrast ? Colors.black : HarborColors.line;
  final borderWidth = highContrast ? 2.0 : 1.0;
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'HarborSans',
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    focusColor: highContrast ? const Color(0xFFFFC857) : null,
    dividerColor: borderColor,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: HarborPageTransitionsBuilder(
          PredictiveBackPageTransitionsBuilder(),
        ),
        TargetPlatform.iOS: HarborPageTransitionsBuilder(
          CupertinoPageTransitionsBuilder(),
        ),
        TargetPlatform.macOS: HarborPageTransitionsBuilder(
          CupertinoPageTransitionsBuilder(),
        ),
        TargetPlatform.windows: HarborPageTransitionsBuilder(
          ZoomPageTransitionsBuilder(),
        ),
        TargetPlatform.linux: HarborPageTransitionsBuilder(
          ZoomPageTransitionsBuilder(),
        ),
        TargetPlatform.fuchsia: HarborPageTransitionsBuilder(
          ZoomPageTransitionsBuilder(),
        ),
      },
    ),
    textTheme: TextTheme(
      displaySmall: TextStyle(
        fontSize: 38,
        height: 1.08,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        height: 1.15,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontSize: 21,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      bodyLarge: TextStyle(fontSize: 17, height: 1.5, color: textColor),
      bodyMedium: TextStyle(fontSize: 15, height: 1.45, color: textColor),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: textColor,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor, width: borderWidth),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor, width: borderWidth),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: highContrast ? Colors.black : HarborColors.plum,
          width: highContrast ? 3 : 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: borderWidth),
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
        side: BorderSide(color: borderColor, width: borderWidth),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
  );
}
