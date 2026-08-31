import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String androidSettings;
  late String androidBuild;
  late String androidManifest;
  late String androidDebugManifest;
  late String androidProfileManifest;
  late String backupRules;
  late String extractionRules;
  late String nativeWorkflow;

  setUpAll(() async {
    androidSettings = await File('android/settings.gradle.kts').readAsString();
    androidBuild = await File('android/app/build.gradle.kts').readAsString();
    androidManifest = await File('android/app/src/main/AndroidManifest.xml')
        .readAsString();
    androidDebugManifest = await File(
      'android/app/src/debug/AndroidManifest.xml',
    ).readAsString();
    androidProfileManifest = await File(
      'android/app/src/profile/AndroidManifest.xml',
    ).readAsString();
    backupRules = await File('android/app/src/main/res/xml/backup_rules.xml')
        .readAsString();
    extractionRules = await File(
      'android/app/src/main/res/xml/data_extraction_rules.xml',
    ).readAsString();
    nativeWorkflow = await File('.github/workflows/native-proof.yml')
        .readAsString();
  });

  test('Android compile toolchain matches the secure-storage requirement', () {
    expect(
      androidSettings,
      contains('id("com.android.application") version "9.1.1"'),
    );
    expect(androidSettings, isNot(contains('version "9.1.+"')));
    expect(androidBuild, contains('compileSdk = 37'));
    expect(androidBuild, contains('targetSdk = flutter.targetSdkVersion'));
    expect(androidBuild, contains('minSdk = flutter.minSdkVersion'));
    expect(androidBuild, isNot(contains('signingConfig =')));
  });

  test('Android release excludes Harbor data from backup and transfer', () {
    expect(androidManifest, contains('android:label="Harbor"'));
    expect(androidManifest, contains('android:allowBackup="false"'));
    expect(
      androidManifest,
      contains('android:fullBackupContent="@xml/backup_rules"'),
    );
    expect(
      androidManifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );
    expect(androidManifest, contains('android:usesCleartextTraffic="false"'));
    expect(androidManifest, isNot(contains('android.permission.INTERNET')));
    expect(androidDebugManifest, contains('android.permission.INTERNET'));
    expect(androidProfileManifest, contains('android.permission.INTERNET'));

    const domains = <String>[
      'root',
      'file',
      'database',
      'sharedpref',
      'external',
      'device_root',
      'device_file',
      'device_database',
      'device_sharedpref',
    ];
    for (final domain in domains) {
      expect(
        RegExp('<exclude domain="$domain" path="\\."\\s*/>')
            .allMatches(backupRules),
        hasLength(1),
        reason: domain,
      );
      expect(
        RegExp('<exclude domain="$domain" path="\\."\\s*/>')
            .allMatches(extractionRules),
        hasLength(2),
        reason: domain,
      );
    }
    expect(backupRules, isNot(contains('<include')));
    expect(extractionRules, contains('<cloud-backup>'));
    expect(extractionRules, contains('<device-transfer>'));
    expect(extractionRules, isNot(contains('<include')));
  });

  test('native shells expose the Harbor product name', () async {
    final iosInfo = await File('ios/Runner/Info.plist').readAsString();
    final macInfo = await File('macos/Runner/Configs/AppInfo.xcconfig')
        .readAsString();
    final windowsCmake = await File('windows/CMakeLists.txt').readAsString();
    final windowsRunner = await File('windows/runner/Runner.rc').readAsString();
    final windowsMain = await File('windows/runner/main.cpp').readAsString();

    expect(
      RegExp(r'<string>Harbor</string>').allMatches(iosInfo),
      hasLength(2),
    );
    expect(macInfo, contains('PRODUCT_NAME = Harbor'));
    expect(macInfo, contains('2026 SeemoreCodez'));
    expect(windowsCmake, contains('set(BINARY_NAME "Harbor")'));
    expect(windowsRunner, contains('VALUE "ProductName", "Harbor"'));
    expect(windowsRunner, contains('VALUE "OriginalFilename", "Harbor.exe"'));
    expect(windowsRunner, contains('2026 SeemoreCodez'));
    expect(windowsMain, contains('window.Create(L"Harbor"'));
  });

  test('native proof stays manual, non-release, and clean-tree checked', () {
    expect(nativeWorkflow, contains('workflow_dispatch:'));
    expect(nativeWorkflow, isNot(contains('branches:')));
    expect(nativeWorkflow, contains('flutter build apk --release --no-pub'));
    expect(nativeWorkflow, contains('--no-codesign'));
    expect(
      RegExp('harbor-[^\\n]*-engineering-proof-').allMatches(nativeWorkflow),
      hasLength(3),
    );
    expect(nativeWorkflow, contains('compiled-android-manifest.xml'));
    expect(nativeWorkflow, contains("android.permission.INTERNET"));
    expect(nativeWorkflow, contains('Get-AuthenticodeSignature'));
    expect(nativeWorkflow, contains("Release/Harbor.app"));
    expect(nativeWorkflow, contains('git diff --exit-code'));
    expect(
      nativeWorkflow,
      contains('git ls-files --others --exclude-standard'),
    );
    expect(nativeWorkflow, isNot(contains('if (git status --porcelain')));
  });
}
