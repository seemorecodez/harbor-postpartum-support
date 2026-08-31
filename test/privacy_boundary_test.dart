import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor_app/core/diagnostics.dart';
import 'package:harbor_app/core/reviewed_clipboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reviewed payloads preserve the exact visible text and purpose', () {
    const questions = 'Questions for my clinician\n\n• Can we discuss sleep?';
    const careRequest = 'I need uninterrupted rest tonight.';

    final questionPayload = HarborReviewedClipboardPayload.clinicianQuestions(
      questions,
    );
    final carePayload = HarborReviewedClipboardPayload.careRequest(careRequest);
    final diagnosticPayload = HarborReviewedClipboardPayload.diagnostics(
      HarborDiagnosticReport.create(
        platform: HarborDiagnosticPlatform.web,
        error: StateError('PRIVATE VALUE MUST NOT ENTER DIAGNOSTICS'),
      ),
    );

    expect(questionPayload.content, HarborClipboardContent.clinicianQuestions);
    expect(questionPayload.text, questions);
    expect(carePayload.content, HarborClipboardContent.careRequest);
    expect(carePayload.text, careRequest);
    expect(diagnosticPayload.content, HarborClipboardContent.diagnostics);
    expect(
      diagnosticPayload.text,
      contains('"errorCode": "vault_unavailable"'),
    );
    expect(diagnosticPayload.text, isNot(contains('PRIVATE VALUE')));
  });

  test('empty personal clipboard payloads fail closed', () {
    expect(
      () => HarborReviewedClipboardPayload.clinicianQuestions('  \n '),
      throwsArgumentError,
    );
    expect(
      () => HarborReviewedClipboardPayload.careRequest(''),
      throwsArgumentError,
    );
  });

  test('the gateway writes only its reviewed payload text', () async {
    String? clipboardText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardText = (call.arguments as Map)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    final payload = HarborReviewedClipboardPayload.careRequest(
      'Please take the next feeding and cleanup.',
    );
    await copyReviewedHarborPayload(payload);

    expect(clipboardText, payload.text);
  });

  test(
    'production source has one typed clipboard sink and no logging sink',
    () async {
      final files = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();
      final sources = <String, String>{
        for (final file in files)
          file.path.replaceAll('\\', '/'): await file.readAsString(),
      };
      final clipboardCalls = <String>[];

      for (final entry in sources.entries) {
        if (entry.value.contains('Clipboard.setData(')) {
          clipboardCalls.add(entry.key);
        }
        for (final forbidden in <String>[
          'debugPrint(',
          'dart:developer',
          'developer.log(',
          'stderr.',
          'stdout.',
        ]) {
          expect(
            entry.value,
            isNot(contains(forbidden)),
            reason: '${entry.key}: $forbidden',
          );
        }
        expect(
          RegExp(r'(?<![A-Za-z])print\s*\(').hasMatch(entry.value),
          isFalse,
          reason: '${entry.key}: print',
        );
      }

      expect(clipboardCalls, <String>['lib/core/reviewed_clipboard.dart']);
      final appSource = sources['lib/app.dart']!;
      expect(
        RegExp(r'copyReviewedHarborPayload\(').allMatches(appSource),
        hasLength(3),
      );
      expect(appSource, isNot(contains('Clipboard.')));
    },
  );
}
