import 'package:flutter/material.dart';

/// Provides [ThemeData] for the application.
class AppTheme {
  // ===== Brand & Neutrals =====
  static const Color _brandAccent = Color(0xFFFF8A00); // notification dot / accent
  static const Color _lightBg = Color(0xFFF3F4F6); // subtle gray background
  static const Color _lightSurface = Colors.white; // cards / surfaces
  static const Color _lightOnBg = Color(0xFF111111); // primary text on light
  static const Color _lightSubtle = Color(0xFF6B7280); // secondary text/icons
  static const Color _lightBorder = Color(0xFFE5E7EB); // card & input borders

  static const Color _darkBg = Color(0xFF111315);
  static const Color _darkSurface = Color(0xFF1A1D21);
  static const Color _darkOnBg = Color(0xFFFFFFFF);
  static const Color _darkSubtle = Color(0xFF9CA3AF);
  static const Color _darkBorder = Color(0xFF2A2F35);

  /// Default light theme data consistent with the reference design.
  static final ThemeData lightThemeData = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: _brandAccent,
      onPrimary: Colors.white,
      secondary: _brandAccent,
      onSecondary: Colors.white,
      error: Color(0xFFB00020),
      onError: Colors.white,
      surface: _lightSurface,
      onSurface: _lightOnBg,
      surfaceContainerHighest: _lightSurface,
      surfaceTint: Colors.transparent,
      // Fallbacks for new M3 fields
      primaryContainer: _lightSurface,
      onPrimaryContainer: _lightOnBg,
      secondaryContainer: _lightSurface,
      onSecondaryContainer: _lightOnBg,
      tertiary: _lightSubtle,
      onTertiary: Colors.white,
      tertiaryContainer: _lightSurface,
      onTertiaryContainer: _lightOnBg,
      outline: _lightBorder,
      outlineVariant: _lightBorder,
      shadow: Colors.black12,
      scrim: Colors.black54,
      inverseSurface: _darkSurface,
      onInverseSurface: _darkOnBg,
      inversePrimary: _brandAccent,
    ),
    scaffoldBackgroundColor: _lightBg,
    primaryColor: _brandAccent,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: _lightBg,
      foregroundColor: _lightOnBg,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: _lightSurface,
      elevation: 1,
      shadowColor: Colors.black12,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: _lightBorder),
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    iconTheme: const IconThemeData(color: _lightSubtle, size: 22),
    dividerTheme: const DividerThemeData(color: _lightBorder),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: _lightSurface,
      hintStyle: const TextStyle(color: _lightSubtle),
      prefixIconColor: _lightSubtle,
      suffixIconColor: _lightSubtle,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _lightOnBg),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all<Color>(_lightOnBg),
        textStyle: WidgetStateProperty.all<TextStyle>(
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        overlayColor: WidgetStateProperty.all<Color>(_lightOnBg.withValues(alpha: 0.06)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _lightSurface,
      foregroundColor: _lightOnBg,
      elevation: 2,
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: _lightSurface,
      side: BorderSide(color: _lightBorder),
      labelStyle: TextStyle(color: _lightOnBg, fontWeight: FontWeight.w600),
      selectedColor: _brandAccent,
    ),
  );

  /// Default dark theme data mirroring the light theme hierarchy.
  static final ThemeData darkThemeData = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: _brandAccent,
      onPrimary: Colors.black,
      secondary: _brandAccent,
      onSecondary: Colors.black,
      error: Color(0xFFCF6679),
      onError: Colors.black,
      surface: _darkSurface,
      onSurface: _darkOnBg,
      surfaceContainerHighest: _darkSurface,
      surfaceTint: Colors.transparent,
      primaryContainer: _darkSurface,
      onPrimaryContainer: _darkOnBg,
      secondaryContainer: _darkSurface,
      onSecondaryContainer: _darkOnBg,
      tertiary: _darkSubtle,
      onTertiary: Colors.black,
      tertiaryContainer: _darkSurface,
      onTertiaryContainer: _darkOnBg,
      outline: _darkBorder,
      outlineVariant: _darkBorder,
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: _lightSurface,
      onInverseSurface: _lightOnBg,
      inversePrimary: _brandAccent,
    ),
    scaffoldBackgroundColor: _darkBg,
    primaryColor: _brandAccent,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: _darkBg,
      foregroundColor: _darkOnBg,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: _darkSurface,
      elevation: 1,
      shadowColor: Colors.black54,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: _darkBorder),
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    iconTheme: const IconThemeData(color: _darkSubtle, size: 22),
    dividerTheme: const DividerThemeData(color: _darkBorder),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: _darkSurface,
      hintStyle: const TextStyle(color: _darkSubtle),
      prefixIconColor: _darkSubtle,
      suffixIconColor: _darkSubtle,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _darkOnBg),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all<Color>(_darkOnBg),
        textStyle: WidgetStateProperty.all<TextStyle>(
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        overlayColor: WidgetStateProperty.all<Color>(_darkOnBg.withValues(alpha: 0.08)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _darkSurface,
      foregroundColor: _darkOnBg,
      elevation: 2,
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: _darkSurface,
      side: BorderSide(color: _darkBorder),
      labelStyle: TextStyle(color: _darkOnBg, fontWeight: FontWeight.w600),
      selectedColor: _brandAccent,
    ),
  );
}
