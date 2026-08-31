import 'dart:convert';

String _newId() => '${DateTime.now().microsecondsSinceEpoch}';

final class HarborData {
  const HarborData({
    this.schemaVersion = currentSchemaVersion,
    this.onboardingComplete = false,
    this.postpartumStage = '0-6 weeks',
    this.checkIns = const [],
    this.journalEntries = const [],
    this.clinicianQuestions = const [],
    this.hardDayPlan = const HardDayPlan(),
    this.careLoadItems = const [],
    this.careAskDraft = const CareAskDraft(),
    this.resonatedStoryIds = const {},
  });

  static const currentSchemaVersion = 3;

  final int schemaVersion;
  final bool onboardingComplete;
  final String postpartumStage;
  final List<CheckIn> checkIns;
  final List<JournalEntry> journalEntries;
  final List<ClinicianQuestion> clinicianQuestions;
  final HardDayPlan hardDayPlan;
  final List<CareLoadItem> careLoadItems;
  final CareAskDraft careAskDraft;
  final Set<String> resonatedStoryIds;

  HarborData copyWith({
    bool? onboardingComplete,
    String? postpartumStage,
    List<CheckIn>? checkIns,
    List<JournalEntry>? journalEntries,
    List<ClinicianQuestion>? clinicianQuestions,
    HardDayPlan? hardDayPlan,
    List<CareLoadItem>? careLoadItems,
    CareAskDraft? careAskDraft,
    Set<String>? resonatedStoryIds,
  }) => HarborData(
    schemaVersion: currentSchemaVersion,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    postpartumStage: postpartumStage ?? this.postpartumStage,
    checkIns: checkIns ?? this.checkIns,
    journalEntries: journalEntries ?? this.journalEntries,
    clinicianQuestions: clinicianQuestions ?? this.clinicianQuestions,
    hardDayPlan: hardDayPlan ?? this.hardDayPlan,
    careLoadItems: careLoadItems ?? this.careLoadItems,
    careAskDraft: careAskDraft ?? this.careAskDraft,
    resonatedStoryIds: resonatedStoryIds ?? this.resonatedStoryIds,
  );

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'onboardingComplete': onboardingComplete,
    'postpartumStage': postpartumStage,
    'checkIns': checkIns.map((item) => item.toJson()).toList(),
    'journalEntries': journalEntries.map((item) => item.toJson()).toList(),
    'clinicianQuestions': clinicianQuestions
        .map((item) => item.toJson())
        .toList(),
    'hardDayPlan': hardDayPlan.toJson(),
    'careLoadItems': careLoadItems.map((item) => item.toJson()).toList(),
    'careAskDraft': careAskDraft.toJson(),
    'resonatedStoryIds': resonatedStoryIds.toList()..sort(),
  };

  factory HarborData.fromJson(Map<String, Object?> json) {
    final version = json['schemaVersion'];
    if (version is! int) {
      throw const FormatException('Invalid Harbor schema version.');
    }
    if (version != currentSchemaVersion) {
      throw UnsupportedHarborDataVersionException(version);
    }
    return HarborData(
      schemaVersion: version,
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      postpartumStage: json['postpartumStage'] as String? ?? '0-6 weeks',
      checkIns: _maps(json['checkIns']).map(CheckIn.fromJson).toList(),
      journalEntries: _maps(json['journalEntries'])
          .map(JournalEntry.fromJson)
          .toList(),
      clinicianQuestions: _maps(json['clinicianQuestions'])
          .map(ClinicianQuestion.fromJson)
          .toList(),
      hardDayPlan: switch (json['hardDayPlan']) {
        final Map value => HardDayPlan.fromJson(
          Map<String, Object?>.from(value),
        ),
        _ => const HardDayPlan(),
      },
      careLoadItems: _maps(json['careLoadItems'])
          .map(CareLoadItem.fromJson)
          .toList(),
      careAskDraft: switch (json['careAskDraft']) {
        final Map value => CareAskDraft.fromJson(
          Map<String, Object?>.from(value),
        ),
        _ => const CareAskDraft(),
      },
      resonatedStoryIds: _strings(json['resonatedStoryIds']).toSet(),
    );
  }

  String encode() => jsonEncode(toJson());

  static HarborDataDocument decodeDocument(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException('Invalid Harbor data document.');
    }
    final source = Map<String, Object?>.from(decoded);
    final rawVersion = source['schemaVersion'] ?? 1;
    if (rawVersion is! int || rawVersion < 1) {
      throw const FormatException('Invalid Harbor schema version.');
    }
    if (rawVersion > currentSchemaVersion) {
      throw UnsupportedHarborDataVersionException(rawVersion);
    }

    final migrated = switch (rawVersion) {
      1 => _migrateVersion2To3(_migrateVersion1To2(source)),
      2 => _migrateVersion2To3(source),
      currentSchemaVersion => source,
      _ => throw UnsupportedHarborDataVersionException(rawVersion),
    };
    return HarborDataDocument(
      data: HarborData.fromJson(migrated),
      sourceSchemaVersion: rawVersion,
    );
  }

  factory HarborData.decode(String value) => decodeDocument(value).data;
}

