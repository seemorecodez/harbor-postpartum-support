enum GuideAudience { woman, baby }

enum GuideUrgency { learn, contactClinician, emergency }

enum GuideSafetyScenario {
  postpartumHemorrhage,
  postpartumPreeclampsia,
  postpartumInfection,
  postpartumPsychosis,
  suicidality,
  newbornFever,
  newbornBreathingDifficulty,
  newbornPoorFeeding,
  newbornJaundice,
}

const guideCatalogVersion = '2026.08.31-source-draft.2';
const guideReviewStatus =
    'Clinical and women-led lived-experience approval pending';

final class GuideEntry {
  const GuideEntry({
    required this.id,
    required this.audience,
    required this.stages,
    required this.urgency,
    required this.title,
    required this.summary,
    required this.action,
    required this.sourceId,
    required this.sourceLabel,
    required this.sourceReviewed,
    this.safetyScenarios = const <GuideSafetyScenario>{},
  });

  final String id;
  final GuideAudience audience;
  final Set<String> stages;
  final GuideUrgency urgency;
  final String title;
  final String summary;
  final String action;
  final String sourceId;
  final String sourceLabel;
  final String sourceReviewed;
  final Set<GuideSafetyScenario> safetyScenarios;

  bool matches(String query) {
    final value = query.trim().toLowerCase();
    if (value.isEmpty) return true;
    return '$title $summary $action $sourceLabel'.toLowerCase().contains(value);
  }
}

