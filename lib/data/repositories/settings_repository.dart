import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/prefs_keys.dart';

/// Repository for app settings.
class SettingsRepository {
  /// Gets whether haptic feedback is enabled.
  Future<bool> getHapticFeedbackEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PrefsKeys.hapticFeedbackEnabled) ?? true;
  }

  /// Sets whether haptic feedback is enabled.
  Future<void> setHapticFeedbackEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.hapticFeedbackEnabled, enabled);
  }

  /// Clears all app settings and data.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
