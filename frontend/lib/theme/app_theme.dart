import 'package:flutter/material.dart';

/// Provides [ThemeData] for the application with accessibility support.
///
/// Includes high contrast themes and responsive text scaling to support
/// users with visual accessibility needs.
class AppTheme {
  // ===== Brand & Neutrals =====
  static const Color _brandAccent = Color(
    0xFFFF8A00,
  ); // notification dot / accent
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

  // ===== High Contrast Colors =====
  static const Color _highContrastLightBg = Color(0xFFFFFFFF);
  static const Color _highContrastLightSurface = Color(0xFFFFFFFF);
  static const Color _highContrastLightOnBg = Color(0xFF000000);
  static const Color _highContrastLightBorder = Color(0xFF000000);
  static const Color _highContrastLightPrimary = Color(0xFF0000FF);

  static const Color _highContrastDarkBg = Color(0xFF000000);
  static const Color _highContrastDarkSurface = Color(0xFF000000);
  static const Color _highContrastDarkOnBg = Color(0xFFFFFFFF);
  static const Color _highContrastDarkBorder = Color(0xFFFFFFFF);
  static const Color _highContrastDarkPrimary = Color(0xFF00FFFF);

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
        overlayColor: WidgetStateProperty.all<Color>(
          _lightOnBg.withValues(alpha: 0.06),
        ),
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

