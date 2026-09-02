import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

const _manifestStart = '/* HARBOR_RELEASE_ASSETS_START */';
const _manifestEnd = '/* HARBOR_RELEASE_ASSETS_END */';
const _serviceWorkerName = 'harbor_service_worker.js';
// The worker cannot contain its own digest without becoming self-referential;
// Flutter's local build marker is not a deployed runtime asset.
const _ignoredBuildFiles = <String>{_serviceWorkerName, '.last_build_id'};
const _precachePaths = <String>{
  'index.html',
  'flutter_bootstrap.js',
  'flutter.js',
  'main.dart.js',
  'main.dart.mjs',
  'main.dart.wasm',
  'manifest.json',
  'privacy.html',
  'version.json',
};

final class HarborWebReleaseSummary {
  const HarborWebReleaseSummary({
    required this.assets,
    required this.precachedAssets,
  });

  final int assets;
  final int precachedAssets;

  Map<String, int> toJson() => <String, int>{
    'assets': assets,
    'precachedAssets': precachedAssets,
  };
}

Future<HarborWebReleaseSummary> finalizeHarborWebRelease(
  Directory buildDirectory,
) async {
  final worker = File('${buildDirectory.path}/$_serviceWorkerName');
  if (!await worker.exists()) {
    throw StateError('Harbor service worker is missing from the web build.');
  }
  final source = await worker.readAsString();
  final currentManifest = _extractManifest(source);
  if (currentManifest.trim() != '[]') {
    throw StateError('Harbor web release is already finalized.');
  }

  final entries = await _buildManifest(buildDirectory);
  final replacement = jsonEncode(entries);
  final finalized = _replaceManifest(source, replacement);
  await worker.writeAsString(finalized, flush: true);
  return verifyHarborWebRelease(buildDirectory);
}

Future<HarborWebReleaseSummary> verifyHarborWebRelease(
  Directory buildDirectory,
) async {
  final worker = File('${buildDirectory.path}/$_serviceWorkerName');
  if (!await worker.exists()) {
    throw StateError('Harbor service worker is missing from the web build.');
  }
  final source = await worker.readAsString();
  final decoded = jsonDecode(_extractManifest(source));
  if (decoded is! List || decoded.isEmpty) {
    throw StateError('Harbor release asset manifest is empty.');
  }

  final entries = decoded.cast<Map<String, Object?>>();
  final expectedFiles = await _releaseFiles(buildDirectory);
  final expectedPaths = expectedFiles.keys.toSet();
  final baseUrls = <String>{};
  var precachedAssets = 0;

  for (final entry in entries) {
    final url = entry['url'];
    final expectedHash = entry['sha256'];
    final expectedBytes = entry['bytes'];
    final precache = entry['precache'];
    if (url is! String ||
        expectedHash is! String ||
        expectedBytes is! int ||
        precache is! bool) {
      throw const FormatException('Invalid Harbor release asset metadata.');
    }
    final path = _pathFromAssetUrl(url);
    final file = expectedFiles[path];
    if (file == null) {
      throw StateError('Release metadata refers to a missing asset: $url');
    }
    final bytes = await file.readAsBytes();
    final actualHash = await _sha256Hex(bytes);
    if (bytes.length != expectedBytes || actualHash != expectedHash) {
      throw StateError('Release asset failed integrity verification: $url');
    }
    if (!url.contains('?')) baseUrls.add(url);
    if (precache) precachedAssets += 1;
  }

  final manifestedPaths = baseUrls.map(_pathFromAssetUrl).toSet();
  if (manifestedPaths.length != expectedPaths.length ||
      !manifestedPaths.containsAll(expectedPaths)) {
    throw StateError(
      'Harbor release manifest does not cover every payload file.',
    );
  }
  for (final path in _precachePaths) {
    final matches = entries.where(
      (entry) => entry['url'] == './$path' && entry['precache'] == true,
    );
    if (matches.length != 1) {
      throw StateError('Required precache asset is missing: $path');
    }
  }

  return HarborWebReleaseSummary(
    assets: entries.length,
    precachedAssets: precachedAssets,
  );
}

