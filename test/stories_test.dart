import 'package:flutter_test/flutter_test.dart';
import 'package:harbor_app/content/stories.dart';

void main() {
  group('offline story catalog', () {
    test('is uniquely identified and explicitly non-live', () {
      expect(storyEntries.length, greaterThanOrEqualTo(6));
      expect(
        storyEntries.map((story) => story.id).toSet().length,
        storyEntries.length,
      );
      expect(
        storyEntries.map((story) => story.provenance.id).toSet().length,
        storyEntries.length,
      );
      for (final story in storyEntries) {
        expect(story.title.trim(), isNotEmpty);
        expect(story.body.trim(), isNotEmpty);
        expect(
          story.provenance.origin,
          contains('not a participant quotation'),
        );
        expect(story.provenance.origin, contains('not a member post'));
        expect(story.provenance.reviewStatus, pendingLivedExperienceReview);
        expect(story.provenance.revision, storyCatalogVersion);
      }
    });

    test('covers every declared topic and supports local search', () {
      expect(
        storyEntries.map((story) => story.topic).toSet(),
        StoryTopic.values.toSet(),
      );
      expect(
        storyEntries.where((story) => story.matches('feeding')).single.id,
        'story-feeding-no-purity-test',
      );
      expect(
        storyEntries.where((story) => story.matches('minimize it')).single.id,
        'story-being-heard-not-dismissed',
      );
      expect(storyEntries.where((story) => story.matches('')), hasLength(6));
    });

    test('contains no simulated popularity or live-post metadata', () {
      for (final story in storyEntries) {
        final serialized =
            '${story.title} ${story.body} ${story.provenance.origin}'
                .toLowerCase();
        expect(serialized, isNot(contains('likes')));
        expect(serialized, isNot(contains('followers')));
        expect(serialized, isNot(contains('posted by')));
        expect(serialized, isNot(contains('minutes ago')));
      }
    });
  });
}
