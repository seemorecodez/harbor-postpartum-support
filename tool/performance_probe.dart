import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:harbor_app/core/journal_search.dart';
import 'package:harbor_app/core/models.dart';
import 'package:harbor_app/core/vault.dart';

import '../test/support/performance_fixture.dart';
import '../test/support/performance_platform.dart';

final class HarborPerformanceProbeResult {
  const HarborPerformanceProbeResult({
    required this.totalRecords,
    required this.checkIns,
    required this.journalEntries,
    required this.encryptedRecordBytes,
    required this.saveMicroseconds,
    required this.reloadMicroseconds,
    required this.migrationRuns,
    required this.migratedRecordsVerified,
    required this.migrationTotalMicroseconds,
    required this.migrationMaximumMicroseconds,
    required this.searchIterations,
    required this.searchMaximumMicroseconds,
    required this.searchThresholdMicroseconds,
  });

  final int totalRecords;
  final int checkIns;
  final int journalEntries;
  final int encryptedRecordBytes;
  final int saveMicroseconds;
  final int reloadMicroseconds;
  final int migrationRuns;
  final int migratedRecordsVerified;
  final int migrationTotalMicroseconds;
  final int migrationMaximumMicroseconds;
  final int searchIterations;
  final int searchMaximumMicroseconds;
  final int searchThresholdMicroseconds;

  bool get passed =>
      totalRecords == checkIns + journalEntries &&
      migratedRecordsVerified == totalRecords * migrationRuns &&
      searchMaximumMicroseconds <= searchThresholdMicroseconds;

  Map<String, Object> toJson() => {
    'status': passed ? 'passed' : 'failed',
    'scope': 'shared-production-vault-and-search-code',
    'platform': performancePlatformLabel,
    'totalRecords': totalRecords,
    'checkIns': checkIns,
    'journalEntries': journalEntries,
    'encryptedRecordBytes': encryptedRecordBytes,
    'saveMicroseconds': saveMicroseconds,
    'reloadMicroseconds': reloadMicroseconds,
    'migrationRuns': migrationRuns,
    'migratedRecordsVerified': migratedRecordsVerified,
    'migrationTotalMicroseconds': migrationTotalMicroseconds,
    'migrationMaximumMicroseconds': migrationMaximumMicroseconds,
    'searchIterations': searchIterations,
    'searchMaximumMicroseconds': searchMaximumMicroseconds,
    'searchThresholdMicroseconds': searchThresholdMicroseconds,
    'limitations': 'This does not measure device launch, UI navigation, plugin storage, or signed application performance.',
  };
}

