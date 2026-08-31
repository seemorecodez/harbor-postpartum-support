enum StoryTopic {
  identity('Identity'),
  anger('Anger'),
  bodyAutonomy('Body autonomy'),
  feeding('Feeding'),
  loneliness('Loneliness'),
  beingHeard('Being heard');

  const StoryTopic(this.label);

  final String label;
}

final class StoryProvenance {
  const StoryProvenance({
    required this.id,
    required this.origin,
    required this.reviewStatus,
    required this.revision,
  });

  final String id;
  final String origin;
  final String reviewStatus;
  final String revision;
}

final class HarborStory {
  const HarborStory({
    required this.id,
    required this.topic,
    required this.title,
    required this.body,
    required this.provenance,
    this.contentNote,
  });

  final String id;
  final StoryTopic topic;
  final String title;
  final String body;
  final StoryProvenance provenance;
  final String? contentNote;

  bool matches(String query) {
    final value = query.trim().toLowerCase();
    if (value.isEmpty) return true;
    return '$title $body ${topic.label} ${contentNote ?? ''}'
        .toLowerCase()
        .contains(value);
  }
}

const storyCatalogVersion = '2026.08.30-editorial-draft.1';
const pendingLivedExperienceReview =
    'Awaiting compensated women-led lived-experience review';

const storyEntries = <HarborStory>[
  HarborStory(
    id: 'story-identity-intact-self',
    topic: StoryTopic.identity,
    title: 'Motherhood did not erase the rest of me',
    body: 'I can love my baby and still miss uninterrupted time, old routines, and the parts of myself that do not answer to anyone else. Both truths fit in the same life. Wanting an intact self is not a failure of love.',
    provenance: StoryProvenance(
      id: 'HBR-STORY-PROV-001',
      origin: 'Harbor editorial draft adapted from the prototype identity theme; not a participant quotation and not a member post',
      reviewStatus: pendingLivedExperienceReview,
      revision: storyCatalogVersion,
    ),
  ),
  HarborStory(
    id: 'story-anger-invisible-load',
    topic: StoryTopic.anger,
    title: 'I needed somewhere to name my anger',
    body: 'I was keeping track of feeds, laundry, appointments, visitors, and everybody else’s feelings. I felt furious and ashamed of feeling furious. Writing down the work helped me see that I needed rest, practical help, and room to speak plainly.',
    contentNote: 'Mentions anger, shame, and exhaustion.',
    provenance: StoryProvenance(
      id: 'HBR-STORY-PROV-002',
      origin: 'Harbor editorial draft adapted from the prototype anger and invisible-care themes; not a participant quotation and not a member post',
      reviewStatus: pendingLivedExperienceReview,
      revision: storyCatalogVersion,
    ),
  ),
  HarborStory(
    id: 'story-body-boundary',
    topic: StoryTopic.bodyAutonomy,
    title: 'My body and my recovery still belong to me',
    body: 'I did not want to host visitors while I was bleeding, sore, and learning how to care for a newborn. I asked people to wait and told my family that help meant bringing food or doing a task—not expecting access to me or the baby. The boundary felt awkward. The quiet felt necessary.',
    contentNote: 'Mentions postpartum bleeding and physical recovery.',
    provenance: StoryProvenance(
      id: 'HBR-STORY-PROV-003',
      origin: 'Harbor editorial draft adapted from the prototype body-autonomy theme; not a participant quotation and not a member post',
      reviewStatus: pendingLivedExperienceReview,
      revision: storyCatalogVersion,
    ),
  ),
  HarborStory(
    id: 'story-feeding-no-purity-test',
    topic: StoryTopic.feeding,
    title: 'Feeding was not a purity test',
    body: 'The plan I made before birth stopped working for my body and my mental health. I changed it. My baby needed to be fed and held; I needed care and sleep. I deserved useful support instead of judgment about how we got there.',
    contentNote: 'Mentions feeding pressure and mental health.',
    provenance: StoryProvenance(
      id: 'HBR-STORY-PROV-004',
      origin: 'Harbor editorial draft adapted from the prototype feeding theme; not a participant quotation and not a member post',
      reviewStatus: pendingLivedExperienceReview,
      revision: storyCatalogVersion,
    ),
  ),
  HarborStory(
    id: 'story-loneliness-company',
    topic: StoryTopic.loneliness,
    title: 'I was rarely alone and still deeply lonely',
    body: 'People asked about the baby and told me how lucky I was. I needed somebody to ask about me and stay long enough to hear the honest answer. Gratitude did not cancel loneliness, and loneliness did not make me ungrateful.',
    contentNote: 'Mentions loneliness and emotional isolation.',
    provenance: StoryProvenance(
      id: 'HBR-STORY-PROV-005',
      origin: 'Harbor editorial draft created for the offline catalog; not a participant quotation and not a member post',
      reviewStatus: pendingLivedExperienceReview,
      revision: storyCatalogVersion,
    ),
  ),
  HarborStory(
    id: 'story-being-heard-not-dismissed',
    topic: StoryTopic.beingHeard,
    title: 'I wrote it down so I would not minimize it',
    body: 'By the time an appointment came, I had started telling myself the hard days were not serious enough to mention. I brought a short list of what had changed, what was getting harder, and what help I was asking for. My questions deserved time even when I could not explain everything perfectly.',
    contentNote: 'Mentions difficulty asking for professional support.',
    provenance: StoryProvenance(
      id: 'HBR-STORY-PROV-006',
      origin: 'Harbor editorial draft created for the clinician-question theme; not a participant quotation and not a member post',
      reviewStatus: pendingLivedExperienceReview,
      revision: storyCatalogVersion,
    ),
  ),
];
