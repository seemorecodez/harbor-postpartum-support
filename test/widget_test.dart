import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor_app/app.dart';
import 'package:harbor_app/core/controller.dart';
import 'package:harbor_app/core/models.dart';
import 'package:harbor_app/core/vault.dart';

import 'support/vault_fixtures.dart';

void main() {
  testWidgets('onboarding requires an explicit privacy acknowledgment', (
    tester,
  ) async {
    final controller = HarborController(
      HarborVault(records: MemoryValueStore(), keys: MemoryValueStore()),
    );
    await controller.initialize();
    await tester.pumpWidget(HarborApp(controller: controller));

    expect(find.text('A space that belongs to you.'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(
      find.widgetWithText(
        CheckboxListTile,
        'I understand where my Harbor data lives.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('care task and care request work through the real UI path', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? clipboardText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardText = (call.arguments as Map)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    final controller = HarborController(
      HarborVault(records: MemoryValueStore(), keys: MemoryValueStore()),
    );
    await controller.initialize();
    await controller.finishOnboarding('0-6 weeks');
    await controller.saveJournal(
      JournalEntry(title: 'Private', body: 'PRIVATE JOURNAL MUST NOT COPY'),
    );
    await tester.pumpWidget(HarborApp(controller: controller));

    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
    expect(find.text('Care, boundaries, and hard days'), findsOneWidget);

    final taskField = find.byKey(const ValueKey('care_task_field'));
    await tester.ensureVisible(taskField);
    await tester.enterText(taskField, 'Wash bottles and pump parts');
    final addTaskButton = find.byKey(const ValueKey('add_care_task'));
    await tester.ensureVisible(addTaskButton);
    await tester.pumpAndSettle();
    await tester.tap(addTaskButton);
    await tester.pumpAndSettle();
    expect(find.text('Wash bottles and pump parts'), findsOneWidget);
    expect(controller.data.careLoadItems.single.owner, 'Unassigned');

    final needField = find.byKey(const ValueKey('care_ask_need'));
    await tester.ensureVisible(needField);
    await tester.enterText(needField, 'the next feeding and cleanup');
    final boundaryField = find.byKey(const ValueKey('care_ask_boundary'));
    await tester.ensureVisible(boundaryField);
    await tester.enterText(
      boundaryField,
      'I am resting instead of managing the task.',
    );
    await tester.pumpAndSettle();

    final reviewButton = find.byKey(const ValueKey('review_care_ask'));
    await tester.ensureVisible(reviewButton);
    await tester.tap(reviewButton);
    await tester.pumpAndSettle();
    expect(find.text('Copy this care request?'), findsOneWidget);
    expect(clipboardText, isNull);

    await tester.tap(find.text('Keep private'));
    await tester.pumpAndSettle();
    expect(clipboardText, isNull);

    await tester.tap(reviewButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy only this text'));
    await tester.pumpAndSettle();

    expect(clipboardText, contains('the next feeding and cleanup'));
    expect(clipboardText, contains('resting instead of managing'));
    expect(clipboardText, isNot(contains('PRIVATE JOURNAL')));
  });

  testWidgets(
    'factual reflection and clinician copy preserve private-data boundaries',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? clipboardText;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              clipboardText = (call.arguments as Map)['text'] as String?;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );

      final controller = HarborController(
        HarborVault(records: MemoryValueStore(), keys: MemoryValueStore()),
      );
      await controller.initialize();
      await controller.finishOnboarding('0-6 weeks');
      await controller.saveJournal(
        JournalEntry(title: 'Private', body: 'SECRET JOURNAL CONTENT'),
      );
      await controller.addCheckIn(
        CheckIn(mood: 2, anxiety: 4, rest: 1, note: 'SECRET CHECK-IN NOTE'),
      );
      await controller.addCheckIn(CheckIn(mood: 2, anxiety: 5, rest: 2));
      await controller.addCheckIn(CheckIn(mood: 3, anxiety: 4, rest: 2));
      await controller.addQuestion('What support is available locally?');
      await controller.addQuestion('Already discussed with clinician');
      await controller.toggleQuestion(
        controller.data.clinicianQuestions.first.id,
      );

      await tester.pumpWidget(HarborApp(controller: controller));

      expect(
        find.textContaining('Across your last 3 check-ins'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('save_reflection_question')));
      await tester.pumpAndSettle();
      expect(
        controller.data.clinicianQuestions.any(
          (question) => question.text.contains('Across my last 3 check-ins'),
        ),
        isTrue,
      );

      await tester.tap(find.text('Questions'));
      await tester.pumpAndSettle();
      final review = find.byKey(const ValueKey('review_clinician_questions'));
      await tester.tap(review);
      await tester.pumpAndSettle();

      expect(find.text('Copy these clinician questions?'), findsOneWidget);
      expect(clipboardText, isNull);
      await tester.tap(find.text('Keep private'));
      await tester.pumpAndSettle();
      expect(clipboardText, isNull);

      await tester.tap(review);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy only these questions'));
      await tester.pumpAndSettle();

      expect(clipboardText, contains('What support is available locally?'));
      expect(clipboardText, contains('Across my last 3 check-ins'));
      expect(clipboardText, isNot(contains('Already discussed')));
      expect(clipboardText, isNot(contains('SECRET JOURNAL')));
      expect(clipboardText, isNot(contains('SECRET CHECK-IN')));
    },
  );

  testWidgets(
    'future encrypted data is locked behind explicit retry or confirmed erase',
    (tester) async {
      final future = legacyVersion1Data()..['schemaVersion'] = 99;
      final originalEnvelope = await encryptedVaultEnvelope(future);
      final records = TestValueStore({
        HarborVault.recordKey: originalEnvelope,
      });
      final keys = seededKeyStore();
      final controller = HarborController(
        HarborVault(records: records, keys: keys),
      );
      await controller.initialize();

      await tester.pumpWidget(HarborApp(controller: controller));

      expect(
        find.text('Harbor needs an update to open your data.'),
        findsOneWidget,
      );
      expect(find.text('A space that belongs to you.'), findsNothing);
      expect(records.values[HarborVault.recordKey], originalEnvelope);

      await tester.tap(find.text('Try opening my data again'));
      await tester.pumpAndSettle();
      expect(
        find.text('Harbor needs an update to open your data.'),
        findsOneWidget,
      );
      expect(records.values[HarborVault.recordKey], originalEnvelope);
      expect(records.writes, isEmpty);

      await tester.tap(find.text('Erase this local Harbor data'));
      await tester.pumpAndSettle();
      expect(find.text('Permanently erase this Harbor data?'), findsOneWidget);
      await tester.tap(find.text('Keep my data'));
      await tester.pumpAndSettle();
      expect(records.values[HarborVault.recordKey], originalEnvelope);

      await tester.tap(find.text('Erase this local Harbor data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Erase permanently'));
      await tester.pumpAndSettle();

      expect(find.text('A space that belongs to you.'), findsOneWidget);
      expect(records.values, isEmpty);
      expect(keys.values, isEmpty);
    },
  );

  testWidgets('missing key shows the protected-data screen without replacement', (
    tester,
  ) async {
    final records = TestValueStore({
      HarborVault.recordKey: await encryptedVaultEnvelope(
        legacyVersion1Data(),
      ),
    });
    final missingKeys = TestValueStore();
    final controller = HarborController(
      HarborVault(records: records, keys: missingKeys),
    );
    await controller.initialize();

    await tester.pumpWidget(HarborApp(controller: controller));

    expect(
      find.text('Harbor could not safely unlock your data.'),
      findsOneWidget,
    );
    expect(find.text('A space that belongs to you.'), findsNothing);
    expect(missingKeys.values, isEmpty);
    expect(missingKeys.writes, isEmpty);
  });
}
