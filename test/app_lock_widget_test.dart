import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor_app/app.dart';
import 'package:harbor_app/core/app_lock.dart';
import 'package:harbor_app/core/controller.dart';
import 'package:harbor_app/core/models.dart';
import 'package:harbor_app/core/vault.dart';

void main() {
  testWidgets(
    'woman can enable, lock, reject a wrong phrase, and restore private data',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1050);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final records = MemoryValueStore();
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
      await controller.saveJournal(
        JournalEntry(
          title: 'PRIVATE LOCK JOURNAL',
          body: 'This returns only after the correct passphrase.',
        ),
      );
      await tester.pumpWidget(HarborApp(controller: controller));

      await tester.tap(find.byIcon(Icons.shield_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('manage_app_lock')));
      await tester.pumpAndSettle();
      expect(find.text('App lock is off'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('enable_app_lock')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('new_app_lock_passphrase')),
        'correct horse harbor',
      );
      await tester.enterText(
        find.byKey(const ValueKey('confirm_app_lock_passphrase')),
        'correct horse harbor',
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.tap(find.byKey(const ValueKey('save_app_lock_settings')));
      await tester.pumpAndSettle();

      expect(controller.appLockEnabled, isTrue);
      expect(keys.values[HarborVault.encryptionKey], isNull);
      expect(find.text('App lock is on'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('lock_harbor_now')));
      await tester.pumpAndSettle();

      expect(find.text('Harbor is locked.'), findsOneWidget);
      expect(find.text('PRIVATE LOCK JOURNAL'), findsNothing);
      expect(find.text('Open urgent support options'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('app_lock_passphrase')),
        'wrong horse harbor',
      );
      await tester.tap(find.byKey(const ValueKey('unlock_harbor')));
      await tester.pumpAndSettle();
      expect(find.textContaining('did not match'), findsOneWidget);
      expect(controller.locked, isTrue);
      expect(controller.data.journalEntries, isEmpty);

      await tester.enterText(
        find.byKey(const ValueKey('app_lock_passphrase')),
        'correct horse harbor',
      );
      await tester.tap(find.byKey(const ValueKey('unlock_harbor')));
      await tester.pumpAndSettle();
      expect(find.text('Harbor is locked.'), findsNothing);
      expect(controller.locked, isFalse);

      await tester.tap(find.text('Journal'));
      await tester.pumpAndSettle();
      expect(find.text('PRIVATE LOCK JOURNAL'), findsOneWidget);
    },
  );

  testWidgets(
    'background lifecycle locks immediately and urgent support remains',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = HarborController(
        HarborVault(
          records: MemoryValueStore(),
          keys: MemoryValueStore(),
          appLockCodec: HarborAppLockCodec(iterations: 1000),
        ),
      );
      await controller.initialize();
      await controller.finishOnboarding('0-6 weeks');
      await controller.saveJournal(
        JournalEntry(title: 'LIFECYCLE PRIVATE', body: 'Hide on background.'),
      );
      await controller.enableAppLock('correct horse harbor');
      await tester.pumpWidget(HarborApp(controller: controller));
      expect(controller.data.journalEntries.single.title, 'LIFECYCLE PRIVATE');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();

      expect(controller.locked, isTrue);
      expect(controller.data.journalEntries, isEmpty);
      expect(find.text('Harbor is locked.'), findsOneWidget);
      expect(find.text('LIFECYCLE PRIVATE'), findsNothing);

      await tester.tap(find.text('Open urgent support options'));
      await tester.pumpAndSettle();
      expect(find.text('Urgent support'), findsOneWidget);
      expect(find.textContaining('Call 911'), findsWidgets);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    },
  );

  testWidgets('locked recovery requires two confirmations before local erase', (
    tester,
  ) async {
    final records = MemoryValueStore();
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
    await controller.saveJournal(
      JournalEntry(title: 'ERASE PRIVATE', body: 'Only after confirmation.'),
    );
    await controller.enableAppLock('correct horse harbor');
    controller.lockNow();
    await tester.pumpWidget(HarborApp(controller: controller));

    await tester.tap(find.byKey(const ValueKey('app_lock_recovery')));
    await tester.pumpAndSettle();
    expect(find.text('No passphrase recovery'), findsOneWidget);
    await tester.tap(find.text('Keep my data'));
    await tester.pumpAndSettle();
    expect(records.values[HarborVault.recordKey], isNotNull);

    await tester.tap(find.byKey(const ValueKey('app_lock_recovery')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue to erase'));
    await tester.pumpAndSettle();
    expect(find.text('Permanently erase this Harbor data?'), findsOneWidget);
    await tester.tap(find.text('Erase permanently'));
    await tester.pumpAndSettle();

    expect(records.values, isEmpty);
    expect(keys.values, isEmpty);
    expect(find.text('A space that belongs to you.'), findsOneWidget);
  });

  testWidgets('change and disable paths verify the current passphrase', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 1050);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = HarborController(
      HarborVault(
        records: MemoryValueStore(),
        keys: MemoryValueStore(),
        appLockCodec: HarborAppLockCodec(iterations: 1000),
      ),
    );
    await controller.initialize();
    await controller.finishOnboarding('0-6 weeks');
    await controller.enableAppLock('first harbor phrase');
    await tester.pumpWidget(HarborApp(controller: controller));
    await tester.tap(find.byIcon(Icons.shield_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('manage_app_lock')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('change_app_lock')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('current_app_lock_passphrase')),
      'wrong current phrase',
    );
    await tester.enterText(
      find.byKey(const ValueKey('new_app_lock_passphrase')),
      'second harbor phrase',
    );
    await tester.enterText(
      find.byKey(const ValueKey('confirm_app_lock_passphrase')),
      'second harbor phrase',
    );
    await tester.tap(find.byType(CheckboxListTile));
    await tester.tap(find.byKey(const ValueKey('save_app_lock_settings')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('current passphrase did not match'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('current_app_lock_passphrase')),
      'first harbor phrase',
    );
    await tester.tap(find.byKey(const ValueKey('save_app_lock_settings')));
    await tester.pumpAndSettle();
    expect(find.text('Your Harbor passphrase was changed.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('disable_app_lock')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('current_app_lock_passphrase')),
      'second harbor phrase',
    );
    await tester.tap(find.byKey(const ValueKey('save_app_lock_settings')));
    await tester.pumpAndSettle();

    expect(controller.appLockEnabled, isFalse);
    expect(find.text('App lock is off'), findsOneWidget);
  });
}
