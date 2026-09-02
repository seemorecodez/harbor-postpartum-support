import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

const _licenseFilePattern =
    r'^(license|licence|copying|notice)(\.[a-z0-9._-]+)?$';

Map<String, Object?> generateDependencyLicenseInventory({
  required Map<String, Object?> sbom,
  required String packageConfigContent,
  required Uri packageConfigUri,
  required String policyContent,
  required Directory dartSdkRoot,
}) {
  final packageConfig =
      jsonDecode(packageConfigContent) as Map<String, dynamic>;
  final policy = jsonDecode(policyContent) as Map<String, dynamic>;
  if (policy['schemaVersion'] != 1) {
    throw const FormatException('Unsupported dependency policy schema.');
  }

  final packageRoots = <String, Directory>{};
  for (final entry
      in (packageConfig['packages'] as List<Object?>? ?? const [])
          .cast<Map<String, dynamic>>()) {
    final rootUri = packageConfigUri.resolve(entry['rootUri'] as String);
    if (rootUri.scheme != 'file') {
      throw FormatException(
        'Package ${entry['name']} has a non-file root URI.',
      );
    }
    packageRoots[entry['name'] as String] = Directory.fromUri(rootUri);
  }

  final metadata = sbom['metadata'] as Map<String, Object?>;
  final root = metadata['component'] as Map<String, Object?>;
  final runtimeComponents = (sbom['components'] as List<Object?>)
      .cast<Map<String, Object?>>();
  _verifyRuntimeAllowlist(runtimeComponents, policy);

  final flutterRoot = packageRoots['flutter'];
  if (flutterRoot == null) {
    throw const FormatException('Flutter package root is missing.');
  }
  final flutterSdkRoot = flutterRoot.parent.parent;
  final approvedTexts =
      (policy['approvedEvidenceTexts'] as Map<String, dynamic>? ??
      const <String, dynamic>{});

  final allComponents =
      <Map<String, Object?>>[
        {...root, '_scope': 'project', '_source': 'project'},
        for (final component in runtimeComponents)
          {
            ...component,
            '_scope': 'runtime',
            '_source': _property(component, 'harbor:source'),
          },
      ]..sort(
        (left, right) =>
            (left['name'] as String).compareTo(right['name'] as String),
      );

  final observedHashes = <String>{};
  final inventoryComponents = <Map<String, Object?>>[];
  for (final component in allComponents) {
    final name = component['name'] as String;
    final source = component['_source'] as String?;
    final rootDirectory = name == 'Dart SDK' ? dartSdkRoot : packageRoots[name];
    if (rootDirectory == null || !rootDirectory.existsSync()) {
      throw FormatException('Package root is missing for $name.');
    }

    var resolution = 'direct';
    var licenseFiles = _licenseFiles(rootDirectory);
    if (licenseFiles.isEmpty && source == 'sdk') {
      if (!_isWithin(rootDirectory, flutterSdkRoot)) {
        throw FormatException('$name is outside the Flutter SDK root.');
      }
      licenseFiles = _licenseFiles(flutterSdkRoot);
      resolution = 'flutter-sdk-root';
    }
    if (licenseFiles.isEmpty) {
      throw FormatException('No license evidence found for $name.');
    }

    final evidence = <Map<String, Object?>>[];
    for (final file in licenseFiles) {
      final hash = _sha256(file.readAsBytesSync());
      final approval = approvedTexts[hash] as Map<String, dynamic>?;
      if (approval == null) {
        throw FormatException(
          'Unapproved evidence text $hash for $name (${file.path}).',
        );
      }
      final classification = approval['classification'] as String?;
      if (classification == null || classification.isEmpty) {
        throw FormatException('Evidence classification is missing for $hash.');
      }
      final evidenceType = approval['evidenceType'] as String? ?? 'license';
      if (evidenceType != 'license' && evidenceType != 'notice') {
        throw FormatException('Invalid evidence type for $hash.');
      }
      observedHashes.add(hash);
      evidence.add({
        'fileName': file.uri.pathSegments.last,
        'resolution': resolution,
        'sha256': hash,
        'evidenceType': evidenceType,
        'classification': classification,
      });
    }
    if (!evidence.any((entry) => entry['evidenceType'] == 'license')) {
      throw FormatException('No approved license evidence found for $name.');
    }
    evidence.sort(
      (left, right) =>
          (left['fileName'] as String).compareTo(right['fileName'] as String),
    );
    inventoryComponents.add({
      'name': name,
      'version': component['version'] as String,
      'scope': component['_scope'] as String,
      'source': source,
      'licenseEvidence': evidence,
    });
  }

  final approvedHashes = approvedTexts.keys.toSet();
  final stale = approvedHashes.difference(observedHashes).toList()..sort();
  if (stale.isNotEmpty) {
    throw FormatException(
      'Dependency policy contains unobserved evidence texts: ${stale.join(', ')}.',
    );
  }

  final classificationCounts = <String, int>{};
  for (final component in inventoryComponents) {
    final classifications = (component['licenseEvidence'] as List<Object?>)
        .cast<Map<String, Object?>>()
        .map((entry) => entry['classification'] as String)
        .toSet();
    for (final classification in classifications) {
      classificationCounts.update(
        classification,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
  }

  return {
    'schemaVersion': 1,
    'sbomSerialNumber': sbom['serialNumber'] as String,
    'rootComponent': root['name'] as String,
    'components': inventoryComponents,
    'summary': {
      'componentCount': inventoryComponents.length,
      'runtimeComponentCount': runtimeComponents.length,
      'uniqueEvidenceTextCount': observedHashes.length,
      'classifications': Map.fromEntries(
        classificationCounts.entries.toList()
          ..sort((left, right) => left.key.compareTo(right.key)),
      ),
    },
    'limitations': [
      'This evidence detects dependency, version, and license-text drift; it is not legal advice or legal approval.',
      'LicenseRef-Flutter-Engine-Composite requires preservation and review of Flutter engine composite notices before redistribution.',
    ],
  };
}

Map<String, List<Map<String, Object?>>> licenseEvidenceByComponent(
  Map<String, Object?> inventory,
) {
  return {
    for (final component
        in (inventory['components'] as List<Object?>)
            .cast<Map<String, Object?>>())
      component['name']
          as String: (component['licenseEvidence'] as List<Object?>)
          .cast<Map<String, Object?>>(),
  };
}

void _verifyRuntimeAllowlist(
  List<Map<String, Object?>> components,
  Map<String, dynamic> policy,
) {
  final allowed =
      (policy['allowedRuntimeComponents'] as Map<String, dynamic>? ??
      const <String, dynamic>{});
  final actual = <String, String>{
    for (final component in components)
      component['name'] as String: component['version'] as String,
  };
  final names = {...allowed.keys, ...actual.keys}.toList()..sort();
  final differences = <String>[];
  for (final name in names) {
    final expected = allowed[name] as String?;
    final observed = actual[name];
    if (expected != observed) {
      differences.add(
        '$name expected=${expected ?? '<absent>'} '
        'observed=${observed ?? '<absent>'}',
      );
    }
  }
  if (differences.isNotEmpty) {
    throw FormatException(
      'Runtime dependency allowlist mismatch: ${differences.join('; ')}.',
    );
  }
}

List<File> _licenseFiles(Directory directory) {
  final pattern = RegExp(_licenseFilePattern, caseSensitive: false);
  return directory
      .listSync(followLinks: false)
      .whereType<File>()
      .where((file) => pattern.hasMatch(file.uri.pathSegments.last))
      .toList()
    ..sort((left, right) => left.path.compareTo(right.path));
}

bool _isWithin(Directory child, Directory parent) {
  final childPath = child.absolute.path.toLowerCase();
  final parentPath = parent.absolute.path.toLowerCase();
  return childPath == parentPath ||
      childPath.startsWith('$parentPath${Platform.pathSeparator}');
}

String? _property(Map<String, Object?> component, String name) {
  for (final property
      in (component['properties'] as List<Object?>? ?? const [])
          .cast<Map<String, Object?>>()) {
    if (property['name'] == name) return property['value'] as String?;
  }
  return null;
}

String _sha256(List<int> bytes) => Sha256()
    .toSync()
    .hashSync(bytes)
    .bytes
    .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
    .join();
