import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:harbor_app/core/diagnostics.dart';
import 'package:harbor_app/core/models.dart';
import 'package:harbor_app/core/release_info.dart';
import 'package:harbor_app/core/vault.dart';

void main() {
  test('diagnostic payload has an exact non-personal allowlist', () {
    final report = HarborDiagnosticReport.create(
      platform: HarborDiagnosticPlatform.web,
      error: null,
    );
    final decoded = jsonDecode(report.encode()) as Map<String, Object?>;

    expect(decoded.keys.toList(), <String>[
      'applicationVersion',
      'buildNumber',
      'platform',
      'dataSchemaVersion',
      'errorCode',
    ]);
    expect(decoded, <String, Object?>{
      'applicationVersion': HarborReleaseInfo.version,
      'buildNumber': HarborReleaseInfo.buildNumber,
      'platform': 'web',
      'dataSchemaVersion': HarborData.currentSchemaVersion,
      'errorCode': 'none',
    });
  });

  test('known vault failures map to bounded error codes', () {
    final cases = <Object, HarborDiagnosticErrorCode>{
      const UnsupportedHarborDataVersionException(99):
          HarborDiagnosticErrorCode.unsupportedDataSchema,
      const UnsupportedHarborVaultVersionException(99):
          HarborDiagnosticErrorCode.unsupportedVaultEnvelope,
      const HarborVaultKeyMissingException():
          HarborDiagnosticErrorCode.keyMissing,
      const HarborVaultCorruptException():
          HarborDiagnosticErrorCode.corruptVault,
      const HarborVaultMigrationException():
          HarborDiagnosticErrorCode.migrationFailed,
    };

    for (final entry in cases.entries) {
      final report = HarborDiagnosticReport.create(
        platform: HarborDiagnosticPlatform.windows,
        error: entry.key,
      );
      expect(report.errorCode, entry.value, reason: '${entry.key}');
      expect(report.encode(), contains('"errorCode": "${entry.value.code}"'));
      expect(report.encode(), isNot(contains('99')));
    }
  });

  test('unknown exception text cannot enter diagnostic output', () {
    const privateExceptionText =
        'PRIVATE JOURNAL VALUE THAT MUST NEVER BE EXPORTED';
    final report = HarborDiagnosticReport.create(
      platform: HarborDiagnosticPlatform.android,
      error: StateError(privateExceptionText),
    );

    expect(report.errorCode, HarborDiagnosticErrorCode.vaultUnavailable);
    expect(report.encode(), contains('"errorCode": "vault_unavailable"'));
    expect(report.encode(), isNot(contains(privateExceptionText)));
    expect(report.semanticLabel, isNot(contains(privateExceptionText)));
  });

  test('diagnostic output excludes tracking and personal-data fields', () {
    final payload = HarborDiagnosticReport.create(
      platform: HarborDiagnosticPlatform.ios,
      error: null,
    ).encode();

    for (final forbidden in <String>[
      'timestamp',
      'deviceId',
      'sessionId',
      'journal',
      'checkIn',
      'question',
      'recordCount',
      'locale',
      'ipAddress',
      'osVersion',
    ]) {
      expect(payload, isNot(contains(forbidden)), reason: forbidden);
    }
  });
}