final class HarborDataDocument {
  const HarborDataDocument({
    required this.data,
    required this.sourceSchemaVersion,
  });

  final HarborData data;
  final int sourceSchemaVersion;

  bool get wasMigrated =>
      sourceSchemaVersion != HarborData.currentSchemaVersion;
}

final class UnsupportedHarborDataVersionException implements Exception {
  const UnsupportedHarborDataVersionException(this.version);

  final int version;

  @override
  String toString() => 'Unsupported Harbor data version: $version';
}

Map<String, Object?> _migrateVersion1To2(Map<String, Object?> source) {
  final migrated = Map<String, Object?>.from(source);
  migrated['schemaVersion'] = 2;
  migrated.putIfAbsent('careLoadItems', () => <Object?>[]);
  migrated.putIfAbsent('careAskDraft', () => <String, Object?>{});
  return migrated;
}

Map<String, Object?> _migrateVersion2To3(Map<String, Object?> source) {
  final migrated = Map<String, Object?>.from(source);
  migrated['schemaVersion'] = HarborData.currentSchemaVersion;
  migrated.putIfAbsent('resonatedStoryIds', () => <Object?>[]);
  return migrated;
}

Iterable<Map<String, Object?>> _maps(Object? value) sync* {
  if (value is! List) return;
  for (final item in value) {
    if (item is Map) yield Map<String, Object?>.from(item);
  }
}

Iterable<String> _strings(Object? value) sync* {
  if (value is! List) return;
  for (final item in value) {
    if (item is String && item.trim().isNotEmpty) yield item;
  }
}

final class CheckIn {
  CheckIn({
    String? id,
    DateTime? createdAt,
    required this.mood,
    required this.anxiety,
    required this.rest,
    this.note = '',
  }) : id = id ?? _newId(),
       createdAt = createdAt ?? DateTime.now().toUtc();

  final String id;
  final DateTime createdAt;
  final int mood;
  final int anxiety;
  final int rest;
  final String note;

  Map<String, Object?> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'mood': mood,
    'anxiety': anxiety,
    'rest': rest,
    'note': note,
  };

  factory CheckIn.fromJson(Map<String, Object?> json) => CheckIn(
    id: json['id'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    mood: json['mood'] as int,
    anxiety: json['anxiety'] as int,
    rest: json['rest'] as int,
    note: json['note'] as String? ?? '',
  );
}

final class JournalEntry {
  JournalEntry({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.title,
    required this.body,
  }) : id = id ?? _newId(),
       createdAt = createdAt ?? DateTime.now().toUtc(),
       updatedAt = updatedAt ?? DateTime.now().toUtc();

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String title;
  final String body;

