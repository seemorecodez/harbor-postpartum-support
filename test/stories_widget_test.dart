import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor_app/app.dart';
import 'package:harbor_app/core/controller.dart';
import 'package:harbor_app/core/vault.dart';

void main() {
  testWidgets(
    'offline Stories filters locally and saves only encrypted resonance',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final records = MemoryValueStore();
      final keys = MemoryValueStore();
      final controller = HarborController(
        HarborVault(records: records, keys: keys),
      );
      await controller.initialize();
      await controller.finishOnboarding('0-6 weeks');
      await tester.pumpWidget(HarborApp(controller: controller));

      await tester.tap(find.text('Stories'));
      await tester.pumpAndSettle();

      expect(find.text('Somebody else has felt it.'), findsOneWidget);
      expect(
        find.text('Not posts. Not live. Not women being tracked.'),
        findsOneWidget,
      );
      expect(find.text('6 story drafts'), findsOneWidget);
      expect(find.textContaining('minutes ago'), findsNothing);
      expect(find.textContaining('likes'), findsNothing);

      await tester.tap(find.widgetWithText(FilterChip, 'Feeding'));
      await tester.pumpAndSettle();
      expect(find.text('1 story draft'), findsOneWidget);
      expect(find.text('Feeding was not a purity test'), findsOneWidget);
      expect(find.text('I needed somewhere to name my anger'), findsNothing);

      await tester.tap(find.widgetWithText(FilterChip, 'All'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Search offline stories'),
        'minimize it',
      );
      await tester.pumpAndSettle();
      expect(find.text('1 story draft'), findsOneWidget);
      expect(
        find.text('I wrote it down so I would not minimize it'),
        findsOneWidget,
      );

      final resonate = find.byKey(
        const ValueKey('story_resonance_story-being-heard-not-dismissed'),
      );
      await tester.ensureVisible(resonate);
      await tester.tap(resonate);
      await tester.pumpAndSettle();

      expect(controller.data.resonatedStoryIds, {
        'story-being-heard-not-dismissed',
      });
      expect(
        find.text(
          'Saved only in your encrypted Harbor vault. Nothing was sent.',
        ),
        findsOneWidget,
      );
      final encoded = records.values[HarborVault.recordKey]!;
      expect(encoded, isNot(contains('story-being-heard-not-dismissed')));

      final restarted = HarborController(
        HarborVault(records: records, keys: keys),
      );
      await restarted.initialize();
      expect(restarted.data.resonatedStoryIds, {
        'story-being-heard-not-dismissed',
      });
    },
  );
}
