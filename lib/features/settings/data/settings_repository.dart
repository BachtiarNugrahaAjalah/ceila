import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _overlayEnabled = 'overlay_enabled';
  static const _appLockEnabled = 'app_lock_enabled';
  static const _remindersEnabled = 'reminders_enabled';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<bool> getOverlayEnabled() async =>
      (await _prefs).getBool(_overlayEnabled) ?? false;
  Future<void> setOverlayEnabled(bool v) async =>
      (await _prefs).setBool(_overlayEnabled, v);

  Future<bool> getAppLockEnabled() async =>
      (await _prefs).getBool(_appLockEnabled) ?? false;
  Future<void> setAppLockEnabled(bool v) async =>
      (await _prefs).setBool(_appLockEnabled, v);

  Future<bool> getRemindersEnabled() async =>
      (await _prefs).getBool(_remindersEnabled) ?? true;
  Future<void> setRemindersEnabled(bool v) async =>
      (await _prefs).setBool(_remindersEnabled, v);
}
