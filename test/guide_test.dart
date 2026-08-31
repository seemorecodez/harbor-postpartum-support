import 'package:flutter_test/flutter_test.dart';
import 'package:harbor_app/content/guide.dart';

void main() {
  group('postpartum guide', () {
    test(
      'every entry has unique identity, scope, action, and source metadata',
      () {
        final ids = <String>{};

        for (final entry in guideEntries) {
          expect(
            ids.add(entry.id),
            isTrue,
            reason: 'Duplicate id: ${entry.id}',
          );
          expect(entry.title.trim(), isNotEmpty);
          expect(entry.summary.trim(), isNotEmpty);
          expect(entry.action.trim(), isNotEmpty);
          expect(entry.stages, isNotEmpty);
          expect(entry.sourceId.trim(), isNotEmpty);
          expect(entry.sourceLabel.trim(), isNotEmpty);
          expect(entry.sourceReviewed.trim(), isNotEmpty);
        }
      },
    );

    test('stage labels stay inside the supported postpartum timeline', () {
      const supportedStages = {
        '0-6 weeks',
        '7-12 weeks',
        '3-6 months',
        '7-12 months',
      };

      for (final entry in guideEntries) {
        expect(
          supportedStages.containsAll(entry.stages),
          isTrue,
          reason: '${entry.id} contains an unsupported stage',
        );
      }
    });

    test('emergency entries provide an immediate action, not reassurance', () {
      final emergencyEntries = guideEntries.where(
        (entry) => entry.urgency == GuideUrgency.emergency,
      );

      expect(emergencyEntries, isNotEmpty);
      for (final entry in emergencyEntries) {
        final action = entry.action.toLowerCase();
        expect(
          action.contains('call emergency services') ||
              action.contains('seek immediate medical care'),
          isTrue,
          reason: '${entry.id} lacks an immediate emergency handoff',
        );
      }
    });

    test('search and filters expose the intended body and baby guidance', () {
      final jaundice = guideEntries.where((entry) => entry.matches('jaundice'));
      expect(jaundice, hasLength(1));
      expect(jaundice.single.audience, GuideAudience.baby);

      final laterMoodGuidance = guideEntries.where(
        (entry) =>
            entry.audience == GuideAudience.woman &&
            entry.stages.contains('7-12 months') &&
            entry.matches('depression'),
      );
      expect(laterMoodGuidance, isNotEmpty);
    });

    test('guide content does not embed remote URLs', () {
      for (final entry in guideEntries) {
        final content =
            '${entry.title} ${entry.summary} ${entry.action} '
            '${entry.sourceLabel}';
        expect(content, isNot(contains('http')));
        expect(content, isNot(contains('www.')));
      }
    });
  });
}
