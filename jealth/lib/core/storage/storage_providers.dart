import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'history_store.dart';
import 'key_value_store.dart';

/// Opens the platform preference storage. Overridable in tests.
final preferencesLoaderProvider = Provider<Future<KeyValueStore> Function()>((
  ref,
) {
  return () async =>
      SharedPreferencesStore(await SharedPreferences.getInstance());
});

/// Application start-up: everything the first real screen needs.
///
/// It never fails. If the platform storage cannot be opened the app continues
/// with in-memory preferences (and says so in Settings) instead of leaving the
/// user on a dead-end error screen.
final appStartupProvider = FutureProvider<KeyValueStore>((ref) async {
  try {
    return await ref.watch(preferencesLoaderProvider)();
  } catch (error) {
    debugPrint('Preferences unavailable, using in-memory storage: $error');
    return InMemoryKeyValueStore();
  }
});

final _preStartupStore = InMemoryKeyValueStore();

/// Preferences for theme, onboarding and UI choices.
final preferencesProvider = Provider<KeyValueStore>((ref) {
  return ref.watch(appStartupProvider).value ?? _preStartupStore;
});

/// Device-local storage for explicitly saved classification records.
final historyStoreProvider = Provider<HistoryStore>((ref) {
  return SecureHistoryStore();
});

/// Current time source. Overridable in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
