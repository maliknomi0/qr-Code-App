import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'theme_mode';

class ThemePreferences {
  ThemePreferences(this._sharedPreferences);

  final SharedPreferences _sharedPreferences;

  ThemeMode loadThemeMode() {
    final value = _sharedPreferences.getString(_themeModeKey);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _sharedPreferences.setString(_themeModeKey, mode.name);
  }
}

final themePreferencesProvider = Provider<ThemePreferences>((ref) {
  throw UnimplementedError('ThemePreferences must be overridden');
});

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController(this._preferences) : super(_preferences.loadThemeMode());

  final ThemePreferences _preferences;

  void setThemeMode(ThemeMode mode) {
    if (mode == state) {
      return;
    }
    state = mode;
    unawaited(_preferences.saveThemeMode(mode));
  }
}

final themeControllerProvider = StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  final preferences = ref.watch(themePreferencesProvider);
  return ThemeController(preferences);
});
