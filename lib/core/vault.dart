import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  HarborVault({ValueStore? records, ValueStore? keys, AesGcm? cipher})
    : _records = records ?? PreferencesValueStore(),
      _keys = keys ?? const SecureValueStore(),
      _cipher = cipher ?? AesGcm.with256bits();

  static const recordKey = 'harbor.encrypted.records.v1';
  static const migrationRecordKey = 'harbor.encrypted.records.migration.v1';
  static const encryptionKey = 'harbor.encryption.key.v1';
  static const associatedData = 'harbor-vault-schema-1';

  final ValueStore _records;
  final ValueStore _keys;
  final AesGcm _cipher;

  Future<SecretKey> _loadExistingKey() async {
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

  Future<void> eraseAll() async {
    await _records.delete(recordKey);
    await _records.delete(migrationRecordKey);
    await _keys.delete(encryptionKey);
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
    if (persisted == null) throw StateError('Harbor could not verify local data.');
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
