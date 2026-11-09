/// Application theme definitions (light and dark).
library;

import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _primaryColor = Color(0xFF1565C0); // Blue 800

  /// Light theme.
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: _primaryColor,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: const CardTheme(
          elevation: 1,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 2,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      );

  /// Dark theme.
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: _primaryColor,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: const CardTheme(
          elevation: 1,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 2,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      );
}