  JournalEntry edited({required String title, required String body}) =>
      JournalEntry(
        id: id,
        createdAt: createdAt,
        updatedAt: DateTime.now().toUtc(),
        title: title,
        body: body,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'title': title,
    'body': body,
  };

  factory JournalEntry.fromJson(Map<String, Object?> json) => JournalEntry(
    id: json['id'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
  );
}

final class ClinicianQuestion {
  ClinicianQuestion({String? id, required this.text, this.answered = false})
    : id = id ?? _newId();

  final String id;
  final String text;
  final bool answered;

  ClinicianQuestion toggled() =>
      ClinicianQuestion(id: id, text: text, answered: !answered);

  Map<String, Object?> toJson() => {
    'id': id,
    'text': text,
    'answered': answered,
  };

  factory ClinicianQuestion.fromJson(Map<String, Object?> json) =>
      ClinicianQuestion(
        id: json['id'] as String,
        text: json['text'] as String,
        answered: json['answered'] as bool? ?? false,
      );
}

final class HardDayPlan {
  const HardDayPlan({
    this.safePerson = '',
    this.safePersonPhone = '',
    this.groundingStep = '',
    this.practicalHelp = '',
  });

  final String safePerson;
  final String safePersonPhone;
  final String groundingStep;
  final String practicalHelp;

  Map<String, Object?> toJson() => {
    'safePerson': safePerson,
    'safePersonPhone': safePersonPhone,
    'groundingStep': groundingStep,
    'practicalHelp': practicalHelp,
  };

  factory HardDayPlan.fromJson(Map<String, Object?> json) => HardDayPlan(
    safePerson: json['safePerson'] as String? ?? '',
    safePersonPhone: json['safePersonPhone'] as String? ?? '',
    groundingStep: json['groundingStep'] as String? ?? '',
    practicalHelp: json['practicalHelp'] as String? ?? '',
  );
}

final class CareLoadItem {
  CareLoadItem({
    String? id,
    required this.task,
    this.owner = 'Unassigned',
    this.completed = false,
  }) : id = id ?? _newId();

  final String id;
  final String task;
  final String owner;
  final bool completed;

  CareLoadItem toggled() =>
      CareLoadItem(id: id, task: task, owner: owner, completed: !completed);

  Map<String, Object?> toJson() => {
    'id': id,
    'task': task,
    'owner': owner,
    'completed': completed,
  };

  factory CareLoadItem.fromJson(Map<String, Object?> json) => CareLoadItem(
    id: json['id'] as String,
    task: json['task'] as String? ?? '',
    owner: json['owner'] as String? ?? 'Unassigned',
    completed: json['completed'] as bool? ?? false,
  );
}

final class CareAskDraft {
  const CareAskDraft({
    this.person = '',
    this.need = '',
    this.when = '',
    this.boundary = '',
  });

  final String person;
  final String need;
  final String when;
  final String boundary;

  Map<String, Object?> toJson() => {
    'person': person,
    'need': need,
    'when': when,
    'boundary': boundary,
  };

  factory CareAskDraft.fromJson(Map<String, Object?> json) => CareAskDraft(
    person: json['person'] as String? ?? '',
    need: json['need'] as String? ?? '',
    when: json['when'] as String? ?? '',
    boundary: json['boundary'] as String? ?? '',
  );

  String compose() {
    final parts = <String>[];
    final recipient = person.trim().isEmpty
        ? 'I need to ask for help'
        : person.trim();
    if (need.trim().isNotEmpty) {
      parts.add(
        '$recipient, I need you to take responsibility for ${need.trim()}',
      );
    } else {
      parts.add('$recipient, I need practical help');
    }
    if (when.trim().isNotEmpty) parts.add('by ${when.trim()}');
    var message = '${parts.join(' ')}.';
    if (boundary.trim().isNotEmpty) {
      message += ' ${boundary.trim()}';
      if (!message.endsWith('.') &&
          !message.endsWith('!') &&
          !message.endsWith('?')) {
        message += '.';
      }
    }
    return message;
  }
}