const guideEntries = <GuideEntry>[
  GuideEntry(
    id: 'woman-recovery-early',
    audience: GuideAudience.woman,
    stages: {'0-6 weeks'},
    urgency: GuideUrgency.learn,
    title: 'Your body is healing from a major event',
    summary: 'Bleeding, cramping, back or joint pain, perineal or incision pain, swollen breasts, and bladder or bowel changes can occur after birth. The intensity and duration vary widely between women.',
    action: 'Ask your clinician about anything that worries you or makes it hard to care for yourself or your baby. "Common" never means you must endure it silently.',
    sourceId: 'ACOG-PP-PAIN-2025',
    sourceLabel: 'ACOG, Postpartum Pain Management',
    sourceReviewed: 'Accessed 2026-08-30',
  ),
  GuideEntry(
    id: 'woman-heavy-bleeding',
    audience: GuideAudience.woman,
    stages: {'0-6 weeks', '7-12 weeks'},
    urgency: GuideUrgency.contactClinician,
    title: 'Bleeding that is much heavier than expected',
    summary: 'Very heavy or gushing bleeding, large clots, faintness, weakness, clammy skin, confusion, or a racing heart can signal a serious postpartum problem.',
    action: 'Contact your obstetric clinician now. If you cannot reach them, feel faint, or believe you need immediate care, call emergency services or go to an emergency department.',
    sourceId: 'ACOG-PP-HEMORRHAGE-2022',
    sourceLabel: 'ACOG, Conditions to Watch After Childbirth',
    sourceReviewed: 'Accessed 2026-08-30',
    safetyScenarios: {GuideSafetyScenario.postpartumHemorrhage},
  ),
  GuideEntry(
    id: 'woman-headache-vision',
    audience: GuideAudience.woman,
    stages: {'0-6 weeks', '7-12 weeks'},
    urgency: GuideUrgency.contactClinician,
    title: 'A severe headache or vision changes',
    summary: 'A headache that does not improve, a severe headache with vision changes, sudden face or hand swelling, or upper-right abdominal pain may need urgent assessment after birth.',
    action: 'Call your obstetric clinician now. If symptoms feel severe, you cannot reach them, or you feel unsafe, seek emergency care.',
    sourceId: 'ACOG-PP-PREECLAMPSIA-2022',
    sourceLabel: 'ACOG, Conditions to Watch After Childbirth',
    sourceReviewed: 'Accessed 2026-08-30',
    safetyScenarios: {GuideSafetyScenario.postpartumPreeclampsia},
  ),
  GuideEntry(
    id: 'woman-postpartum-infection',
    audience: GuideAudience.woman,
    stages: {'0-6 weeks', '7-12 weeks'},
    urgency: GuideUrgency.contactClinician,
    title: 'Fever, chills, belly tenderness, or bad-smelling discharge',
    summary: 'A fever of 100.4 F (38 C) or higher, chills, worsening lower-belly pain or tenderness, or vaginal discharge that smells bad can be a sign of a serious infection after birth.',
    action: 'Get medical care right away and tell them you gave birth within the last year. Call your obstetric clinician now; if you cannot reach them, go to an emergency department.',
    sourceId: 'ACOG-PP-ENDOMETRITIS-2026',
    sourceLabel: 'ACOG, 3 Conditions to Watch for After Childbirth',
    sourceReviewed: 'Accessed 2026-08-31',
    safetyScenarios: {GuideSafetyScenario.postpartumInfection},
  ),
  GuideEntry(
    id: 'woman-postpartum-psychosis',
    audience: GuideAudience.woman,
    stages: {'0-6 weeks', '7-12 weeks', '3-6 months', '7-12 months'},
    urgency: GuideUrgency.emergency,
    title: 'Hallucinations, delusions, mania, paranoia, or confusion',
    summary: 'Seeing, hearing, or smelling things that are not there; beliefs that are not true; an unusually high or elated mood that seems out of touch with reality; paranoia; or confusion after birth can be symptoms of postpartum psychosis.',
    action: 'Postpartum psychosis is a psychiatric emergency. Call emergency services now—in the U.S., call 911—or go to the nearest emergency room. Harbor cannot assess or monitor these symptoms.',
    sourceId: 'NIMH-PERINATAL-DEPRESSION-2026',
    sourceLabel: 'National Institute of Mental Health, Perinatal Depression',
    sourceReviewed: 'Accessed 2026-08-31',
    safetyScenarios: {GuideSafetyScenario.postpartumPsychosis},
  ),
  GuideEntry(
    id: 'woman-emergency',
    audience: GuideAudience.woman,
    stages: {'0-6 weeks', '7-12 weeks', '3-6 months', '7-12 months'},
    urgency: GuideUrgency.emergency,
    title: 'Chest pain, gasping, seizure, or immediate danger',
    summary: 'Chest pain, coughing or gasping for air, a seizure, thoughts of hurting yourself or your baby, severe lower-abdominal pain, or painful leg swelling require immediate help.',
    action: 'Call emergency services now. In the U.S., call 911. Harbor cannot make the call or monitor you.',
    sourceId: 'ACOG-PP-PAIN-2025',
    sourceLabel: 'ACOG, Postpartum Pain Management',
    sourceReviewed: 'Accessed 2026-08-30',
    safetyScenarios: {GuideSafetyScenario.suicidality},
  ),
  GuideEntry(
    id: 'woman-baby-blues',
    audience: GuideAudience.woman,
    stages: {'0-6 weeks'},
    urgency: GuideUrgency.learn,
    title: 'Baby blues and postpartum depression are not the same',
    summary: 'Temporary tearfulness, anxiety, or feeling upset can begin a few days after birth and often eases within one to two weeks. Intense sadness, anxiety, or despair that interferes with daily life may be postpartum depression.',
    action: 'If you think you may have postpartum depression, contact your obstetric clinician or another health professional now rather than waiting for a routine postpartum visit.',
    sourceId: 'ACOG-PPD-2025',
    sourceLabel: 'ACOG, Postpartum Depression',
    sourceReviewed: 'Reviewed by source December 2025',
  ),
  GuideEntry(
    id: 'woman-mood-anytime',
    audience: GuideAudience.woman,
    stages: {'0-6 weeks', '7-12 weeks', '3-6 months', '7-12 months'},
    urgency: GuideUrgency.contactClinician,
    title: 'Depression or anxiety can begin anytime in the first year',
    summary: 'Postpartum depression can occur during the first year after birth. Shame, anger, numbness, fear, intrusive thoughts, or feeling disconnected also deserve care even when they do not match a stereotype.',
    action: 'Contact an obstetric, primary-care, or mental-health professional. If thoughts of harm or immediate danger are present, use emergency or crisis support now.',
    sourceId: 'ACOG-PPD-2025',
    sourceLabel: 'ACOG, Postpartum Depression',
    sourceReviewed: 'Reviewed by source December 2025',
  ),
  GuideEntry(
    id: 'baby-feeding-change',
    audience: GuideAudience.baby,
    stages: {'0-6 weeks'},
    urgency: GuideUrgency.contactClinician,
    title: 'A newborn is suddenly feeding poorly',
    summary: 'A sudden change in feeding, weak sucking, difficulty finishing feeds, unusual sleepiness, or a newborn who looks or acts different can be an early sign of illness.',
    action: "Call your baby's clinician now. Newborn illness can be subtle; you do not need to wait for more dramatic symptoms.",
    sourceId: 'AAP-NEWBORN-ILLNESS',
    sourceLabel: 'American Academy of Pediatrics, Newborn Illness',
    sourceReviewed: 'Accessed 2026-08-30',
    safetyScenarios: {GuideSafetyScenario.newbornPoorFeeding},
  ),
  GuideEntry(
    id: 'baby-fever',
    audience: GuideAudience.baby,
    stages: {'0-6 weeks', '7-12 weeks'},
    urgency: GuideUrgency.emergency,
    title: 'Fever in a baby younger than three months',
    summary: 'A temperature of 100.4 F (38 C) or higher in a baby under three months needs prompt medical evaluation because young infants can become seriously ill quickly.',
    action: "Seek immediate medical care and contact your baby's clinician. Do not use Harbor to decide whether to wait.",
    sourceId: 'AAP-INFANT-FEVER-2025',
    sourceLabel: 'American Academy of Pediatrics, Fever and Your Baby',
    sourceReviewed: 'Accessed 2026-08-30',
    safetyScenarios: {GuideSafetyScenario.newbornFever},
  ),
  GuideEntry(
    id: 'baby-breathing',
    audience: GuideAudience.baby,
    stages: {'0-6 weeks', '7-12 weeks', '3-6 months', '7-12 months'},
    urgency: GuideUrgency.emergency,
    title: 'Trouble breathing, blue or gray color, or hard to wake',
    summary: 'Blue or gray lips, tongue, or face; grunting with each breath; being very weak; not moving; or being unable to wake can signal a life-threatening emergency.',
    action: 'Call emergency services now. Harbor cannot assess breathing or monitor your baby.',
    sourceId: 'AAP-NEWBORN-ILLNESS',
    sourceLabel: 'American Academy of Pediatrics, Newborn Illness',
    sourceReviewed: 'Accessed 2026-08-30',
    safetyScenarios: {GuideSafetyScenario.newbornBreathingDifficulty},
  ),
  GuideEntry(
    id: 'baby-jaundice',
    audience: GuideAudience.baby,
    stages: {'0-6 weeks'},
    urgency: GuideUrgency.contactClinician,
    title: 'Yellow skin or eyes, especially with poor feeding',
    summary: "Jaundice is common in newborns, but bilirubin can sometimes become dangerously high. Yellowing that spreads, hard-to-wake behavior, fussiness, or poor feeding needs a clinician's advice.",
    action: "Call your baby's clinician. Jaundice in the first 24 hours needs prompt bilirubin measurement, and sunlight is not a safe treatment.",
    sourceId: 'AAP-JAUNDICE-2024',
    sourceLabel: 'American Academy of Pediatrics, Jaundice in Newborns',
    sourceReviewed: 'Updated by source August 2024',
    safetyScenarios: {GuideSafetyScenario.newbornJaundice},
  ),
];
