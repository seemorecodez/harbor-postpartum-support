import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:harbor_app/core/journal_search.dart';
import 'package:harbor_app/core/models.dart';

import '../tool/performance_probe.dart';
import 'support/performance_fixture.dart';

void main() {
  test('journal search normalizes input and preserves record order', () {
    final entries = [
      JournalEntry(id: 'first', title: 'Quiet Morning', body: 'Asked for tea.'),
      JournalEntry(id: 'second', title: 'Evening', body: 'A QUIET room.'),
      JournalEntry(id: 'third', title: 'Outside', body: 'Fresh air.'),
    ];

    expect(
      searchJournalEntries(entries, '  quiet  ').map((entry) => entry.id),
      ['first', 'second'],
    );
    expect(searchJournalEntries(entries, '   '), entries);
  });

  test('scaled workload preserves encrypted data across migrations', () async {
    final result = await runHarborPerformanceProbe(
      totalRecords: 40,
      migrationRuns: 3,
      searchIterations: 3,
    );

    expect(result.passed, isTrue);
    expect(result.totalRecords, 40);
    expect(result.checkIns, 20);
    expect(result.journalEntries, 20);
    expect(result.migratedRecordsVerified, 120);
    expect(result.encryptedRecordBytes, greaterThan(0));
  });

  test('public CI runs the full governed workload', () async {
    expect(performanceAcceptanceRecordCount, 1000);
    expect(performanceAcceptanceMigrationRuns, 20);
    expect(performanceAcceptanceSearchIterations, 25);
    expect(
      performanceAcceptanceSearchThreshold,
      const Duration(milliseconds: 300),
    );
    final workflow = await File('.github/workflows/ci.yml').readAsString();
    expect(
      workflow,
      contains('flutter test --no-pub tool/performance_probe_test.dart'),
    );
    expect(
      workflow,
      contains(
        'timeout 5m xvfb-run --auto-servernum\n'
        '          flutter test --no-pub --platform chrome\n'
        '          test/browser_performance_test.dart',
      ),
    );
  });
}
