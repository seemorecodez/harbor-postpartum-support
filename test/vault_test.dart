import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:harbor_app/core/app_lock.dart';
import 'package:harbor_app/core/models.dart';
import 'package:harbor_app/core/vault.dart';

import 'support/vault_fixtures.dart';

void main() {
  group('HarborVault', () {
    test('round-trips records without persisting plaintext', () async {
      final records = MemoryValueStore();
      final keys = MemoryValueStore();
      final vault = HarborVault(records: records, keys: keys);
      final data = HarborData(
        onboardingComplete: true,
        checkIns: [
          CheckIn(mood: 2, anxiety: 4, rest: 1, note: 'PRIVATE-SENTINEL'),
        ],
        journalEntries: [
          JournalEntry(title: 'Truth', body: 'I need help today'),
        ],
        resonatedStoryIds: const {'PRIVATE-STORY-RESONANCE'},
      );

      await vault.save(data);
      final persisted = records.values[HarborVault.recordKey]!;

      expect(data.schemaVersion, HarborData.currentSchemaVersion);
      expect(persisted, isNot(contains('PRIVATE-SENTINEL')));
      expect(persisted, isNot(contains('I need help today')));
      expect(persisted, isNot(contains('PRIVATE-STORY-RESONANCE')));
      expect((await vault.load()).checkIns.single.note, 'PRIVATE-SENTINEL');
      expect(
        (await vault.load()).journalEntries.single.body,
        'I need help today',
      );
      expect((await vault.load()).resonatedStoryIds, {
        'PRIVATE-STORY-RESONANCE',
      });
    });

    test('rejects a copied record opened with the wrong key', () async {
      final records = MemoryValueStore();
      final firstKeys = MemoryValueStore();
      await HarborVault(records: records, keys: firstKeys).save(
        HarborData(
          journalEntries: [JournalEntry(title: '', body: 'private')],
        ),
      );
      final wrongKeys = MemoryValueStore({
        HarborVault.encryptionKey: base64Encode(List<int>.filled(32, 7)),
      });

      expect(
        () => HarborVault(records: records, keys: wrongKeys).load(),
        throwsA(isA<HarborVaultCorruptException>()),
      );
    });

    test(
      'migrates encrypted version 1 data without losing any field',
      () async {
        final legacy = legacyVersion1Data();
        final originalEnvelope = await encryptedVaultEnvelope(legacy);
        final records = TestValueStore({
          HarborVault.recordKey: originalEnvelope,
        });
        final keys = seededKeyStore();
        final vault = HarborVault(records: records, keys: keys);

        final migrated = await vault.load();

        expect(migrated.schemaVersion, HarborData.currentSchemaVersion);
        expect(migrated.onboardingComplete, isTrue);
        expect(migrated.postpartumStage, '3-6 months');
        expect(migrated.checkIns.single.note, 'LEGACY-PRIVATE-CHECK-IN');
        expect(migrated.journalEntries.single.body, 'LEGACY-PRIVATE-JOURNAL');
        expect(
          migrated.clinicianQuestions.single.text,
          'LEGACY-PRIVATE-QUESTION',
        );
        expect(migrated.hardDayPlan.safePerson, 'Maya');
        expect(migrated.careLoadItems.single.task, 'LEGACY-PRIVATE-CARE-TASK');
        expect(migrated.careAskDraft.need, 'LEGACY-PRIVATE-CARE-ASK');
        expect(migrated.resonatedStoryIds, isEmpty);
        expect(records.writes, [
          HarborVault.migrationRecordKey,
          HarborVault.recordKey,
        ]);
        expect(records.values[HarborVault.migrationRecordKey], isNull);
        final persisted = records.values[HarborVault.recordKey]!;
        expect(persisted, isNot(originalEnvelope));
        expect(persisted, isNot(contains('LEGACY-PRIVATE')));

        final writesAfterMigration = records.writes.length;
        final restarted = await HarborVault(
          records: records,
          keys: keys,
        ).load();
        expect(restarted.encode(), migrated.encode());
        expect(records.writes.length, writesAfterMigration);
      },
    );

    test(
      'version 1 records missing newer fields migrate to safe defaults',
      () async {
        final legacy = legacyVersion1Data()
          ..remove('careLoadItems')
          ..remove('careAskDraft');
        final records = TestValueStore({
          HarborVault.recordKey: await encryptedVaultEnvelope(legacy),
        });

        final migrated = await HarborVault(
          records: records,
          keys: seededKeyStore(),
        ).load();

        expect(migrated.schemaVersion, HarborData.currentSchemaVersion);
        expect(migrated.careLoadItems, isEmpty);
        expect(migrated.careAskDraft.need, isEmpty);
        expect(migrated.journalEntries.single.body, 'LEGACY-PRIVATE-JOURNAL');
        expect(migrated.resonatedStoryIds, isEmpty);
      },
    );

    test(
      'migrates encrypted version 2 data with empty story resonance',
      () async {
        final records = TestValueStore({
          HarborVault.recordKey: await encryptedVaultEnvelope(
            legacyVersion2Data(),
          ),
        });

        final migrated = await HarborVault(
          records: records,
          keys: seededKeyStore(),
        ).load();

        expect(migrated.schemaVersion, HarborData.currentSchemaVersion);
        expect(migrated.resonatedStoryIds, isEmpty);
        expect(migrated.careLoadItems.single.task, 'LEGACY-PRIVATE-CARE-TASK');
        expect(records.writes, [
          HarborVault.migrationRecordKey,
          HarborVault.recordKey,
        ]);
      },
    );

    test(
      'interrupted migration keeps legacy primary and recovers on retry',
      () async {
        final originalEnvelope = await encryptedVaultEnvelope(
          legacyVersion1Data(),
        );
        final records = TestValueStore({
          HarborVault.recordKey: originalEnvelope,
        })..failOnceOnWriteKey = HarborVault.recordKey;
        final keys = seededKeyStore();
        final vault = HarborVault(records: records, keys: keys);

        await expectLater(
          vault.load(),
          throwsA(isA<HarborVaultMigrationException>()),
        );

        expect(records.values[HarborVault.recordKey], originalEnvelope);
        expect(records.values[HarborVault.migrationRecordKey], isNotNull);
        expect(
          records.values[HarborVault.migrationRecordKey],
          isNot(contains('LEGACY-PRIVATE')),
        );

        final recovered = await HarborVault(
          records: records,
          keys: keys,
        ).load();
        expect(recovered.schemaVersion, HarborData.currentSchemaVersion);
        expect(recovered.journalEntries.single.body, 'LEGACY-PRIVATE-JOURNAL');
        expect(records.values[HarborVault.migrationRecordKey], isNull);
      },
    );

    test(
      'future data schema remains untouched for a newer Harbor version',
      () async {
        final future = legacyVersion1Data()..['schemaVersion'] = 99;
        final records = TestValueStore({
          HarborVault.recordKey: await encryptedVaultEnvelope(future),
        });
        final keys = seededKeyStore();
        final originalRecords = Map<String, String>.from(records.values);
        final originalKeys = Map<String, String>.from(keys.values);

        await expectLater(
          HarborVault(records: records, keys: keys).load(),
          throwsA(
            isA<UnsupportedHarborDataVersionException>().having(
              (error) => error.version,
              'version',
              99,
            ),
          ),
        );

        expect(records.values, originalRecords);
        expect(keys.values, originalKeys);
        expect(records.writes, isEmpty);
        expect(keys.writes, isEmpty);
      },
    );

    test('future vault envelope remains untouched', () async {
      final records = TestValueStore({
        HarborVault.recordKey: await encryptedVaultEnvelope(
          legacyVersion1Data(),
          envelopeVersion: 2,
        ),
      });
      final keys = seededKeyStore();

      await expectLater(
        HarborVault(records: records, keys: keys).load(),
        throwsA(
          isA<UnsupportedHarborVaultVersionException>().having(
            (error) => error.version,
            'version',
            2,
          ),
        ),
      );
      expect(records.writes, isEmpty);
      expect(keys.writes, isEmpty);
    });

    test(
      'existing encrypted records never generate a replacement missing key',
      () async {
        final records = MemoryValueStore({
          HarborVault.recordKey: await encryptedVaultEnvelope(
            legacyVersion1Data(),
          ),
        });
        final missingKeys = MemoryValueStore();

        await expectLater(
          HarborVault(records: records, keys: missingKeys).load(),
          throwsA(isA<HarborVaultKeyMissingException>()),
        );

        expect(missingKeys.values, isEmpty);
      },
    );

    test(
      'tampered ciphertext is rejected without changing stored data',
      () async {
        final encoded = await encryptedVaultEnvelope(legacyVersion1Data());
        final envelope = Map<String, Object?>.from(jsonDecode(encoded) as Map);
        final cipherText = base64Decode(envelope['cipherText'] as String);
        cipherText[0] ^= 1;
        envelope['cipherText'] = base64Encode(cipherText);
        final tampered = jsonEncode(envelope);
        final records = TestValueStore({HarborVault.recordKey: tampered});
        final keys = seededKeyStore();

        await expectLater(
          HarborVault(records: records, keys: keys).load(),
          throwsA(isA<HarborVaultCorruptException>()),
        );

        expect(records.values[HarborVault.recordKey], tampered);
        expect(records.writes, isEmpty);
        expect(keys.writes, isEmpty);
      },
    );

    test('orphan migration staging never becomes canonical data', () async {
      final records = TestValueStore({
        HarborVault.migrationRecordKey: await encryptedVaultEnvelope(
          legacyVersion1Data()..['schemaVersion'] = 2,
        ),
      });

      await expectLater(
        HarborVault(records: records, keys: seededKeyStore()).load(),
        throwsA(isA<HarborVaultMigrationException>()),
      );
      expect(records.writes, isEmpty);
    });

    test('erase removes encrypted records and the key', () async {
      final records = MemoryValueStore();
      final keys = MemoryValueStore();
      final vault = HarborVault(records: records, keys: keys);
      await vault.save(const HarborData(onboardingComplete: true));
      records.values[HarborVault.migrationRecordKey] =
          records.values[HarborVault.recordKey]!;

      await vault.eraseAll();

      expect(records.values, isEmpty);
      expect(keys.values, isEmpty);
      expect((await vault.load()).onboardingComplete, isFalse);
    });

    test(
      'app lock wraps the existing key and blocks startup until unlock',
      () async {
        final records = MemoryValueStore();
        final keys = MemoryValueStore();
        final codec = HarborAppLockCodec(iterations: 1000);
        final vault = HarborVault(
          records: records,
          keys: keys,
          appLockCodec: codec,
        );
        final privateData = HarborData(
          onboardingComplete: true,
          journalEntries: [
            JournalEntry(
              title: 'LOCKED PRIVATE TITLE',
              body: 'LOCKED PRIVATE BODY',
            ),
          ],
        );
        await vault.save(privateData);
        final rawKey = keys.values[HarborVault.encryptionKey]!;

        await vault.enableAppLock('correct horse harbor');

        expect(await vault.appLockEnabled(), isTrue);
        expect(keys.values[HarborVault.encryptionKey], isNull);
        expect(records.values[HarborVault.appLockStagingKey], isNull);
        final lockRecord = records.values[HarborVault.appLockKey]!;
        expect(lockRecord, isNot(contains('correct horse harbor')));
        expect(lockRecord, isNot(contains(rawKey)));
        expect(lockRecord, isNot(contains('LOCKED PRIVATE')));

        vault.lockApp();
        await expectLater(
          vault.load(),
          throwsA(isA<HarborAppLockedException>()),
        );

        final restarted = HarborVault(
          records: records,
          keys: keys,
          appLockCodec: codec,
        );
        await expectLater(
          restarted.unlockAppLock('wrong horse harbor'),
          throwsA(isA<HarborAppLockPassphraseException>()),
        );
        expect(records.values[HarborVault.recordKey], isNotNull);
        expect(records.values[HarborVault.appLockKey], lockRecord);

        await restarted.unlockAppLock('correct horse harbor');
        final loaded = await restarted.load();
        expect(loaded.journalEntries.single.title, 'LOCKED PRIVATE TITLE');
        expect(loaded.journalEntries.single.body, 'LOCKED PRIVATE BODY');
        expect(keys.values[HarborVault.encryptionKey], isNull);
      },
    );

    test('passphrase change invalidates the old wrapped-key record', () async {
      final records = MemoryValueStore();
      final keys = MemoryValueStore();
      final codec = HarborAppLockCodec(iterations: 1000);
      final vault = HarborVault(
        records: records,
        keys: keys,
        appLockCodec: codec,
      );
      await vault.save(
        HarborData(
          journalEntries: [JournalEntry(title: '', body: 'PRESERVE ME')],
        ),
      );
      await vault.enableAppLock('first harbor phrase');

      await expectLater(
        vault.changeAppLockPassphrase(
          currentPassphrase: 'wrong current phrase',
          newPassphrase: 'second harbor phrase',
        ),
        throwsA(isA<HarborAppLockPassphraseException>()),
      );
      await vault.changeAppLockPassphrase(
        currentPassphrase: 'first harbor phrase',
        newPassphrase: 'second harbor phrase',
      );
      vault.lockApp();

      await expectLater(
        vault.unlockAppLock('first harbor phrase'),
        throwsA(isA<HarborAppLockPassphraseException>()),
      );
      await vault.unlockAppLock('second harbor phrase');
      expect((await vault.load()).journalEntries.single.body, 'PRESERVE ME');
      expect(records.values[HarborVault.appLockStagingKey], isNull);
    });

    test('disabling app lock restores automatic local vault opening', () async {
      final records = MemoryValueStore();
      final keys = MemoryValueStore();
      final codec = HarborAppLockCodec(iterations: 1000);
      final vault = HarborVault(
        records: records,
        keys: keys,
        appLockCodec: codec,
      );
      await vault.save(
        HarborData(
          journalEntries: [JournalEntry(title: '', body: 'STAYS ENCRYPTED')],
        ),
      );
      await vault.enableAppLock('correct horse harbor');

      await expectLater(
        vault.disableAppLock('incorrect horse harbor'),
        throwsA(isA<HarborAppLockPassphraseException>()),
      );
      expect(await vault.appLockEnabled(), isTrue);
      expect(keys.values[HarborVault.encryptionKey], isNull);

      await vault.disableAppLock('correct horse harbor');
      expect(await vault.appLockEnabled(), isFalse);
      expect(keys.values[HarborVault.encryptionKey], isNotNull);
      final restarted = HarborVault(
        records: records,
        keys: keys,
        appLockCodec: codec,
      );
      expect(
        (await restarted.load()).journalEntries.single.body,
        'STAYS ENCRYPTED',
      );
    });

    test(
      'failed canonical lock write leaves the original vault open',
      () async {
        final records = TestValueStore()
          ..failOnceOnWriteKey = HarborVault.appLockKey;
        final keys = TestValueStore();
        final vault = HarborVault(
          records: records,
          keys: keys,
          appLockCodec: HarborAppLockCodec(iterations: 1000),
        );
        await vault.save(
          HarborData(
            journalEntries: [JournalEntry(title: '', body: 'DO NOT LOSE')],
          ),
        );

        await expectLater(
          vault.enableAppLock('correct horse harbor'),
          throwsA(isA<StateError>()),
        );

        expect(await vault.appLockEnabled(), isFalse);
        expect(records.values[HarborVault.appLockStagingKey], isNull);
        expect(keys.values[HarborVault.encryptionKey], isNotNull);
        expect((await vault.load()).journalEntries.single.body, 'DO NOT LOSE');
      },
    );

    test(
      'erase while locked removes vault, wrapped key, and staging',
      () async {
        final records = MemoryValueStore();
        final keys = MemoryValueStore();
        final vault = HarborVault(
          records: records,
          keys: keys,
          appLockCodec: HarborAppLockCodec(iterations: 1000),
        );
        await vault.save(
          HarborData(
            journalEntries: [JournalEntry(title: '', body: 'ERASE ME')],
          ),
        );
        await vault.enableAppLock('correct horse harbor');
        records.values[HarborVault.appLockStagingKey] =
            records.values[HarborVault.appLockKey]!;
        vault.lockApp();

        await vault.eraseAll();

        expect(records.values, isEmpty);
        expect(keys.values, isEmpty);
        expect(await vault.appLockEnabled(), isFalse);
        expect((await vault.load()).onboardingComplete, isFalse);
      },
    );
  });
}
