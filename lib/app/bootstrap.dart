import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/logging/logger.dart';
import 'app.dart';
import 'theme/theme_controller.dart';

Future<void> bootstrap() async {
  await Hive.initFlutter();
  final sharedPreferences = await SharedPreferences.getInstance();
  final themePreferences = ThemePreferences(sharedPreferences);

  final logger = AppLogger();

  runZonedGuarded(
    () => runApp(
      ProviderScope(
        overrides: [
          loggerProvider.overrideWithValue(logger),
          themePreferencesProvider.overrideWithValue(themePreferences),
        ],
        child: const QrToolApp(),
      ),
    ),
    (error, stackTrace) {
      logger.error('Uncaught zone error', error, stackTrace);
    },
  );
}
