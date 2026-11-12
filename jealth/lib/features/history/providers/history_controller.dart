import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/storage/key_value_store.dart';
import '../../../core/storage/storage_providers.dart';
import '../../classification/models/prediction_result.dart';
import '../models/history_record.dart';
import '../repositories/history_repository.dart';

/// Locally saved classification history.
///
/// Mutating methods throw [StorageException] when the device storage fails, so
/// callers can show an honest error instead of a success message.
class HistoryController extends AsyncNotifier<HistorySnapshot> {
  HistoryRepository get _repository => ref.read(historyRepositoryProvider);

  @override
  Future<HistorySnapshot> build() =>
      ref.watch(historyRepositoryProvider).load();

  /// Reloads from storage (used by "Try again").
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.load);
  }

  /// Saves a completed classification. Returns `false` when it was already
  /// saved.
  Future<bool> save(ClassificationOutcome outcome) async {
    final current = await _current();
    if (current.contains(outcome.id)) return false;
    final record = HistoryRecord.fromOutcome(outcome);
    await _repository.save(record, currentCount: current.records.length);
    final records = [...current.records, record]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    state = AsyncData(
      HistorySnapshot(
        records: records,
        unreadableCount: current.unreadableCount,
      ),
    );
    return true;
  }

  Future<void> delete(String id) async {
    final current = await _current();
    await _repository.delete(id);
    state = AsyncData(
      HistorySnapshot(
        records: current.records.where((r) => r.id != id).toList(),
        unreadableCount: current.unreadableCount,
      ),
    );
  }

  /// Deletes every locally saved health-related record.
  Future<void> clearAll() async {
    await _repository.clear();
    state = const AsyncData(HistorySnapshot(records: []));
  }

  Future<HistorySnapshot> _current() async {
    final value = state.value;
    if (value != null) return value;
    try {
      return await future;
    } on StorageException {
      rethrow;
    } catch (_) {
      throw const StorageException(
        "Saved classifications couldn't be read from this device.",
      );
    }
  }
}

final historyControllerProvider =
    AsyncNotifierProvider<HistoryController, HistorySnapshot>(
      HistoryController.new,
    );

/// History list ordering preference (persisted UI preference).
class HistorySortController extends Notifier<bool> {
  /// State is `true` for newest first.
  @override
  bool build() =>
      ref.watch(preferencesProvider).getBool(PrefKeys.historySortNewestFirst) ??
      true;

  Future<void> setNewestFirst(bool value) async {
    state = value;
    await ref
        .read(preferencesProvider)
        .setBool(PrefKeys.historySortNewestFirst, value);
  }
}

final historySortControllerProvider =
    NotifierProvider<HistorySortController, bool>(HistorySortController.new);
