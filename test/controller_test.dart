import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:harbor_app/core/app_lock.dart';
import 'package:harbor_app/core/controller.dart';
import 'package:harbor_app/core/models.dart';
import 'package:harbor_app/core/vault.dart';

import 'support/vault_fixtures.dart';

void main() {
  test('complete vertical data slice persists through restart', () async {
    final records = MemoryValueStore();
    final keys = MemoryValueStore();
    final first = HarborController(HarborVault(records: records, keys: keys));
    await first.initialize();
    await first.finishOnboarding('3-6 months');
    await first.addCheckIn(
      CheckIn(mood: 2, anxiety: 5, rest: 1, note: 'hard morning'),
    );
    final journal = JournalEntry(title: 'Today', body: 'I asked for help.');
    await first.saveJournal(journal);
    await first.addQuestion('Could this be postpartum depression?');
    await first.savePlan(
      const HardDayPlan(
        safePerson: 'Maya',
        safePersonPhone: '5550102',
        groundingStep: 'Feet on the floor',
        practicalHelp: 'Bring dinner',
      ),
    );
    await first.addCareLoadItem(
      task: 'Wash bottles and pump parts',
      owner: 'Support person',
    );
    await first.saveCareAsk(
      const CareAskDraft(
        person: 'Maya',
        need: 'tonight\'s dishes and bottle washing',
        when: '8 p.m.',
        boundary: 'I am resting instead of supervising the task.',
      ),
    );
    await first.toggleStoryResonance('story-identity-intact-self');

    final restarted = HarborController(
      HarborVault(records: records, keys: keys),
    );
    await restarted.initialize();

    expect(restarted.data.onboardingComplete, isTrue);
    expect(restarted.data.postpartumStage, '3-6 months');
    expect(restarted.data.checkIns.single.note, 'hard morning');
    expect(restarted.data.journalEntries.single.body, 'I asked for help.');
    expect(
      restarted.data.clinicianQuestions.single.text,
      contains('postpartum'),
    );
    expect(restarted.data.hardDayPlan.safePerson, 'Maya');
    expect(restarted.data.careLoadItems.single.task, contains('bottles'));
    expect(restarted.data.careLoadItems.single.owner, 'Support person');
    expect(restarted.data.careAskDraft.boundary, contains('resting'));
    expect(restarted.data.resonatedStoryIds, {'story-identity-intact-self'});
  });

  test(
    'story resonance toggles privately without changing other records',
    () async {
      final records = MemoryValueStore();
      final keys = MemoryValueStore();
      final controller = HarborController(
        HarborVault(records: records, keys: keys),
      );
      await controller.initialize();
      await controller.saveJournal(
        JournalEntry(title: 'Private', body: 'Keep this separate.'),
      );

      await controller.toggleStoryResonance('story-anger-invisible-load');
      expect(controller.data.resonatedStoryIds, {'story-anger-invisible-load'});
      expect(controller.data.journalEntries.single.body, 'Keep this separate.');
      expect(
        records.values[HarborVault.recordKey],
        isNot(contains('story-anger-invisible-load')),
      );

      await controller.toggleStoryResonance('story-anger-invisible-load');
      expect(controller.data.resonatedStoryIds, isEmpty);
      expect(controller.data.journalEntries.single.body, 'Keep this separate.');
    },
  );

  test(
    'care-load items toggle and delete without touching private records',
    () async {
      final records = MemoryValueStore();
      final keys = MemoryValueStore();
      final controller = HarborController(
        HarborVault(records: records, keys: keys),
      );
      await controller.initialize();
      await controller.saveJournal(
        JournalEntry(title: 'Private', body: 'This must remain untouched.'),
      );
      await controller.addCareLoadItem(
        task: 'Schedule the pediatric appointment',
        owner: 'Someone else',
      );
      final id = controller.data.careLoadItems.single.id;

      await controller.toggleCareLoadItem(id);
      expect(controller.data.careLoadItems.single.completed, isTrue);
      expect(controller.data.journalEntries.single.title, 'Private');

      await controller.deleteCareLoadItem(id);
      expect(controller.data.careLoadItems, isEmpty);
      expect(controller.data.journalEntries.single.body, contains('untouched'));
    },
  );

  test('care request is deterministic and contains only its own fields', () {
    const draft = CareAskDraft(
      person: 'Alex',
      need: 'the 2 a.m. bottle and cleanup',
      when: 'tonight',
      boundary: 'Please do not wake me to ask where supplies are.',
    );

    expect(
      draft.compose(),
      'Alex, I need you to take responsibility for the 2 a.m. bottle and cleanup by tonight. Please do not wake me to ask where supplies are.',
    );
    expect(draft.compose(), isNot(contains('journal')));
    expect(draft.compose(), isNot(contains('check-in')));
  });

  test('unopenable encrypted data locks every normal write path', () async {
    final future = legacyVersion1Data()..['schemaVersion'] = 99;
    final records = TestValueStore({
      HarborVault.recordKey: await encryptedVaultEnvelope(future),
    });
    final keys = seededKeyStore();
    final controller = HarborController(
      HarborVault(records: records, keys: keys),
    );
    final originalRecords = Map<String, String>.from(records.values);
    final originalKeys = Map<String, String>.from(keys.values);

    await controller.initialize();

    expect(controller.error, isA<UnsupportedHarborDataVersionException>());
    expect(controller.loading, isFalse);
    await expectLater(
      controller.addQuestion('This must never overwrite the future vault.'),
      throwsA(isA<StateError>()),
    );
    expect(records.values, originalRecords);
    expect(keys.values, originalKeys);
  });

  test('retry resumes an interrupted migration without data loss', () async {
    final records = TestValueStore({
      HarborVault.recordKey: await encryptedVaultEnvelope(legacyVersion1Data()),
    })..failOnceOnWriteKey = HarborVault.recordKey;
    final controller = HarborController(
      HarborVault(records: records, keys: seededKeyStore()),
    );

    await controller.initialize();
    expect(controller.error, isA<HarborVaultMigrationException>());
    expect(controller.data.onboardingComplete, isFalse);

    await controller.initialize();
    expect(controller.error, isNull);
    expect(controller.data.schemaVersion, HarborData.currentSchemaVersion);
    expect(
      controller.data.journalEntries.single.body,
      'LEGACY-PRIVATE-JOURNAL',
    );
    expect(records.values[HarborVault.migrationRecordKey], isNull);
  });

  test('locked startup does not read or expose the encrypted record', () async {
    final records = TestValueStore();
    final keys = TestValueStore();
    final codec = HarborAppLockCodec(iterations: 1000);
    final first = HarborController(
      HarborVault(records: records, keys: keys, appLockCodec: codec),
    );
    await first.initialize();
    await first.finishOnboarding('0-6 weeks');
    await first.saveJournal(
      JournalEntry(title: 'PRIVATE TITLE', body: 'PRIVATE LOCKED BODY'),
    );
    await first.enableAppLock('correct horse harbor');
    records.reads.clear();

    final restarted = HarborController(
      HarborVault(records: records, keys: keys, appLockCodec: codec),
    );
    await restarted.initialize();

    expect(restarted.appLockEnabled, isTrue);
    expect(restarted.locked, isTrue);
    expect(restarted.error, isNull);
    expect(restarted.data.onboardingComplete, isFalse);
    expect(restarted.data.journalEntries, isEmpty);
    expect(records.reads, contains(HarborVault.appLockKey));
    expect(records.reads, isNot(contains(HarborVault.recordKey)));

    await expectLater(
      restarted.addQuestion('A write must not happen while locked.'),
      throwsA(isA<StateError>()),
    );
    expect(records.values[HarborVault.recordKey], isNotNull);
  });

  test(
    'manual lock clears the in-memory model and correct unlock restores it',
    () async {
      final records = MemoryValueStore();
      final keys = MemoryValueStore();
      final codec = HarborAppLockCodec(iterations: 1000);
      final controller = HarborController(
        HarborVault(records: records, keys: keys, appLockCodec: codec),
      );
      await controller.initialize();
      await controller.finishOnboarding('0-6 weeks');
      await controller.saveJournal(
        JournalEntry(title: 'PRIVATE TITLE', body: 'PRIVATE LOCKED BODY'),
      );
      await controller.enableAppLock('correct horse harbor');

      controller.lockNow();

      expect(controller.locked, isTrue);
      expect(controller.data.journalEntries, isEmpty);
      await expectLater(
        controller.unlockApp('wrong horse harbor'),
        throwsA(isA<HarborAppLockPassphraseException>()),
      );
      expect(controller.locked, isTrue);
      expect(controller.data.journalEntries, isEmpty);

      await controller.unlockApp('correct horse harbor');
      expect(controller.locked, isFalse);
      expect(controller.data.onboardingComplete, isTrue);
      expect(controller.data.journalEntries.single.body, 'PRIVATE LOCKED BODY');
    },
  );

  test(
    'repeated wrong attempts add a bounded in-memory unlock delay',
    () async {
      var now = DateTime.utc(2026, 8, 31, 12);
      final controller = HarborController(
        HarborVault(
          records: MemoryValueStore(),
          keys: MemoryValueStore(),
          appLockCodec: HarborAppLockCodec(iterations: 1000),
        ),
        now: () => now,
      );
      await controller.initialize();
      await controller.finishOnboarding('0-6 weeks');
      await controller.enableAppLock('correct horse harbor');
      controller.lockNow();

      for (var attempt = 0; attempt < 3; attempt++) {
        await expectLater(
          controller.unlockApp('wrong horse harbor'),
          throwsA(isA<HarborAppLockPassphraseException>()),
        );
      }
      expect(controller.failedUnlockAttempts, 3);
      expect(controller.unlockWait, const Duration(seconds: 5));
      await expectLater(
        controller.unlockApp('correct horse harbor'),
        throwsA(isA<HarborAppLockThrottledException>()),
      );

      now = now.add(const Duration(seconds: 6));
      await controller.unlockApp('correct horse harbor');
      expect(controller.failedUnlockAttempts, 0);
      expect(controller.unlockWait, Duration.zero);
      expect(controller.locked, isFalse);
    },
  );

  test(
    'lock during an active save hides memory immediately and preserves commit',
    () async {
      final records = BlockingValueStore();
      final keys = MemoryValueStore();
      final controller = HarborController(
        HarborVault(
          records: records,
          keys: keys,
          appLockCodec: HarborAppLockCodec(iterations: 1000),
        ),
      );
      await controller.initialize();
      await controller.finishOnboarding('0-6 weeks');
      await controller.enableAppLock('correct horse harbor');
      records.blockNextWrite();

      final pendingSave = controller.saveJournal(
        JournalEntry(title: 'SAVE WHILE HIDING', body: 'Preserve this commit.'),
      );
      await records.writeStarted.future;
      controller.lockNow();

      expect(controller.locked, isTrue);
      expect(controller.data.journalEntries, isEmpty);
      records.allowWrite.complete();
      await pendingSave;
      expect(controller.locked, isTrue);
      expect(controller.data.journalEntries, isEmpty);

      await controller.unlockApp('correct horse harbor');
      expect(controller.data.journalEntries.single.title, 'SAVE WHILE HIDING');
    },
  );
}

final class BlockingValueStore implements ValueStore {
  final Map<String, String> values = {};
  Completer<void> writeStarted = Completer<void>();
  Completer<void> allowWrite = Completer<void>();
  bool _block = false;

  void blockNextWrite() {
    writeStarted = Completer<void>();
    allowWrite = Completer<void>();
    _block = true;
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    if (_block) {
      _block = false;
      writeStarted.complete();
      await allowWrite.future;
    }
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
