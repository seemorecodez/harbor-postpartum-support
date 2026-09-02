import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor_app/app.dart';
import 'package:harbor_app/content/privacy_notice.dart';
import 'package:harbor_app/core/controller.dart';
import 'package:harbor_app/core/models.dart';
import 'package:harbor_app/core/vault.dart';

void main() {
  late String html;
  late String worker;
  late String finalizer;

  setUpAll(() async {
    html = await File('web/privacy.html').readAsString();
    worker = await File('web/harbor_service_worker.js').readAsString();
    finalizer = await File('tool/finalize_web_release.dart').readAsString();
  });

  test('public page and in-app notice share every governed claim', () {
    expect(html, contains(HarborPrivacyNotice.version));
    expect(html, contains(HarborPrivacyNotice.status));
    expect(html, contains(HarborPrivacyNotice.summary));
    expect(html, contains(HarborPrivacyNotice.publicAddress));
    expect(HarborPrivacyNotice.sections, hasLength(9));

    for (final section in HarborPrivacyNotice.sections) {
      expect(html, contains(section.title), reason: section.title);
      expect(html, contains(section.body), reason: section.title);
    }
  });

  test('public notice is self-contained, non-tracking, and accessible', () {
    expect(html, contains('<html lang="en">'));
    expect(html, contains('<meta name="viewport"'));
    expect(html, contains('<meta name="referrer" content="no-referrer">'));
    expect(html, contains('<main>'));
    expect(RegExp(r'<h1(?:\s|>)').allMatches(html), hasLength(1));
    expect(RegExp(r'<section\s').allMatches(html), hasLength(10));

    final ids = RegExp(r'\bid="([^"]+)"')
        .allMatches(html)
        .map((match) => match.group(1)!)
        .toList();
    final labels = RegExp(r'aria-labelledby="([^"]+)"')
        .allMatches(html)
        .map((match) => match.group(1)!)
        .toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(labels, everyElement(isIn(ids)));

    for (final forbidden in <Pattern>[
      RegExp(r'<script\b', caseSensitive: false),
      RegExp(r'<form\b', caseSensitive: false),
      RegExp(r'<input\b', caseSensitive: false),
      RegExp(r'<iframe\b', caseSensitive: false),
      RegExp(r'<img\b', caseSensitive: false),
      RegExp(r'\ssrc\s*=', caseSensitive: false),
      RegExp(r'\son[a-z]+\s*=', caseSensitive: false),
      RegExp(r'\bfetch\s*\(', caseSensitive: false),
      'google-analytics',
      'googletagmanager',
      'facebook',
      'segment.io',
      'sentry',
    ]) {
      expect(html, isNot(contains(forbidden)), reason: '$forbidden');
    }

    final hrefs = RegExp(r'href="([^"]+)"')
        .allMatches(html)
        .map((match) => match.group(1))
        .toList();
    expect(hrefs, <String?>['./']);
  });

  test('privacy page policy forbids all runtime subresource connections', () {
    final policy = RegExp(
      r'<meta http-equiv="Content-Security-Policy" content="([^"]+)">',
    ).firstMatch(html)!.group(1)!;

    for (final directive in <String>[
      "default-src 'none'",
      "base-uri 'none'",
      "object-src 'none'",
      "frame-src 'none'",
      "child-src 'none'",
      "form-action 'none'",
      "connect-src 'none'",
      "img-src 'none'",
      "media-src 'none'",
      "font-src 'none'",
      "style-src 'unsafe-inline'",
    ]) {
      expect(policy, contains(directive), reason: directive);
    }
    expect(policy, isNot(contains('http:')));
    expect(policy, isNot(contains('https:')));
    expect(policy, isNot(contains("'self'")));
  });

  test('verified offline release gives privacy navigation its own asset', () {
    expect(finalizer, contains("'privacy.html'"));
    expect(worker, contains('releaseAssetForNavigation(request)'));
    expect(worker, contains('exact && exact.url === "./privacy.html"'));
    expect(worker, contains('const cacheKey = navigationAsset'));
    expect(worker, contains('await cache.put(cacheKey, verified.clone())'));
    expect(worker, contains('matchPreviousRelease(cacheKey)'));
    expect(
      worker,
      isNot(contains('releaseAssetForRequest(event.request, true)')),
    );
  });

  testWidgets('Privacy opens the bundled notice without exposing vault data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = HarborController(
      HarborVault(records: MemoryValueStore(), keys: MemoryValueStore()),
    );
    await controller.initialize();
    await controller.finishOnboarding('0-6 weeks');
    await controller.saveJournal(
      JournalEntry(
        title: 'PRIVATE NOTICE SENTINEL',
        body: 'This vault text must not appear in the privacy notice.',
      ),
    );
    await tester.pumpWidget(HarborApp(controller: controller));

    await tester.tap(find.text('Privacy'));
    await tester.pumpAndSettle();
    final openNotice = find.byKey(const ValueKey('open_privacy_notice'));
    await tester.ensureVisible(openNotice);
    await tester.tap(openNotice);
    await tester.pumpAndSettle();

    expect(find.text('Privacy notice'), findsOneWidget);
    expect(find.text(HarborPrivacyNotice.status), findsOneWidget);
    expect(find.text(HarborPrivacyNotice.summary), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Privacy notice version ${HarborPrivacyNotice.version}',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(HarborPrivacyNotice.publicAddress),
      findsOneWidget,
    );
    expect(find.text('No live community board'), findsOneWidget);
    expect(find.textContaining('PRIVATE NOTICE SENTINEL'), findsNothing);
    expect(find.byTooltip('Urgent support'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
