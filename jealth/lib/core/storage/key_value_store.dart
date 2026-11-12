import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal key-value storage for non-sensitive preferences
/// (theme, onboarding completion, UI preferences, service address).
abstract interface class KeyValueStore {
  /// False when values only live in memory for the current session.
  bool get isPersistent;

  String? getString(String key);
  bool? getBool(String key);
  Future<void> setString(String key, String value);
  Future<void> setBool(String key, bool value);
  Future<void> remove(String key);
}

/// Keys used by the application. Health measurements are never stored here.
abstract final class PrefKeys {
  static const String onboardingComplete = 'jealth.onboarding_complete';
  static const String themeMode = 'jealth.theme_mode';
  static const String apiBaseUrl = 'jealth.api_base_url';
  static const String historySortNewestFirst =
      'jealth.history_sort_newest_first';
}

/// [KeyValueStore] backed by the platform's preference storage.
class SharedPreferencesStore implements KeyValueStore {
  SharedPreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  bool get isPersistent => true;

  @override
  String? getString(String key) {
    final value = _prefs.get(key);
    return value is String ? value : null;
  }

  @override
  bool? getBool(String key) {
    final value = _prefs.get(key);
    return value is bool ? value : null;
  }

  @override
  Future<void> setString(String key, String value) =>
      _write(() => _prefs.setString(key, value));

  @override
  Future<void> setBool(String key, bool value) =>
      _write(() => _prefs.setBool(key, value));

  @override
  Future<void> remove(String key) => _write(() => _prefs.remove(key));

  /// Preferences are a convenience: a failed write must never break the
  /// screen that triggered it. The choice still applies for this session.
  Future<void> _write(Future<bool> Function() action) async {
    try {
      await action();
    } catch (error) {
      debugPrint('Preference could not be saved: $error');
    }
  }
}

/// Fallback used when the platform storage cannot be opened: the app stays
/// fully usable, but preferences last only for the current session.
class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore({this.isPersistent = false});

  final Map<String, Object> _values = {};

  @override
  final bool isPersistent;

  @override
  String? getString(String key) {
    final value = _values[key];
    return value is String ? value : null;
  }

  @override
  bool? getBool(String key) {
    final value = _values[key];
    return value is bool ? value : null;
  }

  @override
  Future<void> setString(String key, String value) async =>
      _values[key] = value;

  @override
  Future<void> setBool(String key, bool value) async => _values[key] = value;

  @override
  Future<void> remove(String key) async => _values.remove(key);
}