  /// High contrast light theme for accessibility.
  static final ThemeData highContrastLightThemeData = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: _highContrastLightPrimary,
      onPrimary: Colors.white,
      secondary: _highContrastLightPrimary,
      onSecondary: Colors.white,
      error: Color(0xFFFF0000),
      onError: Colors.white,
      surface: _highContrastLightSurface,
      onSurface: _highContrastLightOnBg,
      surfaceContainerHighest: _highContrastLightSurface,
      surfaceTint: Colors.transparent,
      primaryContainer: _highContrastLightSurface,
      onPrimaryContainer: _highContrastLightOnBg,
      secondaryContainer: _highContrastLightSurface,
      onSecondaryContainer: _highContrastLightOnBg,
      tertiary: _highContrastLightOnBg,
      onTertiary: Colors.white,
      tertiaryContainer: _highContrastLightSurface,
      onTertiaryContainer: _highContrastLightOnBg,
      outline: _highContrastLightBorder,
      outlineVariant: _highContrastLightBorder,
      shadow: Colors.black,
      scrim: Colors.black87,
      inverseSurface: _highContrastDarkSurface,
      onInverseSurface: _highContrastDarkOnBg,
      inversePrimary: _highContrastDarkPrimary,
    ),
    scaffoldBackgroundColor: _highContrastLightBg,
    primaryColor: _highContrastLightPrimary,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: _highContrastLightBg,
      foregroundColor: _highContrastLightOnBg,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: _highContrastLightSurface,
      elevation: 0,
      shadowColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: const BorderSide(width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    iconTheme: const IconThemeData(color: _highContrastLightOnBg, size: 24),
    dividerTheme: const DividerThemeData(color: _highContrastLightBorder, thickness: 2),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: _highContrastLightSurface,
      hintStyle: const TextStyle(color: _highContrastLightOnBg),
      prefixIconColor: _highContrastLightOnBg,
      suffixIconColor: _highContrastLightOnBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _highContrastLightPrimary, width: 3),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all<Color>(_highContrastLightPrimary),
        textStyle: WidgetStateProperty.all<TextStyle>(
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        overlayColor: WidgetStateProperty.all<Color>(
          _highContrastLightPrimary.withValues(alpha: 0.1),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _highContrastLightPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: _highContrastLightSurface,
      side: BorderSide(width: 2),
      labelStyle: TextStyle(color: _highContrastLightOnBg, fontWeight: FontWeight.w700),
      selectedColor: _highContrastLightPrimary,
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
        overlayColor: WidgetStateProperty.all<Color>(
          _darkOnBg.withValues(alpha: 0.08),
        ),
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

  /// High contrast dark theme for accessibility.
  static final ThemeData highContrastDarkThemeData = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: _highContrastDarkPrimary,
      onPrimary: Colors.black,
      secondary: _highContrastDarkPrimary,
      onSecondary: Colors.black,
      error: Color(0xFFFF4444),
      onError: Colors.black,
      surface: _highContrastDarkSurface,
      onSurface: _highContrastDarkOnBg,
      surfaceContainerHighest: _highContrastDarkSurface,
      surfaceTint: Colors.transparent,
      primaryContainer: _highContrastDarkSurface,
      onPrimaryContainer: _highContrastDarkOnBg,
      secondaryContainer: _highContrastDarkSurface,
      onSecondaryContainer: _highContrastDarkOnBg,
      tertiary: _highContrastDarkOnBg,
      onTertiary: Colors.black,
      tertiaryContainer: _highContrastDarkSurface,
      onTertiaryContainer: _highContrastDarkOnBg,
      outline: _highContrastDarkBorder,
      outlineVariant: _highContrastDarkBorder,
      shadow: Colors.white,
      scrim: Colors.white70,
      inverseSurface: _highContrastLightSurface,
      onInverseSurface: _highContrastLightOnBg,
      inversePrimary: _highContrastLightPrimary,
    ),
    scaffoldBackgroundColor: _highContrastDarkBg,
    primaryColor: _highContrastDarkPrimary,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: _highContrastDarkBg,
      foregroundColor: _highContrastDarkOnBg,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: _highContrastDarkSurface,
      elevation: 0,
      shadowColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: _highContrastDarkBorder, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    iconTheme: const IconThemeData(color: _highContrastDarkOnBg, size: 24),
    dividerTheme: const DividerThemeData(color: _highContrastDarkBorder, thickness: 2),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: _highContrastDarkSurface,
      hintStyle: const TextStyle(color: _highContrastDarkOnBg),
      prefixIconColor: _highContrastDarkOnBg,
      suffixIconColor: _highContrastDarkOnBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _highContrastDarkBorder, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _highContrastDarkBorder, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _highContrastDarkPrimary, width: 3),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all<Color>(_highContrastDarkPrimary),
        textStyle: WidgetStateProperty.all<TextStyle>(
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        overlayColor: WidgetStateProperty.all<Color>(
          _highContrastDarkPrimary.withValues(alpha: 0.1),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _highContrastDarkPrimary,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: _highContrastDarkSurface,
      side: BorderSide(color: _highContrastDarkBorder, width: 2),
      labelStyle: TextStyle(color: _highContrastDarkOnBg, fontWeight: FontWeight.w700),
      selectedColor: _highContrastDarkPrimary,
    ),
  );

  /// Gets the appropriate theme based on system accessibility settings.
  ///
  /// Returns high contrast themes when high contrast mode is enabled,
  /// otherwise returns the standard themes.
  ///
  /// @param context BuildContext for accessing media query
  /// @param brightness The desired brightness (light or dark)
  /// @returns ThemeData appropriate for current accessibility settings
  static ThemeData getThemeForAccessibility(BuildContext context, Brightness brightness) {
    final bool isHighContrast = MediaQuery.of(context).highContrast;

    if (isHighContrast) {
      return brightness == Brightness.light ? highContrastLightThemeData : highContrastDarkThemeData;
    } else {
      return brightness == Brightness.light ? lightThemeData : darkThemeData;
    }
  }

  /// Gets text theme with appropriate scaling for accessibility.
  ///
  /// Adjusts text sizes based on the user's text scale factor preference
  /// while maintaining proper hierarchy and readability.
  ///
  /// @param context BuildContext for accessing media query
  /// @param baseTheme The base theme to scale
  /// @returns TextTheme with appropriate scaling applied
  static TextTheme getAccessibleTextTheme(BuildContext context, ThemeData baseTheme) {
    final double textScaleFactor = MediaQuery.of(context).textScaler.scale(1.0);
    final TextTheme baseTextTheme = baseTheme.textTheme;

    // Apply additional scaling for large text accessibility
    if (textScaleFactor > 1.3) {
      return baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontSize: (baseTextTheme.displayLarge?.fontSize ?? 32) * 1.1,
          height: 1.2,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          fontSize: (baseTextTheme.displayMedium?.fontSize ?? 28) * 1.1,
          height: 1.2,
        ),
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          fontSize: (baseTextTheme.displaySmall?.fontSize ?? 24) * 1.1,
          height: 1.2,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontSize: (baseTextTheme.headlineLarge?.fontSize ?? 22) * 1.1,
          height: 1.3,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontSize: (baseTextTheme.headlineMedium?.fontSize ?? 20) * 1.1,
          height: 1.3,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontSize: (baseTextTheme.headlineSmall?.fontSize ?? 18) * 1.1,
          height: 1.3,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: (baseTextTheme.titleLarge?.fontSize ?? 16) * 1.1,
          height: 1.4,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontSize: (baseTextTheme.titleMedium?.fontSize ?? 14) * 1.1,
          height: 1.4,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          fontSize: (baseTextTheme.titleSmall?.fontSize ?? 12) * 1.1,
          height: 1.4,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: (baseTextTheme.bodyLarge?.fontSize ?? 16) * 1.1,
          height: 1.5,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: (baseTextTheme.bodyMedium?.fontSize ?? 14) * 1.1,
          height: 1.5,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          fontSize: (baseTextTheme.bodySmall?.fontSize ?? 12) * 1.1,
          height: 1.5,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontSize: (baseTextTheme.labelLarge?.fontSize ?? 14) * 1.1,
          height: 1.4,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          fontSize: (baseTextTheme.labelMedium?.fontSize ?? 12) * 1.1,
          height: 1.4,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          fontSize: (baseTextTheme.labelSmall?.fontSize ?? 10) * 1.1,
          height: 1.4,
        ),
      );
    }

    return baseTextTheme;
  }
}
