import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'content/guide.dart';
import 'content/stories.dart';
import 'core/app_lock.dart';
import 'core/app_visibility.dart';
import 'core/controller.dart';
import 'core/diagnostics.dart';
import 'core/models.dart';
import 'core/reflections.dart';
import 'core/release_info.dart';
import 'core/vault.dart';
import 'theme.dart';

final class HarborApp extends StatefulWidget {
  const HarborApp({super.key, required this.controller});

  final HarborController controller;

  @override
  State<HarborApp> createState() => _HarborAppState();
}

final class _HarborAppState extends State<HarborApp>
    with WidgetsBindingObserver {
  late final RemoveVisibilityLockListener _removeVisibilityLockListener;

  HarborController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _removeVisibilityLockListener = registerVisibilityLock(controller.lockNow);
  }

  @override
  void dispose() {
    _removeVisibilityLockListener();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      controller.lockNow();
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => MaterialApp(
      key: ValueKey(
        'harbor-${controller.locked ? 'locked' : 'open'}-'
        '${controller.error == null ? 'ready' : 'error'}',
      ),
      debugShowCheckedModeBanner: false,
      title: 'Harbor',
      theme: harborTheme(),
      home: controller.loading
          ? const _LoadingScreen()
          : controller.error != null
          ? VaultProblemScreen(controller: controller)
          : controller.locked
          ? AppLockScreen(controller: controller)
          : controller.data.onboardingComplete
          ? HarborShell(controller: controller)
          : OnboardingScreen(controller: controller),
    ),
  );
}

final class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key, required this.controller});

  final HarborController controller;

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

final class _AppLockScreenState extends State<AppLockScreen> {
  final passphrase = TextEditingController();
  bool obscure = true;
  String? message;

  @override
  void dispose() {
    passphrase.dispose();
    super.dispose();
  }

  Future<void> unlock() async {
    FocusScope.of(context).unfocus();
    setState(() => message = null);
    try {
      await widget.controller.unlockApp(passphrase.text);
    } on HarborAppLockThrottledException catch (error) {
      if (!mounted) return;
      setState(
        () => message =
            'Unlock is briefly paused after repeated attempts. Try again in ${error.remaining.inSeconds + 1} seconds.',
      );
    } on HarborAppLockPassphraseException {
      if (!mounted) return;
      final wait = widget.controller.unlockWait;
      setState(
        () => message = wait > Duration.zero
            ? 'That passphrase did not match. Try again in ${wait.inSeconds + 1} seconds.'
            : 'That passphrase did not match. Check spaces and capitalization, then try again.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => message = 'Harbor could not unlock this local vault. Your encrypted data was not replaced.',
      );
    }
  }

