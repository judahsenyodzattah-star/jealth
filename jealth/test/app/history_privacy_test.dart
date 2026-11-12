import 'package:flutter_test/flutter_test.dart';
import 'package:jealth/app/routes.dart';
import 'package:jealth/app/router.dart';
import 'package:jealth/features/classification/models/prediction_result.dart';
import 'package:jealth/features/history/screens/history_detail_screen.dart';
import 'package:jealth/features/history/screens/history_screen.dart';
import 'package:jealth/features/history/widgets/history_record_tile.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fixtures.dart';
import 'onboarding_navigation_test.dart' show navItem;

InMemoryHistoryStore seededStore() => InMemoryHistoryStore({
  'rec-a': fixtureRecord(
    id: 'rec-a',
    predictedClass: HeartDiseaseClass.heartDisease,
    timestamp: DateTime(2026, 3, 14, 9, 30),
  ).encode(),
  'rec-b': fixtureRecord(
    id: 'rec-b',
    predictedClass: HeartDiseaseClass.noHeartDisease,
    timestamp: DateTime(2026, 4, 2, 16, 5),
  ).encode(),
});

Future<void> openHistory(WidgetTester tester) async {
  await tester.tap(navItem('History'));
  await tester.pumpAndSettle();
}

void main() {
  const tall = Size(600, 2400);

  group('history states', () {
    testWidgets('empty state: no records and no sample data', (tester) async {
      await pumpJealthApp(tester, size: tall);
      await openHistory(tester);

      expect(find.text('No saved classifications yet'), findsOneWidget);
      expect(find.byType(HistoryRecordTile), findsNothing);
      expect(find.byKey(const ValueKey('history-clear-all')), findsNothing);
      expect(find.text('What is stored on this device?'), findsOneWidget);
    });

    testWidgets('error state: storage cannot be read', (tester) async {
      final store = InMemoryHistoryStore()..failReads = true;
      await pumpJealthApp(tester, historyStore: store, size: tall);
      await openHistory(tester);

      expect(find.text("History couldn't be loaded"), findsOneWidget);
      expect(find.textContaining('fixture: read failed'), findsNothing);

      store.failReads = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('No saved classifications yet'), findsOneWidget);
    });

    testWidgets('unreadable records are reported, not shown', (tester) async {
      final store = seededStore()..entries['bad'] = '{corrupt';
      await pumpJealthApp(tester, historyStore: store, size: tall);
      await openHistory(tester);

      expect(find.byType(HistoryRecordTile), findsNWidgets(2));
      expect(
        find.textContaining("1 saved record couldn't be read"),
        findsOneWidget,
      );
    });
  });

  group('history list', () {
    testWidgets('lists saved records newest first and can reverse', (
      tester,
    ) async {
      await pumpJealthApp(tester, historyStore: seededStore(), size: tall);
      await openHistory(tester);

      List<String> order() => tester
          .widgetList<HistoryRecordTile>(find.byType(HistoryRecordTile))
          .map((t) => t.record.id)
          .toList();

      expect(order(), ['rec-b', 'rec-a']);
      expect(find.text('2 saved classifications'), findsOneWidget);

      await tapKey(tester, 'history-sort');
      expect(order(), ['rec-a', 'rec-b']);
      expect(find.text('Oldest first'), findsOneWidget);
    });

    testWidgets('filters by class and searches', (tester) async {
      await pumpJealthApp(tester, historyStore: seededStore(), size: tall);
      await openHistory(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'No Heart Disease'));
      await tester.pumpAndSettle();
      expect(find.byType(HistoryRecordTile), findsOneWidget);
      expect(
        tester
            .widget<HistoryRecordTile>(find.byType(HistoryRecordTile))
            .record
            .id,
        'rec-b',
      );
      expect(find.text('Showing 1 of 2 saved classifications'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'All'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('history-search')),
        'no such thing',
      );
      await tester.pumpAndSettle();
      expect(find.byType(HistoryRecordTile), findsNothing);
      expect(find.text('No matching records'), findsOneWidget);

      await tester.tap(find.text('Clear search and filter'));
      await tester.pumpAndSettle();
      expect(find.byType(HistoryRecordTile), findsNWidgets(2));
    });

    testWidgets('opens the details of a record', (tester) async {
      await pumpJealthApp(tester, historyStore: seededStore(), size: tall);
      await openHistory(tester);

      await tester.tap(find.byKey(const ValueKey('history-rec-a')));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryDetailScreen), findsOneWidget);
      expect(find.text('MODEL PREDICTED CLASS'), findsOneWidget);
      expect(find.text('Submitted measurements'), findsOneWidget);
      expect(find.text('Educational use only'), findsOneWidget);
    });

    testWidgets('deleting one record asks first', (tester) async {
      final store = seededStore();
      await pumpJealthApp(tester, historyStore: store, size: tall);
      await openHistory(tester);

      final deleteButton = find.descendant(
        of: find.byKey(const ValueKey('history-rec-a')),
        matching: find.byTooltip('Delete record'),
      );

      await tester.tap(deleteButton);
      await tester.pumpAndSettle();
      expect(find.text('Delete this record?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(store.entries, hasLength(2));

      await tester.tap(deleteButton);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(store.entries.keys, ['rec-b']);
      expect(find.byType(HistoryRecordTile), findsOneWidget);
    });

    testWidgets('a failed delete is reported and keeps the record', (
      tester,
    ) async {
      final store = seededStore();
      await pumpJealthApp(tester, historyStore: store, size: tall);
      await openHistory(tester);
      store.failWrites = true;

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('history-rec-a')),
          matching: find.byTooltip('Delete record'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('fixture: delete failed'), findsOneWidget);
      expect(find.byType(HistoryRecordTile), findsNWidgets(2));
    });
  });

  group('privacy deletion', () {
    testWidgets('Clear all in History needs confirmation and removes '
        'everything', (tester) async {
      final store = seededStore()..entries['bad'] = '{corrupt';
      await pumpJealthApp(tester, historyStore: store, size: tall);
      await openHistory(tester);

      await tapKey(tester, 'history-clear-all');
      expect(find.text('Clear classification history?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(store.entries, hasLength(3));

      await tapKey(tester, 'history-clear-all');
      await tester.tap(find.widgetWithText(FilledButton, 'Delete all'));
      await tester.pumpAndSettle();

      expect(store.entries, isEmpty, reason: 'unreadable records go too');
      expect(find.text('No saved classifications yet'), findsOneWidget);
    });

    testWidgets('Settings can delete all saved health data', (tester) async {
      final store = seededStore();
      await pumpJealthApp(tester, historyStore: store, size: tall);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('2 saved records on this device'),
        findsOneWidget,
      );

      await tapKey(tester, 'settings-clear-history');
      await tester.tap(find.widgetWithText(FilledButton, 'Delete all'));
      await tester.pumpAndSettle();

      expect(store.entries, isEmpty);
      expect(
        find.text('No classifications are saved on this device.'),
        findsOneWidget,
      );
    });

    testWidgets('the Privacy page offers the same deletion', (tester) async {
      final store = seededStore();
      final container = await pumpJealthApp(
        tester,
        historyStore: store,
        size: tall,
      );
      container.read(routerProvider).push(AppRoutes.privacy);
      await tester.pumpAndSettle();
      expect(find.text('What is sent over the network'), findsOneWidget);

      await tapKey(tester, 'privacy-delete-all');
      await tester.tap(find.widgetWithText(FilledButton, 'Delete all'));
      await tester.pumpAndSettle();

      expect(store.entries, isEmpty);
      expect(find.text('No saved health data'), findsOneWidget);
    });

    testWidgets('deleting from the detail page returns to the list', (
      tester,
    ) async {
      final store = seededStore();
      final container = await pumpJealthApp(
        tester,
        historyStore: store,
        size: tall,
      );
      container.read(routerProvider).go(AppRoutes.historyDetail('rec-a'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete Record'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(store.entries.keys, ['rec-b']);
      expect(find.byType(HistoryScreen), findsOneWidget);
    });
  });
}
