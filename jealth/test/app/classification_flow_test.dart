import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jealth/core/errors/app_exceptions.dart';
import 'package:jealth/features/classification/models/prediction_result.dart';
import 'package:jealth/features/classification/screens/classification_screen.dart';
import 'package:jealth/features/home/screens/home_screen.dart';
import 'package:jealth/features/results/screens/result_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fixtures.dart';
import 'onboarding_navigation_test.dart' show navItem;

Future<void> openForm(WidgetTester tester) async {
  await tester.tap(navItem('classify'));
  await tester.pumpAndSettle();
}

String fieldText(WidgetTester tester, String field) => tester
    .widget<TextField>(find.byKey(ValueKey('field-$field')))
    .controller!
    .text;

void main() {
  group('classification form', () {
    testWidgets('shows all ten inputs and no identifying fields', (
      tester,
    ) async {
      await pumpJealthApp(tester, size: const Size(1000, 3000));
      await openForm(tester);
      for (final field in [
        'age',
        'sex',
        'bloodPressure',
        'cholesterol',
        'bmi',
        'smoker',
        'diabetes',
        'physicalActivity',
        'familyHistory',
        'stressLevel',
      ]) {
        expect(find.byKey(ValueKey('field-$field')), findsOneWidget);
      }
      expect(find.byType(TextField), findsNWidgets(6));
      expect(find.textContaining('Name'), findsNothing);
      expect(find.text('0 of 10 fields complete'), findsOneWidget);
    });

    testWidgets('Predict on an empty form shows errors and sends nothing', (
      tester,
    ) async {
      final service = FakePredictionService(
        response: const PredictionResult(
          predictedClass: HeartDiseaseClass.noHeartDisease,
        ),
      );
      await pumpJealthApp(tester, service: service);
      await openForm(tester);

      await tapKey(tester, 'predict');

      expect(service.requests, isEmpty);
      expect(find.byType(ClassificationScreen), findsOneWidget);
      expect(find.byType(ResultScreen), findsNothing);
      expect(find.text('10 fields need attention.'), findsOneWidget);
      expect(find.text('Enter an age.'), findsOneWidget);
    });

    testWidgets('validates as the user types', (tester) async {
      await pumpJealthApp(tester, size: const Size(1000, 3000));
      await openForm(tester);
      await tapKey(tester, 'predict');

      await tester.enterText(find.byKey(const ValueKey('field-age')), '0');
      await tester.pump();
      expect(find.text('Age must be a positive whole number.'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('field-age')), '25');
      await tester.pumpAndSettle();
      expect(find.text('Age must be a positive whole number.'), findsNothing);
      expect(
        find.textContaining('outside the usual range for this assessment'),
        findsOneWidget,
      );
    });

    testWidgets('numeric fields refuse letters', (tester) async {
      await pumpJealthApp(tester);
      await openForm(tester);
      await tester.enterText(find.byKey(const ValueKey('field-age')), 'abc');
      await tester.pump();
      expect(fieldText(tester, 'age'), isEmpty);
    });

    testWidgets('Reset clears the form and Undo restores it', (tester) async {
      await pumpJealthApp(tester, size: const Size(1000, 3000));
      await openForm(tester);
      await fillClassificationForm(tester);
      expect(find.text('10 of 10 fields complete'), findsOneWidget);

      await tapKey(tester, 'reset-form');
      expect(fieldText(tester, 'age'), isEmpty);
      expect(find.text('0 of 10 fields complete'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(fieldText(tester, 'age'), '68');
      expect(find.text('10 of 10 fields complete'), findsOneWidget);
    });

    testWidgets('keeps what was typed when moving between sections', (
      tester,
    ) async {
      await pumpJealthApp(tester);
      await openForm(tester);
      await tester.enterText(find.byKey(const ValueKey('field-age')), '68');
      await tester.pump();

      await tester.tap(navItem('learn'));
      await tester.pumpAndSettle();
      await tester.tap(navItem('classify'));
      await tester.pumpAndSettle();

      expect(fieldText(tester, 'age'), '68');
    });
  });

  group('assessment service unavailable', () {
    testWidgets('submitting explains that no service is connected', (
      tester,
    ) async {
      final store = InMemoryHistoryStore();
      await pumpJealthApp(
        tester,
        historyStore: store,
        size: const Size(1000, 3000),
      );
      await openForm(tester);
      expect(find.text('Assessment service unavailable'), findsOneWidget);

      await fillClassificationForm(tester);
      await tapKey(tester, 'predict');

      expect(find.byType(ResultScreen), findsOneWidget);
      expect(find.text('Assessment service unavailable'), findsOneWidget);
      expect(find.textContaining('No result was generated'), findsOneWidget);
      // No class, score or save action may appear without a real response.
      expect(find.byKey(const ValueKey('result-class-label')), findsNothing);
      expect(find.text('ASSESSMENT RESULT'), findsNothing);
      expect(find.byKey(const ValueKey('result-save')), findsNothing);
      expect(find.byKey(const ValueKey('result-retry')), findsNothing);
      // The measurements are echoed back so the user can check them.
      expect(find.text('Measurements you submitted'), findsOneWidget);
      expect(store.entries, isEmpty);
    });

    testWidgets('Home reports an unconfigured service', (tester) async {
      await pumpJealthApp(tester, size: const Size(1000, 3000));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.textContaining('not configured'), findsWidgets);
    });
  });

  group('with a scripted service (test fixture)', () {
    testWidgets('shows the returned class with neutral wording and can save', (
      tester,
    ) async {
      final store = InMemoryHistoryStore();
      final service = FakePredictionService(
        response: const PredictionResult(
          predictedClass: HeartDiseaseClass.heartDisease,
          modelScore: 0.61,
          modelVersion: 'fixture-model',
        ),
      );
      await pumpJealthApp(
        tester,
        service: service,
        historyStore: store,
        size: const Size(1000, 3000),
      );
      await openForm(tester);
      await fillClassificationForm(tester);
      await tapKey(tester, 'predict');

      expect(service.requests.single.toJson(), contractExampleInput.toJson());
      expect(find.text('ASSESSMENT RESULT'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('result-class-label')))
            .data,
        'Heart Disease',
      );
      expect(find.text('Model score'), findsOneWidget);
      expect(find.text('0.61'), findsOneWidget);
      expect(
        find.textContaining('not a diagnosis, a validated risk estimate'),
        findsOneWidget,
      );
      expect(find.text('fixture-model'), findsOneWidget);
      expect(find.textContaining('not a diagnosis'), findsNWidgets(2));
      expect(find.textContaining('%'), findsNothing);

      // Nothing is saved until the user asks.
      expect(store.entries, isEmpty);
      await tapKey(tester, 'result-save');
      expect(store.entries, hasLength(1));
      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('omits the score and version when the service sends none', (
      tester,
    ) async {
      await pumpJealthApp(
        tester,
        service: FakePredictionService(
          response: const PredictionResult(
            predictedClass: HeartDiseaseClass.noHeartDisease,
          ),
        ),
        size: const Size(1000, 3000),
      );
      await openForm(tester);
      await fillClassificationForm(tester);
      await tapKey(tester, 'predict');

      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('result-class-label')))
            .data,
        'No Heart Disease',
      );
      expect(find.text('Model score'), findsNothing);
      expect(find.text('Model version'), findsNothing);
    });

    testWidgets('disables Predict while a request is running', (tester) async {
      final gate = Completer<void>();
      final service = FakePredictionService(
        response: const PredictionResult(
          predictedClass: HeartDiseaseClass.noHeartDisease,
        ),
        gate: gate,
      );
      await pumpJealthApp(
        tester,
        service: service,
        size: const Size(1000, 3000),
      );
      await openForm(tester);
      await fillClassificationForm(tester);

      final predict = find.byKey(const ValueKey('predict'));
      await tester.ensureVisible(predict);
      await tester.pumpAndSettle();
      await tester.tap(predict);
      await tester.pump();

      expect(find.text('Reviewing…'), findsOneWidget);
      expect(tester.widget<FilledButton>(predict).onPressed, isNull);
      await tester.tap(predict, warnIfMissed: false);
      await tester.pump();
      expect(service.requests, hasLength(1));

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byType(ResultScreen), findsOneWidget);
      expect(service.requests, hasLength(1));
    });

    testWidgets('a failure shows a friendly message and Retry works', (
      tester,
    ) async {
      final service = FakePredictionService(
        failure: const PredictionException(PredictionFailureType.timeout),
        response: const PredictionResult(
          predictedClass: HeartDiseaseClass.noHeartDisease,
        ),
      );
      await pumpJealthApp(
        tester,
        service: service,
        size: const Size(1000, 3000),
      );
      await openForm(tester);
      await fillClassificationForm(tester);
      await tapKey(tester, 'predict');

      expect(find.text('Assessment service timed out'), findsOneWidget);
      expect(find.byKey(const ValueKey('result-class-label')), findsNothing);
      expect(find.textContaining('Exception'), findsNothing);

      service.failure = null;
      await tapKey(tester, 'result-retry');
      expect(find.byKey(const ValueKey('result-class-label')), findsOneWidget);
    });

    testWidgets('an invalid reply is discarded, not displayed', (tester) async {
      await pumpJealthApp(
        tester,
        service: FakePredictionService(
          failure: const PredictionException(
            PredictionFailureType.invalidResponse,
            detail: '"predicted_class" must be 0 or 1',
          ),
        ),
        size: const Size(1000, 3000),
      );
      await openForm(tester);
      await fillClassificationForm(tester);
      await tapKey(tester, 'predict');

      expect(
        find.text('Assessment service returned an unexpected result'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('result-class-label')), findsNothing);
    });

    testWidgets('"Start another assessment" returns to an empty form', (
      tester,
    ) async {
      await pumpJealthApp(
        tester,
        service: FakePredictionService(
          response: const PredictionResult(
            predictedClass: HeartDiseaseClass.noHeartDisease,
          ),
        ),
        size: const Size(1000, 3000),
      );
      await openForm(tester);
      await fillClassificationForm(tester);
      await tapKey(tester, 'predict');
      await tapKey(tester, 'result-classify-another');

      expect(find.byType(ClassificationScreen), findsOneWidget);
      expect(fieldText(tester, 'age'), isEmpty);
    });

    testWidgets('sharing needs a confirmation and hides measurements by '
        'default', (tester) async {
      final share = RecordingShareService();
      await pumpJealthApp(
        tester,
        service: FakePredictionService(
          response: const PredictionResult(
            predictedClass: HeartDiseaseClass.heartDisease,
          ),
        ),
        shareService: share,
        size: const Size(1000, 3000),
      );
      await openForm(tester);
      await fillClassificationForm(tester);
      await tapKey(tester, 'predict');

      await tapKey(tester, 'result-share');
      expect(share.shared, isEmpty, reason: 'opening the sheet shares nothing');
      expect(find.text('Include patient measurements'), findsOneWidget);

      await tapKey(tester, 'share-confirm');
      expect(share.shared, hasLength(1));
      expect(share.shared.single, contains('Assessment result: Heart Disease'));
      expect(share.shared.single, isNot(contains('Cholesterol')));

      await tapKey(tester, 'result-share');
      final measurementsToggle = find.byKey(
        const ValueKey('share-include-measurements'),
      );
      expect(tester.widget<SwitchListTile>(measurementsToggle).value, isFalse);
      await tester.tap(measurementsToggle);
      await tester.pumpAndSettle();
      expect(share.shared, hasLength(1), reason: 'previewing shares nothing');
      await tapKey(tester, 'share-confirm');
      expect(share.shared, hasLength(2));
      expect(share.shared.last, contains('Cholesterol: 191'));
    });
  });
}
