import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/dependency_license_inventory.dart';

void main() {
  late Directory temporary;
  late Directory projectRoot;
  late Directory runtimeRoot;
  late Directory flutterSdkRoot;
  late Directory flutterRoot;
  late Directory webPluginsRoot;
  late Directory dartSdkRoot;
  late File packageConfig;
  late Map<String, Object?> sbom;
  late Map<String, Object?> policy;

  setUp(() {
    temporary = Directory.systemTemp.createTempSync('harbor-license-test-');
    projectRoot = Directory('${temporary.path}/project')..createSync();
    runtimeRoot = Directory('${temporary.path}/runtime')..createSync();
    flutterSdkRoot = Directory('${temporary.path}/flutter-sdk')..createSync();
    flutterRoot = Directory('${flutterSdkRoot.path}/packages/flutter')
      ..createSync(recursive: true);
    webPluginsRoot = Directory(
      '${flutterSdkRoot.path}/packages/flutter_web_plugins',
    )..createSync(recursive: true);
    dartSdkRoot = Directory('${temporary.path}/dart-sdk')..createSync();

    File('${projectRoot.path}/LICENSE').writeAsStringSync('project license');
    File('${projectRoot.path}/NOTICE').writeAsStringSync('project notice');
    File('${runtimeRoot.path}/LICENSE').writeAsStringSync('runtime license');
    File('${flutterRoot.path}/LICENSE').writeAsStringSync('flutter license');
    File('${flutterSdkRoot.path}/LICENSE')
        .writeAsStringSync('sdk root license');
    File('${dartSdkRoot.path}/LICENSE').writeAsStringSync('dart license');

    final configDirectory = Directory('${temporary.path}/config')..createSync();
    packageConfig = File('${configDirectory.path}/package_config.json');
    packageConfig.writeAsStringSync(
      jsonEncode({
        'configVersion': 2,
        'packages': [
          _package('harbor_app', projectRoot),
          _package('runtime_a', runtimeRoot),
          _package('flutter', flutterRoot),
          _package('flutter_web_plugins', webPluginsRoot),
        ],
      }),
    );

    sbom = {
      'serialNumber': 'urn:uuid:12345678-1234-5123-8123-123456789012',
      'metadata': {
        'component': {'name': 'harbor_app', 'version': '1.0.0'},
      },
      'components': [
        _component('Dart SDK', '3.13.2', 'sdk'),
        _component('flutter', '3.47.2', 'sdk'),
        _component('flutter_web_plugins', '0.0.0', 'sdk'),
        _component('runtime_a', '2.0.0', 'hosted'),
      ],
    };
    policy = {
      'schemaVersion': 1,
      'allowedRuntimeComponents': {
        'Dart SDK': '3.13.2',
        'flutter': '3.47.2',
        'flutter_web_plugins': '0.0.0',
        'runtime_a': '2.0.0',
      },
      'approvedEvidenceTexts': {
        _hash('project license'): {'classification': 'MIT'},
        _hash('project notice'): {
          'classification': 'NoticeRef-Project',
          'evidenceType': 'notice',
        },
        _hash('runtime license'): {'classification': 'Apache-2.0'},
        _hash('flutter license'): {'classification': 'BSD-3-Clause'},
        _hash('sdk root license'): {'classification': 'BSD-3-Clause'},
        _hash('dart license'): {'classification': 'BSD-3-Clause'},
      },
    };
  });

  tearDown(() => temporary.deleteSync(recursive: true));

  test('inventory is deterministic, exact, and records SDK inheritance', () {
    final first = _generate(
      sbom: sbom,
      policy: policy,
      packageConfig: packageConfig,
      dartSdkRoot: dartSdkRoot,
    );
    final second = _generate(
      sbom: sbom,
      policy: policy,
      packageConfig: packageConfig,
      dartSdkRoot: dartSdkRoot,
    );
    expect(jsonEncode(first), jsonEncode(second));
    final summary = first['summary'] as Map<String, Object?>;
    expect(summary['componentCount'], 5);
    expect(summary['runtimeComponentCount'], 4);
    expect(summary['uniqueEvidenceTextCount'], 6);
    final components = (first['components'] as List<Object?>)
        .cast<Map<String, Object?>>();
    final webPlugins = components.singleWhere(
      (component) => component['name'] == 'flutter_web_plugins',
    );
    final webEvidence = (webPlugins['licenseEvidence'] as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(webEvidence.single['resolution'], 'flutter-sdk-root');
    expect(webEvidence.single['sha256'], _hash('sdk root license'));
    final project = components.singleWhere(
      (component) => component['name'] == 'harbor_app',
    );
    final projectEvidence = (project['licenseEvidence'] as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(projectEvidence, hasLength(2));
    expect(
      projectEvidence.map((entry) => entry['fileName']),
      orderedEquals(['license', 'notice']),
    );
    expect(
      projectEvidence.singleWhere(
        (entry) => entry['evidenceType'] == 'notice',
      )['classification'],
      'NoticeRef-Project',
    );
  });

  test('changed license text fails closed', () {
    File('${runtimeRoot.path}/LICENSE').writeAsStringSync('changed license');
    expect(
      () => _generate(
        sbom: sbom,
        policy: policy,
        packageConfig: packageConfig,
        dartSdkRoot: dartSdkRoot,
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Unapproved evidence text'),
        ),
      ),
    );
  });

  test('license evidence hash is stable across platform line endings', () {
    expect(
      canonicalEvidenceHash(utf8.encode('first line\r\nsecond line\r\n')),
      canonicalEvidenceHash(utf8.encode('first line\nsecond line\n')),
    );
  });

  test('a notice without an approved license fails closed', () {
    File('${runtimeRoot.path}/LICENSE').deleteSync();
    File('${runtimeRoot.path}/NOTICE').writeAsStringSync('runtime notice');
    final noticeOnly = jsonDecode(jsonEncode(policy)) as Map<String, dynamic>;
    final texts = noticeOnly['approvedEvidenceTexts'] as Map<String, dynamic>;
    texts.remove(_hash('runtime license'));
    texts[_hash('runtime notice')] = {
      'classification': 'NoticeRef-Runtime',
      'evidenceType': 'notice',
    };
    expect(
      () => _generate(
        sbom: sbom,
        policy: noticeOnly,
        packageConfig: packageConfig,
        dartSdkRoot: dartSdkRoot,
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('No approved license evidence'),
        ),
      ),
    );
  });

  test('dependency version drift fails closed', () {
    final components = (sbom['components'] as List<Object?>)
        .cast<Map<String, Object?>>();
    components.last['version'] = '2.0.1';
    expect(
      () => _generate(
        sbom: sbom,
        policy: policy,
        packageConfig: packageConfig,
        dartSdkRoot: dartSdkRoot,
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('allowlist mismatch'),
        ),
      ),
    );
  });

  test('committed policy is exact, explicit, and wildcard-free', () {
    final committed = jsonDecode(
      File('tool/runtime_dependency_policy.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final components =
        committed['allowedRuntimeComponents'] as Map<String, dynamic>;
    final texts = committed['approvedEvidenceTexts'] as Map<String, dynamic>;
    expect(components, hasLength(64));
    expect(texts, hasLength(29));
    expect(components.keys, isNot(contains('*')));
    expect(texts.keys, everyElement(matches(RegExp(r'^[0-9a-f]{64}$'))));
    final classifications = texts.values
        .cast<Map<String, dynamic>>()
        .map((entry) => entry['classification'])
        .toSet();
    expect(
      classifications,
      containsAll([
        'MIT',
        'BSD-3-Clause',
        'Apache-2.0',
        'LicenseRef-Flutter-Engine-Composite',
      ]),
    );
  });
}

Map<String, Object?> _generate({
  required Map<String, Object?> sbom,
  required Map<String, Object?> policy,
  required File packageConfig,
  required Directory dartSdkRoot,
}) {
  return generateDependencyLicenseInventory(
    sbom: sbom,
    packageConfigContent: packageConfig.readAsStringSync(),
    packageConfigUri: packageConfig.absolute.uri,
    policyContent: jsonEncode(policy),
    dartSdkRoot: dartSdkRoot,
  );
}

Map<String, Object?> _package(String name, Directory root) => {
  'name': name,
  'rootUri': root.absolute.uri.toString(),
  'packageUri': 'lib/',
};

Map<String, Object?> _component(String name, String version, String source) => {
  'name': name,
  'version': version,
  'properties': [
    {'name': 'harbor:source', 'value': source},
  ],
};

String _hash(String value) => canonicalEvidenceHash(utf8.encode(value));
