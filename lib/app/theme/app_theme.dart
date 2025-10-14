import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0057FF)),
    useMaterial3: true,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: base.colorScheme.onBackground),
    scaffoldBackgroundColor: base.colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: base.colorScheme.surface,
      foregroundColor: base.colorScheme.onSurface,
      elevation: 0,
    ),
    navigationBarTheme: base.navigationBarTheme.copyWith(
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
  );
}
