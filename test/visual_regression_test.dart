import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor_app/app.dart';
import 'package:harbor_app/core/controller.dart';
import 'package:harbor_app/core/vault.dart';

void main() {
  setUpAll(() async {
    final harborFonts = FontLoader('HarborSans')
      ..addFont(rootBundle.load('assets/fonts/HarborSans-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/HarborSans-Medium.ttf'));
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([harborFonts.load(), materialIcons.load()]);
  });

  void usePhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  void useAccessibilityPreferences(
    WidgetTester tester, {
    bool highContrast = false,
  }) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(
          disableAnimations: true,
          highContrast: highContrast,
        );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  Future<HarborController> controller({bool onboarded = false}) async {
    final result = HarborController(
      HarborVault(records: MemoryValueStore(), keys: MemoryValueStore()),
    );
    await result.initialize();
    if (onboarded) await result.finishOnboarding('0-6 weeks');
    return result;
  }

  testWidgets('privacy onboarding phone visual remains stable', (tester) async {
    usePhoneViewport(tester);
    useAccessibilityPreferences(tester);

    await tester.pumpWidget(HarborApp(controller: await controller()));
    await tester.pump();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/privacy_onboarding_phone.png'),
    );
  });

  testWidgets('Today phone visual remains stable', (tester) async {
    usePhoneViewport(tester);
    useAccessibilityPreferences(tester);

    await tester.pumpWidget(
      HarborApp(controller: await controller(onboarded: true)),
    );
    await tester.pump();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/today_phone.png'),
    );
  });

  testWidgets('Today high-contrast phone visual remains stable', (
    tester,
  ) async {
    usePhoneViewport(tester);
    useAccessibilityPreferences(tester, highContrast: true);

    await tester.pumpWidget(
      HarborApp(controller: await controller(onboarded: true)),
    );
    await tester.pump();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/today_high_contrast_phone.png'),
    );
  });

  testWidgets('urgent-support dialog phone visual remains stable', (
    tester,
  ) async {
    usePhoneViewport(tester);
    useAccessibilityPreferences(tester);

    await tester.pumpWidget(
      HarborApp(controller: await controller(onboarded: true)),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Urgent support'));
    await tester.pump();

    expect(find.text('Call 911'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/urgent_support_phone.png'),
    );
  });
}
