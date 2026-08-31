import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'models.dart';
import 'release_info.dart';
import 'vault.dart';

enum HarborDiagnosticPlatform {
  web('web'),
  android('android'),
  ios('ios'),
  windows('windows'),
  macos('macos'),
  linux('linux'),
  unknown('unknown');

  const HarborDiagnosticPlatform(this.code);

  final String code;
}

enum HarborDiagnosticErrorCode {
  none('none'),
  unsupportedDataSchema('unsupported_data_schema'),
  unsupportedVaultEnvelope('unsupported_vault_envelope'),
  keyMissing('key_missing'),
  corruptVault('corrupt_vault'),
  migrationFailed('migration_failed'),
  vaultUnavailable('vault_unavailable');

  const HarborDiagnosticErrorCode(this.code);

  final String code;
}

HarborDiagnosticPlatform currentHarborDiagnosticPlatform() {
  if (kIsWeb) return HarborDiagnosticPlatform.web;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => HarborDiagnosticPlatform.android,
    TargetPlatform.iOS => HarborDiagnosticPlatform.ios,
    TargetPlatform.windows => HarborDiagnosticPlatform.windows,
    TargetPlatform.macOS => HarborDiagnosticPlatform.macos,
    TargetPlatform.linux => HarborDiagnosticPlatform.linux,
    TargetPlatform.fuchsia => HarborDiagnosticPlatform.unknown,
  };
}

final class HarborDiagnosticReport {
  const HarborDiagnosticReport._({
    required this.platform,
    required this.errorCode,
  });

  factory HarborDiagnosticReport.create({
    required HarborDiagnosticPlatform platform,
    required Object? error,
  }) => HarborDiagnosticReport._(
    platform: platform,
    errorCode: _classifyError(error),
  );

  final HarborDiagnosticPlatform platform;
  final HarborDiagnosticErrorCode errorCode;

  Map<String, Object> toJson() => <String, Object>{
    'applicationVersion': HarborReleaseInfo.version,
    'buildNumber': HarborReleaseInfo.buildNumber,
    'platform': platform.code,
    'dataSchemaVersion': HarborData.currentSchemaVersion,
    'errorCode': errorCode.code,
  };

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  String get semanticLabel =>
      'Diagnostic details. Application version ${HarborReleaseInfo.version}. '
      'Build number ${HarborReleaseInfo.buildNumber}. Platform ${platform.code}. '
      'Data schema version ${HarborData.currentSchemaVersion}. '
      'Error code ${errorCode.code}.';
}

HarborDiagnosticErrorCode _classifyError(Object? error) => switch (error) {
  null => HarborDiagnosticErrorCode.none,
  UnsupportedHarborDataVersionException() =>
    HarborDiagnosticErrorCode.unsupportedDataSchema,
  UnsupportedHarborVaultVersionException() =>
    HarborDiagnosticErrorCode.unsupportedVaultEnvelope,
  HarborVaultKeyMissingException() => HarborDiagnosticErrorCode.keyMissing,
  HarborVaultCorruptException() => HarborDiagnosticErrorCode.corruptVault,
  HarborVaultMigrationException() => HarborDiagnosticErrorCode.migrationFailed,
  _ => HarborDiagnosticErrorCode.vaultUnavailable,
};
