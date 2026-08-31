import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor_app/app.dart';
import 'package:harbor_app/core/controller.dart';
import 'package:harbor_app/core/vault.dart';

Future<HarborController> readyGuideController() async {
  final controller = HarborController(
    HarborVault(records: MemoryValueStore(), keys: MemoryValueStore()),
  );
  await controller.initialize();
  await controller.finishOnboarding('0-6 weeks');
  return controller;
}

void useGuideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets(
    'every release safety scenario is discoverable in the real guide',
    (tester) async {
      useGuideViewport(tester);
      final controller = await readyGuideController();
      await tester.pumpWidget(HarborApp(controller: controller));
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();

      final search = find.byType(TextField);
      const scenarios = <String, String>{
        'gushing bleeding': 'Bleeding that is much heavier than expected',
        'vision changes': 'A severe headache or vision changes',
        'bad-smelling discharge':
            'Fever, chills, belly tenderness, or bad-smelling discharge',
        'hallucinations':
            'Hallucinations, delusions, mania, paranoia, or confusion',
        'thoughts of hurting yourself':
            'Chest pain, gasping, seizure, or immediate danger',
        'younger than three months':
            'Fever in a baby younger than three months',
        'grunting with each breath':
            'Trouble breathing, blue or gray color, or hard to wake',
        'suddenly feeding poorly': 'A newborn is suddenly feeding poorly',
        'sunlight': 'Yellow skin or eyes, especially with poor feeding',
      };

      for (final scenario in scenarios.entries) {
        await tester.enterText(search, scenario.key);
        await tester.pumpAndSettle();
        expect(find.text('1 entry'), findsOneWidget, reason: scenario.key);
        expect(find.text(scenario.value), findsOneWidget, reason: scenario.key);
      }
    },
  );

  testWidgets(
    'postpartum psychosis opens immediate support without diagnosis',
    (tester) async {
      useGuideViewport(tester);
      final controller = await readyGuideController();
      await tester.pumpWidget(HarborApp(controller: controller));
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'hallucinations');
      await tester.pumpAndSettle();
      expect(find.text('EMERGENCY'), findsOneWidget);
      expect(find.textContaining('can be symptoms'), findsOneWidget);
      expect(find.textContaining('Harbor cannot assess'), findsOneWidget);
      expect(
        find.textContaining('you have postpartum psychosis'),
        findsNothing,
      );

      final urgent = find.text('Open urgent support options');
      await tester.ensureVisible(urgent);
      await tester.tap(urgent);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Urgent support'),
        ),
        findsOneWidget,
      );
      expect(find.text('Call 911'), findsOneWidget);
      expect(find.text('Call 988'), findsOneWidget);
      expect(find.text('Text 988'), findsOneWidget);
    },
  );
}
