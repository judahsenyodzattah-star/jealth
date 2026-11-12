import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/storage/key_value_store.dart';
import '../../../core/storage/storage_providers.dart';

/// Runtime override of the prediction service address (Settings).
///
/// State is the saved base URL, or `null` when none was entered.
class ApiSettingsController extends Notifier<String?> {
  @override
  String? build() {
    final prefs = ref.watch(preferencesProvider);
    return ApiConfig.normalizeBaseUrl(prefs.getString(PrefKeys.apiBaseUrl));
  }

  /// Saves [raw] as the service address. An empty value removes the override.
  /// Returns a validation message when [raw] is not a usable address.
  Future<String?> setBaseUrl(String raw) async {
    final problem = ApiConfig.validateBaseUrl(raw);
    if (problem != null) return problem;
    final prefs = ref.read(preferencesProvider);
    final normalized = ApiConfig.normalizeBaseUrl(raw);
    if (normalized == null) {
      await prefs.remove(PrefKeys.apiBaseUrl);
    } else {
      await prefs.setString(PrefKeys.apiBaseUrl, normalized);
    }
    state = normalized;
    return null;
  }
}

final apiSettingsControllerProvider =
    NotifierProvider<ApiSettingsController, String?>(ApiSettingsController.new);
