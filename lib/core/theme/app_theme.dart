import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4A6B57),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF3EFE8),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: const Color(0xFF241F1A),
        displayColor: const Color(0xFF241F1A),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4A6B57),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: const Color(0xFFEDEAE3),
        displayColor: const Color(0xFFEDEAE3),
      ),
    );
  }
}
