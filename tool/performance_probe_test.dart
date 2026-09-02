import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../test/support/performance_fixture.dart';
import 'performance_probe.dart';

void main() {
  test('governed 1000-record and 20-migration workload passes', () async {
    final result = await runHarborPerformanceProbe();

    expect(result.passed, isTrue);
    expect(result.totalRecords, performanceAcceptanceRecordCount);
    expect(result.migrationRuns, performanceAcceptanceMigrationRuns);
    expect(
      result.migratedRecordsVerified,
      performanceAcceptanceRecordCount * performanceAcceptanceMigrationRuns,
    );
    stdout.writeln('HARBOR_PERFORMANCE_RESULT ${jsonEncode(result.toJson())}');
  });
}
