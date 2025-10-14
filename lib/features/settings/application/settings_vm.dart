import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_code/core/functional/result.dart';

import '../../../core/error/app_error.dart';
import '../../../domain/repositories/history_repository.dart';

class SettingsState {
  const SettingsState({this.analyticsEnabled = false, this.error});

  final bool analyticsEnabled;
  final AppError? error;

  SettingsState copyWith({bool? analyticsEnabled, AppError? error}) {
    return SettingsState(
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      error: error,
    );
  }
}

class SettingsVm extends StateNotifier<SettingsState> {
  SettingsVm(this._historyRepository) : super(const SettingsState());

  final HistoryRepository _historyRepository;

  void setAnalytics(bool enabled) {
    state = state.copyWith(analyticsEnabled: enabled, error: null);
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
