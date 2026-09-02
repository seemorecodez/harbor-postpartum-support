import 'package:harbor_app/core/models.dart';

const performanceAcceptanceRecordCount = 1000;
const performanceAcceptanceMigrationRuns = 20;
const performanceAcceptanceSearchIterations = 25;
const performanceAcceptanceSearchThreshold = Duration(milliseconds: 300);
const performanceSyntheticPrivateSentinel =
    'HARBOR-PERFORMANCE-PRIVATE-SENTINEL';

HarborData buildHarborPerformanceData({
  required int totalRecords,
  required int cycle,
}) {
  final checkInCount = totalRecords ~/ 2;
  final journalCount = totalRecords - checkInCount;
  final base = DateTime.utc(2026, 1, 1).add(Duration(days: cycle));
  return HarborData(
    onboardingComplete: true,
    postpartumStage: '3-6 months',
    checkIns: List<CheckIn>.generate(
      checkInCount,
      (index) => CheckIn(
        id: 'check-in-$cycle-$index',
        createdAt: base.add(Duration(minutes: index)),
        mood: 1 + index % 5,
        anxiety: 1 + (index + 1) % 5,
        rest: 1 + (index + 2) % 5,
        note: '$performanceSyntheticPrivateSentinel check-in $cycle $index',
      ),
    ),
    journalEntries: List<JournalEntry>.generate(
      journalCount,
      (index) => JournalEntry(
        id: 'journal-$cycle-$index',
        createdAt: base.add(Duration(minutes: checkInCount + index)),
        updatedAt: base.add(Duration(minutes: checkInCount + index + 1)),
        title: index == journalCount - 1
            ? 'Target journal $cycle $index'
            : 'Journal $cycle $index',
        body: '$performanceSyntheticPrivateSentinel journal $cycle $index',
      ),
    ),
    clinicianQuestions: [
      ClinicianQuestion(
        id: 'question-$cycle',
        text: '$performanceSyntheticPrivateSentinel question $cycle',
      ),
    ],
    hardDayPlan: const HardDayPlan(
      safePerson: 'Synthetic support person',
      safePersonPhone: '5550100',
      groundingStep: 'Synthetic grounding step',
      practicalHelp: 'Synthetic practical help',
    ),
  );
}
