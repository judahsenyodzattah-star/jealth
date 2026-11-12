import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/storage/key_value_store.dart';
import '../../../core/storage/storage_providers.dart';

/// Light / dark / system theme preference, persisted locally.
class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final stored = ref.watch(preferencesProvider).getString(PrefKeys.themeMode);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == state) return;
    state = mode;
    await ref
        .read(preferencesProvider)
        .setString(PrefKeys.themeMode, mode.name);
  }
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);
