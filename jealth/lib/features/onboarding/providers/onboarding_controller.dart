import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/key_value_store.dart';
import '../../../core/storage/storage_providers.dart';

/// Whether the first-launch onboarding has been completed (persisted).
class OnboardingController extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(preferencesProvider).getBool(PrefKeys.onboardingComplete) ??
      false;

  Future<void> complete() async {
    state = true;
    await ref
        .read(preferencesProvider)
        .setBool(PrefKeys.onboardingComplete, true);
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, bool>(OnboardingController.new);
