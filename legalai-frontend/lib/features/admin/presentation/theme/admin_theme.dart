import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_button_tokens.dart';

class AdminPalette {
  final Color primary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  const AdminPalette({
    required this.primary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
  });
}

class AdminTheme {
  static const AdminPalette _darkPalette = AdminPalette(
    primary: AppPalette.primary,
    accent: AppPalette.secondary,
    background: AppPalette.backgroundDark,
    surface: AppPalette.surfaceDark,
    surfaceAlt: AppPalette.surfaceVariantDark,
    border: AppPalette.outlineDark,
    textPrimary: AppPalette.textPrimaryDark,
    textSecondary: AppPalette.textSecondaryDark,
    success: AppPalette.success,
    warning: AppPalette.warning,
    error: AppPalette.error,
    info: AppPalette.info,
  );

  static const AdminPalette _lightPalette = AdminPalette(
    primary: AppPalette.primary,
    accent: AppPalette.secondary,
    background: AppPalette.backgroundLight,
    surface: AppPalette.surfaceLight,
    surfaceAlt: AppPalette.surfaceVariantLight,
    border: AppPalette.outlineLight,
    textPrimary: AppPalette.textPrimaryLight,
    textSecondary: AppPalette.textSecondaryLight,
    success: AppPalette.success,
    warning: AppPalette.warning,
    error: AppPalette.error,
    info: AppPalette.info,
  );

  static AdminPalette _palette = _darkPalette;

  static AdminPalette get palette => _palette;

  static ThemeData forBrightness(Brightness brightness) {
    final palette = brightness == Brightness.dark ? _darkPalette : _lightPalette;
    _palette = palette;
    final base = brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();
    final scheme = brightness == Brightness.dark ? AppPalette.darkScheme : AppPalette.lightScheme;
    final textTheme = GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.displayLarge),
      displayMedium: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.displayMedium),
      displaySmall: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.displaySmall),
      headlineLarge: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.headlineLarge),
      headlineMedium: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.headlineMedium),
      headlineSmall: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.headlineSmall),
      titleLarge: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.titleLarge),
      titleMedium: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.titleMedium),
      titleSmall: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.titleSmall),
    );

    return base.copyWith(
      useMaterial3: true,
      colorScheme: scheme,
      canvasColor: palette.surface,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: textTheme.apply(
        bodyColor: palette.textPrimary,
        displayColor: palette.textPrimary,
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: textTheme.bodyMedium?.copyWith(color: palette.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.disabled) ? palette.surfaceAlt : scheme.primary,
          ),
          foregroundColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.disabled) ? palette.textSecondary : scheme.onPrimary,
          ),
          overlayColor: MaterialStateProperty.all(scheme.onPrimary.withOpacity(0.12)),
          minimumSize: MaterialStateProperty.all(const Size(0, AppButtonTokens.minHeight)),
          padding: MaterialStateProperty.all(AppButtonTokens.padding),
          shape: MaterialStateProperty.all(AppButtonTokens.shape),
          textStyle: MaterialStateProperty.all(AppButtonTokens.textStyle),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.disabled) ? palette.textSecondary : scheme.primary,
          ),
          side: MaterialStateProperty.all(BorderSide(color: palette.border)),
          minimumSize: MaterialStateProperty.all(const Size(0, AppButtonTokens.minHeight)),
          padding: MaterialStateProperty.all(AppButtonTokens.padding),
          shape: MaterialStateProperty.all(AppButtonTokens.shape),
          textStyle: MaterialStateProperty.all(AppButtonTokens.textStyle),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all(scheme.primary),
          textStyle: MaterialStateProperty.all(const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceAlt,
        selectedColor: palette.primary.withOpacity(0.16),
        labelStyle: TextStyle(color: palette.textPrimary),
        side: BorderSide(color: palette.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: palette.surface,
        selectedIconTheme: IconThemeData(color: palette.primary),
        unselectedIconTheme: IconThemeData(color: palette.textSecondary),
        selectedLabelTextStyle: TextStyle(
          color: palette.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(color: palette.textSecondary),
        indicatorColor: palette.primary.withOpacity(0.16),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: palette.surface,
        indicatorColor: palette.primary.withOpacity(0.16),
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? palette.primary : palette.textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? palette.textPrimary : palette.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get dark => forBrightness(Brightness.dark);
  static ThemeData get light => forBrightness(Brightness.light);
}

class AdminColors {
  static Color get primary => AdminTheme.palette.primary;
  static Color get accent => AdminTheme.palette.accent;
  static Color get background => AdminTheme.palette.background;
  static Color get surface => AdminTheme.palette.surface;
  static Color get surfaceAlt => AdminTheme.palette.surfaceAlt;
  static Color get border => AdminTheme.palette.border;
  static Color get textPrimary => AdminTheme.palette.textPrimary;
  static Color get textSecondary => AdminTheme.palette.textSecondary;
  static Color get success => AdminTheme.palette.success;
  static Color get warning => AdminTheme.palette.warning;
  static Color get error => AdminTheme.palette.error;
  static Color get info => AdminTheme.palette.info;
}
