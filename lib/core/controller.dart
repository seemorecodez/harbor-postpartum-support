import 'package:flutter/foundation.dart';

import 'app_lock.dart';
import 'models.dart';
import 'vault.dart';

final class HarborController extends ChangeNotifier {
  HarborController(this.vault, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final HarborVault vault;
  final DateTime Function() _now;
  HarborData data = const HarborData();
  bool loading = true;
  bool saving = false;
  bool unlocking = false;
  bool appLockEnabled = false;
  bool locked = false;
  Object? error;
  int failedUnlockAttempts = 0;
  DateTime? unlockNotBefore;
  bool _pendingVaultLock = false;

  Duration get unlockWait {
    final until = unlockNotBefore;
    if (until == null) return Duration.zero;
    final remaining = until.difference(_now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> initialize() async {
    loading = true;
    notifyListeners();
    try {
      appLockEnabled = await vault.appLockEnabled();
      if (appLockEnabled && !vault.hasUnlockedAppLock) {
        vault.lockApp();
        data = const HarborData();
        locked = true;
        error = null;
        return;
      }
      data = await vault.load();
      locked = false;
      error = null;
    } catch (caught) {
      error = caught;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _commit(HarborData next) async {
    if (error != null || locked) {
      throw StateError(
        'Harbor data is locked until the local vault opens or is erased.',
      );
    }
    saving = true;
    notifyListeners();
    try {
      await vault.save(next);
      if (!locked) data = next;
      error = null;
    } catch (caught) {
      error = caught;
      rethrow;
    } finally {
      saving = false;
      if (_pendingVaultLock) {
        _pendingVaultLock = false;
        vault.lockApp();
        data = const HarborData();
      }
      notifyListeners();
    }
  }

  Future<void> enableAppLock(String passphrase) async {
    if (error != null || locked || appLockEnabled) {
      throw StateError('Harbor cannot change app-lock settings right now.');
    }
    saving = true;
    notifyListeners();
    try {
      await vault.enableAppLock(passphrase);
      appLockEnabled = true;
      error = null;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> unlockApp(String passphrase) async {
    if (!locked || !appLockEnabled) {
      throw StateError('Harbor is not waiting to be unlocked.');
    }
    final wait = unlockWait;
    if (wait > Duration.zero) {
      throw HarborAppLockThrottledException(wait);
    }
    unlocking = true;
    notifyListeners();
    try {
      await vault.unlockAppLock(passphrase);
      data = await vault.load();
      locked = false;
      error = null;
      failedUnlockAttempts = 0;
      unlockNotBefore = null;
    } on HarborAppLockPassphraseException {
      failedUnlockAttempts++;
      final delay = _delayAfterFailure(failedUnlockAttempts);
      unlockNotBefore = delay == Duration.zero ? null : _now().add(delay);
      rethrow;
    } catch (caught) {
      error = caught;
      rethrow;
    } finally {
      unlocking = false;
      notifyListeners();
    }
  }

  Future<void> changeAppLockPassphrase({
    required String currentPassphrase,
    required String newPassphrase,
  }) async {
    if (error != null || locked || !appLockEnabled) {
      throw StateError('Harbor cannot change app-lock settings right now.');
    }
    saving = true;
    notifyListeners();
    try {
      await vault.changeAppLockPassphrase(
        currentPassphrase: currentPassphrase,
        newPassphrase: newPassphrase,
      );
      error = null;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> disableAppLock(String currentPassphrase) async {
    if (error != null || locked || !appLockEnabled) {
      throw StateError('Harbor cannot change app-lock settings right now.');
    }
    saving = true;
    notifyListeners();
    try {
      await vault.disableAppLock(currentPassphrase);
      appLockEnabled = false;
      failedUnlockAttempts = 0;
      unlockNotBefore = null;
      error = null;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  void lockNow() {
    if (!appLockEnabled || locked) return;
    locked = true;
    data = const HarborData();
    error = null;
    if (saving) {
      _pendingVaultLock = true;
    } else {
      vault.lockApp();
    }
    notifyListeners();
  }

  static Duration _delayAfterFailure(int attempts) => switch (attempts) {
    <= 2 => Duration.zero,
    3 => const Duration(seconds: 5),
    4 => const Duration(seconds: 15),
    _ => const Duration(seconds: 30),
  };

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
      appLockEnabled = false;
      locked = false;
      failedUnlockAttempts = 0;
      unlockNotBefore = null;
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

final class HarborAppLockThrottledException implements Exception {
  const HarborAppLockThrottledException(this.remaining);

  final Duration remaining;

  @override
  String toString() => 'Harbor unlock is paused for ${remaining.inSeconds}s.';
}