  Future<void> showRecovery() async {
    final erase = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('No passphrase recovery'),
        content: const Text(
          'Harbor has no account, server copy, recovery email, or hidden back door. If the passphrase is lost, the encrypted local data cannot be opened. You can keep trying or permanently erase Harbor and start over.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep my data'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: HarborColors.clay),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue to erase'),
          ),
        ],
      ),
    );
    if (erase != true || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Permanently erase this Harbor data?'),
        content: const Text(
          'This removes the encrypted records, wrapped key, and app lock from this browser or device. It cannot be undone. Nothing will be sent anywhere.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep my data'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: HarborColors.clay),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Erase permanently'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.controller.eraseAll();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _HarborMark(),
                  const SizedBox(height: 28),
                  const Icon(
                    Icons.lock_outline,
                    size: 44,
                    color: HarborColors.plum,
                    semanticLabel: 'Harbor local app lock active',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Harbor is locked.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Enter your Harbor passphrase. The passphrase stays on this device and is used only to unwrap the local vault key.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    key: const ValueKey('app_lock_passphrase'),
                    controller: passphrase,
                    obscureText: obscure,
                    enableSuggestions: false,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) =>
                        widget.controller.unlocking ? null : unlock(),
                    decoration: InputDecoration(
                      labelText: 'Harbor passphrase',
                      suffixIcon: IconButton(
                        tooltip: obscure
                            ? 'Show passphrase'
                            : 'Hide passphrase',
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        message!,
                        key: const ValueKey('app_lock_message'),
                        style: const TextStyle(color: HarborColors.clay),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    key: const ValueKey('unlock_harbor'),
                    onPressed: widget.controller.unlocking ? null : unlock,
                    icon: widget.controller.unlocking
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_open_outlined),
                    label: Text(
                      widget.controller.unlocking
                          ? 'Unlocking…'
                          : 'Unlock Harbor',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    key: const ValueKey('app_lock_recovery'),
                    onPressed: widget.controller.unlocking
                        ? null
                        : showRecovery,
                    child: const Text('I cannot remember the passphrase'),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () => showEmergencySupport(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: HarborColors.clay,
                    ),
                    icon: const Icon(Icons.emergency_outlined),
                    label: const Text('Open urgent support options'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

final class VaultProblemScreen extends StatelessWidget {
  const VaultProblemScreen({super.key, required this.controller});

  final HarborController controller;

  bool get _needsNewerVersion =>
      controller.error is UnsupportedHarborDataVersionException ||
      controller.error is UnsupportedHarborVaultVersionException ||
      controller.error is UnsupportedHarborAppLockVersionException;

  Future<void> _confirmErase(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Permanently erase this Harbor data?'),
        content: const Text(
          'This removes the encrypted records and their key from this device. '
          'It cannot be undone. Nothing will be sent anywhere.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep my data'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: HarborColors.clay),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Erase permanently'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await controller.eraseAll();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harbor could not erase the local vault. Your data was not replaced.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _needsNewerVersion
        ? 'Harbor needs an update to open your data.'
        : 'Harbor could not safely unlock your data.';
    final body = _needsNewerVersion
        ? 'Your encrypted records remain on this device. Update Harbor, then try again. Do not clear this site or app data if you want to preserve them.'
        : 'Harbor stopped before showing or replacing any records. Your encrypted local data remains untouched. You can try again or deliberately erase it and start over.';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _HarborMark(),
                  const SizedBox(height: 30),
                  Icon(
                    Icons.lock_clock_outlined,
                    color: HarborColors.plum,
                    size: 42,
                    semanticLabel: 'Encrypted data protected',
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: controller.saving ? null : controller.initialize,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try opening my data again'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const ValueKey('vault_problem_diagnostics'),
                    onPressed: controller.saving
                        ? null
                        : () => showDiagnosticExport(context, controller),
                    icon: const Icon(Icons.bug_report_outlined),
                    label: const Text('Preview diagnostic details'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: HarborColors.clay,
                    ),
                    onPressed: controller.saving
                        ? null
                        : () => _confirmErase(context),
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: const Text('Erase this local Harbor data'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Semantics(
        label: 'Opening encrypted local Harbor data',
        child: const CircularProgressIndicator(),
      ),
    ),
  );
}

final class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.controller});

  final HarborController controller;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

final class _OnboardingScreenState extends State<OnboardingScreen> {
  static const stages = [
    '0-6 weeks',
    '7-12 weeks',
    '3-6 months',
    '7-12 months',
  ];
  int step = 0;
  bool understandsPrivacy = false;
  bool understandsSafety = false;
  String stage = stages.first;

  Future<void> finish() async {
    try {
      await widget.controller.finishOnboarding(stage);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harbor could not save this setup. Nothing was sent anywhere.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = switch (step) {
      0 => _PrivacyOnboarding(
        accepted: understandsPrivacy,
        onChanged: (value) => setState(() => understandsPrivacy = value),
      ),
      1 => _StageOnboarding(
        stage: stage,
        stages: stages,
        onChanged: (value) => setState(() => stage = value),
      ),
      _ => _SafetyOnboarding(
        accepted: understandsSafety,
        onChanged: (value) => setState(() => understandsSafety = value),
      ),
    };
    final canContinue = step == 0
        ? understandsPrivacy
        : step == 2
        ? understandsSafety
        : true;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _HarborMark(),
                  const SizedBox(height: 30),
                  Semantics(
                    label: 'Setup step ${step + 1} of 3',
                    child: LinearProgressIndicator(value: (step + 1) / 3),
                  ),
                  const SizedBox(height: 28),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: page,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      if (step > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => step -= 1),
                            child: const Text('Back'),
                          ),
                        ),
                      if (step > 0) const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: canContinue && !widget.controller.saving
                              ? () => step < 2
                                    ? setState(() => step += 1)
                                    : finish()
                              : null,
                          child: Text(step < 2 ? 'Continue' : 'Enter Harbor'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _PrivacyOnboarding extends StatelessWidget {
  const _PrivacyOnboarding({required this.accepted, required this.onChanged});

  final bool accepted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('privacy'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'A space that belongs to you.',
        style: Theme.of(context).textTheme.displaySmall,
      ),
      const SizedBox(height: 14),
      Text(
        'No account. No ads. No analytics. No engagement tracking. Harbor encrypts what you write and keeps it in this ${kIsWeb ? 'browser profile' : 'device'}.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 18),
      const _InfoPanel(
        icon: Icons.lock_outline,
        title: 'Your words are not a product',
        body: 'Harbor does not send journal entries, check-ins, questions, plans, care-load tasks, care-request drafts, or private story responses to a server. Each installation is independent.',
      ),
      if (kIsWeb) ...[
        const SizedBox(height: 12),
        const _InfoPanel(
          icon: Icons.language_outlined,
          title: 'Browser boundary',
          body: "Opening Harbor downloads the app from its host. The host may see ordinary request metadata, but Harbor sends none of your entries. Clearing this site's browser data permanently erases them.",
          tone: HarborColors.blush,
        ),
      ],
      const SizedBox(height: 14),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: accepted,
        onChanged: (value) => onChanged(value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        title: const Text('I understand where my Harbor data lives.'),
      ),
    ],
  );
}

final class _StageOnboarding extends StatelessWidget {
  const _StageOnboarding({
    required this.stage,
    required this.stages,
    required this.onChanged,
  });

  final String stage;
  final List<String> stages;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('stage'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Where are you right now?',
        style: Theme.of(context).textTheme.displaySmall,
      ),
      const SizedBox(height: 14),
      Text(
        'Choose the closest stage. You can change it later. Harbor uses this only on this device to organize information; it does not diagnose anything.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 24),
      DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: stage,
        decoration: const InputDecoration(labelText: 'Postpartum stage'),
        items: stages
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
      const SizedBox(height: 18),
      const _InfoPanel(
        icon: Icons.female,
        title: "Built around women's realities",
        body: 'Harbor names invisible care work, medical dismissal, feeding pressure, body changes, anger, grief, joy, and ambivalence without judging women for any of them.',
      ),
    ],
  );
}

final class _SafetyOnboarding extends StatelessWidget {
  const _SafetyOnboarding({required this.accepted, required this.onChanged});

  final bool accepted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('safety'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Support, not surveillance.',
        style: Theme.of(context).textTheme.displaySmall,
      ),
      const SizedBox(height: 14),
      Text(
        'Harbor is educational and reflective. It does not monitor you, diagnose postpartum depression, replace a clinician, or contact emergency services for you.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 18),
      const _InfoPanel(
        icon: Icons.emergency_outlined,
        title: 'If safety is at risk',
        body: 'In the United States, call 911 for immediate danger. Call or text 988 for suicide or crisis support. Outside the U.S., use your local emergency or crisis service.',
        tone: HarborColors.blush,
      ),
      const SizedBox(height: 14),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: accepted,
        onChanged: (value) => onChanged(value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        title: const Text(
          'I understand Harbor is not emergency or medical care.',
        ),
      ),
    ],
  );
}

final class HarborShell extends StatefulWidget {
  const HarborShell({super.key, required this.controller});

  final HarborController controller;

  @override
  State<HarborShell> createState() => _HarborShellState();
}

final class _HarborShellState extends State<HarborShell> {
  int selected = 0;

  static const destinations = [
    NavigationDestination(
      icon: Icon(Icons.wb_sunny_outlined),
      selectedIcon: Icon(Icons.wb_sunny),
      label: 'Today',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book),
      label: 'Journal',
    ),
    NavigationDestination(
      icon: Icon(Icons.question_answer_outlined),
      selectedIcon: Icon(Icons.question_answer),
      label: 'Questions',
    ),
    NavigationDestination(
      icon: Icon(Icons.health_and_safety_outlined),
      selectedIcon: Icon(Icons.health_and_safety),
      label: 'Plan',
    ),
    NavigationDestination(
      icon: Icon(Icons.auto_stories_outlined),
      selectedIcon: Icon(Icons.auto_stories),
      label: 'Library',
    ),
    NavigationDestination(
      icon: Icon(Icons.diversity_2_outlined),
      selectedIcon: Icon(Icons.diversity_2),
      label: 'Stories',
    ),
    NavigationDestination(
      icon: Icon(Icons.shield_outlined),
      selectedIcon: Icon(Icons.shield),
      label: 'Privacy',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      TodayScreen(controller: widget.controller),
      JournalScreen(controller: widget.controller),
      QuestionsScreen(controller: widget.controller),
      PlanScreen(controller: widget.controller),
      const LibraryScreen(),
      StoriesScreen(controller: widget.controller),
      PrivacyScreen(controller: widget.controller),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 920;
        final body = Column(
          children: [
            _TopBar(saving: widget.controller.saving, showNavigation: !wide),
            Expanded(
              child: IndexedStack(index: selected, children: screens),
            ),
          ],
        );
        if (!wide) {
          return Scaffold(
            drawer: Drawer(
              width: constraints.maxWidth,
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  children: [
                    Row(
                      children: [
                        const Expanded(child: _HarborMark()),
                        IconButton(
                          tooltip: 'Close navigation',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ...destinations.indexed.map((entry) {
                      final (index, item) = entry;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          minVerticalPadding: 12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          selected: selected == index,
                          selectedTileColor: HarborColors.blush,
                          leading: selected == index
                              ? item.selectedIcon
                              : item.icon,
                          title: Text(item.label),
                          onTap: () {
                            setState(() => selected = index);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            body: body,
          );
        }
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                extended: constraints.maxWidth >= 1180,
                selectedIndex: selected,
                onDestinationSelected: (value) =>
                    setState(() => selected = value),
                leading: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: _HarborMark(compact: true),
                ),
                destinations: destinations
                    .map(
                      (item) => NavigationRailDestination(
                        icon: item.icon,
                        selectedIcon: item.selectedIcon,
                        label: Text(item.label),
                      ),
                    )
                    .toList(),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }
}

final class _TopBar extends StatelessWidget {
  const _TopBar({required this.saving, required this.showNavigation});

  final bool saving;
  final bool showNavigation;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: HarborColors.line)),
    ),
    child: Row(
      children: [
        if (showNavigation) ...[
          Builder(
            builder: (context) => IconButton(
              tooltip: 'Open navigation',
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu),
            ),
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            saving ? 'Encrypting locally...' : 'Private on this device',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        if (showNavigation)
          IconButton(
            tooltip: 'Urgent support',
            color: HarborColors.clay,
            onPressed: () => showEmergencySupport(context),
            icon: const Icon(Icons.emergency_outlined),
          )
        else
          TextButton.icon(
            onPressed: () => showEmergencySupport(context),
            style: TextButton.styleFrom(foregroundColor: HarborColors.clay),
            icon: const Icon(Icons.emergency_outlined),
            label: const Text('Urgent support'),
          ),
      ],
    ),
  );
}

final class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.controller});

  final HarborController controller;

  @override
  Widget build(BuildContext context) {
    final latest = controller.data.checkIns.firstOrNull;
    final reflection = reflectOnCheckIns(controller.data.checkIns);
    final reflectionQuestion = reflection.clinicianQuestion;
    final reflectionAlreadySaved =
        reflectionQuestion != null &&
        controller.data.clinicianQuestions.any(
          (question) => question.text == reflectionQuestion,
        );
    return _Page(
      title: 'How is today, really?',
      eyebrow: controller.data.postpartumStage,
      action: FilledButton.icon(
        onPressed: () => showCheckIn(context, controller),
        icon: const Icon(Icons.add),
        label: const Text('Check in'),
      ),
      children: [
        _HeroCard(latest: latest),
        const SizedBox(height: 22),
        _InfoPanel(
          icon: reflection.ready
              ? Icons.query_stats_outlined
              : Icons.lock_clock_outlined,
          title: reflection.ready
              ? 'A factual reflection, not a diagnosis'
              : 'Patterns need at least three check-ins',
          body: reflection.observation,
          tone: reflection.ready ? HarborColors.mist : HarborColors.blush,
        ),
        if (reflectionQuestion != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('save_reflection_question'),
              onPressed: reflectionAlreadySaved
                  ? null
                  : () async {
                      await controller.addQuestion(reflectionQuestion);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Factual reflection added to your private clinician questions.',
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.add_comment_outlined),
              label: Text(
                reflectionAlreadySaved
                    ? 'Already in clinician questions'
                    : 'Add these facts to clinician questions',
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        Text(
          'Your recent check-ins',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        if (controller.data.checkIns.isEmpty)
          const _EmptyState(
            icon: Icons.favorite_border,
            title: 'No score to perform for',
            body: 'A check-in is a private note to yourself, not a streak and not a judgment.',
          )
        else
          ...controller.data.checkIns
              .take(5)
              .map(
                (item) => Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: HarborColors.blush,
                      child: Text('${item.mood}'),
                    ),
                    title: Text(_date(item.createdAt)),
                    subtitle: Text(
                      'Anxiety ${item.anxiety}/5 | Rest ${item.rest}/5${item.note.isEmpty ? '' : '\n${item.note}'}',
                    ),
                    isThreeLine: item.note.isNotEmpty,
                    trailing: IconButton(
                      tooltip: 'Delete check-in',
                      onPressed: () => confirmDelete(
                        context,
                        'Delete this check-in?',
                        () => controller.deleteCheckIn(item.id),
                      ),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

final class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.latest});

  final CheckIn? latest;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [HarborColors.plumDark, HarborColors.plum],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.water_outlined, color: Colors.white, size: 34),
        const SizedBox(height: 24),
        Text(
          latest == null
              ? 'You do not have to make this look easy.'
              : 'Your last check-in is information, not a verdict.',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 10),
        Text(
          latest == null
              ? 'Harbor makes room for the whole truth of postpartum life.'
              : 'Mood ${latest!.mood}/5 | Anxiety ${latest!.anxiety}/5 | Rest ${latest!.rest}/5',
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: Colors.white.withValues(alpha: 0.88)),
        ),
      ],
    ),
  );
}

final class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key, required this.controller});

  final HarborController controller;

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

final class _JournalScreenState extends State<JournalScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final normalized = query.trim().toLowerCase();
    final entries = widget.controller.data.journalEntries
        .where(
          (item) =>
              normalized.isEmpty ||
              item.title.toLowerCase().contains(normalized) ||
              item.body.toLowerCase().contains(normalized),
        )
        .toList();
    return _Page(
      title: 'Your private journal',
      eyebrow: 'Encrypted on this device',
      action: FilledButton.icon(
        onPressed: () => editJournal(context, widget.controller),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('New entry'),
      ),
      children: [
        TextField(
          onChanged: (value) => setState(() => query = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Search your journal',
          ),
        ),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          _EmptyState(
            icon: Icons.menu_book_outlined,
            title: normalized.isEmpty
                ? 'A page with no audience'
                : 'No matching entries',
            body: normalized.isEmpty
                ? 'Write what is true without polishing it for anyone else.'
                : 'Try another word or clear your search.',
          )
        else
          ...entries.map(
            (entry) => Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                title: Text(entry.title.isEmpty ? 'Untitled' : entry.title),
                subtitle: Text(
                  '${_date(entry.updatedAt)}\n${entry.body}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: true,
                onTap: () =>
                    editJournal(context, widget.controller, existing: entry),
                trailing: IconButton(
                  tooltip: 'Delete journal entry',
                  onPressed: () => confirmDelete(
                    context,
                    'Permanently delete this journal entry?',
                    () => widget.controller.deleteJournal(entry.id),
                  ),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

final class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key, required this.controller});

  final HarborController controller;

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

final class _QuestionsScreenState extends State<QuestionsScreen> {
  final field = TextEditingController();

  @override
  void dispose() {
    field.dispose();
    super.dispose();
  }

  Future<void> add() async {
    final value = field.text.trim();
    if (value.isEmpty) return;
    await widget.controller.addQuestion(value);
    field.clear();
  }

  Future<void> copyOpenQuestions() async {
    final text = composeClinicianQuestionList(
      widget.controller.data.clinicianQuestions,
    );
    if (text.isEmpty) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Copy these clinician questions?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Only the unanswered questions shown below will leave Harbor. Your journal, check-ins, plans, care data, and answered questions stay in the encrypted vault. Other apps may be able to read the device clipboard.',
            ),
            const SizedBox(height: 14),
            SelectableText(text),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep private'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Copy only these questions'),
          ),
        ],
      ),
    );
    if (approved != true) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Clinician questions copied.')),
    );
  }

  @override
  Widget build(BuildContext context) => _Page(
    title: 'Questions for your clinician',
    eyebrow: 'You deserve to be heard',
    action: OutlinedButton.icon(
      key: const ValueKey('review_clinician_questions'),
      onPressed:
          widget.controller.data.clinicianQuestions.any(
            (question) => !question.answered,
          )
          ? copyOpenQuestions
          : null,
      icon: const Icon(Icons.content_copy_outlined),
      label: const Text('Review before copying'),
    ),
    children: [
      const _InfoPanel(
        icon: Icons.record_voice_over_outlined,
        title: 'Your concern is worth the appointment time',
        body: 'Use your own words. Harbor stores the list here so you do not have to remember everything under pressure.',
      ),
      const SizedBox(height: 18),
      TextField(
        controller: field,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => add(),
        decoration: InputDecoration(
          labelText: 'What do you want to ask?',
          suffixIcon: IconButton(
            tooltip: 'Add question',
            onPressed: add,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ),
      ),
      const SizedBox(height: 16),
      if (widget.controller.data.clinicianQuestions.isEmpty)
        const _EmptyState(
          icon: Icons.question_answer_outlined,
          title: 'No questions saved yet',
          body: 'Add one as soon as it occurs to you, even if it feels small.',
        )
      else
        ...widget.controller.data.clinicianQuestions.map(
          (item) => Card(
            child: CheckboxListTile(
              value: item.answered,
              onChanged: (_) => widget.controller.toggleQuestion(item.id),
              title: Text(
                item.text,
                style: TextStyle(
                  decoration: item.answered ? TextDecoration.lineThrough : null,
                ),
              ),
              secondary: IconButton(
                tooltip: 'Delete question',
                onPressed: () => confirmDelete(
                  context,
                  'Delete this question?',
                  () => widget.controller.deleteQuestion(item.id),
                ),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          ),
        ),
    ],
  );
}

final class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key, required this.controller});

  final HarborController controller;

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

