import 'package:shared_preferences/shared_preferences.dart';

enum _PreferenceKey {
  autoSaveGenerated('auto_save_generated'),
  autoSaveScanned('auto_save_scanned');

  const _PreferenceKey(this.value);
  final String value;
}

class HistoryPreferences {
  HistoryPreferences(this._preferences);

  final SharedPreferences _preferences;

  bool loadAutoSaveGenerated() {
    return _preferences.getBool(_PreferenceKey.autoSaveGenerated.value) ?? false;
  }

  bool loadAutoSaveScanned() {
    return _preferences.getBool(_PreferenceKey.autoSaveScanned.value) ?? true;
  }

  Future<void> setAutoSaveGenerated(bool value) async {
    await _preferences.setBool(_PreferenceKey.autoSaveGenerated.value, value);
  }

  Future<void> setAutoSaveScanned(bool value) async {
    await _preferences.setBool(_PreferenceKey.autoSaveScanned.value, value);
  }
}