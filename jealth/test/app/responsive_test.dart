import 'package:flutter_test/flutter_test.dart';
import 'package:jealth/app/routes.dart';
import 'package:jealth/app/router.dart';
import 'package:jealth/core/storage/key_value_store.dart';
import 'package:jealth/features/classification/models/prediction_result.dart';
import 'package:jealth/features/classification/providers/prediction_controller.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fixtures.dart';

/// Layout problems such as RenderFlex overflows are reported as test
/// failures by the framework, so visiting a screen is itself the assertion.
void main() {
  const sizes = <String, Size>{
    'small phone 320x568': Size(320, 568),
    'phone 390x844': Size(390, 844),
    'phone landscape 844x390': Size(844, 390),
    'tablet 768x1024': Size(768, 1024),
    'desktop 1280x800': Size(1280, 800),
    'wide desktop 1920x1080': Size(1920, 1080),
  };

  const routes = <String>[
    AppRoutes.home,
    AppRoutes.classify,
    AppRoutes.history,
    AppRoutes.analytics,
    AppRoutes.learn,
    AppRoutes.settings,
    AppRoutes.privacy,
    AppRoutes.about,
    AppRoutes.modelInfo,
  ];

  Future<void> visitEverything(WidgetTester tester, Size size) async {
    final store = InMemoryHistoryStore({
      'rec-a': fixtureRecord(
        id: 'rec-a',
        modelScore: 0.61,
        modelVersion: 'fixture-model',
      ).encode(),
    });
    final container = await pumpJealthApp(
      tester,
      historyStore: store,
      service: FakePredictionService(
        response: const PredictionResult(
          predictedClass: HeartDiseaseClass.heartDisease,
          modelScore: 0.61,
          modelVersion: 'fixture-model',
        ),
      ),
      size: size,
    );
    final router = container.read(routerProvider);

    for (final route in routes) {
      router.go(route);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$route at $size');
    }

    // Result screen: idle, then a (fixture) success.
    router.go(AppRoutes.result);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'result (idle) at $size');
    await container
        .read(predictionControllerProvider.notifier)
        .submit(contractExampleInput);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'result at $size');

    router.go(AppRoutes.historyDetail('rec-a'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'detail at $size');
  }

  for (final entry in sizes.entries) {
    testWidgets('every screen lays out without overflow: ${entry.key}', (
      tester,
    ) async {
      await visitEverything(tester, entry.value);
    });
  }

  testWidgets('every screen survives 2x text on a small phone', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await visitEverything(tester, const Size(320, 568));
  });

  testWidgets('every screen lays out in dark mode', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await visitEverything(tester, const Size(390, 844));
  });

  for (final entry in {
    'phone': const Size(390, 844),
    'small phone, 2x text': const Size(320, 568),
    'desktop': const Size(1280, 800),
  }.entries) {
    testWidgets('onboarding lays out on ${entry.key}', (tester) async {
      if (entry.key.contains('2x')) {
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      }
      await pumpJealthApp(
        tester,
        prefs: InMemoryKeyValueStore(isPersistent: true),
        size: entry.value,
      );
      expect(find.text("Welcome to J'ealth"), findsOneWidget);
      await tapKey(tester, 'onboarding-next');
      await tapKey(tester, 'onboarding-next');
      expect(
        find.byKey(const ValueKey('onboarding-get-started')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('navigation adapts to the window width', (tester) async {
    await pumpJealthApp(tester, size: const Size(390, 844));
    expect(find.byType(NavigationBar), findsOneWidget);

    tester.view.physicalSize = const Size(1000, 800);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isFalse,
    );

    tester.view.physicalSize = const Size(1400, 800);
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
      isTrue,
    );
  });
}
