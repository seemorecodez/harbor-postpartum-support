import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/finalize_web_release.dart';

void main() {
  late Directory fixture;

  setUp(() async {
    fixture = await Directory.systemTemp.createTemp('harbor-web-release-');
    final workerSource = await File('web/harbor_service_worker.js')
        .readAsString();
    await File('${fixture.path}/harbor_service_worker.js')
        .writeAsString(workerSource);
    final files = <String, List<int>>{
      'index.html': '<!doctype html><title>Harbor</title>'.codeUnits,
      'flutter_bootstrap.js': 'const HARBOR_RELEASE="alpha.26";'.codeUnits,
      'flutter.js': 'window._flutter={};'.codeUnits,
      'main.dart.js': 'consoleThisIsNotALogSink();'.codeUnits,
      'main.dart.mjs': 'export const harbor=true;'.codeUnits,
      'main.dart.wasm': <int>[0, 97, 115, 109, 1, 0, 0, 0],
      'manifest.json': '{"name":"Harbor"}'.codeUnits,
      'version.json': '{"version":"0.1.0-alpha.26"}'.codeUnits,
      'assets/fonts/HarborSans-Regular.ttf': <int>[1, 2, 3, 4, 5],
    };
    for (final entry in files.entries) {
      final file = File('${fixture.path}/${entry.key}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
  });

  tearDown(() async {
    if (await fixture.exists()) await fixture.delete(recursive: true);
  });

  test(
    'finalizer pins every payload file and required precache asset',
    () async {
      final finalized = await finalizeHarborWebRelease(fixture);
      final verified = await verifyHarborWebRelease(fixture);
      final worker = await File('${fixture.path}/harbor_service_worker.js')
          .readAsString();

      expect(finalized.assets, 10);
      expect(finalized.precachedAssets, 9);
      expect(verified.assets, finalized.assets);
      expect(verified.precachedAssets, finalized.precachedAssets);
      expect(worker, contains('./assets/fonts/HarborSans-Regular.ttf'));
      expect(worker, contains('./flutter_bootstrap.js?v=0.1.0-alpha.26'));
      expect(RegExp(r'"sha256":"[0-9a-f]{64}"').hasMatch(worker), isTrue);
      expect(worker, isNot(contains('HARBOR_RELEASE_ASSETS_START */\n  []')));
    },
  );

  test('verification rejects a corrupt lazy runtime asset', () async {
    await finalizeHarborWebRelease(fixture);
    await File('${fixture.path}/assets/fonts/HarborSans-Regular.ttf')
        .writeAsBytes(<int>[9, 9, 9, 9, 9]);

    await expectLater(
      verifyHarborWebRelease(fixture),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('failed integrity verification'),
        ),
      ),
    );
  });

  test('verification rejects a truncated precache asset', () async {
    await finalizeHarborWebRelease(fixture);
    await File('${fixture.path}/main.dart.wasm').writeAsBytes(<int>[0, 97]);

    await expectLater(
      verifyHarborWebRelease(fixture),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('failed integrity verification'),
        ),
      ),
    );
  });
}