Future<HarborPerformanceProbeResult> runHarborPerformanceProbe({
  int totalRecords = performanceAcceptanceRecordCount,
  int migrationRuns = performanceAcceptanceMigrationRuns,
  int searchIterations = performanceAcceptanceSearchIterations,
}) async {
  if (totalRecords < 2 || migrationRuns < 1 || searchIterations < 1) {
    throw ArgumentError('Harbor performance workload values are invalid.');
  }

  final currentData = buildHarborPerformanceData(
    totalRecords: totalRecords,
    cycle: 0,
  );
  final records = MemoryValueStore();
  final keys = MemoryValueStore();
  final vault = HarborVault(records: records, keys: keys);

  final saveWatch = Stopwatch()..start();
  await vault.save(currentData);
  saveWatch.stop();
  final encrypted = records.values[HarborVault.recordKey];
  if (encrypted == null ||
      encrypted.contains(performanceSyntheticPrivateSentinel)) {
    throw StateError('Harbor encrypted-record verification failed.');
  }

  final reloadWatch = Stopwatch()..start();
  final reloaded = await HarborVault(records: records, keys: keys).load();
  reloadWatch.stop();
  if (reloaded.encode() != currentData.encode()) {
    throw StateError('Harbor record reload lost data.');
  }

  for (var warmup = 0; warmup < 5; warmup++) {
    _verifySearch(currentData, totalRecords);
  }
  var searchMaximumMicroseconds = 0;
  for (var iteration = 0; iteration < searchIterations; iteration++) {
    final watch = Stopwatch()..start();
    _verifySearch(currentData, totalRecords);
    watch.stop();
    if (watch.elapsedMicroseconds > searchMaximumMicroseconds) {
      searchMaximumMicroseconds = watch.elapsedMicroseconds;
    }
  }

  var migrationTotalMicroseconds = 0;
  var migrationMaximumMicroseconds = 0;
  for (var cycle = 1; cycle <= migrationRuns; cycle++) {
    final expected = buildHarborPerformanceData(
      totalRecords: totalRecords,
      cycle: cycle,
    );
    final keyBytes = List<int>.generate(32, (index) => index + cycle);
    final legacyEnvelope = await _legacyEnvelope(expected, keyBytes);
    final migrationRecords = MemoryValueStore({
      HarborVault.recordKey: legacyEnvelope,
    });
    final migrationKeys = MemoryValueStore({
      HarborVault.encryptionKey: base64Encode(keyBytes),
    });
    final watch = Stopwatch()..start();
    final migrated = await HarborVault(
      records: migrationRecords,
      keys: migrationKeys,
    ).load();
    watch.stop();
    migrationTotalMicroseconds += watch.elapsedMicroseconds;
    if (watch.elapsedMicroseconds > migrationMaximumMicroseconds) {
      migrationMaximumMicroseconds = watch.elapsedMicroseconds;
    }
    if (migrated.encode() != expected.encode()) {
      throw StateError('Harbor migration lost data.');
    }
    if (migrationRecords.values[HarborVault.migrationRecordKey] != null) {
      throw StateError('Harbor migration left staging data behind.');
    }
    final restarted = await HarborVault(
      records: migrationRecords,
      keys: migrationKeys,
    ).load();
    if (restarted.encode() != expected.encode()) {
      throw StateError('Harbor migrated restart lost data.');
    }
    final migratedEnvelope = migrationRecords.values[HarborVault.recordKey];
    if (migratedEnvelope == null ||
        migratedEnvelope.contains(performanceSyntheticPrivateSentinel)) {
      throw StateError(
        'Harbor migrated-record encryption verification failed.',
      );
    }
  }

  final result = HarborPerformanceProbeResult(
    totalRecords: totalRecords,
    checkIns: currentData.checkIns.length,
    journalEntries: currentData.journalEntries.length,
    encryptedRecordBytes: utf8.encode(encrypted).length,
    saveMicroseconds: saveWatch.elapsedMicroseconds,
    reloadMicroseconds: reloadWatch.elapsedMicroseconds,
    migrationRuns: migrationRuns,
    migratedRecordsVerified: totalRecords * migrationRuns,
    migrationTotalMicroseconds: migrationTotalMicroseconds,
    migrationMaximumMicroseconds: migrationMaximumMicroseconds,
    searchIterations: searchIterations,
    searchMaximumMicroseconds: searchMaximumMicroseconds,
    searchThresholdMicroseconds:
        performanceAcceptanceSearchThreshold.inMicroseconds,
  );
  if (!result.passed) {
    throw StateError('Harbor performance acceptance workload failed.');
  }
  return result;
}

void _verifySearch(HarborData data, int totalRecords) {
  final journalCount = totalRecords - totalRecords ~/ 2;
  final result = searchJournalEntries(
    data.journalEntries,
    '  TARGET JOURNAL 0 ${journalCount - 1}  ',
  );
  if (result.length != 1 ||
      result.single.id != 'journal-0-${journalCount - 1}') {
    throw StateError('Harbor journal search returned the wrong record.');
  }
}

Future<String> _legacyEnvelope(HarborData data, List<int> keyBytes) async {
  final legacy = Map<String, Object?>.from(data.toJson())
    ..['schemaVersion'] = 1
    ..remove('careLoadItems')
    ..remove('careAskDraft')
    ..remove('resonatedStoryIds');
  final box = await AesGcm.with256bits().encrypt(
    utf8.encode(jsonEncode(legacy)),
    secretKey: SecretKey(keyBytes),
    aad: utf8.encode(HarborVault.associatedData),
  );
  return jsonEncode({
    'version': 1,
    'cipher': 'AES-256-GCM',
    'nonce': base64Encode(box.nonce),
    'cipherText': base64Encode(box.cipherText),
    'mac': base64Encode(box.mac.bytes),
  });
}
