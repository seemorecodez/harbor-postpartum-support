import 'dart:io';

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

    test('every release-mandated safety scenario has one controlled entry', () {
      const expected =
          <
            GuideSafetyScenario,
            ({String id, GuideAudience audience, GuideUrgency urgency})
          >{
            GuideSafetyScenario.postpartumHemorrhage: (
              id: 'woman-heavy-bleeding',
              audience: GuideAudience.woman,
              urgency: GuideUrgency.contactClinician,
            ),
            GuideSafetyScenario.postpartumPreeclampsia: (
              id: 'woman-headache-vision',
              audience: GuideAudience.woman,
              urgency: GuideUrgency.contactClinician,
            ),
            GuideSafetyScenario.postpartumInfection: (
              id: 'woman-postpartum-infection',
              audience: GuideAudience.woman,
              urgency: GuideUrgency.contactClinician,
            ),
            GuideSafetyScenario.postpartumPsychosis: (
              id: 'woman-postpartum-psychosis',
              audience: GuideAudience.woman,
              urgency: GuideUrgency.emergency,
            ),
            GuideSafetyScenario.suicidality: (
              id: 'woman-emergency',
              audience: GuideAudience.woman,
              urgency: GuideUrgency.emergency,
            ),
            GuideSafetyScenario.newbornFever: (
              id: 'baby-fever',
              audience: GuideAudience.baby,
              urgency: GuideUrgency.emergency,
            ),
            GuideSafetyScenario.newbornBreathingDifficulty: (
              id: 'baby-breathing',
              audience: GuideAudience.baby,
              urgency: GuideUrgency.emergency,
            ),
            GuideSafetyScenario.newbornPoorFeeding: (
              id: 'baby-feeding-change',
              audience: GuideAudience.baby,
              urgency: GuideUrgency.contactClinician,
            ),
            GuideSafetyScenario.newbornJaundice: (
              id: 'baby-jaundice',
              audience: GuideAudience.baby,
              urgency: GuideUrgency.contactClinician,
            ),
          };

      expect(expected.keys.toSet(), GuideSafetyScenario.values.toSet());
      for (final scenario in GuideSafetyScenario.values) {
        final matches = guideEntries
            .where((entry) => entry.safetyScenarios.contains(scenario))
            .toList();
        final target = expected[scenario]!;
        expect(matches, hasLength(1), reason: scenario.name);
        expect(matches.single.id, target.id);
        expect(matches.single.audience, target.audience);
        expect(matches.single.urgency, target.urgency);
      }
    });

    test('urgent action copy cannot reassure a woman or tell her to wait', () {
      const prohibitedActionPhrases = <String>[
        'you are fine',
        'nothing to worry about',
        'wait and see',
        'probably normal',
        'just normal',
      ];

      for (final entry in guideEntries.where(
        (entry) => entry.urgency != GuideUrgency.learn,
      )) {
        final action = entry.action.toLowerCase();
        for (final phrase in prohibitedActionPhrases) {
          expect(action, isNot(contains(phrase)), reason: entry.id);
        }
        expect(
          action.contains('clinician') ||
              action.contains('medical care') ||
              action.contains('emergency') ||
              action.contains('call 911'),
          isTrue,
          reason: '${entry.id} lacks a professional-care handoff',
        );
      }
    });

    test('every shipped source id is controlled by the clinical registry', () {
      final registry = File('docs/governance/CLINICAL_CONTENT_REGISTRY.md')
          .readAsStringSync();

      for (final entry in guideEntries) {
        expect(
          registry,
          contains('| ${entry.sourceId} |'),
          reason: '${entry.id} has an unregistered source',
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
