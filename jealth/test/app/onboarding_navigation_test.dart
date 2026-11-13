import 'package:flutter_test/flutter_test.dart';
import 'package:jealth/app/routes.dart';
import 'package:jealth/app/router.dart';
import 'package:jealth/core/storage/key_value_store.dart';
import 'package:jealth/features/analytics/screens/analytics_screen.dart';
import 'package:jealth/features/classification/screens/classification_screen.dart';
import 'package:jealth/features/history/screens/history_screen.dart';
import 'package:jealth/features/home/screens/home_screen.dart';
import 'package:jealth/features/learn/screens/learn_screen.dart';
import 'package:jealth/features/onboarding/screens/onboarding_screen.dart';
import 'package:jealth/features/settings/screens/about_screen.dart';
import 'package:jealth/features/settings/screens/model_info_screen.dart';
import 'package:jealth/features/settings/screens/privacy_screen.dart';
import 'package:jealth/features/settings/screens/settings_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fixtures.dart';

Finder navItem(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is NavigationBar || w is NavigationRail),
  matching: find.byKey(ValueKey('navigation-$label')),
);

void main() {
  group('onboarding', () {
    testWidgets('first launch walks through three pages, then opens Home', (
      tester,
    ) async {
      final prefs = InMemoryKeyValueStore(isPersistent: true);
      await pumpJealthApp(tester, prefs: prefs);

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text("Welcome to J'ealth"), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.bySemanticsLabel('Page 1 of 3'), findsOneWidget);

      await tapKey(tester, 'onboarding-next');
      expect(find.text('Enter health measurements'), findsOneWidget);

      await tapKey(tester, 'onboarding-next');
      expect(find.text('Results are experimental'), findsOneWidget);
      expect(find.byKey(const ValueKey('onboarding-next')), findsNothing);

      await tapKey(tester, 'onboarding-get-started');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(prefs.getBool(PrefKeys.onboardingComplete), isTrue);
    });

    testWidgets('Skip also completes onboarding', (tester) async {
      final prefs = InMemoryKeyValueStore(isPersistent: true);
      await pumpJealthApp(tester, prefs: prefs);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(prefs.getBool(PrefKeys.onboardingComplete), isTrue);
    });

    testWidgets('is not shown again on the next launch', (tester) async {
      final prefs = InMemoryKeyValueStore(isPersistent: true);
      await pumpJealthApp(tester, prefs: prefs);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // "Restart": a fresh app instance over the same stored preferences.
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpJealthApp(tester, prefs: prefs);

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('can be replayed from Settings and returns there', (
      tester,
    ) async {
      await pumpJealthApp(tester);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'settings-replay-onboarding');

      expect(find.byType(OnboardingScreen), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('bottom navigation switches between the five sections', (
      tester,
    ) async {
      await pumpJealthApp(tester);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);

      await tester.tap(navItem('classify'));
      await tester.pumpAndSettle();
      expect(find.byType(ClassificationScreen), findsOneWidget);

      await tester.tap(navItem('history'));
      await tester.pumpAndSettle();
      expect(find.byType(HistoryScreen), findsOneWidget);

      await tester.tap(navItem('analytics'));
      await tester.pumpAndSettle();
      expect(find.byType(AnalyticsScreen), findsOneWidget);

      await tester.tap(navItem('learn'));
      await tester.pumpAndSettle();
      expect(find.byType(LearnScreen), findsOneWidget);

      await tester.tap(navItem('home'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('wide screens use a navigation rail instead', (tester) async {
      await pumpJealthApp(tester, size: desktopSize);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await tester.tap(navItem('analytics'));
      await tester.pumpAndSettle();
      expect(find.byType(AnalyticsScreen), findsOneWidget);
    });

    testWidgets('"Start Classification" on Home opens the form', (
      tester,
    ) async {
      await pumpJealthApp(tester);
      await tapKey(tester, 'home-start-classification');
      expect(find.byType(ClassificationScreen), findsOneWidget);
    });

    testWidgets('Settings opens from the app bar and leads to its pages', (
      tester,
    ) async {
      await pumpJealthApp(tester);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('1.0.0 (build 1)'), findsOneWidget);

      await tapKey(tester, 'settings-privacy');
      expect(find.byType(PrivacyScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      await tapKey(tester, 'settings-model-info');
      expect(find.byType(ModelInfoScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      await tapKey(tester, 'settings-about');
      expect(find.byType(AboutScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('the licences page opens', (tester) async {
      await pumpJealthApp(tester);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'settings-licenses');
      expect(find.byType(LicensePage), findsOneWidget);
    });

    testWidgets('an unknown address shows a friendly not-found page', (
      tester,
    ) async {
      final container = await pumpJealthApp(tester);
      container.read(routerProvider).go('/no/such/page');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.textContaining('Exception'), findsNothing);
    });

    testWidgets('a deep link to an unknown history record explains itself', (
      tester,
    ) async {
      final container = await pumpJealthApp(tester);
      container.read(routerProvider).go(AppRoutes.historyDetail('missing'));
      await tester.pumpAndSettle();
      expect(find.text('Record not found'), findsOneWidget);
    });
  });

  group('theme switching', () {
    ThemeMode? appThemeMode(WidgetTester tester) =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode;
    Brightness brightness(WidgetTester tester) =>
        Theme.of(tester.element(find.byType(SettingsScreen))).brightness;

    testWidgets('follows the system by default and can be changed', (
      tester,
    ) async {
      final prefs = await onboardedPrefs();
      await pumpJealthApp(tester, prefs: prefs);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(appThemeMode(tester), ThemeMode.system);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(appThemeMode(tester), ThemeMode.dark);
      expect(brightness(tester), Brightness.dark);
      expect(prefs.getString(PrefKeys.themeMode), 'dark');

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(appThemeMode(tester), ThemeMode.light);
      expect(brightness(tester), Brightness.light);
      expect(prefs.getString(PrefKeys.themeMode), 'light');
    });

    testWidgets('the chosen theme is restored on the next launch', (
      tester,
    ) async {
      final prefs = await onboardedPrefs();
      await prefs.setString(PrefKeys.themeMode, 'dark');
      await pumpJealthApp(tester, prefs: prefs);
      expect(appThemeMode(tester), ThemeMode.dark);
      expect(
        Theme.of(tester.element(find.byType(HomeScreen))).brightness,
        Brightness.dark,
      );
    });
  });
}
