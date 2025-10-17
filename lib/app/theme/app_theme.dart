import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

ThemeData _buildTheme({required Brightness brightness}) {
  final isLight = brightness == Brightness.light;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF3B5BFF),
    surface: isLight ? const Color(0xFFF5F7FF) : const Color(0xFF11121A),
    brightness: brightness,
  );

  final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);

  final textTheme = base.textTheme.apply(
    bodyColor: colorScheme.onSurface,
    displayColor: colorScheme.onSurface,
  );

  final cardColor = isLight
      ? Color.lerp(colorScheme.surface, Colors.white, 0.6) ??
            colorScheme.surface
      : Color.lerp(
              colorScheme.surface,
              colorScheme.surfaceContainerHighest,
              0.35,
            ) ??
            colorScheme.surface;
  final inputFill =
      Color.lerp(
        colorScheme.surface,
        colorScheme.surfaceContainerHighest,
        isLight ? 0.55 : 0.3,
      ) ??
      colorScheme.surface;

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,

    textTheme: textTheme.copyWith(
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge,
      systemOverlayStyle: isLight
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
    ),
    cardTheme: base.cardTheme.copyWith(
      margin: EdgeInsets.zero,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFill,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: colorScheme.outline.withOpacity(isLight ? 0.3 : 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      labelStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      hintStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(isLight ? 0.35 : 0.6),
        ),
        textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: colorScheme.primary,
      inactiveTrackColor: colorScheme.primary.withOpacity(
        isLight ? 0.15 : 0.25,
      ),
      thumbColor: colorScheme.primary,
      overlayColor: colorScheme.primary.withOpacity(0.12),
    ),
    snackBarTheme: base.snackBarTheme.copyWith(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onInverseSurface,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: base.navigationBarTheme.copyWith(
      height: 68,
      elevation: 0,
      backgroundColor: Colors.transparent,
      indicatorColor: colorScheme.primary.withOpacity(isLight ? 0.12 : 0.2),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.all(
        textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    bottomSheetTheme: base.bottomSheetTheme.copyWith(
      backgroundColor: colorScheme.surface,
      modalBackgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    popupMenuTheme: base.popupMenuTheme.copyWith(
      color: colorScheme.surface,
      textStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
    ),
  );
}

ThemeData buildAppTheme() => _buildTheme(brightness: Brightness.light);

ThemeData buildDarkAppTheme() => _buildTheme(brightness: Brightness.dark);
