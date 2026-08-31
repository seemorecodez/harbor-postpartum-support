import 'models.dart';

final class CheckInReflection {
  const CheckInReflection({
    required this.ready,
    required this.observation,
    this.clinicianQuestion,
  });

  final bool ready;
  final String observation;
  final String? clinicianQuestion;
}

CheckInReflection reflectOnCheckIns(List<CheckIn> checkIns) {
  if (checkIns.length < 3) {
    final remaining = 3 - checkIns.length;
    return CheckInReflection(
      ready: false,
      observation:
          'Add $remaining more private ${remaining == 1 ? 'check-in' : 'check-ins'} before Harbor describes a pattern. Harbor does not use streaks or diagnose from scores.',
    );
  }

  final recent = checkIns.take(7).toList(growable: false);
  final lowMood = recent.where((item) => item.mood <= 2).length;
  final highAnxiety = recent.where((item) => item.anxiety >= 4).length;
  final lowRest = recent.where((item) => item.rest <= 2).length;
  final facts = <String>[
    'mood at 2/5 or lower $lowMood ${lowMood == 1 ? 'time' : 'times'}',
    'anxiety at 4/5 or higher $highAnxiety ${highAnxiety == 1 ? 'time' : 'times'}',
    'rest at 2/5 or lower $lowRest ${lowRest == 1 ? 'time' : 'times'}',
  ];
  final factSentence = facts.join('; ');

  return CheckInReflection(
    ready: true,
    observation:
        'Across your last ${recent.length} check-ins, you recorded $factSentence. This only describes what you entered; it does not explain why or decide what care you need.',
    clinicianQuestion:
        'Across my last ${recent.length} check-ins, I recorded $factSentence. Could we discuss what you would want to know about this in my postpartum care?',
  );
}

String composeClinicianQuestionList(List<ClinicianQuestion> questions) {
  final open = questions.where((question) => !question.answered).toList();
  if (open.isEmpty) return '';
  final lines = <String>['Questions I want to discuss with my clinician:'];
  for (var index = 0; index < open.length; index += 1) {
    lines.add('${index + 1}. ${open[index].text.trim()}');
  }
  return lines.join('\n');
}
