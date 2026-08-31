import 'dart:convert';

import 'package:cryptography/cryptography.dart';

final class HarborAppLockedException implements Exception {
  const HarborAppLockedException();

  @override
  String toString() => 'Harbor is locked.';
}

final class HarborAppLockPassphraseException implements Exception {
  const HarborAppLockPassphraseException();

  @override
  String toString() => 'The Harbor passphrase did not unlock this vault.';
}

final class HarborAppLockCorruptException implements Exception {
  const HarborAppLockCorruptException();

  @override
  String toString() => 'The Harbor app-lock record is invalid.';
}

final class UnsupportedHarborAppLockVersionException implements Exception {
  const UnsupportedHarborAppLockVersionException(this.version);

  final int version;

  @override
  String toString() => 'Unsupported Harbor app-lock version: $version';
}

final class HarborAppLockPassphrasePolicyException implements Exception {
  const HarborAppLockPassphrasePolicyException(this.reason);

  final String reason;

  @override
  String toString() => reason;
}

/// Wraps the vault key with a passphrase-derived key. The passphrase itself and
/// a separate password verifier are never persisted.
final class HarborAppLockCodec {
  HarborAppLockCodec({AesGcm? cipher, this.iterations = productionIterations})
    : _cipher = cipher ?? AesGcm.with256bits();

  static const productionIterations = 600000;
  static const minimumPassphraseCharacters = 12;
  static const maximumPassphraseCharacters = 128;
  static const _version = 1;
  static const _kdf = 'PBKDF2-HMAC-SHA256';
  static const _cipherName = 'AES-256-GCM';
  static const _associatedData = 'harbor-app-lock-envelope-v1';

  final AesGcm _cipher;
  final int iterations;

  static void validateNewPassphrase(String passphrase) {
    final length = passphrase.runes.length;
    if (length < minimumPassphraseCharacters) {
      throw const HarborAppLockPassphrasePolicyException(
        'Use at least 12 characters. A short phrase is easier to remember than a complicated code.',
      );
    }
    if (length > maximumPassphraseCharacters) {
      throw const HarborAppLockPassphrasePolicyException(
        'Use no more than 128 characters.',
      );
    }
    if (passphrase.trim().isEmpty) {
      throw const HarborAppLockPassphrasePolicyException(
        'The passphrase must include something other than spaces.',
      );
    }
  }

  Future<String> wrapKey({
    required SecretKey vaultKey,
    required String passphrase,
  }) async {
    validateNewPassphrase(passphrase);
    if (iterations != productionIterations) {
      // Lower work factors are supported only by explicitly constructed test
      // codecs. Production Harbor always uses the governed value above.
      assert(iterations > 0);
    }
    final saltKey = SecretKeyData.random(length: 16);
    final salt = List<int>.from(saltKey.bytes);
    saltKey.destroy();
    final wrappingKey = await _deriveKey(passphrase, salt);
    try {
      final box = await _cipher.encrypt(
        await vaultKey.extractBytes(),
        secretKey: wrappingKey,
        aad: _aad(iterations, salt),
      );
      return jsonEncode({
        'version': _version,
        'kdf': _kdf,
        'iterations': iterations,
        'salt': base64Encode(salt),
        'cipher': _cipherName,
        'nonce': base64Encode(box.nonce),
        'cipherText': base64Encode(box.cipherText),
        'mac': base64Encode(box.mac.bytes),
      });
    } finally {
      _destroy(wrappingKey);
    }
  }

  Future<SecretKey> unwrapKey({
    required String encoded,
    required String passphrase,
  }) async {
    final envelope = _parse(encoded);
    final salt = envelope.salt;
    final wrappingKey = await _deriveKey(passphrase, salt);
    try {
      final clear = await _cipher.decrypt(
        SecretBox(
          envelope.cipherText,
          nonce: envelope.nonce,
          mac: Mac(envelope.mac),
        ),
        secretKey: wrappingKey,
        aad: _aad(envelope.iterations, salt),
      );
      if (clear.length != 32) {
        throw const HarborAppLockCorruptException();
      }
      return SecretKeyData(
        clear,
        overwriteWhenDestroyed: true,
        debugLabel: 'Harbor unlocked vault key',
      );
    } on HarborAppLockCorruptException {
      rethrow;
    } on SecretBoxAuthenticationError {
      throw const HarborAppLockPassphraseException();
    } catch (_) {
      // Authentication failure and ciphertext corruption are deliberately not
      // distinguished at the unlock boundary.
      throw const HarborAppLockPassphraseException();
    } finally {
      _destroy(wrappingKey);
    }
  }

  Future<SecretKey> _deriveKey(String passphrase, List<int> salt) => Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: 256,
  ).deriveKeyFromPassword(password: passphrase, nonce: salt);

  _ParsedAppLockEnvelope _parse(String encoded) {
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) throw const HarborAppLockCorruptException();
      final source = Map<String, Object?>.from(decoded);
      final version = source['version'];
      if (version is int && version != _version) {
        throw UnsupportedHarborAppLockVersionException(version);
      }
      if (version != _version ||
          source['kdf'] != _kdf ||
          source['cipher'] != _cipherName ||
          source['iterations'] != iterations) {
        // Version 1 has one governed work factor. Rejecting a lower value also
        // prevents a modified record from silently weakening derivation.
        throw const HarborAppLockCorruptException();
      }
      final salt = base64Decode(source['salt'] as String);
      final nonce = base64Decode(source['nonce'] as String);
      final cipherText = base64Decode(source['cipherText'] as String);
      final mac = base64Decode(source['mac'] as String);
      if (salt.length != 16 ||
          nonce.length != 12 ||
          cipherText.length != 32 ||
          mac.length != 16) {
        throw const HarborAppLockCorruptException();
      }
      return _ParsedAppLockEnvelope(
        iterations: iterations,
        salt: salt,
        nonce: nonce,
        cipherText: cipherText,
        mac: mac,
      );
    } on UnsupportedHarborAppLockVersionException {
      rethrow;
    } on HarborAppLockCorruptException {
      rethrow;
    } catch (_) {
      throw const HarborAppLockCorruptException();
    }
  }

  static List<int> _aad(int iterations, List<int> salt) =>
      utf8.encode('$_associatedData|$_kdf|$iterations|${base64Encode(salt)}');

  static void _destroy(SecretKey key) {
    if (key case final SecretKeyData data) data.destroy();
  }
}

final class _ParsedAppLockEnvelope {
  const _ParsedAppLockEnvelope({
    required this.iterations,
    required this.salt,
    required this.nonce,
    required this.cipherText,
    required this.mac,
  });

  final int iterations;
  final List<int> salt;
  final List<int> nonce;
  final List<int> cipherText;
  final List<int> mac;
}
