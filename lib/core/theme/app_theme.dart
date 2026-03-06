import 'package:flutter/material.dart';

/// Material 3 light and dark themes for Outista.
class AppTheme {
  AppTheme._();

  static const _primary = Color(0xFF1A1A2E);
  static const _accent = Color(0xFF4A90D9);
  static const _surface = Color(0xFFF8F9FA);
  static const _darkSurface = Color(0xFF1C1C2E);
  static const _darkCard = Color(0xFF252540);
  static const _darkFill = Color(0xFF252540);
  static const _lightFill = Color(0xFFF0F2F5);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: _accent,
      primary: _primary,
      secondary: _accent,
      surface: isDark ? _darkSurface : _surface,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? _darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : _primary,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? _darkCard : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: _accent.withOpacity(0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _accent);
          }
          return IconThemeData(
            color: isDark ? Colors.white54 : Colors.black45,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.black45,
          );
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(
              color: _accent,
              fontWeight: FontWeight.w600,
            );
          }
          return base;
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? _darkFill : _lightFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}