final class _PlanScreenState extends State<PlanScreen> {
  late final TextEditingController person;
  late final TextEditingController phone;
  late final TextEditingController grounding;
  late final TextEditingController help;
  late final TextEditingController careTask;
  late final TextEditingController askPerson;
  late final TextEditingController askNeed;
  late final TextEditingController askWhen;
  late final TextEditingController askBoundary;
  String careOwner = 'Unassigned';

  @override
  void initState() {
    super.initState();
    final plan = widget.controller.data.hardDayPlan;
    person = TextEditingController(text: plan.safePerson);
    phone = TextEditingController(text: plan.safePersonPhone);
    grounding = TextEditingController(text: plan.groundingStep);
    help = TextEditingController(text: plan.practicalHelp);
    careTask = TextEditingController();
    final ask = widget.controller.data.careAskDraft;
    askPerson = TextEditingController(text: ask.person);
    askNeed = TextEditingController(text: ask.need);
    askWhen = TextEditingController(text: ask.when);
    askBoundary = TextEditingController(text: ask.boundary);
  }

  @override
  void dispose() {
    person.dispose();
    phone.dispose();
    grounding.dispose();
    help.dispose();
    careTask.dispose();
    askPerson.dispose();
    askNeed.dispose();
    askWhen.dispose();
    askBoundary.dispose();
    super.dispose();
  }

