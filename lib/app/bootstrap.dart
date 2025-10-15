import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_code/app/di/providers.dart';
import 'package:qr_code/data/preferences/history_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/logging/logger.dart';
import 'app.dart';
import 'theme/theme_controller.dart';

Future<void> bootstrap() async {
  await Hive.initFlutter();
  final sharedPreferences = await SharedPreferences.getInstance();
  final themePreferences = ThemePreferences(sharedPreferences);
  final historyPreferences = HistoryPreferences(sharedPreferences);

  final logger = AppLogger();

  runZonedGuarded(
    () => runApp(
      ProviderScope(
        overrides: [
          loggerProvider.overrideWithValue(logger),
          themePreferencesProvider.overrideWithValue(themePreferences),
          historyPreferencesProvider.overrideWithValue(historyPreferences),
        ],
        child: const QrToolApp(),
      ),
    ),
    (error, stackTrace) {
      logger.error('Uncaught zone error', error, stackTrace);
    },
  );
}
