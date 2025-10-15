import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_code/core/functional/result.dart';

import '../../../core/error/app_error.dart';
import '../../../domain/repositories/history_repository.dart';
import '../../../data/preferences/history_preferences.dart';

class SettingsState {
  const SettingsState({
    this.analyticsEnabled = false,
    this.autoSaveGenerated = false,
    this.autoSaveScanned = true,
    this.error,
  });

  final bool analyticsEnabled;
  final bool autoSaveGenerated;
  final bool autoSaveScanned;
  final AppError? error;

  SettingsState copyWith({
    bool? analyticsEnabled,
    bool? autoSaveGenerated,
    bool? autoSaveScanned,
    AppError? error,
  }) {
    return SettingsState(
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      autoSaveGenerated: autoSaveGenerated ?? this.autoSaveGenerated,
      autoSaveScanned: autoSaveScanned ?? this.autoSaveScanned,
      error: error,
    );
  }
}

class SettingsVm extends StateNotifier<SettingsState> {
  SettingsVm(this._historyRepository, this._preferences)
      : super(
          SettingsState(
            autoSaveGenerated: _preferences.loadAutoSaveGenerated(),
            autoSaveScanned: _preferences.loadAutoSaveScanned(),
          ),
        );

  final HistoryRepository _historyRepository;
  final HistoryPreferences _preferences;

  void setAnalytics(bool enabled) {
    state = state.copyWith(analyticsEnabled: enabled, error: null);
  }

  Future<void> setAutoSaveGenerated(bool enabled) async {
    state = state.copyWith(autoSaveGenerated: enabled, error: null);
    await _preferences.setAutoSaveGenerated(enabled);
  }

  Future<void> setAutoSaveScanned(bool enabled) async {
    state = state.copyWith(autoSaveScanned: enabled, error: null);
    await _preferences.setAutoSaveScanned(enabled);
  }

  Future<void> clearHistory() async {
    final result = await _historyRepository.fetchAll();
    if (result.isOk) {
      for (final item in result.valueOrNull!) {
        final deleteResult = await _historyRepository.delete(item.id.value);
        if (deleteResult.isErr) {
          state = state.copyWith(error: deleteResult.errorOrNull);
          return;
        }
      }
      state = state.copyWith(error: null);
    } else {
      state = state.copyWith(error: result.errorOrNull);
    }
  }
}