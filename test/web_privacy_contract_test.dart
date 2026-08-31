import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String index;
  late String bootstrap;
  late String serviceWorker;
  late String pubspec;
  late String dartSource;

  setUpAll(() async {
    index = await File('web/index.html').readAsString();
    bootstrap = await File('web/flutter_bootstrap.js').readAsString();
    serviceWorker = await File('web/harbor_service_worker.js').readAsString();
    pubspec = await File('pubspec.yaml').readAsString();
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    dartSource = (await Future.wait(
      dartFiles.map((file) => file.readAsString()),
    )).join('\n');
  });

  test('web shell permits only local runtime assets', () {
    final assetAttributes = RegExp(
      r'''(?:src|href)\s*=\s*["']([^"']+)["']''',
      caseSensitive: false,
    ).allMatches(index).map((match) => match.group(1)!);

    expect(assetAttributes, isNotEmpty);
    for (final asset in assetAttributes) {
      expect(asset, isNot(startsWith('http://')), reason: asset);
      expect(asset, isNot(startsWith('https://')), reason: asset);
      expect(asset, isNot(startsWith('//')), reason: asset);
    }
    expect(index, isNot(contains('<form')));
    expect(index, isNot(contains('integrity=')));
  });

  test('meta policy constrains executable and connection surfaces', () {
    final match = RegExp(
      r'''<meta http-equiv="Content-Security-Policy" content="([^"]+)">''',
    ).firstMatch(index);
    expect(match, isNotNull);
    final policy = match!.group(1)!;

    for (final directive in <String>[
      "default-src 'self'",
      "base-uri 'self'",
      "object-src 'none'",
      "frame-src 'none'",
      "form-action 'none'",
      "connect-src 'self'",
      "media-src 'none'",
      "script-src 'self' 'wasm-unsafe-eval'",
      "worker-src 'self' blob:",
    ]) {
      expect(policy, contains(directive), reason: directive);
    }
    expect(policy, isNot(contains('https:')));
    expect(policy, isNot(contains('http:')));
    expect(policy, isNot(contains("script-src 'unsafe-inline'")));
    expect(policy, isNot(contains("script-src 'unsafe-eval'")));
    expect(policy, isNot(contains('frame-ancestors')));
    expect(index, contains('<meta name="referrer" content="no-referrer">'));
    expect(
      index,
      contains('production host must send Content-Security-Policy'),
    );
  });

  test('application source has no general-purpose network client', () {
    for (final package in <String>[
      'http',
      'dio',
      'web_socket_channel',
      'firebase_analytics',
      'firebase_core',
      'sentry_flutter',
    ]) {
      expect(
        RegExp('^  $package:', multiLine: true).hasMatch(pubspec),
        isFalse,
        reason: package,
      );
    }
    expect(dartSource, isNot(contains('package:http/')));
    expect(dartSource, isNot(contains('http://')));
    expect(dartSource, isNot(contains('https://')));
    expect(dartSource, isNot(contains('WebSocket')));
    expect(dartSource, isNot(contains('HttpClient')));
  });

  test('external handoffs are limited to deliberate call and text schemes', () {
    expect(RegExp(r'launchUrl\(').allMatches(dartSource), hasLength(4));
    expect(dartSource, isNot(contains('Uri.parse(')));
    expect(dartSource, contains("Uri(scheme: 'tel'"));
    expect(dartSource, contains("Uri(scheme: 'sms'"));
    expect(dartSource, isNot(contains("scheme: 'http'")));
    expect(dartSource, isNot(contains("scheme: 'https'")));
    expect(dartSource, isNot(contains("scheme: 'mailto'")));
  });

  test('owned JavaScript networking stays inside the offline shell', () {
    expect(RegExp(r'\bfetch\s*\(').allMatches(bootstrap), hasLength(1));
    expect(RegExp(r'\bfetch\s*\(').allMatches(serviceWorker), hasLength(3));
    expect(serviceWorker, contains('event.request.method !== "GET"'));
    expect(
      serviceWorker,
      contains('requestUrl.origin !== self.location.origin'),
    );
    final ownedJavaScript = '$bootstrap\n$serviceWorker';
    expect(ownedJavaScript, isNot(contains('XMLHttpRequest')));
    expect(ownedJavaScript, isNot(contains('WebSocket')));
    expect(ownedJavaScript, isNot(contains('EventSource')));
    expect(ownedJavaScript, isNot(contains('sendBeacon')));
  });
}
