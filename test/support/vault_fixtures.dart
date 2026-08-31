import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:harbor_app/core/vault.dart';

List<int> testVaultKeyBytes() => List<int>.generate(32, (index) => index + 1);

Map<String, Object?> legacyVersion1Data() => {
  'schemaVersion': 1,
  'onboardingComplete': true,
  'postpartumStage': '3-6 months',
  'checkIns': [
    {
      'id': 'legacy-check-in',
      'createdAt': '2026-08-20T12:00:00.000Z',
      'mood': 2,
      'anxiety': 4,
      'rest': 1,
      'note': 'LEGACY-PRIVATE-CHECK-IN',
    },
  ],
  'journalEntries': [
    {
      'id': 'legacy-journal',
      'createdAt': '2026-08-20T13:00:00.000Z',
      'updatedAt': '2026-08-21T13:00:00.000Z',
      'title': 'Legacy title',
      'body': 'LEGACY-PRIVATE-JOURNAL',
    },
  ],
  'clinicianQuestions': [
    {
      'id': 'legacy-question',
      'text': 'LEGACY-PRIVATE-QUESTION',
      'answered': false,
    },
  ],
  'hardDayPlan': {
    'safePerson': 'Maya',
    'safePersonPhone': '5550102',
    'groundingStep': 'Feet on the floor',
    'practicalHelp': 'Bring dinner',
  },
  'careLoadItems': [
    {
      'id': 'legacy-care-load',
      'task': 'LEGACY-PRIVATE-CARE-TASK',
      'owner': 'Support person',
      'completed': false,
    },
  ],
  'careAskDraft': {
    'person': 'Maya',
    'need': 'LEGACY-PRIVATE-CARE-ASK',
    'when': 'tonight',
    'boundary': 'I am resting.',
  },
};

Map<String, Object?> legacyVersion2Data() => {
  ...legacyVersion1Data(),
  'schemaVersion': 2,
};

Future<String> encryptedVaultEnvelope(
  Map<String, Object?> document, {
  List<int>? keyBytes,
  int envelopeVersion = 1,
}) async {
  final cipher = AesGcm.with256bits();
  final box = await cipher.encrypt(
    utf8.encode(jsonEncode(document)),
    secretKey: SecretKey(keyBytes ?? testVaultKeyBytes()),
    aad: utf8.encode(HarborVault.associatedData),
  );
  return jsonEncode({
    'version': envelopeVersion,
    'cipher': 'AES-256-GCM',
    'nonce': base64Encode(box.nonce),
    'cipherText': base64Encode(box.cipherText),
    'mac': base64Encode(box.mac.bytes),
  });
}

TestValueStore seededKeyStore() => TestValueStore({
  HarborVault.encryptionKey: base64Encode(testVaultKeyBytes()),
});

final class TestValueStore implements ValueStore {
  TestValueStore([Map<String, String>? seed]) : values = {...?seed};

  final Map<String, String> values;
  final List<String> writes = [];
  final List<String> deletes = [];
  String? failOnceOnWriteKey;
  bool _writeFailed = false;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    writes.add(key);
    if (!_writeFailed && key == failOnceOnWriteKey) {
      _writeFailed = true;
      throw StateError('Intentional test write failure.');
    }
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    deletes.add(key);
    values.remove(key);
  }
}
