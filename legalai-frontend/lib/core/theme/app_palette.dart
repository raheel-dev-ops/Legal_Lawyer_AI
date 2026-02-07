import 'package:flutter/material.dart';

class AppPalette {
  static const Color primary = Color(0xFF0B6E6F);
  static const Color onPrimary = Colors.white;
  static const Color primaryContainerLight = Color(0xFFB9E6E3);
  static const Color onPrimaryContainerLight = Color(0xFF003334);
  static const Color primaryContainerDark = Color(0xFF11494A);
  static const Color onPrimaryContainerDark = Color(0xFFB9E6E3);

  static const Color secondary = Color(0xFFF5B301);
  static const Color onSecondary = Color(0xFF2B1F00);
  static const Color secondaryContainerLight = Color(0xFFFFE3A6);
  static const Color onSecondaryContainerLight = Color(0xFF4A2C00);
  static const Color secondaryContainerDark = Color(0xFF5A4200);
  static const Color onSecondaryContainerDark = Color(0xFFFFE3A6);

  static const Color tertiary = Color(0xFF3B4B63);
  static const Color onTertiary = Colors.white;
  static const Color tertiaryContainerLight = Color(0xFFD8E2F7);
  static const Color onTertiaryContainerLight = Color(0xFF1E2A40);
  static const Color tertiaryContainerDark = Color(0xFF2B3A52);
  static const Color onTertiaryContainerDark = Color(0xFFD6E3FF);

  static const Color backgroundLight = Color(0xFFF7F8FB);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color surfaceLight = Colors.white;
  static const Color outlineLight = Color(0xFFE2E8F0);
  static const Color outlineVariantLight = Color(0xFFCBD5E1);

  static const Color backgroundDark = Color(0xFF0E1420);
  static const Color surfaceVariantDark = Color(0xFF182235);
  static const Color surfaceDark = Color(0xFF121A2A);
  static const Color outlineDark = Color(0xFF23324A);
  static const Color outlineVariantDark = Color(0xFF2C3B55);

  static const Color error = Color(0xFFDC2626);
  static const Color onError = Colors.white;
  static const Color errorContainerLight = Color(0xFFFEE2E2);
  static const Color onErrorContainerLight = Color(0xFF7F1D1D);
  static const Color errorContainerDark = Color(0xFF7F1D1D);
  static const Color onErrorContainerDark = Color(0xFFFEE2E2);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF2563EB);
  
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textTertiaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFE2E8F0);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF7C8CA5);

  static const Color inverseSurfaceLight = Color(0xFF1C2432);
  static const Color onInverseSurfaceLight = Color(0xFFF1F5F9);
  static const Color inverseSurfaceDark = Color(0xFFE2E8F0);
  static const Color onInverseSurfaceDark = Color(0xFF1C2432);
  static const Color inversePrimaryLight = Color(0xFF8DD4D1);
  static const Color inversePrimaryDark = Color(0xFF8DD4D1);

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainerLight,
    onPrimaryContainer: onPrimaryContainerLight,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainerLight,
    onSecondaryContainer: onSecondaryContainerLight,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainerLight,
    onTertiaryContainer: onTertiaryContainerLight,
    error: error,
    onError: onError,
    errorContainer: errorContainerLight,
    onErrorContainer: onErrorContainerLight,
    background: backgroundLight,
    onBackground: textPrimaryLight,
    surface: surfaceLight,
    onSurface: textPrimaryLight,
    surfaceVariant: surfaceVariantLight,
    onSurfaceVariant: textSecondaryLight,
    outline: outlineLight,
    outlineVariant: outlineVariantLight,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: inverseSurfaceLight,
    onInverseSurface: onInverseSurfaceLight,
    inversePrimary: inversePrimaryLight,
    surfaceTint: primary,
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainerDark,
    onPrimaryContainer: onPrimaryContainerDark,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainerDark,
    onSecondaryContainer: onSecondaryContainerDark,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainerDark,
    onTertiaryContainer: onTertiaryContainerDark,
    error: error,
    onError: onError,
    errorContainer: errorContainerDark,
    onErrorContainer: onErrorContainerDark,
    background: backgroundDark,
    onBackground: textPrimaryDark,
    surface: surfaceDark,
    onSurface: textPrimaryDark,
    surfaceVariant: surfaceVariantDark,
    onSurfaceVariant: textSecondaryDark,
    outline: outlineDark,
    outlineVariant: outlineVariantDark,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: inverseSurfaceDark,
    onInverseSurface: onInverseSurfaceDark,
    inversePrimary: inversePrimaryDark,
    surfaceTint: primary,
  );
}
