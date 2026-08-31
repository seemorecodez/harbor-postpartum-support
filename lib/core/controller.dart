import 'package:flutter/foundation.dart';

import 'models.dart';
import 'vault.dart';

final class HarborController extends ChangeNotifier {
  HarborController(this.vault);

  final HarborVault vault;
  HarborData data = const HarborData();
  bool loading = true;
  bool saving = false;
  Object? error;

  Future<void> initialize() async {
    loading = true;
    notifyListeners();
    try {
      data = await vault.load();
      error = null;
    } catch (caught) {
      error = caught;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _commit(HarborData next) async {
    if (error != null) {
      throw StateError(
        'Harbor data is locked until the local vault opens or is erased.',
      );
    }
    saving = true;
    notifyListeners();
    try {
      await vault.save(next);
      data = next;
      error = null;
    } catch (caught) {
      error = caught;
      rethrow;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> finishOnboarding(String stage) =>
      _commit(data.copyWith(onboardingComplete: true, postpartumStage: stage));

  Future<void> addCheckIn(CheckIn checkIn) =>
      _commit(data.copyWith(checkIns: [checkIn, ...data.checkIns]));

  Future<void> deleteCheckIn(String id) => _commit(
    data.copyWith(
      checkIns: data.checkIns.where((item) => item.id != id).toList(),
    ),
  );

  Future<void> saveJournal(JournalEntry entry) {
    final existing = data.journalEntries.indexWhere(
      (item) => item.id == entry.id,
    );
    final entries = [...data.journalEntries];
    if (existing == -1) {
      entries.insert(0, entry);
    } else {
      entries[existing] = entry;
    }
    return _commit(data.copyWith(journalEntries: entries));
  }

  Future<void> deleteJournal(String id) => _commit(
    data.copyWith(
      journalEntries: data.journalEntries
          .where((item) => item.id != id)
          .toList(),
    ),
  );

  Future<void> addQuestion(String text) => _commit(
    data.copyWith(
      clinicianQuestions: [
        ClinicianQuestion(text: text),
        ...data.clinicianQuestions,
      ],
    ),
  );

  Future<void> toggleQuestion(String id) => _commit(
    data.copyWith(
      clinicianQuestions: data.clinicianQuestions
          .map((item) => item.id == id ? item.toggled() : item)
          .toList(),
    ),
  );

  Future<void> deleteQuestion(String id) => _commit(
    data.copyWith(
      clinicianQuestions: data.clinicianQuestions
          .where((item) => item.id != id)
          .toList(),
    ),
  );

  Future<void> savePlan(HardDayPlan plan) =>
      _commit(data.copyWith(hardDayPlan: plan));

  Future<void> addCareLoadItem({required String task, required String owner}) =>
      _commit(
        data.copyWith(
          careLoadItems: [
            CareLoadItem(task: task, owner: owner),
            ...data.careLoadItems,
          ],
        ),
      );

  Future<void> toggleCareLoadItem(String id) => _commit(
    data.copyWith(
      careLoadItems: data.careLoadItems
          .map((item) => item.id == id ? item.toggled() : item)
          .toList(),
    ),
  );

  Future<void> deleteCareLoadItem(String id) => _commit(
    data.copyWith(
      careLoadItems: data.careLoadItems.where((item) => item.id != id).toList(),
    ),
  );

  Future<void> saveCareAsk(CareAskDraft draft) =>
      _commit(data.copyWith(careAskDraft: draft));

  Future<void> toggleStoryResonance(String storyId) {
    final normalized = storyId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(storyId, 'storyId', 'Must not be empty.');
    }
    final next = Set<String>.from(data.resonatedStoryIds);
    if (!next.remove(normalized)) next.add(normalized);
    return _commit(data.copyWith(resonatedStoryIds: next));
  }

  Future<void> eraseAll() async {
    saving = true;
    notifyListeners();
    try {
      await vault.eraseAll();
      data = const HarborData();
      error = null;
    } catch (caught) {
      error = caught;
      rethrow;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
