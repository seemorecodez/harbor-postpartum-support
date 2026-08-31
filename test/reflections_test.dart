import 'package:flutter_test/flutter_test.dart';
import 'package:harbor_app/core/models.dart';
import 'package:harbor_app/core/reflections.dart';

void main() {
  test('reflection waits for three entries without creating an inference', () {
    final result = reflectOnCheckIns([
      CheckIn(mood: 2, anxiety: 4, rest: 1),
      CheckIn(mood: 3, anxiety: 3, rest: 2),
    ]);

    expect(result.ready, isFalse);
    expect(result.observation, contains('1 more private check-in'));
    expect(result.observation, contains('does not use streaks or diagnose'));
    expect(result.clinicianQuestion, isNull);
  });

  test('reflection states threshold counts from at most seven entries', () {
    final entries = List.generate(
      9,
      (index) => CheckIn(
        mood: index.isEven ? 2 : 4,
        anxiety: index < 4 ? 5 : 2,
        rest: index < 3 ? 1 : 4,
      ),
    );

    final result = reflectOnCheckIns(entries);

    expect(result.ready, isTrue);
    expect(result.observation, startsWith('Across your last 7 check-ins'));
    expect(result.observation, contains('mood at 2/5 or lower 4 times'));
    expect(result.observation, contains('anxiety at 4/5 or higher 4 times'));
    expect(result.observation, contains('rest at 2/5 or lower 3 times'));
    expect(result.observation, contains('does not explain why'));
    expect(result.clinicianQuestion, isNot(contains('diagnosis')));
  });

  test('clinician list contains only unanswered questions', () {
    final questions = [
      ClinicianQuestion(text: 'Could we discuss my sleep?'),
      ClinicianQuestion(text: 'Already discussed', answered: true),
      ClinicianQuestion(text: 'What support is available?'),
    ];

    final text = composeClinicianQuestionList(questions);

    expect(text, startsWith('Questions I want to discuss'));
    expect(text, contains('1. Could we discuss my sleep?'));
    expect(text, contains('2. What support is available?'));
    expect(text, isNot(contains('Already discussed')));
  });
}
