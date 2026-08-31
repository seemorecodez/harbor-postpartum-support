import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
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
  });
}
