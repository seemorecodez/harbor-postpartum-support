import 'package:flutter/services.dart';

import 'diagnostics.dart';

enum HarborClipboardContent { clinicianQuestions, careRequest, diagnostics }

/// Text that Harbor may copy only after the complete [text] was shown in a
/// confirmation dialog and the woman explicitly approved that exact copy.
///
/// The private constructor keeps arbitrary strings from reaching the system
/// clipboard through Harbor's production code without selecting one of the
/// three reviewed product boundaries below.
final class HarborReviewedClipboardPayload {
  const HarborReviewedClipboardPayload._({
    required this.content,
    required this.text,
  });

  factory HarborReviewedClipboardPayload.clinicianQuestions(String text) =>
      HarborReviewedClipboardPayload._(
        content: HarborClipboardContent.clinicianQuestions,
        text: _requireVisibleText(text),
      );

  factory HarborReviewedClipboardPayload.careRequest(String text) =>
      HarborReviewedClipboardPayload._(
        content: HarborClipboardContent.careRequest,
        text: _requireVisibleText(text),
      );

  factory HarborReviewedClipboardPayload.diagnostics(
    HarborDiagnosticReport report,
  ) => HarborReviewedClipboardPayload._(
    content: HarborClipboardContent.diagnostics,
    text: report.encode(),
  );

  final HarborClipboardContent content;
  final String text;

  static String _requireVisibleText(String text) {
    if (text.trim().isEmpty) {
      throw ArgumentError('Clipboard text must be visible.');
    }
    return text;
  }
}

/// Harbor's only production write to the operating-system clipboard.
///
/// Callers must first show [payload.text] in full and receive explicit approval.
Future<void> copyReviewedHarborPayload(
  HarborReviewedClipboardPayload payload,
) => Clipboard.setData(ClipboardData(text: payload.text));
