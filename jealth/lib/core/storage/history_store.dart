import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../errors/app_exceptions.dart';

/// Raw, device-local persistence for saved classification records.
///
/// Each record is stored as one JSON string under its own identifier so a
/// single damaged entry can never make the rest of the history unreadable.
abstract interface class HistoryStore {
  /// Returns every stored record as `id -> JSON`.
  Future<Map<String, String>> readAll();

  Future<void> write(String id, String json);

  Future<void> delete(String id);

  /// Removes every record written by this application.
  Future<void> deleteAll();
}

/// [HistoryStore] backed by the operating system's protected storage:
/// Android Keystore-encrypted storage, the iOS Keychain, AES-encrypted files
/// keyed through Windows Credential Manager, and (on the web)
/// WebCrypto-encrypted browser storage.
class SecureHistoryStore implements HistoryStore {
  SecureHistoryStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const String keyPrefix = 'jealth.history.';

  final FlutterSecureStorage _storage;

  @override
  Future<Map<String, String>> readAll() => _guard(
    "Saved classifications couldn't be read from this device.",
    () async {
      final all = await _storage.readAll();
      return {
        for (final entry in all.entries)
          if (entry.key.startsWith(keyPrefix))
            entry.key.substring(keyPrefix.length): entry.value,
      };
    },
  );

  @override
  Future<void> write(String id, String json) => _guard(
    "The classification couldn't be saved on this device.",
    () => _storage.write(key: '$keyPrefix$id', value: json),
  );

  @override
  Future<void> delete(String id) => _guard(
    "The record couldn't be deleted from this device.",
    () => _storage.delete(key: '$keyPrefix$id'),
  );

  @override
  Future<void> deleteAll() => _guard(
    "Saved classifications couldn't be deleted from this device.",
    () async {
      final all = await _storage.readAll();
      for (final key in all.keys) {
        if (key.startsWith(keyPrefix)) await _storage.delete(key: key);
      }
    },
  );

  Future<T> _guard<T>(String message, Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      // Technical details stay in the debug console; users get [message].
      debugPrint('SecureHistoryStore failure: $error');
      throw StorageException(message);
    }
  }
}

/// Plain-language description of how saved records are protected on the
/// current platform. Shown on the Privacy screen and in History.
String historyStorageDescription() {
  if (kIsWeb) {
    return 'In this browser, saved records are encrypted and kept in the '
        "browser's local storage for this site. The encryption key is kept in "
        'the same browser, so anyone with access to this browser profile '
        'could read them. Avoid saving records on shared computers, and use '
        '"Clear classification history" when you are done.';
  }
  return switch (defaultTargetPlatform) {
    TargetPlatform.android =>
      'On Android, saved records are encrypted with a key held in the Android '
          'Keystore and are excluded from cloud backup and device transfer.',
    TargetPlatform.iOS =>
      'On iOS, saved records are kept in the system Keychain, which is '
          'encrypted by the operating system.',
    TargetPlatform.windows =>
      'On Windows, saved records are encrypted with a key kept in Windows '
          'Credential Manager for your Windows user account.',
    _ =>
      "Saved records are kept in this device's protected application storage.",
  };
}
