import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../services/prediction_service.dart';
import '../models/patient_input.dart';
import '../models/prediction_result.dart';

/// State of the current classification request.
sealed class PredictionState {
  const PredictionState();
}

/// Nothing has been submitted yet.
class PredictionIdle extends PredictionState {
  const PredictionIdle();
}

/// A request for [input] is in flight.
class PredictionLoading extends PredictionState {
  const PredictionLoading(this.input);
  final PatientInput input;
}

/// The service answered with a valid result.
class PredictionSuccess extends PredictionState {
  const PredictionSuccess(this.outcome);
  final ClassificationOutcome outcome;
}

/// No result could be obtained for [input].
class PredictionFailed extends PredictionState {
  const PredictionFailed(this.input, this.error);
  final PatientInput input;
  final PredictionException error;
}

/// Sends validated measurements to the [PredictionService] and exposes the
/// outcome. It contains no classification logic of its own.
class PredictionController extends Notifier<PredictionState> {
  @override
  PredictionState build() => const PredictionIdle();

  /// Submits [input]. Calls made while a request is already running are
  /// ignored (duplicate-submission protection).
  Future<void> submit(PatientInput input) async {
    if (state is PredictionLoading) return;
    state = PredictionLoading(input);
    final service = ref.read(predictionServiceProvider);
    final now = ref.read(clockProvider);
    try {
      final result = await service.predict(input);
      if (!ref.mounted) return;
      state = PredictionSuccess(
        ClassificationOutcome(
          id: _newId(now()),
          input: input,
          result: result,
          timestamp: now(),
        ),
      );
    } on PredictionException catch (error) {
      if (!ref.mounted) return;
      state = PredictionFailed(input, error);
    } catch (error) {
      debugPrint('Unexpected prediction failure: $error');
      if (!ref.mounted) return;
      state = PredictionFailed(
        input,
        const PredictionException(PredictionFailureType.unknown),
      );
    }
  }

  /// Sends the most recent measurements again after a failure.
  Future<void> retry() async {
    final current = state;
    if (current is PredictionFailed) await submit(current.input);
  }

  /// Forgets the current request and result.
  void clear() {
    if (state is PredictionLoading) return;
    state = const PredictionIdle();
  }

  static final Random _random = _secureRandom();

  static Random _secureRandom() {
    try {
      return Random.secure();
    } catch (_) {
      return Random();
    }
  }

  /// Random, non-identifying record id (time component keeps ids sortable).
  static String _newId(DateTime time) {
    final suffix = List.generate(
      4,
      (_) => _random.nextInt(0x10000).toRadixString(16).padLeft(4, '0'),
    ).join();
    return '${time.microsecondsSinceEpoch.toRadixString(16)}-$suffix';
  }
}

final predictionControllerProvider =
    NotifierProvider<PredictionController, PredictionState>(
      PredictionController.new,
    );
