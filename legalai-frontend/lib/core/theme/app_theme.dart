import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_palette.dart';
import 'app_button_tokens.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light();
    final scheme = AppPalette.lightScheme;
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
    final navIconTheme = MaterialStateProperty.resolveWith<IconThemeData>((states) {
      final selected = states.contains(MaterialState.selected);
      return IconThemeData(color: selected ? scheme.primary : scheme.onSurfaceVariant);
    });
    final navLabelStyle = MaterialStateProperty.resolveWith<TextStyle>((states) {
      final selected = states.contains(MaterialState.selected);
      return TextStyle(
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      );
    });

    return base.copyWith(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      canvasColor: scheme.surface,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      primaryIconTheme: IconThemeData(color: scheme.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: scheme.onSurface),
        titleTextStyle: textTheme.titleLarge?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ) ??
            TextStyle(color: scheme.onSurface, fontSize: 20, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withOpacity(0.12),
        iconTheme: navIconTheme,
        labelTextStyle: navLabelStyle,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withOpacity(0.12),
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.disabled) ? scheme.surfaceVariant : scheme.primary,
          ),
          foregroundColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.disabled) ? scheme.onSurfaceVariant : scheme.onPrimary,
          ),
          overlayColor: MaterialStateProperty.all(scheme.onPrimary.withOpacity(0.12)),
          minimumSize: MaterialStateProperty.all(const Size(double.infinity, AppButtonTokens.minHeight)),
          padding: MaterialStateProperty.all(AppButtonTokens.padding),
          shape: MaterialStateProperty.all(AppButtonTokens.shape),
          textStyle: MaterialStateProperty.all(AppButtonTokens.textStyle),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.disabled) ? scheme.onSurfaceVariant : scheme.primary,
          ),
          side: MaterialStateProperty.all(BorderSide(color: scheme.outline)),
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
        backgroundColor: scheme.surfaceVariant,
        selectedColor: scheme.primary.withOpacity(0.14),
        labelStyle: TextStyle(color: scheme.onSurface),
        secondaryLabelStyle: TextStyle(color: scheme.onSurface),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected) ? scheme.onPrimary : scheme.onSurfaceVariant,
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected) ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surfaceVariant,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        actionTextColor: scheme.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    final scheme = AppPalette.darkScheme;
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
    final navIconTheme = MaterialStateProperty.resolveWith<IconThemeData>((states) {
      final selected = states.contains(MaterialState.selected);
      return IconThemeData(color: selected ? scheme.primary : scheme.onSurfaceVariant);
    });
    final navLabelStyle = MaterialStateProperty.resolveWith<TextStyle>((states) {
      final selected = states.contains(MaterialState.selected);
      return TextStyle(
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      );
    });

    return base.copyWith(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      canvasColor: scheme.surface,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      primaryIconTheme: IconThemeData(color: scheme.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: scheme.onSurface),
        titleTextStyle: textTheme.titleLarge?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ) ??
            TextStyle(color: scheme.onSurface, fontSize: 20, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withOpacity(0.2),
        iconTheme: navIconTheme,
        labelTextStyle: navLabelStyle,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withOpacity(0.2),
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.disabled) ? scheme.surfaceVariant : scheme.primary,
          ),
          foregroundColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.disabled) ? scheme.onSurfaceVariant : scheme.onPrimary,
          ),
          overlayColor: MaterialStateProperty.all(scheme.onPrimary.withOpacity(0.12)),
          minimumSize: MaterialStateProperty.all(const Size(double.infinity, AppButtonTokens.minHeight)),
          padding: MaterialStateProperty.all(AppButtonTokens.padding),
          shape: MaterialStateProperty.all(AppButtonTokens.shape),
          textStyle: MaterialStateProperty.all(AppButtonTokens.textStyle),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.disabled) ? scheme.onSurfaceVariant : scheme.primary,
          ),
          side: MaterialStateProperty.all(BorderSide(color: scheme.outline)),
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
        backgroundColor: scheme.surfaceVariant,
        selectedColor: scheme.primary.withOpacity(0.18),
        labelStyle: TextStyle(color: scheme.onSurface),
        secondaryLabelStyle: TextStyle(color: scheme.onSurface),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected) ? scheme.onPrimary : scheme.onSurfaceVariant,
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected) ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surfaceVariant,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        actionTextColor: scheme.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
