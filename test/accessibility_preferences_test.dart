import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor_app/accessibility.dart';
import 'package:harbor_app/app.dart';
import 'package:harbor_app/core/controller.dart';
import 'package:harbor_app/core/vault.dart';
import 'package:harbor_app/theme.dart';

void main() {
  Future<HarborController> readyController() async {
    final controller = HarborController(
      HarborVault(records: MemoryValueStore(), keys: MemoryValueStore()),
    );
    await controller.initialize();
    await controller.finishOnboarding('0-6 weeks');
    return controller;
  }

  double contrastRatio(Color first, Color second) {
    final lighter = first.computeLuminance() > second.computeLuminance()
        ? first.computeLuminance()
        : second.computeLuminance();
    final darker = first.computeLuminance() > second.computeLuminance()
        ? second.computeLuminance()
        : first.computeLuminance();
    return (lighter + 0.05) / (darker + 0.05);
  }

  test('high-contrast palette preserves enhanced text contrast', () {
    final theme = harborHighContrastTheme();
    final scheme = theme.colorScheme;
    final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
    final inputBorder =
        theme.inputDecorationTheme.enabledBorder! as OutlineInputBorder;

    expect(theme.scaffoldBackgroundColor, Colors.white);
    expect(
      contrastRatio(scheme.primary, scheme.onPrimary),
      greaterThanOrEqualTo(7),
    );
    expect(
      contrastRatio(scheme.surface, scheme.onSurface),
      greaterThanOrEqualTo(7),
    );
    expect(cardShape.side.width, 2);
    expect(cardShape.side.color, Colors.black);
    expect(inputBorder.borderSide.width, 2);
    expect(inputBorder.borderSide.color, Colors.black);
  });

  testWidgets(
    'platform high-contrast preference selects Harbor high-contrast theme',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(highContrast: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final controller = await readyController();

      await tester.pumpWidget(HarborApp(controller: controller));
      await tester.pumpAndSettle();

      final context = tester.element(find.text('How is today, really?'));
      final applied = Theme.of(context);
      expect(applied.colorScheme, harborHighContrastTheme().colorScheme);
      expect(applied.colorScheme, isNot(harborTheme().colorScheme));
      expect(find.byTooltip('Urgent support'), findsOneWidget);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    },
  );

  testWidgets(
    'platform reduced-motion preference removes Harbor-owned transitions',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final controller = await readyController();

      await tester.pumpWidget(HarborApp(controller: controller));
      await tester.pump();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final context = tester.element(find.text('How is today, really?'));
      final transitions = Theme.of(context).pageTransitionsTheme;
      final builder = transitions.builders[TargetPlatform.android]!;
      final child = Container(key: const ValueKey('transition_child'));
      final route = MaterialPageRoute<void>(builder: (_) => child);

      expect(materialApp.themeAnimationStyle, AnimationStyle.noAnimation);
      expect(
        harborMotionDuration(context, const Duration(seconds: 1)),
        Duration.zero,
      );
      expect(harborAnimationStyle(context), AnimationStyle.noAnimation);
      expect(builder, isA<HarborPageTransitionsBuilder>());
      expect(
        identical(
          builder.buildTransitions<void>(
            route,
            context,
            const AlwaysStoppedAnimation(0.5),
            const AlwaysStoppedAnimation(0),
            child,
          ),
          child,
        ),
        isTrue,
      );

      await tester.tap(find.byTooltip('Urgent support'));
      await tester.pump();
      expect(find.text('Call 911'), findsOneWidget);
      final dialogRoute = ModalRoute.of(
        tester.element(find.byType(AlertDialog)),
      )!;
      expect(dialogRoute.animation!.value, 1);
      expect(dialogRoute.animation!.status, AnimationStatus.completed);
    },
  );

  testWidgets('onboarding page changes become immediate with reduced motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final controller = HarborController(
      HarborVault(records: MemoryValueStore(), keys: MemoryValueStore()),
    );
    await controller.initialize();

    await tester.pumpWidget(HarborApp(controller: controller));
    await tester.pump();

    expect(
      tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
      Duration.zero,
    );
    final acknowledgment = find.text(
      'I understand where my Harbor data lives.',
    );
    await tester.ensureVisible(acknowledgment);
    await tester.pump();
    await tester.tap(acknowledgment);
    final continueButton = find.text('Continue');
    await tester.ensureVisible(continueButton);
    await tester.pump();
    await tester.tap(continueButton);
    await tester.pump();

    expect(find.text('Where are you right now?'), findsOneWidget);
    expect(
      tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
      Duration.zero,
    );
  });
}