  CareAskDraft get careAsk => CareAskDraft(
    person: askPerson.text.trim(),
    need: askNeed.text.trim(),
    when: askWhen.text.trim(),
    boundary: askBoundary.text.trim(),
  );

  Future<void> save() async {
    await widget.controller.savePlan(
      HardDayPlan(
        safePerson: person.text.trim(),
        safePersonPhone: phone.text.trim(),
        groundingStep: grounding.text.trim(),
        practicalHelp: help.text.trim(),
      ),
    );
    await widget.controller.saveCareAsk(careAsk);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Care tools encrypted and saved on this device.'),
      ),
    );
  }

  Future<void> addCareTask() async {
    final task = careTask.text.trim();
    if (task.isEmpty) return;
    await widget.controller.addCareLoadItem(task: task, owner: careOwner);
    careTask.clear();
  }

  Future<void> copyCareAsk() async {
    final draft = careAsk;
    if (draft.need.isEmpty && draft.boundary.isEmpty) return;
    await widget.controller.saveCareAsk(draft);
    if (!mounted) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Copy this care request?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Only the text shown below will leave Harbor. Your journal, check-ins, plan, and care-load list stay in the encrypted vault. Other apps may be able to read the device clipboard.',
            ),
            const SizedBox(height: 14),
            SelectableText(
              draft.compose(),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep private'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Copy only this text'),
          ),
        ],
      ),
    );
    if (approved != true) return;
    await Clipboard.setData(ClipboardData(text: draft.compose()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Care request copied to the clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) => _Page(
    title: 'Care, boundaries, and hard days',
    eyebrow: 'Care work counts as work',
    action: FilledButton.icon(
      onPressed: widget.controller.saving ? null : save,
      icon: const Icon(Icons.lock_outline),
      label: const Text('Save plan'),
    ),
    children: [
      const _InfoPanel(
        icon: Icons.diversity_1_outlined,
        title: 'Care is collective',
        body: 'Needing practical help is not a personal failure. Name one person, one grounding action, and one task someone else can carry.',
      ),
      const SizedBox(height: 18),
      TextField(
        controller: person,
        decoration: const InputDecoration(labelText: 'A person I can contact'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: phone,
        onChanged: (_) => setState(() {}),
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(labelText: 'Their phone number'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: grounding,
        decoration: const InputDecoration(
          labelText: 'One thing that helps me feel present',
        ),
        maxLines: 2,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: help,
        decoration: const InputDecoration(
          labelText: 'One practical task someone can take',
        ),
        maxLines: 2,
      ),
      if (phone.text.trim().isNotEmpty) ...[
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () =>
              launchUrl(Uri(scheme: 'tel', path: phone.text.trim())),
          icon: const Icon(Icons.call_outlined),
          label: Text(
            'Call ${person.text.trim().isEmpty ? 'my person' : person.text.trim()}',
          ),
        ),
      ],
      const SizedBox(height: 32),
      const Divider(),
      const SizedBox(height: 22),
      Text(
        'Make the invisible load visible',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      const Text(
        'Appointments, bottles, meals, laundry, medication, messages, and remembering what everyone needs are labor. Record the work and name who is responsible for carrying it.',
      ),
      const SizedBox(height: 16),
      TextField(
        key: const ValueKey('care_task_field'),
        controller: careTask,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => addCareTask(),
        decoration: const InputDecoration(
          labelText: 'A care task that needs carrying',
        ),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        key: const ValueKey('care_owner_field'),
        isExpanded: true,
        initialValue: careOwner,
        decoration: const InputDecoration(labelText: 'Who owns this task?'),
        items: const [
          DropdownMenuItem(value: 'Unassigned', child: Text('Unassigned')),
          DropdownMenuItem(value: 'Me', child: Text('Me')),
          DropdownMenuItem(
            value: 'Support person',
            child: Text('Support person'),
          ),
          DropdownMenuItem(value: 'Someone else', child: Text('Someone else')),
        ],
        onChanged: (value) => setState(() => careOwner = value ?? 'Unassigned'),
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          key: const ValueKey('add_care_task'),
          onPressed: addCareTask,
          icon: const Icon(Icons.add_task),
          label: const Text('Add care task'),
        ),
      ),
      const SizedBox(height: 14),
      if (widget.controller.data.careLoadItems.isEmpty)
        const _EmptyState(
          icon: Icons.balance_outlined,
          title: 'The work does not have to stay invisible',
          body: 'Add one task at a time. Unassigned work is still work.',
        )
      else
        ...widget.controller.data.careLoadItems.map(
          (item) => Card(
            child: CheckboxListTile(
              value: item.completed,
              onChanged: (_) => widget.controller.toggleCareLoadItem(item.id),
              title: Text(
                item.task,
                style: TextStyle(
                  decoration: item.completed
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              subtitle: Text('Responsible: ${item.owner}'),
              secondary: IconButton(
                tooltip: 'Delete care task',
                onPressed: () => confirmDelete(
                  context,
                  'Delete this care task?',
                  () => widget.controller.deleteCareLoadItem(item.id),
                ),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          ),
        ),
      const SizedBox(height: 32),
      const Divider(),
      const SizedBox(height: 22),
      Text(
        'Write a direct care request',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      const Text(
        'Harbor does not soften your request, diagnose the relationship, or send anything automatically. You edit every word and choose whether to copy it.',
      ),
      const SizedBox(height: 16),
      TextField(
        key: const ValueKey('care_ask_person'),
        controller: askPerson,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(labelText: 'Who am I asking?'),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const ValueKey('care_ask_need'),
        controller: askNeed,
        onChanged: (_) => setState(() {}),
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'What do I need them to take responsibility for?',
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const ValueKey('care_ask_when'),
        controller: askWhen,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(labelText: 'By when?'),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const ValueKey('care_ask_boundary'),
        controller: askBoundary,
        onChanged: (_) => setState(() {}),
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'A boundary I need to state',
          hintText: 'I am not available to organize this for you.',
        ),
      ),
      const SizedBox(height: 16),
      Semantics(
        liveRegion: true,
        label: 'Care request preview',
        child: _InfoPanel(
          icon: Icons.format_quote_outlined,
          title: 'Your editable request',
          body: careAsk.compose(),
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        key: const ValueKey('review_care_ask'),
        onPressed: careAsk.need.isEmpty && careAsk.boundary.isEmpty
            ? null
            : copyCareAsk,
        icon: const Icon(Icons.content_copy_outlined),
        label: const Text('Review before copying'),
      ),
    ],
  );
}

final class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

final class _LibraryScreenState extends State<LibraryScreen> {
  static const stages = [
    'All stages',
    '0-6 weeks',
    '7-12 weeks',
    '3-6 months',
    '7-12 months',
  ];
  final search = TextEditingController();
  GuideAudience? audience;
  String stage = stages.first;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Color urgencyColor(GuideUrgency urgency) => switch (urgency) {
    GuideUrgency.learn => HarborColors.sage,
    GuideUrgency.contactClinician => HarborColors.plum,
    GuideUrgency.emergency => HarborColors.clay,
  };

  String urgencyLabel(GuideUrgency urgency) => switch (urgency) {
    GuideUrgency.learn => 'LEARN & NOTICE',
    GuideUrgency.contactClinician => 'CONTACT A CLINICIAN',
    GuideUrgency.emergency => 'EMERGENCY',
  };

  @override
  Widget build(BuildContext context) {
    final results = guideEntries
        .where((item) => audience == null || item.audience == audience)
        .where((item) => stage == stages.first || item.stages.contains(stage))
        .where((item) => item.matches(search.text))
        .toList();
    return _Page(
      title: 'Body, mind & baby guide',
      eyebrow: 'Educational orientation, not diagnosis',
      children: [
        const _InfoPanel(
          icon: Icons.fact_check_outlined,
          title: 'Source-traceable clinical draft',
          body: 'These entries conservatively paraphrase authoritative ACOG, National Institute of Mental Health, and American Academy of Pediatrics sources. Public release still requires named independent clinical approval and expiry review.',
          tone: HarborColors.mist,
        ),
        const SizedBox(height: 18),
        TextField(
          controller: search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Search a change or concern',
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('All'),
              selected: audience == null,
              onSelected: (_) => setState(() => audience = null),
            ),
            FilterChip(
              label: const Text('My body & mind'),
              selected: audience == GuideAudience.woman,
              onSelected: (_) => setState(() => audience = GuideAudience.woman),
            ),
            FilterChip(
              label: const Text('Baby'),
              selected: audience == GuideAudience.baby,
              onSelected: (_) => setState(() => audience = GuideAudience.baby),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: stage,
          decoration: const InputDecoration(labelText: 'Stage'),
          items: stages
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => stage = value);
          },
        ),
        const SizedBox(height: 18),
        Semantics(
          liveRegion: true,
          child: Text(
            '${results.length} ${results.length == 1 ? 'entry' : 'entries'}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        if (results.isEmpty)
          const _EmptyState(
            icon: Icons.search_off_outlined,
            title: 'No matching entry',
            body: 'Try a broader word. If you are worried, contact a clinician even when the guide has no match.',
          )
        else
          ...results.map((item) {
            final color = urgencyColor(item.urgency);
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        urgencyLabel(item.urgency),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(item.summary),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: HarborColors.blush,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.action,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${item.sourceLabel} | ${item.sourceReviewed} | ${item.sourceId}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: HarborColors.sage,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.urgency == GuideUrgency.emergency) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => showEmergencySupport(context),
                        icon: const Icon(Icons.emergency_outlined),
                        label: const Text('Open urgent support options'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

final class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key, required this.controller});

  final HarborController controller;

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

final class _StoriesScreenState extends State<StoriesScreen> {
  final search = TextEditingController();
  StoryTopic? topic;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> toggleResonance(HarborStory story) async {
    final wasSaved = widget.controller.data.resonatedStoryIds.contains(
      story.id,
    );
    await widget.controller.toggleStoryResonance(story.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasSaved
              ? 'Removed from your encrypted private responses.'
              : 'Saved only in your encrypted Harbor vault. Nothing was sent.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = storyEntries
        .where((story) => topic == null || story.topic == topic)
        .where((story) => story.matches(search.text))
        .toList();
    return _Page(
      title: 'Somebody else has felt it.',
      eyebrow: 'Offline women’s story drafts',
      children: [
        const _InfoPanel(
          icon: Icons.offline_bolt_outlined,
          title: 'Not posts. Not live. Not women being tracked.',
          body: 'These editorial composite drafts are bundled inside Harbor for recognition and reflection. They are not quotations or member posts. Opening, filtering, or responding sends nothing anywhere.',
          tone: HarborColors.mist,
        ),
        const SizedBox(height: 12),
        const _InfoPanel(
          icon: Icons.rate_review_outlined,
          title: 'Review status is visible on purpose',
          body: 'The catalog is an engineering-alpha editorial draft awaiting compensated women-led lived-experience review. Harbor will not present these pieces as validated experiences until that review is recorded.',
          tone: HarborColors.blush,
        ),
        const SizedBox(height: 18),
        TextField(
          controller: search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Search offline stories',
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('All'),
              selected: topic == null,
              onSelected: (_) => setState(() => topic = null),
            ),
            ...StoryTopic.values.map(
              (item) => FilterChip(
                label: Text(item.label),
                selected: topic == item,
                onSelected: (_) => setState(() => topic = item),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Semantics(
          liveRegion: true,
          child: Text(
            '${results.length} ${results.length == 1 ? 'story draft' : 'story drafts'}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        if (results.isEmpty)
          const _EmptyState(
            icon: Icons.search_off_outlined,
            title: 'No matching story draft',
            body: 'Try another word or choose All to see the complete offline catalog.',
          )
        else
          ...results.map((story) {
            final resonated = widget.controller.data.resonatedStoryIds.contains(
              story.id,
            );
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StoryLabel(text: story.topic.label),
                        const _StoryLabel(text: 'EDITORIAL COMPOSITE DRAFT'),
                        const _StoryLabel(text: 'OFFLINE'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      story.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (story.contentNote != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Content note: ${story.contentNote}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: HarborColors.clay,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(story.body),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: HarborColors.mist,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${story.provenance.id} • ${story.provenance.reviewStatus}\n${story.provenance.origin}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      key: ValueKey('story_resonance_${story.id}'),
                      onPressed: widget.controller.saving
                          ? null
                          : () => toggleResonance(story),
                      icon: Icon(
                        resonated ? Icons.favorite : Icons.favorite_border,
                      ),
                      label: Text(
                        resonated
                            ? 'Resonates privately — saved'
                            : 'This resonates — save privately',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 8),
        const _InfoPanel(
          icon: Icons.groups_outlined,
          title: 'Local means this is not a message board',
          body: 'Harbor does not pretend these drafts are current posts. A real cross-user community requires deliberate network publishing, remote storage, trained moderation, and a separate consent boundary. That feature is not active.',
          tone: HarborColors.blush,
        ),
      ],
    );
  }
}

final class _StoryLabel extends StatelessWidget {
  const _StoryLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: HarborColors.blush,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: HarborColors.plumDark,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    ),
  );
}

enum _AppLockAction { enable, change, disable }

final class AppLockSettingsScreen extends StatelessWidget {
  const AppLockSettingsScreen({super.key, required this.controller});

  final HarborController controller;

  Future<void> _openAction(BuildContext context, _AppLockAction action) async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) =>
            _AppLockPassphraseScreen(controller: controller, action: action),
      ),
    );
    if (message == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('Local app lock'),
        actions: [
          IconButton(
            tooltip: 'Urgent support',
            color: HarborColors.clay,
            onPressed: () => showEmergencySupport(context),
            icon: const Icon(Icons.emergency_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InfoPanel(
                    icon: controller.appLockEnabled
                        ? Icons.lock_outlined
                        : Icons.lock_open_outlined,
                    title: controller.appLockEnabled
                        ? 'App lock is on'
                        : 'App lock is off',
                    body: controller.appLockEnabled
                        ? kIsWeb
                              ? 'Harbor requires your local passphrase after you lock it, reload it, or the browser reports the page hidden or unfocused. Some embedded browsers may not report every switch, so use Lock Harbor now before sharing your device. The vault key is stored only in wrapped form while locked.'
                              : 'Harbor requires your local passphrase after the app is hidden, backgrounded, or manually locked. The vault key is stored only in wrapped form while locked.'
                        : 'Harbor opens its local vault when this browser profile or app starts. Turning on app lock adds a separate passphrase before Harbor can decrypt your entries.',
                    tone: controller.appLockEnabled
                        ? HarborColors.mist
                        : HarborColors.blush,
                  ),
                  const SizedBox(height: 14),
                  _InfoPanel(
                    icon: Icons.key_outlined,
                    title: 'Local protection, with honest limits',
                    body: kIsWeb
                        ? 'The passphrase never leaves this device and is not stored as readable text. Harbor cannot recover it. Reload and Lock Harbor now are guaranteed lock boundaries in this release. Automatic locking depends on the browser reporting visibility or focus loss. This cannot protect an already unlocked device from malware, browser extensions, screen capture, or a browser that withholds those events.'
                        : 'The passphrase never leaves this device and is not stored as readable text. Harbor cannot recover it. This protects a closed or backgrounded Harbor, but cannot protect an already unlocked device from malware, screen capture, or someone using Harbor before it locks.',
                  ),
                  const SizedBox(height: 14),
                  _InfoPanel(
                    icon: kIsWeb
                        ? Icons.language_outlined
                        : Icons.phonelink_lock_outlined,
                    title: kIsWeb
                        ? 'Web passphrase fallback'
                        : 'Device credential still pending verification',
                    body: kIsWeb
                        ? 'Browsers do not give Harbor the same hardware-backed key custody as an installed app. This release uses a passphrase-derived wrapping key; clearing browser data still erases the encrypted vault and lock record.'
                        : 'This shared passphrase path works without an account. Biometric or operating-system credential integration remains a separate signed-device release gate.',
                  ),
                  const SizedBox(height: 24),
                  if (!controller.appLockEnabled)
                    FilledButton.icon(
                      key: const ValueKey('enable_app_lock'),
                      onPressed: controller.saving
                          ? null
                          : () => _openAction(context, _AppLockAction.enable),
                      icon: const Icon(Icons.add_moderator_outlined),
                      label: const Text('Turn on app lock'),
                    )
                  else ...[
                    FilledButton.icon(
                      key: const ValueKey('lock_harbor_now'),
                      onPressed: controller.saving ? null : controller.lockNow,
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Lock Harbor now'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const ValueKey('change_app_lock'),
                      onPressed: controller.saving
                          ? null
                          : () => _openAction(context, _AppLockAction.change),
                      icon: const Icon(Icons.password_outlined),
                      label: const Text('Change passphrase'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const ValueKey('disable_app_lock'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: HarborColors.clay,
                      ),
                      onPressed: controller.saving
                          ? null
                          : () => _openAction(context, _AppLockAction.disable),
                      icon: const Icon(Icons.lock_open_outlined),
                      label: const Text('Turn off app lock'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => showEmergencySupport(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: HarborColors.clay,
                    ),
                    icon: const Icon(Icons.emergency_outlined),
                    label: const Text('Open urgent support options'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

final class _AppLockPassphraseScreen extends StatefulWidget {
  const _AppLockPassphraseScreen({
    required this.controller,
    required this.action,
  });

  final HarborController controller;
  final _AppLockAction action;

  @override
  State<_AppLockPassphraseScreen> createState() =>
      _AppLockPassphraseScreenState();
}

final class _AppLockPassphraseScreenState
    extends State<_AppLockPassphraseScreen> {
  final current = TextEditingController();
  final next = TextEditingController();
  final confirmation = TextEditingController();
  bool obscure = true;
  bool understandsRecovery = false;
  bool busy = false;
  String? message;

  bool get needsCurrent => widget.action != _AppLockAction.enable;
  bool get needsNew => widget.action != _AppLockAction.disable;

  String get title => switch (widget.action) {
    _AppLockAction.enable => 'Turn on app lock',
    _AppLockAction.change => 'Change passphrase',
    _AppLockAction.disable => 'Turn off app lock',
  };

  @override
  void dispose() {
    current.dispose();
    next.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    setState(() => message = null);
    if (needsNew) {
      if (next.text != confirmation.text) {
        setState(() => message = 'The two new passphrases do not match.');
        return;
      }
      try {
        HarborAppLockCodec.validateNewPassphrase(next.text);
      } on HarborAppLockPassphrasePolicyException catch (error) {
        setState(() => message = error.reason);
        return;
      }
      if (!understandsRecovery) {
        setState(
          () => message = 'Confirm that Harbor cannot recover this passphrase.',
        );
        return;
      }
    }
    setState(() => busy = true);
    try {
      switch (widget.action) {
        case _AppLockAction.enable:
          await widget.controller.enableAppLock(next.text);
        case _AppLockAction.change:
          await widget.controller.changeAppLockPassphrase(
            currentPassphrase: current.text,
            newPassphrase: next.text,
          );
        case _AppLockAction.disable:
          await widget.controller.disableAppLock(current.text);
      }
      if (!mounted) return;
      final result = switch (widget.action) {
        _AppLockAction.enable =>
          kIsWeb
              ? 'App lock is on. Lock Harbor now and reload are guaranteed; automatic locking depends on browser visibility and focus reports.'
              : 'App lock is on. Harbor will lock when hidden or backgrounded.',
        _AppLockAction.change => 'Your Harbor passphrase was changed.',
        _AppLockAction.disable => 'App lock is off.',
      };
      Navigator.pop(context, result);
    } on HarborAppLockPassphraseException {
      if (!mounted) return;
      setState(
        () => message =
            'The current passphrase did not match. No setting was changed.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => message = 'Harbor could not safely change the app lock. Your encrypted entries were not erased or replaced.',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InfoPanel(
                    icon: needsNew
                        ? Icons.password_outlined
                        : Icons.lock_open_outlined,
                    title: title,
                    body: switch (widget.action) {
                      _AppLockAction.enable => 'Choose a memorable phrase of at least 12 characters. Spaces and capitalization count. Harbor uses it to wrap the existing vault key; your entries are not re-created or uploaded.',
                      _AppLockAction.change => 'Enter the current phrase, then choose a new phrase. Harbor verifies the replacement before removing the old wrapped-key record.',
                      _AppLockAction.disable => 'Enter the current phrase to remove the extra lock. Your encrypted vault remains local, but Harbor will again open it automatically in this browser profile or app.',
                    },
                    tone: widget.action == _AppLockAction.disable
                        ? HarborColors.blush
                        : HarborColors.mist,
                  ),
                  const SizedBox(height: 20),
                  if (needsCurrent) ...[
                    TextField(
                      key: const ValueKey('current_app_lock_passphrase'),
                      controller: current,
                      obscureText: obscure,
                      enableSuggestions: false,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: needsNew
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onSubmitted: (_) {
                        if (!needsNew && !busy) submit();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Current passphrase',
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (needsNew) ...[
                    TextField(
                      key: const ValueKey('new_app_lock_passphrase'),
                      controller: next,
                      obscureText: obscure,
                      maxLength: HarborAppLockCodec.maximumPassphraseCharacters,
                      enableSuggestions: false,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'New passphrase',
                        helperText:
                            'At least 12 characters; no composition rule',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const ValueKey('confirm_app_lock_passphrase'),
                      controller: confirmation,
                      obscureText: obscure,
                      maxLength: HarborAppLockCodec.maximumPassphraseCharacters,
                      enableSuggestions: false,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (!busy) submit();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Confirm new passphrase',
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: understandsRecovery,
                      onChanged: busy
                          ? null
                          : (value) => setState(
                              () => understandsRecovery = value ?? false,
                            ),
                      title: const Text(
                        'I understand Harbor cannot recover this passphrase or restore erased browser/app data.',
                      ),
                    ),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: busy
                          ? null
                          : () => setState(() => obscure = !obscure),
                      icon: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      label: Text(
                        obscure ? 'Show passphrases' : 'Hide passphrases',
                      ),
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 8),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        message!,
                        key: const ValueKey('app_lock_settings_message'),
                        style: const TextStyle(color: HarborColors.clay),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    key: const ValueKey('save_app_lock_settings'),
                    style: widget.action == _AppLockAction.disable
                        ? FilledButton.styleFrom(
                            backgroundColor: HarborColors.clay,
                          )
                        : null,
                    onPressed: busy ? null : submit,
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            widget.action == _AppLockAction.disable
                                ? Icons.lock_open_outlined
                                : Icons.check,
                          ),
                    label: Text(
                      busy
                          ? 'Verifying…'
                          : switch (widget.action) {
                              _AppLockAction.enable => 'Turn on app lock',
                              _AppLockAction.change => 'Change passphrase',
                              _AppLockAction.disable => 'Turn off app lock',
                            },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: busy ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

final class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key, required this.controller});

  final HarborController controller;

  @override
  Widget build(BuildContext context) => _Page(
    title: 'Privacy center',
    eyebrow: 'Nothing hidden',
    children: [
      const _InfoPanel(
        icon: Icons.cloud_off_outlined,
        title: 'No Harbor account or cloud',
        body: 'Harbor does not have a server for your entries, sync your data, run analytics, show ads, or use remote AI.',
      ),
      const SizedBox(height: 12),
      const _InfoPanel(
        icon: Icons.enhanced_encryption_outlined,
        title: 'Encrypted local vault',
        body: "Journal entries, check-ins, questions, your plan, care-load tasks, care-request drafts, private story responses, and setup choices are encrypted with AES-256-GCM before the record is stored. The key is held through the platform's secure-storage adapter.",
      ),
      if (kIsWeb) ...[
        const SizedBox(height: 12),
        const _InfoPanel(
          icon: Icons.delete_sweep_outlined,
          title: 'Browser storage can disappear',
          body: "Private browsing, browser cleanup, storage eviction, or clearing this site's data can permanently erase Harbor. Browser protection is not equivalent to a phone or computer keystore.",
          tone: HarborColors.blush,
        ),
      ],
      const SizedBox(height: 24),
      Text('Local app lock', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      Text(
        controller.appLockEnabled
            ? kIsWeb
                  ? 'App lock is on. Harbor requires your passphrase after manual lock or reload, and when the browser reports the page hidden or unfocused.'
                  : 'App lock is on. Harbor requires your passphrase after it is hidden, backgrounded, or manually locked.'
            : kIsWeb
            ? 'App lock is off. Add a local passphrase to protect Harbor after manual lock, reload, or reported visibility and focus loss.'
            : 'App lock is off. Add a local passphrase before Harbor can decrypt entries after it is hidden or backgrounded.',
      ),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        key: const ValueKey('manage_app_lock'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AppLockSettingsScreen(controller: controller),
          ),
        ),
        icon: Icon(
          controller.appLockEnabled
              ? Icons.lock_outlined
              : Icons.lock_open_outlined,
        ),
        label: const Text('Manage local app lock'),
      ),
      const SizedBox(height: 24),
      Text(
        'About this Harbor build',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      const Text(
        'Inspect the exact app, local-data, guide, and Stories versions on this device, including what has not been independently approved.',
      ),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        key: const ValueKey('open_about_harbor'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AboutHarborScreen(controller: controller),
          ),
        ),
        icon: const Icon(Icons.info_outline),
        label: const Text('About and content versions'),
      ),
      const SizedBox(height: 24),
      Text(
        'Erase Harbor from this ${kIsWeb ? 'browser' : 'device'}',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      const Text(
        'This permanently removes all encrypted records and the encryption key. Harbor has no remote copy to restore.',
      ),
      const SizedBox(height: 14),
      FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: HarborColors.clay),
        onPressed: controller.saving
            ? null
            : () => confirmDelete(
                context,
                'Erase every Harbor entry and reset the app?',
                controller.eraseAll,
                destructiveLabel: 'Erase everything',
              ),
        icon: const Icon(Icons.delete_forever_outlined),
        label: const Text('Erase all local data'),
      ),
    ],
  );
}

final class AboutHarborScreen extends StatelessWidget {
  const AboutHarborScreen({super.key, required this.controller});

  final HarborController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('About Harbor'),
      actions: [
        IconButton(
          tooltip: 'Urgent support',
          color: HarborColors.clay,
          onPressed: () => showEmergencySupport(context),
          icon: const Icon(Icons.emergency_outlined),
        ),
      ],
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _InfoPanel(
                  icon: Icons.science_outlined,
                  title: HarborReleaseInfo.releaseStatus,
                  body: 'This build is still being engineered and tested. It is not clinically approved, independently security-certified, or a completed five-platform release. Harbor does not diagnose, monitor, or replace professional or emergency care.',
                  tone: HarborColors.blush,
                ),
                const SizedBox(height: 20),
                Text(
                  'Versions on this device',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                _VersionPanel(
                  rows: [
                    ('Application', HarborReleaseInfo.versionLabel),
                    (
                      'Local data schema',
                      '${HarborReleaseInfo.dataSchemaVersion}',
                    ),
                    ('Body and baby guide', HarborReleaseInfo.guideLabel),
                    ('Stories library', HarborReleaseInfo.storiesLabel),
                  ],
                ),
                const SizedBox(height: 20),
                const _InfoPanel(
                  icon: Icons.fact_check_outlined,
                  title: 'Review status',
                  body:
                      'Guide: ${HarborReleaseInfo.guideStatus}. Stories: ${HarborReleaseInfo.storiesStatus}. The current catalogs remain visibly labeled drafts until named reviewers approve them.',
                ),
                const SizedBox(height: 12),
                const _InfoPanel(
                  icon: Icons.phonelink_lock_outlined,
                  title: 'Private product boundary',
                  body: 'This screen reads only public build metadata. Harbor has no account, analytics, advertising, remote AI, cloud sync, or backend for private entries. A live anonymous board is not active.',
                ),
                const SizedBox(height: 12),
                const _InfoPanel(
                  icon: Icons.bug_report_outlined,
                  title: 'Diagnostic details stay minimal',
                  body: 'Harbor can prepare app version, platform, local-data schema, and a bounded error code. It excludes entries, record counts, device identifiers, OS version, timestamps, and usage history. Nothing is sent automatically.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const ValueKey('preview_diagnostic_export'),
                  onPressed: () => showDiagnosticExport(context, controller),
                  icon: const Icon(Icons.content_copy_outlined),
                  label: const Text('Preview diagnostic details'),
                ),
                const SizedBox(height: 12),
                const _InfoPanel(
                  icon: Icons.balance_outlined,
                  title: HarborReleaseInfo.license,
                  body: HarborReleaseInfo.copyright,
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => showEmergencySupport(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HarborColors.clay,
                  ),
                  icon: const Icon(Icons.emergency_outlined),
                  label: const Text('Open urgent support options'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> showDiagnosticExport(
  BuildContext context,
  HarborController controller,
) async {
  final report = HarborDiagnosticReport.create(
    platform: currentHarborDiagnosticPlatform(),
    error: controller.error,
  );
  final payload = report.encode();
  final approved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      scrollable: true,
      title: const Text('Copy diagnostic details?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review the complete payload below. It contains only app version, build number, platform, local-data schema, and an error code. Harbor does not attach anything else.',
          ),
          const SizedBox(height: 14),
          Semantics(
            container: true,
            label: report.semanticLabel,
            child: ExcludeSemantics(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: HarborColors.mist,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: HarborColors.line),
                ),
                child: SelectableText(payload),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Nothing is sent automatically. If you copy this, other apps or clipboard history may retain it.',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Keep private'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(dialogContext, true),
          icon: const Icon(Icons.content_copy_outlined),
          label: const Text('Copy diagnostic details'),
        ),
      ],
    ),
  );
  if (approved != true || !context.mounted) return;
  try {
    await Clipboard.setData(ClipboardData(text: payload));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Diagnostic details copied after your review.'),
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Harbor could not copy the diagnostic details.'),
      ),
    );
  }
}

final class _VersionPanel extends StatelessWidget {
  const _VersionPanel({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: HarborColors.mist,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: HarborColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows.indexed.map((entry) {
        final (index, row) = entry;
        final (label, value) = row;
        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 14),
          child: Semantics(
            container: true,
            label: '$label: $value',
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: HarborColors.plumDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(value),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}

final class _Page extends StatelessWidget {
  const _Page({
    required this.title,
    required this.eyebrow,
    required this.children,
    this.action,
  });

  final String title;
  final String eyebrow;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 48),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: HarborColors.sage, letterSpacing: 1.2),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 16,
              runSpacing: 14,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                ?action,
              ],
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    ),
  );
}

final class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.body,
    this.tone = HarborColors.mist,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color tone;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: HarborColors.plumDark),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

final class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: HarborColors.blush,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Icon(icon, size: 34, color: HarborColors.plum),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(body, textAlign: TextAlign.center),
      ],
    ),
  );
}

final class _HarborMark extends StatelessWidget {
  const _HarborMark({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Harbor, private postpartum support for women',
    child: Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: HarborColors.plum,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.water_drop_outlined, color: Colors.white),
        ),
        if (!compact) ...[
          Text('Harbor', style: Theme.of(context).textTheme.headlineMedium),
        ],
      ],
    ),
  );
}

Future<void> showCheckIn(
  BuildContext context,
  HarborController controller,
) async {
  var mood = 3.0;
  var anxiety = 3.0;
  var rest = 3.0;
  final note = TextEditingController();
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('A private check-in'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'There is no good score. Choose what feels closest right now.',
                ),
                const SizedBox(height: 16),
                _LabeledSlider(
                  label: 'Mood',
                  value: mood,
                  low: 'Very low',
                  high: 'Steady',
                  onChanged: (value) => setState(() => mood = value),
                ),
                _LabeledSlider(
                  label: 'Anxiety',
                  value: anxiety,
                  low: 'Quiet',
                  high: 'Overwhelming',
                  onChanged: (value) => setState(() => anxiety = value),
                ),
                _LabeledSlider(
                  label: 'Rest',
                  value: rest,
                  low: 'None',
                  high: 'Rested',
                  onChanged: (value) => setState(() => rest = value),
                ),
                TextField(
                  controller: note,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Anything you want to remember (optional)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Encrypt & save'),
          ),
        ],
      ),
    ),
  );
  if (saved == true) {
    await controller.addCheckIn(
      CheckIn(
        mood: mood.round(),
        anxiety: anxiety.round(),
        rest: rest.round(),
        note: note.text.trim(),
      ),
    );
  }
  note.dispose();
}

final class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.low,
    required this.high,
    required this.onChanged,
  });

  final String label;
  final double value;
  final String low;
  final String high;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label, ${value.round()} out of 5',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label | ${value.round()}/5',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        Slider(
          value: value,
          min: 1,
          max: 5,
          divisions: 4,
          label: value.round().toString(),
          onChanged: onChanged,
        ),
        Row(children: [Text(low), const Spacer(), Text(high)]),
        const SizedBox(height: 15),
      ],
    ),
  );
}

Future<void> editJournal(
  BuildContext context,
  HarborController controller, {
  JournalEntry? existing,
}) async {
  final title = TextEditingController(text: existing?.title ?? '');
  final body = TextEditingController(text: existing?.body ?? '');
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        existing == null ? 'New journal entry' : 'Edit journal entry',
      ),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Title (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: body,
              minLines: 5,
              maxLines: 10,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'What is true right now?',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Encrypt & save'),
        ),
      ],
    ),
  );
  if (saved == true &&
      (title.text.trim().isNotEmpty || body.text.trim().isNotEmpty)) {
    final entry = existing == null
        ? JournalEntry(title: title.text.trim(), body: body.text.trim())
        : existing.edited(title: title.text.trim(), body: body.text.trim());
    await controller.saveJournal(entry);
  }
  title.dispose();
  body.dispose();
}

