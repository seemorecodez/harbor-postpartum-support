import 'dart:convert';
import 'dart:io';

const _repositoryUrl =
    'https://github.com/seemorecodez/harbor-postpartum-support';

void main(List<String> arguments) {
  final verify = arguments.isNotEmpty && arguments.first == '--verify';
  final paths = verify ? arguments.skip(1).toList() : arguments;
  if (paths.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/generate_sbom.dart [--verify] '
      '<dart-pub-deps.json> <pubspec.lock> <output.cdx.json>',
    );
    exitCode = 64;
    return;
  }

  final dependencyGraph = File(paths[0]).readAsStringSync();
  final lockfile = File(paths[1]).readAsStringSync();
  final expected = encodeCycloneDx(
    generateCycloneDx(dependencyGraph: dependencyGraph, lockfile: lockfile),
  );
  final output = File(paths[2]);

  if (verify) {
    if (!output.existsSync() || output.readAsStringSync() != expected) {
      stderr.writeln('Harbor SBOM verification failed: ${output.path}');
      exitCode = 1;
      return;
    }
    stdout.writeln(jsonEncode({'status': 'verified', 'path': output.path}));
    return;
  }

  output.parent.createSync(recursive: true);
  output.writeAsStringSync(expected);
  final decoded = jsonDecode(expected) as Map<String, dynamic>;
  stdout.writeln(
    jsonEncode({
      'status': 'generated',
      'path': output.path,
      'components': (decoded['components'] as List<Object?>).length,
    }),
  );
}

Map<String, Object?> generateCycloneDx({
  required String dependencyGraph,
  required String lockfile,
}) {
  final graph = jsonDecode(dependencyGraph) as Map<String, dynamic>;
  final rootName = graph['root'] as String?;
  final packageList = (graph['packages'] as List<Object?>? ?? const [])
      .cast<Map<String, dynamic>>();
  final packages = <String, Map<String, dynamic>>{
    for (final package in packageList) package['name'] as String: package,
  };
  final root = rootName == null ? null : packages[rootName];
  if (rootName == null || root == null || root['kind'] != 'root') {
    throw const FormatException('Dart dependency graph has no valid root.');
  }

  final runtimeNames = <String>{};
  final pending = <String>[..._strings(root['directDependencies'])];
  while (pending.isNotEmpty) {
    final name = pending.removeLast();
    if (!runtimeNames.add(name)) continue;
    final package = packages[name];
    if (package == null) {
      throw FormatException('Dependency graph is missing package $name.');
    }
    pending.addAll(_strings(package['dependencies']));
  }

  final sdkVersions = <String, String>{
    for (final sdk
        in (graph['sdks'] as List<Object?>? ?? const [])
            .cast<Map<String, dynamic>>())
      sdk['name'] as String: sdk['version'] as String,
  };
  final lockHashes = parsePubLockHashes(lockfile);
  final refs = <String, String>{};
  for (final name in runtimeNames) {
    final package = packages[name]!;
    refs[name] = _packageReference(package, sdkVersions);
  }

  final components = <Map<String, Object?>>[];
  for (final name in runtimeNames.toList()..sort()) {
    components.add(
      _componentFor(packages[name]!, sdkVersions, lockHashes[name]),
    );
  }

  final dartVersion = sdkVersions['Dart'];
  if (dartVersion == null) {
    throw const FormatException('Dart SDK version is missing.');
  }
  final dartRef = 'pkg:generic/dart-sdk@${_purl(dartVersion)}';
  components.add({
    'type': 'framework',
    'bom-ref': dartRef,
    'name': 'Dart SDK',
    'version': dartVersion,
    'purl': dartRef,
    'scope': 'required',
    'properties': [
      {'name': 'harbor:source', 'value': 'sdk'},
    ],
  });
  components.sort(
    (left, right) =>
        (left['bom-ref'] as String).compareTo(right['bom-ref'] as String),
  );

  final rootVersion = root['version'] as String;
  final rootRef = 'pkg:generic/$rootName@${_purl(rootVersion)}';
  final rootDependencies = <String>{dartRef};
  for (final name in _strings(root['directDependencies'])) {
    if (runtimeNames.contains(name)) rootDependencies.add(refs[name]!);
  }

  final dependencies = <Map<String, Object?>>[
    {'ref': rootRef, 'dependsOn': rootDependencies.toList()..sort()},
  ];
  for (final name in runtimeNames.toList()..sort()) {
    final package = packages[name]!;
    final childRefs = <String>{};
    for (final child in _strings(package['dependencies'])) {
      if (runtimeNames.contains(child)) childRefs.add(refs[child]!);
    }
    dependencies.add({
      'ref': refs[name]!,
      'dependsOn': childRefs.toList()..sort(),
    });
  }
  dependencies.add({'ref': dartRef, 'dependsOn': <String>[]});
  dependencies.sort(
    (left, right) => (left['ref'] as String).compareTo(right['ref'] as String),
  );

  final buildNumber = rootVersion.contains('+')
      ? rootVersion.split('+').last
      : 'none';
  return {
    'bomFormat': 'CycloneDX',
    'specVersion': '1.5',
    'version': 1,
    'metadata': {
      'tools': {
        'components': [
          {
            'type': 'application',
            'name': 'Harbor deterministic Dart SBOM generator',
            'version': '1',
          },
        ],
      },
      'component': {
        'type': 'application',
        'bom-ref': rootRef,
        'name': rootName,
        'version': rootVersion,
        'purl': rootRef,
        'description':
            'Harbor shared Flutter runtime dependency closure. Platform '
            'implementations resolved by the shared lockfile are included; '
            'the web compiler may tree-shake target-inapplicable code.',
        'externalReferences': [
          {'type': 'vcs', 'url': _repositoryUrl},
        ],
        'properties': [
          {'name': 'harbor:build-number', 'value': buildNumber},
          {
            'name': 'harbor:composition',
            'value': 'locked-shared-runtime-dependency-closure',
          },
          {'name': 'harbor:target', 'value': 'web-release'},
        ],
      },
    },
    'components': components,
    'dependencies': dependencies,
  };
}

