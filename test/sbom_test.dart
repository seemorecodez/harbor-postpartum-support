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
    expect(first, endsWith('\n'));
    final decoded = jsonDecode(first) as Map<String, dynamic>;
    final metadata = decoded['metadata'] as Map<String, dynamic>;
    final root = metadata['component'] as Map<String, dynamic>;
    expect(root['version'], '1.2.3+4');
    expect(root['description'], contains('tree-shake'));
    expect(first, isNot(contains('dev_only')));
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
        r'build/harbor-web\.cdx\.json',
      ).hasMatch(workflow),
      isTrue,
    );
    expect(workflow, contains('sbom-path: build/harbor-web.cdx.json'));
    expect(workflow, contains(r'harbor-release-evidence-${{ github.sha }}'));
  });
}
