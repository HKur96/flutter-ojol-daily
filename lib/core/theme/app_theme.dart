import 'package:flutter/material.dart';

/// App color tokens for Ojol Daily application.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF006B2C);
  static const Color primaryContainer = Color(0xFF00873A);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFF7FFC97);
  static const Color onPrimaryFixedVariant = Color(0xFF005320);

  static const Color secondary = Color(0xFF565E74);
  static const Color secondaryContainer = Color(0xFFDAE2FD);
  static const Color onSecondary = Color(0xFFFFFFFF);

  static const Color tertiary = Color(0xFF8D4B00);
  static const Color tertiaryContainer = Color(0xFFB15F00);
  static const Color onTertiary = Color(0xFFFFFFFF);

  static const Color background = Color(0xFFFBF8FF);
  static const Color surface = Color(0xFFFBF8FF);
  static const Color surfaceContainer = Color(0xFFEEEDF7);
  static const Color surfaceContainerLow = Color(0xFFF4F2FD);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFE8E7F1);
  static const Color surfaceContainerHighest = Color(0xFFE3E1EC);

  static const Color onSurface = Color(0xFF1A1B22);
  static const Color onSurfaceVariant = Color(0xFF3E4A3D);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);

  static const Color warning = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color outline = Color(0xFFC4C7C0);
}

/// Modular AppTheme class accessible across the entire project.
class AppTheme {
  AppTheme._();

  // Direct static color references for modular component access
  static const Color primary = AppColors.primary;
  static const Color primaryContainer = AppColors.primaryContainer;
  static const Color onPrimary = AppColors.onPrimary;
  static const Color primaryFixed = AppColors.primaryFixed;
  static const Color onPrimaryFixedVariant = AppColors.onPrimaryFixedVariant;

  static const Color secondary = AppColors.secondary;
  static const Color secondaryContainer = AppColors.secondaryContainer;
  static const Color onSecondary = AppColors.onSecondary;

  static const Color tertiary = AppColors.tertiary;
  static const Color tertiaryContainer = AppColors.tertiaryContainer;
  static const Color onTertiary = AppColors.onTertiary;

  static const Color background = AppColors.background;
  static const Color surface = AppColors.surface;
  static const Color surfaceContainer = AppColors.surfaceContainer;
  static const Color surfaceContainerLow = AppColors.surfaceContainerLow;
  static const Color surfaceContainerLowest = AppColors.surfaceContainerLowest;
  static const Color surfaceContainerHigh = AppColors.surfaceContainerHigh;
  static const Color surfaceContainerHighest = AppColors.surfaceContainerHighest;

  static const Color onSurface = AppColors.onSurface;
  static const Color onSurfaceVariant = AppColors.onSurfaceVariant;

  static const Color error = AppColors.error;
  static const Color errorContainer = AppColors.errorContainer;
  static const Color onError = AppColors.onError;

  static const Color warning = AppColors.warning;
  static const Color warningContainer = AppColors.warningContainer;
  static const Color outline = AppColors.outline;

  // Typography Constants
  static const String fontFamily = 'Plus Jakarta Sans';

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: onSurface,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: onSurface,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: onSurface,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: onSurfaceVariant,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: onSurfaceVariant,
  );

  // Helper method for modular custom input decoration
  static InputDecoration inputDecoration({
    String? labelText,
    String? hintText,
    String? prefixText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color? fillColor,
    BorderRadius? borderRadius,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(12);
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixText: prefixText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor ?? surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: error, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
    );
  }

  // Light ThemeData definition
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryContainer,
        tertiary: AppColors.tertiary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        error: AppColors.error,
        errorContainer: AppColors.errorContainer,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.onSurface),
        titleTextStyle: TextStyle(
          color: AppColors.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: fontFamily,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: fontFamily,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}