Future<void> confirmDelete(
  BuildContext context,
  String message,
  Future<void> Function() action, {
  String destructiveLabel = 'Delete',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(message),
      content: const Text(
        'This cannot be recovered because Harbor keeps no remote copy.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep it'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: HarborColors.clay),
          onPressed: () => Navigator.pop(context, true),
          child: Text(destructiveLabel),
        ),
      ],
    ),
  );
  if (confirmed == true) await action();
}

Future<void> showEmergencySupport(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Urgent support'),
      content: const SizedBox(
        width: 520,
        child: Text(
          'Harbor cannot monitor or contact help for you. In the United States, call 911 for immediate danger. Call or text 988 for suicide or crisis support. Outside the U.S., use your local emergency or crisis service.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
        OutlinedButton.icon(
          onPressed: () => launchUrl(Uri(scheme: 'sms', path: '988')),
          icon: const Icon(Icons.sms_outlined),
          label: const Text('Text 988'),
        ),
        FilledButton.icon(
          onPressed: () => launchUrl(Uri(scheme: 'tel', path: '988')),
          icon: const Icon(Icons.call_outlined),
          label: const Text('Call 988'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: HarborColors.clay),
          onPressed: () => launchUrl(Uri(scheme: 'tel', path: '911')),
          icon: const Icon(Icons.emergency),
          label: const Text('Call 911'),
        ),
      ],
    ),
  );
}

String _date(DateTime date) {
  final local = date.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}
