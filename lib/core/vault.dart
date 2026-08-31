import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_lock.dart';
import 'models.dart';

final class UnsupportedHarborVaultVersionException implements Exception {
  const UnsupportedHarborVaultVersionException(this.version);

  final int version;

  @override
  String toString() => 'Unsupported Harbor vault version: $version';
}

final class HarborVaultKeyMissingException implements Exception {
  const HarborVaultKeyMissingException();

  @override
  String toString() => 'The Harbor vault key is missing.';
}

final class HarborVaultCorruptException implements Exception {
  const HarborVaultCorruptException();

  @override
  String toString() => 'The Harbor vault could not be authenticated.';
}

final class HarborVaultMigrationException implements Exception {
  const HarborVaultMigrationException();

  @override
  String toString() => 'The Harbor vault migration did not commit safely.';
}

abstract interface class ValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

final class PreferencesValueStore implements ValueStore {
  @override
  Future<String?> read(String key) async =>
      (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> write(String key, String value) async {
    final saved = await (await SharedPreferences.getInstance()).setString(
      key,
      value,
    );
    if (!saved) throw StateError('Harbor could not persist local data.');
  }

  @override
  Future<void> delete(String key) async {
    final removed = await (await SharedPreferences.getInstance()).remove(key);
    if (!removed && await read(key) != null) {
      throw StateError('Harbor could not erase local data.');
    }
  }
}

final class SecureValueStore implements ValueStore {
  const SecureValueStore([this.storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage storage;

  @override
  Future<String?> read(String key) => storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => storage.delete(key: key);
}

final class HarborVault {
  HarborVault({
    ValueStore? records,
    ValueStore? keys,
    AesGcm? cipher,
    HarborAppLockCodec? appLockCodec,
  }) : _records = records ?? PreferencesValueStore(),
       _keys = keys ?? const SecureValueStore(),
       _cipher = cipher ?? AesGcm.with256bits(),
       _appLockCodec = appLockCodec ?? HarborAppLockCodec();

  static const recordKey = 'harbor.encrypted.records.v1';
  static const migrationRecordKey = 'harbor.encrypted.records.migration.v1';
  static const encryptionKey = 'harbor.encryption.key.v1';
  static const appLockKey = 'harbor.app-lock.v1';
  static const appLockStagingKey = 'harbor.app-lock.staging.v1';
  static const associatedData = 'harbor-vault-schema-1';

  final ValueStore _records;
  final ValueStore _keys;
  final AesGcm _cipher;
  final HarborAppLockCodec _appLockCodec;
  SecretKey? _unlockedSessionKey;

  bool get hasUnlockedAppLock => _unlockedSessionKey != null;

  Future<bool> appLockEnabled() async =>
      await _records.read(appLockKey) != null;

  Future<SecretKey> _loadExistingKey() async {
    if (await appLockEnabled()) {
      final sessionKey = _unlockedSessionKey;
      if (sessionKey == null) throw const HarborAppLockedException();
      return sessionKey;
    }
    final encoded = await _keys.read(encryptionKey);
    if (encoded == null) throw const HarborVaultKeyMissingException();
    try {
      final bytes = base64Decode(encoded);
      if (bytes.length != 32) throw const HarborVaultCorruptException();
      return SecretKey(bytes);
    } on HarborVaultCorruptException {
      rethrow;
    } catch (_) {
      throw const HarborVaultCorruptException();
    }
  }

  Future<SecretKey> _loadOrCreateKey() async {
    if (await appLockEnabled()) return _loadExistingKey();
    final encoded = await _keys.read(encryptionKey);
    if (encoded != null) {
      return _loadExistingKey();
    }

    final key = await _cipher.newSecretKey();
    final bytes = await key.extractBytes();
    if (bytes.length != 32) {
      throw StateError('Harbor generated an invalid encryption key.');
    }
    await _keys.write(encryptionKey, base64Encode(bytes));
    return key;
  }

  Future<HarborData> load() async {
    final encoded = await _records.read(recordKey);
    if (encoded == null) {
      if (await _records.read(migrationRecordKey) != null) {
        throw const HarborVaultMigrationException();
      }
      return const HarborData();
    }

    final key = await _loadExistingKey();
    final document = await _decryptEnvelope(encoded, key);
    if (document.wasMigrated) {
      await _commitMigration(document.data, key);
    } else if (await _records.read(migrationRecordKey) != null) {
      try {
        await _records.delete(migrationRecordKey);
      } catch (_) {
        throw const HarborVaultMigrationException();
      }
    }
    return document.data;
  }

  Future<void> save(HarborData data) async {
    if (data.schemaVersion != HarborData.currentSchemaVersion) {
      throw UnsupportedHarborDataVersionException(data.schemaVersion);
    }
    final key = await _loadOrCreateKey();
    final encoded = await _encryptEnvelope(data, key);
    await _writeAndVerify(recordKey, encoded, data, key);
    if (await _records.read(migrationRecordKey) != null) {
      await _records.delete(migrationRecordKey);
    }
  }

  Future<void> enableAppLock(String passphrase) async {
    if (await appLockEnabled()) {
      throw StateError('Harbor app lock is already enabled.');
    }
    final vaultKey = await _loadOrCreateKey();
    final wrapped = await _appLockCodec.wrapKey(
      vaultKey: vaultKey,
      passphrase: passphrase,
    );
    try {
      await _writeAndVerifyWrappedKey(appLockStagingKey, wrapped, passphrase);
      await _writeAndVerifyWrappedKey(appLockKey, wrapped, passphrase);
      _unlockedSessionKey = vaultKey;
      await _keys.delete(encryptionKey);
      if (await _keys.read(encryptionKey) != null) {
        throw StateError('Harbor could not remove the unlocked vault key.');
      }
      await _bestEffortDelete(_records, appLockStagingKey);
    } catch (_) {
      final rawKeyStillExists = await _keys.read(encryptionKey) != null;
      if (rawKeyStillExists) {
        await _bestEffortDelete(_records, appLockKey);
        await _bestEffortDelete(_records, appLockStagingKey);
        _unlockedSessionKey = null;
        rethrow;
      }
      if (await _records.read(appLockKey) != null) {
        await _bestEffortDelete(_records, appLockStagingKey);
        return;
      }
      rethrow;
    }
  }

  Future<void> unlockAppLock(String passphrase) async {
    final encoded = await _records.read(appLockKey);
    if (encoded == null) {
      throw StateError('Harbor app lock is not enabled.');
    }
    final key = await _appLockCodec.unwrapKey(
      encoded: encoded,
      passphrase: passphrase,
    );
    try {
      if (await _keys.read(encryptionKey) != null) {
        await _keys.delete(encryptionKey);
        if (await _keys.read(encryptionKey) != null) {
          throw StateError('Harbor could not remove an unlocked key copy.');
        }
      }
      _destroyKey(_unlockedSessionKey);
      _unlockedSessionKey = key;
      await _bestEffortDelete(_records, appLockStagingKey);
    } catch (_) {
      _destroyKey(key);
      rethrow;
    }
  }

  Future<void> changeAppLockPassphrase({
    required String currentPassphrase,
    required String newPassphrase,
  }) async {
    final original = await _records.read(appLockKey);
    if (original == null) {
      throw StateError('Harbor app lock is not enabled.');
    }
    final key = await _appLockCodec.unwrapKey(
      encoded: original,
      passphrase: currentPassphrase,
    );
    var canonicalChanged = false;
    try {
      final replacement = await _appLockCodec.wrapKey(
        vaultKey: key,
        passphrase: newPassphrase,
      );
      await _writeAndVerifyWrappedKey(
        appLockStagingKey,
        replacement,
        newPassphrase,
      );
      canonicalChanged = true;
      await _writeAndVerifyWrappedKey(appLockKey, replacement, newPassphrase);
      await _bestEffortDelete(_records, appLockStagingKey);
      _destroyKey(_unlockedSessionKey);
      _unlockedSessionKey = key;
    } catch (_) {
      if (canonicalChanged) {
        try {
          await _records.write(appLockKey, original);
        } catch (_) {
          // The canonical record may now require recovery. Never replace or
          // erase the encrypted personal record in response.
        }
      }
      await _bestEffortDelete(_records, appLockStagingKey);
      _destroyKey(key);
      rethrow;
    }
  }

  Future<void> disableAppLock(String currentPassphrase) async {
    final encoded = await _records.read(appLockKey);
    if (encoded == null) {
      throw StateError('Harbor app lock is not enabled.');
    }
    final key = await _appLockCodec.unwrapKey(
      encoded: encoded,
      passphrase: currentPassphrase,
    );
    try {
      final keyBytes = await key.extractBytes();
      final persistedKey = base64Encode(keyBytes);
      await _keys.write(encryptionKey, persistedKey);
      if (await _keys.read(encryptionKey) != persistedKey) {
        throw StateError('Harbor could not verify the unlocked vault key.');
      }
      await _records.delete(appLockKey);
      await _bestEffortDelete(_records, appLockStagingKey);
      _destroyKey(_unlockedSessionKey);
      _unlockedSessionKey = null;
    } catch (_) {
      final disabledSafely =
          await _records.read(appLockKey) == null &&
          await _keys.read(encryptionKey) != null;
      if (disabledSafely) {
        _destroyKey(_unlockedSessionKey);
        _unlockedSessionKey = null;
        _destroyKey(key);
        return;
      }
      _destroyKey(key);
      rethrow;
    }
    _destroyKey(key);
  }

  void lockApp() {
    _destroyKey(_unlockedSessionKey);
    _unlockedSessionKey = null;
  }

  Future<void> eraseAll() async {
    lockApp();
    await _records.delete(recordKey);
    await _records.delete(migrationRecordKey);
    await _records.delete(appLockKey);
    await _records.delete(appLockStagingKey);
    await _keys.delete(encryptionKey);
  }

  Future<void> _writeAndVerifyWrappedKey(
    String keyName,
    String encoded,
    String passphrase,
  ) async {
    await _records.write(keyName, encoded);
    final persisted = await _records.read(keyName);
    if (persisted == null) {
      throw StateError('Harbor could not verify the app lock.');
    }
    final unwrapped = await _appLockCodec.unwrapKey(
      encoded: persisted,
      passphrase: passphrase,
    );
    try {
      final expected = await _keyBytesForLockVerification();
      if (!_sameBytes(await unwrapped.extractBytes(), expected)) {
        throw StateError('Harbor could not verify the app lock.');
      }
    } finally {
      _destroyKey(unwrapped);
    }
  }

  Future<List<int>> _keyBytesForLockVerification() async {
    final session = _unlockedSessionKey;
    if (session != null) return session.extractBytes();
    final encoded = await _keys.read(encryptionKey);
    if (encoded == null) throw const HarborVaultKeyMissingException();
    try {
      final bytes = base64Decode(encoded);
      if (bytes.length != 32) throw const HarborVaultCorruptException();
      return bytes;
    } catch (_) {
      throw const HarborVaultCorruptException();
    }
  }

  static bool _sameBytes(List<int> first, List<int> second) {
    if (first.length != second.length) return false;
    var difference = 0;
    for (var index = 0; index < first.length; index++) {
      difference |= first[index] ^ second[index];
    }
    return difference == 0;
  }

  static void _destroyKey(SecretKey? key) {
    if (key case final SecretKeyData data) data.destroy();
  }

  static Future<void> _bestEffortDelete(ValueStore store, String key) async {
    try {
      await store.delete(key);
    } catch (_) {
      // A leftover staging value is ignored on startup and contains only a
      // wrapped key. The canonical lock record remains authoritative.
    }
  }

  Future<String> _encryptEnvelope(HarborData data, SecretKey key) async {
    final box = await _cipher.encrypt(
      Uint8List.fromList(utf8.encode(data.encode())),
      secretKey: key,
      aad: utf8.encode(associatedData),
    );
    return jsonEncode({
      'version': 1,
      'cipher': 'AES-256-GCM',
      'nonce': base64Encode(box.nonce),
      'cipherText': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    });
  }

  Future<HarborDataDocument> _decryptEnvelope(
    String encoded,
    SecretKey key,
  ) async {
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) throw const HarborVaultCorruptException();
      final envelope = Map<String, Object?>.from(decoded);
      final version = envelope['version'];
      if (version is int && version != 1) {
        throw UnsupportedHarborVaultVersionException(version);
      }
      if (version != 1 || envelope['cipher'] != 'AES-256-GCM') {
        throw const HarborVaultCorruptException();
      }
      final box = SecretBox(
        base64Decode(envelope['cipherText'] as String),
        nonce: base64Decode(envelope['nonce'] as String),
        mac: Mac(base64Decode(envelope['mac'] as String)),
      );
      final clear = await _cipher.decrypt(
        box,
        secretKey: key,
        aad: utf8.encode(associatedData),
      );
      return HarborData.decodeDocument(utf8.decode(clear));
    } on UnsupportedHarborVaultVersionException {
      rethrow;
    } on UnsupportedHarborDataVersionException {
      rethrow;
    } on HarborVaultCorruptException {
      rethrow;
    } catch (_) {
      throw const HarborVaultCorruptException();
    }
  }

  Future<void> _writeAndVerify(
    String keyName,
    String encoded,
    HarborData expected,
    SecretKey key,
  ) async {
    await _records.write(keyName, encoded);
    final persisted = await _records.read(keyName);
    if (persisted == null) {
      throw StateError('Harbor could not verify local data.');
    }
    final verified = await _decryptEnvelope(persisted, key);
    if (verified.wasMigrated || verified.data.encode() != expected.encode()) {
      throw StateError('Harbor could not verify local data.');
    }
  }

  Future<void> _commitMigration(HarborData data, SecretKey key) async {
    try {
      final staged = await _encryptEnvelope(data, key);
      await _writeAndVerify(migrationRecordKey, staged, data, key);
      await _writeAndVerify(recordKey, staged, data, key);
      await _records.delete(migrationRecordKey);
    } on UnsupportedHarborDataVersionException {
      rethrow;
    } catch (_) {
      throw const HarborVaultMigrationException();
    }
  }
}

final class MemoryValueStore implements ValueStore {
  MemoryValueStore([Map<String, String>? seed]) : values = {...?seed};

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
