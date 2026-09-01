import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String index;
  late String bootstrap;
  late String serviceWorker;
  late String releaseFinalizer;
  late String pubspec;

  setUpAll(() async {
    index = await File('web/index.html').readAsString();
    bootstrap = await File('web/flutter_bootstrap.js').readAsString();
    serviceWorker = await File('web/harbor_service_worker.js').readAsString();
    releaseFinalizer = await File('tool/finalize_web_release.dart')
        .readAsString();
    pubspec = await File('pubspec.yaml').readAsString();
  });

  test(
    'accessible startup shell exists before the asynchronous Flutter script',
    () {
      final shellPosition = index.indexOf('id="harbor-startup"');
      final scriptPosition = index.indexOf('src="flutter_bootstrap.js');

      expect(shellPosition, greaterThan(-1));
      expect(scriptPosition, greaterThan(shellPosition));
      expect(index, contains('role="status"'));
      expect(index, contains('aria-live="polite"'));
      expect(index, contains('id="harbor-startup-retry"'));
      expect(index, contains('@media (prefers-reduced-motion: reduce)'));
    },
  );

  test('startup shell resolves from the real first frame and exposes failure retry', () {
    expect(bootstrap, contains('"flutter-first-frame"'));
    expect(bootstrap, contains('harbor-startup--ready'));
    expect(bootstrap, contains('startupShell.remove()'));
    expect(bootstrap, contains('showStartupFailure()'));
    expect(bootstrap, contains('harbor-startup--failed'));
    expect(bootstrap, contains('function retryHarbor()'));
    expect(
      bootstrap,
      contains('startupRetry.addEventListener("click", retryHarbor)'),
    );
    expect(bootstrap, contains('startupRetry.addEventListener("keydown"'));
    expect(bootstrap, contains('event.key !== "Enter"'));
    expect(bootstrap, contains('event.key !== " "'));
    expect(bootstrap, contains('event.preventDefault()'));
    expect(bootstrap, contains('window.location.reload()'));
  });

  test('framed startup fails closed before Flutter can expose private UI', () {
    expect(bootstrap, contains('window.self !== window.top'));
    expect(bootstrap, contains('function showFramedBoundary()'));
    expect(bootstrap, contains('harbor-startup--framed'));
    expect(bootstrap, contains('startupShell.setAttribute("role", "alert")'));
    expect(
      bootstrap,
      contains('startupShell.setAttribute("aria-live", "assertive")'),
    );
    expect(bootstrap, contains('"Open Harbor directly"'));
    expect(
      bootstrap,
      contains(
        'window.open(document.baseURI, "_blank", "noopener,noreferrer")',
      ),
    );
    expect(
      bootstrap,
      contains(
        'if (harborIsFramed) {\n'
        '  showFramedBoundary();\n'
        '} else {\n'
        '  startHarbor();\n'
        '}',
      ),
    );
    expect(
      index,
      contains('#harbor-startup.harbor-startup--framed .harbor-startup__bar'),
    );
    expect(
      index,
      contains('#harbor-startup.harbor-startup--framed .harbor-startup__retry'),
    );
  });

  test('release identity is consistent across bootstrap and offline shell', () {
    final match = RegExp(
      r'^version: ([^+]+)\+\d+$',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(match, isNotNull);
    final release = match!.group(1)!;

    expect(bootstrap, contains('HARBOR_RELEASE = "$release"'));
    expect(index, contains('flutter_bootstrap.js?v=$release'));
    expect(serviceWorker, contains('harbor-shell-$release'));
    expect(releaseFinalizer, contains("'./flutter_bootstrap.js?v=\$release'"));
    expect(releaseFinalizer, contains("'index.html'"));
    expect(releaseFinalizer, contains("'main.dart.wasm'"));
  });

  test('new release is verified in staging before cache promotion', () {
    expect(serviceWorker, contains('STAGING_CACHE_NAME'));
    expect(
      serviceWorker,
      contains('new Request(asset.url, { cache: "reload" })'),
    );
    expect(serviceWorker, contains('await verifyReleaseResponse('));
    expect(serviceWorker, contains('crypto.subtle.digest("SHA-256", body)'));
    expect(serviceWorker, contains('body.byteLength !== asset.bytes'));
    expect(serviceWorker, contains('await staging.put(asset.url, verified)'));
    expect(serviceWorker, contains('await release.put(asset.url, verified)'));
    expect(serviceWorker, contains('await self.skipWaiting()'));
    expect(serviceWorker, isNot(contains('cache.addAll(RELEASE_CORE)')));
  });

  test('failed or abandoned updates cannot become fallback caches', () {
    expect(
      RegExp(r'caches\.delete\(STAGING_CACHE_NAME\)').allMatches(serviceWorker),
      hasLength(greaterThanOrEqualTo(3)),
    );
    expect(
      RegExp(r'caches\.delete\(CACHE_NAME\)').allMatches(serviceWorker),
      hasLength(greaterThanOrEqualTo(2)),
    );
    expect(serviceWorker, contains('!name.endsWith(STAGING_SUFFIX)'));
    expect(serviceWorker, contains('matchPreviousRelease'));
    expect(serviceWorker, isNot(contains('caches.match(event.request)')));
    expect(serviceWorker, isNot(contains('caches.match("./index.html")')));
  });

  test('unfinalized web build fails closed', () {
    expect(serviceWorker, contains('HARBOR_RELEASE_ASSETS_START'));
    expect(serviceWorker, contains('HARBOR_RELEASE_ASSETS_END'));
    expect(serviceWorker, contains('if (RELEASE_ASSETS.length === 0)'));
    expect(
      serviceWorker,
      contains("throw new Error(\"Harbor's web release was not finalized.\")"),
    );
  });
}
