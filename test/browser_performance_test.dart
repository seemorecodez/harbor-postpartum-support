import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor_app/app.dart';
import 'package:harbor_app/core/controller.dart';
import 'package:harbor_app/core/vault.dart';

import 'support/performance_fixture.dart';
import 'support/performance_platform.dart';

const _navigationThreshold = Duration(milliseconds: 150);

void main() {
  testWidgets('1000-record journal navigation and search meet UI thresholds', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final vault = HarborVault(
      records: MemoryValueStore(),
      keys: MemoryValueStore(),
    );
    await vault.save(
      buildHarborPerformanceData(
        totalRecords: performanceAcceptanceRecordCount,
        cycle: 0,
      ),
    );
    final controller = HarborController(vault);
    await controller.initialize();

    await tester.pumpWidget(HarborApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Journal'));
    final navigationWatch = Stopwatch()..start();
    await tester.pump();
    navigationWatch.stop();

    expect(find.byKey(const ValueKey('journal_lazy_scroll')), findsOneWidget);
    expect(find.byType(Card).evaluate().length, lessThan(50));
    expect(navigationWatch.elapsed, lessThanOrEqualTo(_navigationThreshold));

    final search = find.byKey(const ValueKey('journal_search_field'));
    const targetQuery = 'TARGET JOURNAL 0 499';
    for (var warmup = 0; warmup < 5; warmup++) {
      await tester.enterText(search, warmup.isEven ? targetQuery : 'missing');
      await tester.pump();
    }

    var maximumSearchMicroseconds = 0;
    for (
      var iteration = 0;
      iteration < performanceAcceptanceSearchIterations;
      iteration++
    ) {
      await tester.enterText(
        search,
        iteration.isEven ? targetQuery : 'missing-$iteration',
      );
      final watch = Stopwatch()..start();
      await tester.pump();
      watch.stop();
      if (watch.elapsedMicroseconds > maximumSearchMicroseconds) {
        maximumSearchMicroseconds = watch.elapsedMicroseconds;
      }
    }

    await tester.enterText(search, targetQuery);
    await tester.pump();
    expect(find.text('Target journal 0 499'), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
    expect(
      maximumSearchMicroseconds,
      lessThanOrEqualTo(performanceAcceptanceSearchThreshold.inMicroseconds),
    );

    final isBrowserCompiled = performancePlatformLabel == 'web';
    final scope = isBrowserCompiled
        ? 'flutter-browser-compiled-widget-navigation-and-journal-search'
        : 'flutter-widget-navigation-and-journal-search';
    final limitations = isBrowserCompiled
        ? 'Compiled browser-engine Flutter test with memory storage; not '
              'release/profile tracing, plugin storage, browser executable '
              'cold start, or a browser/device matrix.'
        : 'Flutter widget-test timing with memory storage; not release/profile '
              'tracing, plugin storage, cold start, or a device matrix.';

    debugPrint(
      'HARBOR_UI_PERFORMANCE_RESULT ${jsonEncode({'status': 'passed', 'scope': scope, 'platform': performancePlatformLabel, 'totalRecords': performanceAcceptanceRecordCount, 'journalEntries': performanceAcceptanceRecordCount ~/ 2, 'navigationMicroseconds': navigationWatch.elapsedMicroseconds, 'navigationThresholdMicroseconds': _navigationThreshold.inMicroseconds, 'searchIterations': performanceAcceptanceSearchIterations, 'searchMaximumMicroseconds': maximumSearchMicroseconds, 'searchThresholdMicroseconds': performanceAcceptanceSearchThreshold.inMicroseconds, 'renderedCardsAfterSearch': 1, 'limitations': limitations})}',
    );
  });
}
