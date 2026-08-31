import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor_app/app.dart';
import 'package:harbor_app/core/controller.dart';
import 'package:harbor_app/core/models.dart';
import 'package:harbor_app/core/vault.dart';

import 'support/vault_fixtures.dart';

void main() {
  Future<HarborController> readyController() async {
    final controller = HarborController(
      HarborVault(records: MemoryValueStore(), keys: MemoryValueStore()),
    );
    await controller.initialize();
    await controller.finishOnboarding('0-6 weeks');
    await controller.saveJournal(
      JournalEntry(
        title: 'One honest page',
        body: 'Today was complicated and I want to remember that.',
      ),
    );
    await controller.addQuestion('Which symptoms should I bring up?');
    await controller.addCheckIn(
      CheckIn(mood: 2, anxiety: 4, rest: 2, note: 'A hard morning.'),
    );
    return controller;
  }

  void useViewport(WidgetTester tester, Size size, {double textScale = 1}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Future<void> expectCoreGuidelines(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  testWidgets('onboarding remains usable at a phone viewport and 200% text', (
    tester,
  ) async {
    useViewport(tester, const Size(390, 844), textScale: 2);
    final controller = HarborController(
      HarborVault(records: MemoryValueStore(), keys: MemoryValueStore()),
    );
    await controller.initialize();

    await tester.pumpWidget(HarborApp(controller: controller));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectCoreGuidelines(tester);

    final privacyAcknowledgment = find.text(
      'I understand where my Harbor data lives.',
    );
    await tester.ensureVisible(privacyAcknowledgment);
    await tester.tap(privacyAcknowledgment);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Where are you right now?'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Support, not surveillance.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectCoreGuidelines(tester);
  });

  testWidgets('all phone destinations withstand 200% text', (tester) async {
    useViewport(tester, const Size(390, 844), textScale: 2);
    final controller = await readyController();
    await tester.pumpWidget(HarborApp(controller: controller));
    await tester.pumpAndSettle();

    for (final destination in const [
      'Today',
      'Journal',
      'Questions',
      'Plan',
      'Library',
      'Stories',
      'Privacy',
    ]) {
      await tester.tap(find.byTooltip('Open navigation'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$destination drawer');
      await tester.tap(find.text(destination).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: destination);
    }
    await expectCoreGuidelines(tester);
  });

  testWidgets('protected-data recovery is accessible at 200% text', (
    tester,
  ) async {
    useViewport(tester, const Size(390, 844), textScale: 2);
    final future = legacyVersion1Data()..['schemaVersion'] = 99;
    final controller = HarborController(
      HarborVault(
        records: TestValueStore({
          HarborVault.recordKey: await encryptedVaultEnvelope(future),
        }),
        keys: seededKeyStore(),
      ),
    );
    await controller.initialize();
    await tester.pumpWidget(HarborApp(controller: controller));
    await tester.pumpAndSettle();

    expect(
      find.text('Harbor needs an update to open your data.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await expectCoreGuidelines(tester);
  });

  testWidgets('About and content versions reflow at phone size and 200% text', (
    tester,
  ) async {
    useViewport(tester, const Size(390, 844), textScale: 2);
    final controller = await readyController();
    await tester.pumpWidget(HarborApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Privacy').last);
    await tester.pumpAndSettle();
    final openAbout = find.byKey(const ValueKey('open_about_harbor'));
    await tester.ensureVisible(openAbout);
    await tester.tap(openAbout);
    await tester.pumpAndSettle();

    expect(find.text('About Harbor'), findsOneWidget);
    expect(find.text('Versions on this device'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectCoreGuidelines(tester);
  });

  testWidgets('keyboard can reach and activate onboarding controls', (
    tester,
  ) async {
    useViewport(tester, const Size(1280, 900));
    final controller = HarborController(
      HarborVault(records: MemoryValueStore(), keys: MemoryValueStore()),
    );
    await controller.initialize();
    await tester.pumpWidget(HarborApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
          .onPressed,
      isNotNull,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Where are you right now?'), findsOneWidget);
  });
}
