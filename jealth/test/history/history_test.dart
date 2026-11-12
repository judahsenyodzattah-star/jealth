import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jealth/core/constants/app_constants.dart';
import 'package:jealth/core/errors/app_exceptions.dart';
import 'package:jealth/core/storage/storage_providers.dart';
import 'package:jealth/features/classification/models/prediction_result.dart';
import 'package:jealth/features/history/models/history_record.dart';
import 'package:jealth/features/history/providers/history_controller.dart';
import 'package:jealth/features/history/repositories/history_repository.dart';
import 'package:jealth/features/results/services/share_service.dart';

import '../support/fixtures.dart';

ClassificationOutcome fixtureOutcome(String id, {DateTime? timestamp}) =>
    ClassificationOutcome(
      id: id,
      input: contractExampleInput,
      result: const PredictionResult(
        predictedClass: HeartDiseaseClass.heartDisease,
        modelScore: 0.61,
        modelVersion: 'fixture-model',
      ),
      timestamp: timestamp ?? DateTime(2026, 3, 14, 9, 30),
    );

void main() {
  group('HistoryRecord', () {
    test('stores exactly the documented fields', () {
      final json = fixtureRecord(modelScore: 0.61, modelVersion: 'v1').toJson();
      expect(json.keys.toSet(), {
        'v',
        'id',
        'timestamp',
        'input',
        'predicted_class',
        'model_score',
        'model_version',
      });
      expect(json['input'], contractExampleInput.toJson());
    });

    test('omits optional fields the service did not supply', () {
      final json = fixtureRecord().toJson();
      expect(json.containsKey('model_score'), isFalse);
      expect(json.containsKey('model_version'), isFalse);
    });

    test('round-trips through its stored form', () {
      final original = fixtureRecord(modelScore: 0.61, modelVersion: 'v1');
      final decoded = HistoryRecord.decode(original.encode());
      expect(decoded.id, original.id);
      expect(decoded.predictedClass, original.predictedClass);
      expect(decoded.timestamp, original.timestamp);
      expect(decoded.modelScore, 0.61);
      expect(decoded.modelVersion, 'v1');
      expect(decoded.input.toJson(), original.input.toJson());
    });

    test('rejects malformed and outdated records', () {
      final good = fixtureRecord().toJson();
      final bad = <String>[
        'not json at all',
        '[]',
        jsonEncode({...good, 'v': 999}),
        jsonEncode({...good}..remove('id')),
        jsonEncode({...good, 'timestamp': 'yesterday'}),
        jsonEncode({...good, 'predicted_class': 7}),
        jsonEncode({
          ...good,
          'input': {'age': 'old'},
        }),
        jsonEncode({...good, 'model_score': 'high'}),
      ];
      for (final raw in bad) {
        expect(
          () => HistoryRecord.decode(raw),
          throwsFormatException,
          reason: raw,
        );
      }
    });
  });

  group('HistoryRepository', () {
    test('returns records newest first', () async {
      final store = InMemoryHistoryStore({
        'a': fixtureRecord(id: 'a', timestamp: DateTime(2026, 1, 1)).encode(),
        'c': fixtureRecord(id: 'c', timestamp: DateTime(2026, 3, 1)).encode(),
        'b': fixtureRecord(id: 'b', timestamp: DateTime(2026, 2, 1)).encode(),
      });
      final snapshot = await HistoryRepository(store).load();
      expect(snapshot.records.map((r) => r.id), ['c', 'b', 'a']);
      expect(snapshot.unreadableCount, 0);
    });

    test('skips unreadable records and counts them', () async {
      final store = InMemoryHistoryStore({
        'ok': fixtureRecord(id: 'ok').encode(),
        'broken': '{"v":1',
        'old': jsonEncode({'v': 0, 'id': 'old'}),
        'mismatch': fixtureRecord(id: 'other').encode(),
      });
      final snapshot = await HistoryRepository(store).load();
      expect(snapshot.records.map((r) => r.id), ['ok']);
      expect(snapshot.unreadableCount, 3);
    });

    test('refuses to save beyond the record limit', () {
      final repository = HistoryRepository(InMemoryHistoryStore());
      expect(
        repository.save(
          fixtureRecord(),
          currentCount: AppConstants.maxHistoryRecords,
        ),
        throwsA(isA<StorageException>()),
      );
    });
  });

  group('HistoryController', () {
    late InMemoryHistoryStore store;
    late ProviderContainer container;
    HistoryController controller() =>
        container.read(historyControllerProvider.notifier);
    Future<HistorySnapshot> snapshot() =>
        container.read(historyControllerProvider.future);

    setUp(() {
      store = InMemoryHistoryStore();
      container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [historyStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
    });

    test('starts empty: no records are fabricated', () async {
      expect((await snapshot()).records, isEmpty);
      expect(store.entries, isEmpty);
    });

    test('saves a result once', () async {
      expect(await controller().save(fixtureOutcome('r1')), isTrue);
      expect(await controller().save(fixtureOutcome('r1')), isFalse);
      expect(store.entries.keys, ['r1']);
      final record = (await snapshot()).records.single;
      expect(record.predictedClass, HeartDiseaseClass.heartDisease);
      expect(record.modelScore, 0.61);
      expect(record.modelVersion, 'fixture-model');
    });

    test('saved records survive a restart', () async {
      await controller().save(fixtureOutcome('r1'));
      final restarted = ProviderContainer(
        overrides: [historyStoreProvider.overrideWithValue(store)],
      );
      addTearDown(restarted.dispose);
      final reloaded = await restarted.read(historyControllerProvider.future);
      expect(reloaded.records.single.id, 'r1');
    });

    test('deletes a single record', () async {
      await controller().save(
        fixtureOutcome('r1', timestamp: DateTime(2026, 1, 1)),
      );
      await controller().save(
        fixtureOutcome('r2', timestamp: DateTime(2026, 1, 2)),
      );
      await controller().delete('r1');
      expect((await snapshot()).records.map((r) => r.id), ['r2']);
      expect(store.entries.keys, ['r2']);
    });

    test('clear all deletes every stored record, readable or not', () async {
      await controller().save(fixtureOutcome('r1'));
      store.entries['broken'] = 'garbage';
      await controller().reload();
      expect((await snapshot()).unreadableCount, 1);

      await controller().clearAll();

      expect(store.entries, isEmpty);
      final cleared = await snapshot();
      expect(cleared.records, isEmpty);
      expect(cleared.unreadableCount, 0);
    });

    test('a failed write is reported and leaves history unchanged', () async {
      await snapshot();
      store.failWrites = true;
      await expectLater(
        controller().save(fixtureOutcome('r1')),
        throwsA(isA<StorageException>()),
      );
      expect((await snapshot()).records, isEmpty);
    });

    test('a failed read surfaces as an error state', () async {
      store.failReads = true;
      await expectLater(snapshot(), throwsA(isA<StorageException>()));
      expect(container.read(historyControllerProvider).hasError, isTrue);
    });
  });

  group('share text', () {
    final record = fixtureRecord(modelScore: 0.61, modelVersion: 'v1');

    test('leaves measurements out unless the user opts in', () {
      final text = buildShareText(record, includeMeasurements: false);
      expect(text, contains('Model predicted class: Heart Disease'));
      expect(text, contains('not a clinical risk percentage'));
      expect(text, contains(AppConstants.resultDisclaimer));
      expect(text, isNot(contains('Cholesterol')));
      expect(text, isNot(contains('191')));
    });

    test('includes measurements when asked', () {
      final text = buildShareText(record, includeMeasurements: true);
      expect(text, contains('Age: 68 years'));
      expect(text, contains('Cholesterol: 191'));
      expect(text, contains('Family History: No'));
    });
  });
}