String encodeCycloneDx(Map<String, Object?> document) =>
    '${const JsonEncoder.withIndent('  ').convert(document)}\n';

Map<String, String> parsePubLockHashes(String lockfile) {
  final hashes = <String, String>{};
  String? currentPackage;
  final packagePattern = RegExp(r'^  ([a-zA-Z0-9_]+):\s*$');
  final hashPattern = RegExp(r'^\s{4,}sha256:\s*"?([0-9a-fA-F]{64})"?\s*$');
  for (final line in const LineSplitter().convert(lockfile)) {
    final packageMatch = packagePattern.firstMatch(line);
    if (packageMatch != null) {
      currentPackage = packageMatch.group(1);
      continue;
    }
    final hashMatch = hashPattern.firstMatch(line);
    if (currentPackage != null && hashMatch != null) {
      hashes[currentPackage] = hashMatch.group(1)!.toLowerCase();
    }
  }
  return hashes;
}

Map<String, Object?> _componentFor(
  Map<String, dynamic> package,
  Map<String, String> sdkVersions,
  String? archiveHash,
) {
  final name = package['name'] as String;
  final source = package['source'] as String;
  if (source == 'hosted' && archiveHash == null) {
    throw FormatException('Locked archive hash is missing for $name.');
  }
  final version = source == 'sdk' && name == 'flutter'
      ? sdkVersions['Flutter'] ?? package['version'] as String
      : package['version'] as String;
  final reference = _packageReference(package, sdkVersions);
  return {
    'type': name == 'flutter' ? 'framework' : 'library',
    'bom-ref': reference,
    'name': name,
    'version': version,
    'purl': reference,
    'scope': 'required',
    if (archiveHash != null)
      'hashes': [
        {'alg': 'SHA-256', 'content': archiveHash},
      ],
    if (source == 'hosted')
      'externalReferences': [
        {'type': 'distribution', 'url': 'https://pub.dev/packages/$name'},
      ],
    'properties': [
      {'name': 'harbor:source', 'value': source},
      {'name': 'harbor:dependency-kind', 'value': package['kind'] as String},
    ],
  };
}

String _packageReference(
  Map<String, dynamic> package,
  Map<String, String> sdkVersions,
) {
  final name = package['name'] as String;
  final source = package['source'] as String;
  final version = source == 'sdk' && name == 'flutter'
      ? sdkVersions['Flutter'] ?? package['version'] as String
      : package['version'] as String;
  final type = source == 'hosted' ? 'pub' : 'generic';
  return 'pkg:$type/${_purl(name)}@${_purl(version)}';
}

List<String> _strings(Object? value) =>
    (value as List<Object?>? ?? const []).cast<String>();

String _purl(String value) => Uri.encodeComponent(value);
