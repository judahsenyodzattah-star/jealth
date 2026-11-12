// TEST FIXTURES ONLY.
//
// Nothing in this file is compiled into the J'ealth application. The fake
// prediction service below returns whatever a test tells it to return; it
// contains no classification logic and is not a stand-in for the trained
// model.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jealth/app/app.dart';
import 'package:jealth/core/errors/app_exceptions.dart';
import 'package:jealth/core/storage/history_store.dart';
import 'package:jealth/core/storage/key_value_store.dart';
import 'package:jealth/core/storage/storage_providers.dart';
import 'package:jealth/features/classification/models/patient_input.dart';
import 'package:jealth/features/classification/models/prediction_result.dart';
import 'package:jealth/features/history/models/history_record.dart';
import 'package:jealth/features/results/services/share_service.dart';
import 'package:jealth/services/prediction_service.dart';
import 'package:material_ui/material_ui.dart';

/// The example request from the project's API contract.
const PatientInput contractExampleInput = PatientInput(
  age: 68,
  sex: Sex.male,
  bloodPressure: 105,
  cholesterol: 191,
  bmi: 38.0,
  smoker: YesNo.yes,
  diabetes: YesNo.yes,
  physicalActivity: 0,
  familyHistory: YesNo.no,
  stressLevel: 2,
);

/// TEST FIXTURE: a scripted prediction service.
///
/// Returns the canned [response] or throws the canned [failure]. It never
/// looks at the measurements to decide a class.
class FakePredictionService implements PredictionService {
  FakePredictionService({this.response, this.failure, this.gate})
    : assert(response != null || failure != null);

  /// Canned answer, chosen by the test.
  PredictionResult? response;

  /// Canned failure, chosen by the test. Takes priority over [response].
  PredictionException? failure;

  /// When set, `predict` waits for this to complete (simulates latency).
  Completer<void>? gate;

  final List<PatientInput> requests = [];
  ServiceHealth health = const ServiceHealth(ServiceConnection.connected);

  @override
  bool get isConfigured => true;

  @override
  Future<PredictionResult> predict(PatientInput input) async {
    requests.add(input);
    if (gate != null) await gate!.future;
    if (failure != null) throw failure!;
    return response!;
  }

  @override
  Future<ServiceHealth> checkHealth() async => health;
}

/// TEST FIXTURE: in-memory replacement for the device's secure storage.
class InMemoryHistoryStore implements HistoryStore {
  InMemoryHistoryStore([Map<String, String>? initial])
    : entries = {...?initial};

  final Map<String, String> entries;
  bool failReads = false;
  bool failWrites = false;

  @override
  Future<Map<String, String>> readAll() async {
    if (failReads) throw const StorageException('fixture: read failed');
    return {...entries};
  }

  @override
  Future<void> write(String id, String json) async {
    if (failWrites) throw const StorageException('fixture: write failed');
    entries[id] = json;
  }

  @override
  Future<void> delete(String id) async {
    if (failWrites) throw const StorageException('fixture: delete failed');
    entries.remove(id);
  }

  @override
  Future<void> deleteAll() async {
    if (failWrites) throw const StorageException('fixture: delete failed');
    entries.clear();
  }
}

/// TEST FIXTURE: records what the app tried to share instead of sharing it.
class RecordingShareService implements ShareService {
  final List<String> shared = [];

  @override
  Future<ShareOutcome> shareText(
    String text, {
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    shared.add(text);
    return ShareOutcome.shared;
  }
}

/// TEST FIXTURE: builds a history record for storage tests.
HistoryRecord fixtureRecord({
  String id = 'fixture-1',
  HeartDiseaseClass predictedClass = HeartDiseaseClass.heartDisease,
  DateTime? timestamp,
  PatientInput input = contractExampleInput,
  double? modelScore,
  String? modelVersion,
}) => HistoryRecord(
  id: id,
  input: input,
  predictedClass: predictedClass,
  timestamp: timestamp ?? DateTime(2026, 3, 14, 9, 30),
  modelScore: modelScore,
  modelVersion: modelVersion,
);

/// Preferences for a user who has already finished onboarding.
Future<InMemoryKeyValueStore> onboardedPrefs() async {
  final prefs = InMemoryKeyValueStore(isPersistent: true);
  await prefs.setBool(PrefKeys.onboardingComplete, true);
  return prefs;
}

/// Sets the test window to a logical [size].
void setSurfaceSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

const Size phoneSize = Size(390, 844);
const Size desktopSize = Size(1280, 800);

/// Pumps the whole J'ealth app with fixture storage and (optionally) a
/// fixture prediction service, then waits for start-up to finish.
Future<ProviderContainer> pumpJealthApp(
  WidgetTester tester, {
  KeyValueStore? prefs,
  HistoryStore? historyStore,
  PredictionService? service,
  ShareService? shareService,
  DateTime Function()? clock,
  Size size = phoneSize,
}) async {
  setSurfaceSize(tester, size);
  final store = prefs ?? await onboardedPrefs();
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      preferencesLoaderProvider.overrideWithValue(() async => store),
      historyStoreProvider.overrideWithValue(
        historyStore ?? InMemoryHistoryStore(),
      ),
      if (service != null) predictionServiceProvider.overrideWithValue(service),
      if (shareService != null)
        shareServiceProvider.overrideWithValue(shareService),
      if (clock != null) clockProvider.overrideWithValue(clock),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const JealthApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Types the contract example into the classification form.
Future<void> fillClassificationForm(WidgetTester tester) async {
  Future<void> type(String field, String value) async {
    final finder = find.byKey(ValueKey('field-$field'));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.enterText(finder, value);
    await tester.pump();
  }

  Future<void> choose(String field, String option) async {
    final finder = find.descendant(
      of: find.byKey(ValueKey('field-$field')),
      matching: find.text(option),
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pump();
  }

  await type('age', '68');
  await choose('sex', 'Male');
  await type('bloodPressure', '105');
  await type('cholesterol', '191');
  await type('bmi', '38.0');
  await choose('smoker', 'Yes');
  await choose('diabetes', 'Yes');
  await type('physicalActivity', '0');
  await choose('familyHistory', 'No');
  await type('stressLevel', '2');
}

/// Scrolls to and taps the widget with [key].
Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
