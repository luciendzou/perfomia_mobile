import 'package:flutter/material.dart';

class PerfomiaTheme {
  const PerfomiaTheme._();

  static ThemeData light() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xff2878ff),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xff2878ff),
          onPrimary: Colors.white,
          secondary: const Color(0xff20bfd7),
          onSecondary: Colors.white,
          surface: Colors.white,
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: const Color(0xfff7fbff),
          outline: const Color(0xffd8e4f2),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xfff7fbff),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xfff7fbff),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffd8e4f2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffd8e4f2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xff2878ff), width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xff2878ff),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        ),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
    );
  }
}
