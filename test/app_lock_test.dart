import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor_app/core/app_lock.dart';

void main() {
  group('HarborAppLockCodec', () {
    test('new passphrases follow the governed length policy', () {
      expect(
        () => HarborAppLockCodec.validateNewPassphrase('too short'),
        throwsA(isA<HarborAppLockPassphrasePolicyException>()),
      );
      expect(
        () => HarborAppLockCodec.validateNewPassphrase('            '),
        throwsA(isA<HarborAppLockPassphrasePolicyException>()),
      );
      expect(
        () => HarborAppLockCodec.validateNewPassphrase('steady harbor light'),
        returnsNormally,
      );
      expect(
        () =>
            HarborAppLockCodec.validateNewPassphrase('🌊 safe quiet harbor 🌊'),
        returnsNormally,
      );
      expect(
        () => HarborAppLockCodec.validateNewPassphrase(
          List<String>.filled(129, 'x').join(),
        ),
        throwsA(isA<HarborAppLockPassphrasePolicyException>()),
      );
    });

    test('production envelope uses the governed KDF and stores no passphrase or raw key', () async {
      final codec = HarborAppLockCodec();
      final keyBytes = List<int>.generate(32, (index) => index + 3);
      const passphrase = 'violet harbor morning';

      final encoded = await codec.wrapKey(
        vaultKey: SecretKey(keyBytes),
        passphrase: passphrase,
      );
      final envelope = Map<String, Object?>.from(jsonDecode(encoded) as Map);

      expect(envelope['version'], 1);
      expect(envelope['kdf'], 'PBKDF2-HMAC-SHA256');
      expect(envelope['iterations'], HarborAppLockCodec.productionIterations);
      expect(envelope['cipher'], 'AES-256-GCM');
      expect(encoded, isNot(contains(passphrase)));
      expect(encoded, isNot(contains(base64Encode(keyBytes))));
      expect(
        await (await codec.unwrapKey(
          encoded: encoded,
          passphrase: passphrase,
        )).extractBytes(),
        keyBytes,
      );
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('wrong passphrase and tampering never return a vault key', () async {
      final codec = HarborAppLockCodec(iterations: 1000);
      final encoded = await codec.wrapKey(
        vaultKey: SecretKey(List<int>.generate(32, (index) => index)),
        passphrase: 'correct horse harbor',
      );

      await expectLater(
        codec.unwrapKey(encoded: encoded, passphrase: 'incorrect horse harbor'),
        throwsA(isA<HarborAppLockPassphraseException>()),
      );

      final tampered = Map<String, Object?>.from(jsonDecode(encoded) as Map);
      final cipherText = base64Decode(tampered['cipherText'] as String);
      cipherText[0] ^= 1;
      tampered['cipherText'] = base64Encode(cipherText);
      await expectLater(
        codec.unwrapKey(
          encoded: jsonEncode(tampered),
          passphrase: 'correct horse harbor',
        ),
        throwsA(isA<HarborAppLockPassphraseException>()),
      );
    });

    test('malformed, downgraded, and future envelopes fail closed', () async {
      final codec = HarborAppLockCodec(iterations: 1000);
      final encoded = await codec.wrapKey(
        vaultKey: SecretKey(List<int>.filled(32, 8)),
        passphrase: 'correct horse harbor',
      );
      final envelope = Map<String, Object?>.from(jsonDecode(encoded) as Map);

      final downgraded = {...envelope, 'iterations': 1};
      await expectLater(
        codec.unwrapKey(
          encoded: jsonEncode(downgraded),
          passphrase: 'correct horse harbor',
        ),
        throwsA(isA<HarborAppLockCorruptException>()),
      );

      final future = {...envelope, 'version': 2};
      await expectLater(
        codec.unwrapKey(
          encoded: jsonEncode(future),
          passphrase: 'correct horse harbor',
        ),
        throwsA(
          isA<UnsupportedHarborAppLockVersionException>().having(
            (error) => error.version,
            'version',
            2,
          ),
        ),
      );

      await expectLater(
        codec.unwrapKey(
          encoded: '{not-json',
          passphrase: 'correct horse harbor',
        ),
        throwsA(isA<HarborAppLockCorruptException>()),
      );
    });
  });
}
