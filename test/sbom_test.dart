import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/generate_sbom.dart';

void main() {
  const graph = '''
{
  "root": "harbor_app",
  "packages": [
    {
      "name": "harbor_app",
      "version": "1.2.3+4",
      "kind": "root",
      "source": "root",
      "dependencies": ["runtime_a", "dev_only"],
      "directDependencies": ["runtime_a"],
      "devDependencies": ["dev_only"]
    },
    {
      "name": "runtime_a",
      "version": "2.0.0",
      "kind": "direct",
      "source": "hosted",
      "dependencies": ["shared"]
    },
    {
      "name": "shared",
      "version": "3.0.0",
      "kind": "transitive",
      "source": "hosted",
      "dependencies": []
    },
    {
      "name": "dev_only",
      "version": "9.0.0",
      "kind": "dev",
      "source": "hosted",
      "dependencies": ["dev_transitive"]
    },
    {
      "name": "dev_transitive",
      "version": "9.1.0",
      "kind": "transitive",
      "source": "hosted",
      "dependencies": []
    }
  ],
  "sdks": [
    {"name": "Dart", "version": "3.13.2"},
    {"name": "Flutter", "version": "3.47.2"}
  ]
}
''';
  const lockfile = '''
packages:
  runtime_a:
    dependency: "direct main"
    description:
      sha256: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  shared:
    dependency: transitive
    description:
      sha256: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
  dev_only:
    dependency: "direct dev"
    description:
      sha256: cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
''';

  test('CycloneDX contains the locked runtime closure but excludes dev roots', () {
    final document = generateCycloneDx(
      dependencyGraph: graph,
      lockfile: lockfile,
    );
    expect(document['bomFormat'], 'CycloneDX');
    expect(document['specVersion'], '1.5');
    expect(
      document['serialNumber'],
      matches(
        RegExp(
          r'^urn:uuid:[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-'
          r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    final components = (document['components'] as List<Object?>)
        .cast<Map<String, Object?>>();
    final names = components.map((component) => component['name']).toSet();
    expect(names, containsAll(['runtime_a', 'shared', 'Dart SDK']));
    expect(names, isNot(contains('dev_only')));
    expect(names, isNot(contains('dev_transitive')));

    final runtime = components.singleWhere(
      (component) => component['name'] == 'runtime_a',
    );
    expect(runtime['purl'], 'pkg:pub/runtime_a@2.0.0');
    expect(
      ((runtime['hashes'] as List<Object?>).single as Map<String, Object?>),
      {
        'alg': 'SHA-256',
        'content':
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      },
    );
  });

  test('SBOM serialization is deterministic and records honest scope', () {
    final first = encodeCycloneDx(
      generateCycloneDx(dependencyGraph: graph, lockfile: lockfile),
    );
    final second = encodeCycloneDx(
      generateCycloneDx(dependencyGraph: graph, lockfile: lockfile),
    );
    expect(first, second);
    expect(
      (jsonDecode(first) as Map<String, dynamic>)['serialNumber'],
      isNotEmpty,
    );
    expect(first, endsWith('\n'));
    final decoded = jsonDecode(first) as Map<String, dynamic>;
    final metadata = decoded['metadata'] as Map<String, dynamic>;
    final root = metadata['component'] as Map<String, dynamic>;
    expect(root['version'], '1.2.3+4');
    expect(root['description'], contains('tree-shake'));
    expect(first, isNot(contains('dev_only')));
  });

  test('SBOM embeds reviewed license classifications and evidence hashes', () {
    const evidenceHash =
        'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
    final document = generateCycloneDx(
      dependencyGraph: graph,
      lockfile: lockfile,
      licenseEvidence: const {
        'harbor_app': [
          {
            'classification': 'MIT',
            'evidenceType': 'license',
            'sha256': evidenceHash,
          },
        ],
        'runtime_a': [
          {
            'classification': 'Apache-2.0',
            'evidenceType': 'license',
            'sha256': evidenceHash,
          },
          {
            'classification': 'NoticeRef-Example',
            'evidenceType': 'notice',
            'sha256': 'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
          },
        ],
      },
    );
    final metadata = document['metadata'] as Map<String, Object?>;
    final root = metadata['component'] as Map<String, Object?>;
    expect(root['licenses'], [
      {
        'license': {'id': 'MIT'},
      },
    ]);
    final components = (document['components'] as List<Object?>)
        .cast<Map<String, Object?>>();
    final runtime = components.singleWhere(
      (component) => component['name'] == 'runtime_a',
    );
    expect(runtime['licenses'], [
      {
        'license': {'id': 'Apache-2.0'},
      },
    ]);
    expect(jsonEncode(runtime), contains(evidenceHash));
    expect(jsonEncode(runtime), isNot(contains('NoticeRef-Example')));
    expect(
      document['serialNumber'],
      isNot(
        generateCycloneDx(
          dependencyGraph: graph,
          lockfile: lockfile,
        )['serialNumber'],
      ),
    );
  });

  test('hosted runtime components require a locked archive hash', () {
    expect(
      () => generateCycloneDx(dependencyGraph: graph, lockfile: 'packages:\n'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('runtime_a'),
        ),
      ),
    );
  });

  test('public workflow generates and signs provenance plus SBOM evidence', () {
    final workflow = File('.github/workflows/ci.yml').readAsStringSync();
    expect(workflow, contains('artifact-metadata: write'));
    expect(workflow, contains('attestations: write'));
    expect(
      RegExp('actions/attest@1e69f48acb82d1966a394da916b4c1698aa569d6')
          .allMatches(workflow),
      hasLength(2),
    );
    expect(
      workflow,
      contains('dart pub deps --json > build/harbor-dependencies.json'),
    );
    expect(
      RegExp(
        r'dart run tool/generate_sbom\.dart --verify \\\s+'
        r'build/harbor-dependencies\.json pubspec\.lock \\\s+'
        r'\.dart_tool/package_config\.json \\\s+'
        r'tool/runtime_dependency_policy\.json \\\s+'
        r'build/harbor-web\.cdx\.json \\\s+'
        r'build/harbor-runtime-licenses\.json',
      ).hasMatch(workflow),
      isTrue,
    );
    expect(workflow, contains('sbom-path: build/harbor-web.cdx.json'));
    expect(workflow, contains('id: upload_web'));
    expect(
      RegExp(r'subject-name: harbor-web-\$\{\{ github\.sha \}\}')
          .allMatches(workflow),
      hasLength(2),
    );
    expect(
      RegExp(
        r'subject-digest: sha256:\$\{\{ steps\.upload_web\.outputs\.'
        r'artifact-digest \}\}',
      ).allMatches(workflow),
      hasLength(2),
    );
    expect(workflow, contains(r'harbor-release-evidence-${{ github.sha }}'));
    expect(
      workflow,
      contains('cp build/harbor-runtime-licenses.json build/release-evidence/'),
    );
  });

  test('public workflow blocks deployment on immutable OSV lock scan', () {
    final workflow = File('.github/workflows/ci.yml').readAsStringSync();
    expect(
      workflow,
      contains(
        'google/osv-scanner-action/.github/workflows/'
        'osv-scanner-reusable.yml@'
        '6e4298ebc4db23e847df9b2e2de2939d6f066c67',
      ),
    );
    expect(workflow, contains('--lockfile=./pubspec.lock'));
    expect(workflow, contains('fail-on-vuln: true'));
    expect(workflow, contains('security-events: write'));
    expect(workflow, contains('needs:\n      - osv_scan\n      - verify'));
  });
}