Future<List<Map<String, Object>>> _buildManifest(
  Directory buildDirectory,
) async {
  final files = await _releaseFiles(buildDirectory);
  final entries = <Map<String, Object>>[];
  for (final entry in files.entries) {
    final bytes = await entry.value.readAsBytes();
    entries.add(<String, Object>{
      'url': './${entry.key}',
      'sha256': await _sha256Hex(bytes),
      'bytes': bytes.length,
      'precache': _precachePaths.contains(entry.key),
    });
  }

  final bootstrap = entries.singleWhere(
    (entry) => entry['url'] == './flutter_bootstrap.js',
  );
  final release = _releaseFromWorker(
    await File('${buildDirectory.path}/$_serviceWorkerName').readAsString(),
  );
  entries.add(<String, Object>{
    ...bootstrap,
    'url': './flutter_bootstrap.js?v=$release',
    'precache': true,
  });
  entries.sort(
    (left, right) =>
        (left['url']! as String).compareTo(right['url']! as String),
  );
  return entries;
}

Future<Map<String, File>> _releaseFiles(Directory buildDirectory) async {
  if (!await buildDirectory.exists()) {
    throw StateError('Harbor web build directory does not exist.');
  }
  final root = buildDirectory.absolute.path.replaceAll('\\', '/');
  final files = <String, File>{};
  await for (final entity in buildDirectory.list(recursive: true)) {
    if (entity is! File) continue;
    final absolute = entity.absolute.path.replaceAll('\\', '/');
    final relative = absolute.substring(root.length + 1);
    if (_ignoredBuildFiles.contains(relative)) continue;
    if (relative.startsWith('../') || relative.contains('/../')) {
      throw StateError('Build asset escaped the web directory.');
    }
    files[relative] = entity;
  }
  if (files.isEmpty) throw StateError('Harbor web build contains no assets.');
  return Map<String, File>.fromEntries(
    files.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
}

String _extractManifest(String source) {
  final start = source.indexOf(_manifestStart);
  final end = source.indexOf(_manifestEnd);
  if (start < 0 || end < 0 || end <= start) {
    throw StateError('Harbor release manifest markers are invalid.');
  }
  if (source.indexOf(_manifestStart, start + _manifestStart.length) >= 0 ||
      source.indexOf(_manifestEnd, end + _manifestEnd.length) >= 0) {
    throw StateError('Harbor release manifest markers are not unique.');
  }
  return source.substring(start + _manifestStart.length, end).trim();
}

String _replaceManifest(String source, String manifest) {
  final start = source.indexOf(_manifestStart) + _manifestStart.length;
  final end = source.indexOf(_manifestEnd);
  return '${source.substring(0, start)}\n  $manifest\n  ${source.substring(end)}';
}

String _releaseFromWorker(String source) {
  final match = RegExp(r'const CACHE_NAME = "harbor-shell-([^"]+)";')
      .firstMatch(source);
  if (match == null) {
    throw StateError('Harbor release cache identity is missing.');
  }
  return match.group(1)!;
}

String _pathFromAssetUrl(String url) {
  final uri = Uri.parse(url);
  if (uri.hasScheme ||
      uri.host.isNotEmpty ||
      !url.startsWith('./') ||
      url.startsWith('../')) {
    throw FormatException('Unsafe Harbor release asset URL: $url');
  }
  final path = url.substring(2).split('?').first;
  final segments = path.split('/');
  if (path.isEmpty || segments.any((segment) => segment == '..')) {
    throw FormatException('Unsafe Harbor release asset path: $url');
  }
  return path;
}

Future<String> _sha256Hex(List<int> bytes) async {
  final digest = await Sha256().hash(bytes);
  return digest.bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
}

Future<void> main(List<String> arguments) async {
  if (arguments.length == 1) {
    final summary = await finalizeHarborWebRelease(Directory(arguments.single));
    stdout.writeln(
      jsonEncode(<String, Object>{'status': 'finalized', ...summary.toJson()}),
    );
    return;
  }
  if (arguments.length == 2 && arguments.first == '--verify') {
    final summary = await verifyHarborWebRelease(Directory(arguments.last));
    stdout.writeln(
      jsonEncode(<String, Object>{'status': 'verified', ...summary.toJson()}),
    );
    return;
  }
  stderr.writeln(
    'Usage: dart run tool/finalize_web_release.dart [--verify] <build/web>',
  );
  exitCode = 64;
}
