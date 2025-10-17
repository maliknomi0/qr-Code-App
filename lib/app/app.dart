import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/logging/logger.dart';
import 'di/providers.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

class QrToolApp extends ConsumerWidget {
  const QrToolApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final logger = ref.watch(loggerProvider);
    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      title: 'QR Tool',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: buildAppTheme(),
      darkTheme: buildDarkAppTheme(),
      themeMode: themeMode,
      builder: (context, child) {
        logger.debug(
          'Building app with locale: '
          '${Localizations.localeOf(context)}',
        );
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
