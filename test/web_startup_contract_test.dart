import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String index;
  late String bootstrap;
  late String serviceWorker;
  late String pubspec;

  setUpAll(() async {
    index = await File('web/index.html').readAsString();
    bootstrap = await File('web/flutter_bootstrap.js').readAsString();
    serviceWorker = await File('web/harbor_service_worker.js').readAsString();
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
    expect(serviceWorker, contains('flutter_bootstrap.js?v=$release'));
    expect(serviceWorker, contains('"./index.html"'));
    expect(serviceWorker, contains('"./main.dart.wasm"'));
  });

  test('new release cache bypasses stale runtime assets during install', () {
    expect(serviceWorker, contains('new Request(asset, { cache: "reload" })'));
    expect(serviceWorker, contains('await fetch(request)'));
    expect(serviceWorker, contains('await cache.put(asset, response)'));
    expect(serviceWorker, isNot(contains('cache.addAll(RELEASE_CORE)')));
  });
}
