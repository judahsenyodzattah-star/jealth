import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/storage/history_store.dart';
import '../../../core/storage/storage_providers.dart';
import '../models/history_record.dart';

/// Records read from the device, newest first.
class HistorySnapshot {
  const HistorySnapshot({required this.records, this.unreadableCount = 0});

  final List<HistoryRecord> records;

  /// Stored entries that could not be understood (damaged or written by an
  /// incompatible version). They are skipped, never shown as data.
  final int unreadableCount;

  bool get isEmpty => records.isEmpty;

  bool contains(String id) => records.any((r) => r.id == id);

  HistoryRecord? byId(String id) {
    for (final record in records) {
      if (record.id == id) return record;
    }
    return null;
  }
}

/// Reads and writes saved classification records.
class HistoryRepository {
  HistoryRepository(this._store);

  final HistoryStore _store;

  Future<HistorySnapshot> load() async {
    final raw = await _store.readAll();
    final records = <HistoryRecord>[];
    var unreadable = 0;
    for (final entry in raw.entries) {
      try {
        final record = HistoryRecord.decode(entry.value);
        if (record.id != entry.key) throw const FormatException('id mismatch');
        records.add(record);
      } on FormatException catch (error) {
        unreadable++;
        debugPrint('Skipping unreadable history record: ${error.message}');
      } catch (error) {
        unreadable++;
        debugPrint('Skipping unreadable history record.');
      }
    }
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return HistorySnapshot(records: records, unreadableCount: unreadable);
  }

  /// Saves [record]. [currentCount] is the number of records already stored.
  Future<void> save(HistoryRecord record, {required int currentCount}) async {
    if (currentCount >= AppConstants.maxHistoryRecords) {
      throw const StorageException(
        'History is full (${AppConstants.maxHistoryRecords} records). Delete '
        'older records to save new ones.',
      );
    }
    await _store.write(record.id, record.encode());
  }

  Future<void> delete(String id) => _store.delete(id);

  /// Deletes every stored record, including unreadable ones.
  Future<void> clear() => _store.deleteAll();
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(historyStoreProvider));
});
