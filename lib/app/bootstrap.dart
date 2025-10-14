import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/logging/logger.dart';
import 'app.dart';

Future<void> bootstrap() async {
  await Hive.initFlutter();

  final logger = AppLogger();

  runZonedGuarded(
    () => runApp(
      ProviderScope(
        overrides: [
          loggerProvider.overrideWithValue(logger),
        ],
        child: const QrToolApp(),
      ),
    ),
    (error, stackTrace) {
      logger.error('Uncaught zone error', error, stackTrace);
    },
  );
}
