import 'dart:async';
import 'dart:math';

import 'package:emscode_sim_vitals/app/app_state.dart';
import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/shared/training_summary_page.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

enum RespirationPattern { regular, shallow, labored, irregular }

extension RespirationPatternLabel on RespirationPattern {
  String get label => switch (this) {
    RespirationPattern.regular => 'Regular / unlabored',
    RespirationPattern.shallow => 'Shallow',
    RespirationPattern.labored => 'Labored',
    RespirationPattern.irregular => 'Irregular',
  };
}

enum RespirationRangePreset { slow, normalAdult, fast, distress, irregular }

extension RespirationRangePresetLabel on RespirationRangePreset {
  String get label => switch (this) {
    RespirationRangePreset.slow => 'Slow respirations',
    RespirationRangePreset.normalAdult => 'Normal adult',
    RespirationRangePreset.fast => 'Fast respirations',
    RespirationRangePreset.distress => 'Respiratory distress',
    RespirationRangePreset.irregular => 'Irregular pattern',
  };

  (int min, int max) get rrRange => switch (this) {
    RespirationRangePreset.slow => (6, 10),
    RespirationRangePreset.normalAdult => (12, 20),
    RespirationRangePreset.fast => (22, 28),
    RespirationRangePreset.distress => (30, 38),
    RespirationRangePreset.irregular => (10, 26),
  };
}

class RespirationsTestPage extends StatefulWidget {
  const RespirationsTestPage({super.key});

  @override
  State<RespirationsTestPage> createState() => _RespirationsTestPageState();
}

class _RespirationsTestPageState extends State<RespirationsTestPage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _rng = Random();
  final TextEditingController _countedBreathsController = TextEditingController();

  RespirationRangePreset _preset = RespirationRangePreset.normalAdult;
  RespirationRangePreset _guidedPreset = RespirationRangePreset.normalAdult;
  int _countSeconds = 30;
  int _walkthroughScreen = 0;

  bool _guidedRun = false;
  bool _running = false;
  int _remainingSeconds = 0;
  int _liveBreathCount = 0;
  bool _awaitingPracticeEntry = false;

  int? _actualRr;
  RespirationPattern? _actualPattern;
  RespirationPattern? _patternPick;

  String? _feedback;
  EMSResultKind? _feedbackKind;

  Timer? _breathTimer;
  Timer? _countdownTimer;
  DateTime? _startTime;

  late final AnimationController _breathController;
  late final Animation<double> _breathScale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _breathController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _breathScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18).chain(CurveTween(curve: Curves.easeInOutCubic)), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 1.0).chain(CurveTween(curve: Curves.easeInOutCubic)), weight: 55),
    ]).animate(_breathController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().markModuleOpened(TrainingModule.respirations);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAll();
    _breathController.dispose();
    _countedBreathsController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _stopAll();
    }
  }

  void _stopAll() {
    _breathTimer?.cancel();
    _breathTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _breathController.stop();
    _running = false;
  }

  int _randIn(int min, int maxVal) => min + _rng.nextInt(max(1, maxVal - min + 1));

  int _guidedDemoRate(RespirationRangePreset preset) => switch (preset) {
    RespirationRangePreset.slow => 8,
    RespirationRangePreset.normalAdult => 16,
    RespirationRangePreset.fast => 24,
    RespirationRangePreset.distress => 32,
    RespirationRangePreset.irregular => 18,
  };

  RespirationPattern _randomPatternForPreset(RespirationRangePreset p) {
    if (p == RespirationRangePreset.irregular) return RespirationPattern.irregular;
    if (p == RespirationRangePreset.distress) return _rng.nextBool() ? RespirationPattern.labored : RespirationPattern.shallow;
    if (p == RespirationRangePreset.fast) return _rng.nextDouble() < 0.35 ? RespirationPattern.labored : RespirationPattern.regular;
    if (p == RespirationRangePreset.slow) return _rng.nextDouble() < 0.35 ? RespirationPattern.shallow : RespirationPattern.regular;
    return _rng.nextDouble() < 0.12 ? RespirationPattern.shallow : RespirationPattern.regular;
  }

  void _goToWalkthroughScreen(int screen) {
    _stopAll();
    setState(() {
      _walkthroughScreen = screen.clamp(0, 2).toInt();
      _guidedRun = false;
      _remainingSeconds = 0;
      _liveBreathCount = 0;
      _awaitingPracticeEntry = false;
      _countedBreathsController.clear();
      _feedback = null;
      _feedbackKind = null;
    });
  }

  Future<void> _startGuidedRespirations() async {
    _stopAll();

    final rr = _guidedDemoRate(_guidedPreset);
    final pattern = _guidedPreset == RespirationRangePreset.irregular
        ? RespirationPattern.irregular
        : (_guidedPreset == RespirationRangePreset.distress
            ? RespirationPattern.labored
            : RespirationPattern.regular);

    setState(() {
      _actualRr = rr;
      _actualPattern = pattern;
      _countSeconds = 30;
      _guidedRun = true;
      _running = true;
      _remainingSeconds = 30;
      _liveBreathCount = 0;
      _awaitingPracticeEntry = false;
      _countedBreathsController.clear();
      _patternPick = pattern;
      _feedback = null;
      _feedbackKind = null;
      _startTime = DateTime.now();
    });

    _scheduleBreaths(rr: rr, pattern: pattern);
    _startCountdown();
  }

  Future<void> _startPractice() async {
    _stopAll();

    final (minRr, maxRr) = _preset.rrRange;
    final rr = _randIn(minRr, maxRr);
    final pattern = _randomPatternForPreset(_preset);

    setState(() {
      _actualRr = rr;
      _actualPattern = pattern;
      _guidedRun = false;
      _running = true;
      _remainingSeconds = _countSeconds;
      _liveBreathCount = 0;
      _awaitingPracticeEntry = false;
      _countedBreathsController.clear();
      _patternPick = null;
      _feedback = null;
      _feedbackKind = null;
      _startTime = DateTime.now();
    });

    _scheduleBreaths(rr: rr, pattern: pattern);
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        t.cancel();
        _finish();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  void _scheduleBreaths({required int rr, required RespirationPattern pattern}) {
    final baseIntervalMs = ((60 / rr) * 1000).round().clamp(900, 10000);
    _breathController.duration = Duration(milliseconds: min(1800, max(850, (baseIntervalMs * 0.50).round())));

    Future<void> tickOnce() async {
      if (!mounted || !_running) return;
      _breathController.forward(from: 0);
      setState(() => _liveBreathCount++);
      // No beep cues in practice; keep visuals only.
    }

    void scheduleNext({required bool first}) {
      if (!_running) return;
      final jitter = pattern == RespirationPattern.irregular ? (_rng.nextInt(1400) - 700) : 0;
      final delay = first ? max(700, baseIntervalMs ~/ 2) : (baseIntervalMs + jitter).clamp(650, 11000);
      _breathTimer = Timer(Duration(milliseconds: delay), () async {
        await tickOnce();
        scheduleNext(first: false);
      });
    }

    scheduleNext(first: true);
  }

  void _registerTap() {
    if (!_running) return;
    // Tapping to count was removed. Students should enter their count after the timer ends.
  }

  void _stopAndRefresh() {
    _stopAll();
    if (!mounted) return;
    setState(() {
      _guidedRun = false;
      _remainingSeconds = 0;
    });
  }

  void _finish() {
    final wasGuidedRun = _guidedRun;
    final liveCount = _liveBreathCount;
    _stopAll();

    final rr = _actualRr;
    if (rr == null) return;

    if (wasGuidedRun) {
      final estimated = ((liveCount * 60) / 30).round();
      setState(() {
        _guidedRun = false;
        _feedbackKind = EMSResultKind.success;
        _feedback = '30-second respirations walkthrough complete.\nLive count: $liveCount breaths in 30 seconds.\nEstimated respiratory rate: $liveCount × 2 = $estimated/min.\n\nTeaching point: Count one full rise and fall as one breath. Watch quietly so the patient does not change their breathing. Document rate, effort, depth, and regularity.';
      });
      return;
    }

    // For practice, the student enters their count after the timer ends.
    setState(() {
      _awaitingPracticeEntry = true;
      _feedback = null;
      _feedbackKind = null;
    });
  }

  void _submitPracticeEntry() {
    final rr = _actualRr;
    if (rr == null) return;

    final parsed = int.tryParse(_countedBreathsController.text.trim());
    if (parsed == null || parsed <= 0) {
      setState(() {
        _feedbackKind = EMSResultKind.warning;
        _feedback = 'Enter the number of breaths you counted (a positive whole number).';
      });
      return;
    }

    final estimated = ((parsed * 60) / _countSeconds).round();
    final diff = (estimated - rr).abs();
    final tol = _countSeconds == 30 ? 2 : 4;
    final within = diff <= tol;
    final patternOk = _patternPick != null && (_patternPick == _actualPattern || (_actualPattern == RespirationPattern.labored && _patternPick == RespirationPattern.shallow));

    final mode = context.read<AppState>().mode;
    final points = (within ? 1 : 0) + (patternOk ? 1 : 0);
    const totalPoints = 2;
    final scorePercent = ((points / totalPoints) * 100).round();
    final explanation = 'Teaching point: Adult respiratory rate is commonly about 12–20/min, but rate alone is not enough. Document work of breathing, depth, regularity, ability to speak, skin color, SpO₂, and response to treatment.';

    if (mode == TrainingMode.test) {
      unawaited(
        TrainingSummaryPage.recordAndShow(
          context,
          args: TrainingSummaryArgs(
            module: TrainingModule.respirations,
            scorePercent: scorePercent,
            correct: points,
            total: totalPoints,
            timeSpent: _startTime == null ? Duration.zero : DateTime.now().difference(_startTime!),
            recommendedReview: explanation,
            missedTeachingPoints: [
              if (!within) 'Count respirations for the full interval and multiply correctly.',
              if (!patternOk) 'Respiratory quality matters: shallow, labored, irregular, or unlabored changes patient interpretation.',
            ],
          ),
        ),
      );
      return;
    }

    setState(() {
      _awaitingPracticeEntry = false;
      _feedbackKind = (within && patternOk) ? EMSResultKind.success : EMSResultKind.warning;
      _feedback = 'Actual: $rr/min (${_actualPattern?.label ?? '—'})\nYour count: $parsed breaths in $_countSeconds seconds\nYour estimate: $estimated/min\nDifference: $diff/min (tolerance ±$tol)\n\n${within ? '✅ Rate within tolerance.' : '❌ Rate outside tolerance.'}\n${patternOk ? '✅ Pattern correct.' : '❌ Pattern incorrect.'}\n\n$explanation';
    });
  }

  void _showInfo() {
    EMSInfoSheet.show(
      context,
      title: 'Respirations walkthrough',
      children: const [
        Text('Use the photo cue first, then run a 30-second visual count. One full rise and fall equals one breath. In practice, count quietly and enter your total when the timer ends.'),
        SizedBox(height: 12),
        Text('Training only — not medical advice.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mode = context.select<AppState, TrainingMode>((s) => s.mode);
    final running = _running;

    return EMSVitalsScaffold(
      title: 'Respirations',
      subtitle: 'Visual walkthrough: watch chest rise, count 30 seconds, document rate + effort.',
      onInfoPressed: _showInfo,
      onBackPressed: () {
        _stopAll();
        context.go(AppRoutes.home);
      },
      bodySlivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  children: [
                    _RespirationStepHeader(
                      current: _walkthroughScreen,
                      running: running,
                      onSelect: _goToWalkthroughScreen,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_walkthroughScreen == 0)
                      _RespirationPhotoPanel(onNext: () => _goToWalkthroughScreen(1))
                    else if (_walkthroughScreen == 1)
                      _RespirationGuidedPanel(
                        running: running,
                        remainingSeconds: _remainingSeconds,
                        liveBreathCount: _liveBreathCount,
                        breathScale: _breathScale,
                        breathProgress: _breathController,
                        guidedPreset: _guidedPreset,
                        onGuidedPresetChanged: running ? null : (v) => setState(() => _guidedPreset = v ?? _guidedPreset),
                        onStart: _startGuidedRespirations,
                        onStop: _stopAndRefresh,
                        onNextPractice: () => _goToWalkthroughScreen(2),
                      )
                    else
                      _RespirationPracticePanel(
                        mode: mode,
                        running: running,
                        preset: _preset,
                        countSeconds: _countSeconds,
                        remainingSeconds: _remainingSeconds,
                        awaitingEntry: _awaitingPracticeEntry,
                        countedBreathsController: _countedBreathsController,
                        patternPick: _patternPick,
                        breathScale: _breathScale,
                        breathProgress: _breathController,
                        onPresetChanged: running ? null : (v) => setState(() => _preset = v ?? _preset),
                        onCountSecondsChanged: running ? null : (v) => setState(() => _countSeconds = v),
                        onPatternChanged: (v) => setState(() => _patternPick = v),
                        onStart: _startPractice,
                        onSubmit: _submitPracticeEntry,
                      ),
                    if (_feedback != null && _feedbackKind != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      EMSResultBox(title: 'Feedback', message: _feedback!, kind: _feedbackKind!),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Text('Educational use only • Not medical advice', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RespirationStepHeader extends StatelessWidget {
  const _RespirationStepHeader({required this.current, required this.running, required this.onSelect});

  final int current;
  final bool running;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final steps = const [
      (Icons.visibility_rounded, 'What to watch'),
      (Icons.play_circle_fill_rounded, '30-sec demo'),
      (Icons.timer_rounded, 'Practice'),
    ];

    return EMSSectionCard(
      title: 'Respirations walkthrough',
      subtitle: 'Step ${current + 1} of 3 • Same short-screen style as BP and Pulse.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (int i = 0; i < steps.length; i++)
            ChoiceChip(
              selected: current == i,
              onSelected: running ? null : (_) => onSelect(i),
              avatar: Icon(steps[i].$1, size: 18, color: current == i ? cs.onPrimary : cs.primary),
              label: Text(steps[i].$2),
              labelStyle: TextStyle(color: current == i ? cs.onPrimary : cs.onSurface, fontWeight: FontWeight.w800),
              selectedColor: cs.primary,
              showCheckmark: false,
              side: BorderSide(color: cs.outline.withValues(alpha: 0.18)),
            ),
        ],
      ),
    );
  }
}

class _RespirationPhotoPanel extends StatelessWidget {
  const _RespirationPhotoPanel({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return EMSSectionCard(
      title: 'Visual cue: count without telling the patient',
      subtitle: 'Watch chest or abdomen rise and fall. One full rise and fall = one breath.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: Image.asset(
                'assets/images/respirations_tutorial.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniCue(icon: Icons.visibility_rounded, label: 'Watch', value: 'Chest / abdomen'),
              const SizedBox(width: 10),
              _MiniCue(icon: Icons.timer_rounded, label: 'Count', value: '30 seconds'),
            ],
          ),
          const SizedBox(height: 10),
          Text('Document more than the number: rate, regularity, depth, effort, ability to speak, skin color, SpO₂, and response to treatment.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: onNext,
              style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              label: const Text('Next: 30-second demo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RespirationGuidedPanel extends StatelessWidget {
  const _RespirationGuidedPanel({required this.running, required this.remainingSeconds, required this.liveBreathCount, required this.breathScale, required this.breathProgress, required this.guidedPreset, required this.onGuidedPresetChanged, required this.onStart, required this.onStop, required this.onNextPractice});

  final bool running;
  final int remainingSeconds;
  final int liveBreathCount;
  final Animation<double> breathScale;
  final Animation<double> breathProgress;
  final RespirationRangePreset guidedPreset;
  final ValueChanged<RespirationRangePreset?>? onGuidedPresetChanged;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onNextPractice;

  @override
  Widget build(BuildContext context) {
    return EMSSectionCard(
      title: 'Guided demo: 30-second respiratory count',
      subtitle: 'Watch the chest rise and fall for 30 seconds. Use this to practice staying subtle while counting.',
      child: Column(
        children: [
          DropdownButtonFormField<RespirationRangePreset>(
            value: guidedPreset,
            decoration: InputDecoration(
              labelText: 'Demo speed / respiratory rate',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            items: [for (final p in RespirationRangePreset.values) DropdownMenuItem(value: p, child: Text('${p.label} • ${switch (p) { RespirationRangePreset.slow => '8/min', RespirationRangePreset.normalAdult => '16/min', RespirationRangePreset.fast => '24/min', RespirationRangePreset.distress => '32/min', RespirationRangePreset.irregular => 'Irregular' }}'))],
            onChanged: onGuidedPresetChanged,
          ),
          const SizedBox(height: 12),
          _BreathingDisplay(
            breathScale: breathScale,
            breathProgress: breathProgress,
            running: running,
            remainingSeconds: remainingSeconds,
            liveBreathCount: liveBreathCount,
            showLiveCount: true,
            title: running ? 'Watch the chest rise and fall' : 'Tap Start Demo',
            subtitle: running ? 'Live count: $liveBreathCount breaths' : 'Animated chest demo at ${switch (guidedPreset) { RespirationRangePreset.slow => '8', RespirationRangePreset.normalAdult => '16', RespirationRangePreset.fast => '24', RespirationRangePreset.distress => '32', RespirationRangePreset.irregular => 'variable' }}/min',
          ),
          const SizedBox(height: 14),
          if (running)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: onStop,
                style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Stop Demo'),
              ),
            )
          else ...[
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: onStart,
                style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text('Start 30-second demo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: onNextPractice,
                style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                icon: const Icon(Icons.timer_rounded),
                label: const Text('Go to practice'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RespirationPracticePanel extends StatelessWidget {
  const _RespirationPracticePanel({required this.mode, required this.running, required this.preset, required this.countSeconds, required this.remainingSeconds, required this.awaitingEntry, required this.countedBreathsController, required this.patternPick, required this.breathScale, required this.breathProgress, required this.onPresetChanged, required this.onCountSecondsChanged, required this.onPatternChanged, required this.onStart, required this.onSubmit});

  final TrainingMode mode;
  final bool running;
  final RespirationRangePreset preset;
  final int countSeconds;
  final int remainingSeconds;
  final bool awaitingEntry;
  final TextEditingController countedBreathsController;
  final RespirationPattern? patternPick;
  final Animation<double> breathScale;
  final Animation<double> breathProgress;
  final ValueChanged<RespirationRangePreset?>? onPresetChanged;
  final ValueChanged<int>? onCountSecondsChanged;
  final ValueChanged<RespirationPattern?> onPatternChanged;
  final VoidCallback onStart;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return EMSSectionCard(
      title: 'Practice: count and document respirations',
      subtitle: mode == TrainingMode.test
          ? 'Test mode: watch the full timer, then enter your count and select the pattern.'
          : 'Watch quietly for the full interval, then enter how many breaths you counted.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<RespirationRangePreset>(
            value: preset,
            decoration: InputDecoration(
              labelText: 'Respiration pattern preset',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            items: [for (final p in RespirationRangePreset.values) DropdownMenuItem(value: p, child: Text(p.label))],
            onChanged: onPresetChanged,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 15, label: Text('15 sec'), icon: Icon(Icons.timer_rounded)),
                  ButtonSegment(value: 30, label: Text('30 sec'), icon: Icon(Icons.timer_rounded)),
                ],
                selected: {countSeconds},
                onSelectionChanged: onCountSecondsChanged == null ? null : (v) => onCountSecondsChanged!(v.first),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _BreathingDisplay(
            breathScale: breathScale,
            breathProgress: breathProgress,
            running: running,
            remainingSeconds: remainingSeconds,
            liveBreathCount: 0,
            showLiveCount: false,
            title: running ? 'Count every full breath' : 'Ready for practice',
            subtitle: running ? 'Count silently, then enter your total' : 'Press start, then count for the full timer',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: FilledButton.icon(
              onPressed: running ? null : onStart,
              style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)))),
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: const Text('Start Practice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ),
          if (running) ...[
            const SizedBox(height: 10),
            Text('Tip: keep your eyes on the chest/abdomen and avoid obvious counting.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
          ],
          if (awaitingEntry) ...[
            const SizedBox(height: 14),
            Text('Enter your count', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            TextField(
              controller: countedBreathsController,
              enabled: !running,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Breaths counted in $countSeconds seconds',
                hintText: 'e.g., 8',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: onSubmit,
                style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                label: const Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text('Document breathing quality:', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in RespirationPattern.values)
                ChoiceChip(
                  selected: patternPick == p,
                  onSelected: running ? null : (_) => onPatternChanged(p),
                  label: Text(p.label),
                  showCheckmark: false,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreathingDisplay extends StatelessWidget {
  const _BreathingDisplay({required this.breathScale, required this.breathProgress, required this.running, required this.remainingSeconds, required this.liveBreathCount, required this.showLiveCount, required this.title, required this.subtitle});

  final Animation<double> breathScale;
  final Animation<double> breathProgress;
  final bool running;
  final int remainingSeconds;
  final int liveBreathCount;
  final bool showLiveCount;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: AppColors.headerGradient.map((c) => c.withValues(alpha: 0.12)).toList()),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _MetricPill(icon: Icons.timer_rounded, label: 'Timer', value: running ? '${remainingSeconds}s' : '30s'),
              if (showLiveCount) ...[
                const SizedBox(width: 10),
                _MetricPill(icon: Icons.air_rounded, label: 'Live count', value: '$liveBreathCount'),
              ],
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: Listenable.merge([breathScale, breathProgress]),
            builder: (context, _) {
              final t = running ? breathProgress.value : 0.25;
              const asset = 'assets/images/resp_chest_frame_2.png';

              // Balloon chest effect (subtle): expand mostly on the Y axis,
              // with a small X-axis expansion so it feels more natural.
              // The underlying animation goes 1.0 -> 1.18; we dampen it.
              final raw = running ? breathScale.value : 1.0;
              final balloonY = 1.0 + (raw - 1.0) * 0.45;
              final balloonX = 1.0 + (raw - 1.0) * 0.18;

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(balloonX, balloonY, 1.0),
                child: Container(
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: cs.outline.withValues(alpha: 0.16)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 22, offset: const Offset(0, 10))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 4 / 5,
                          child: Image.asset(asset, fit: BoxFit.cover),
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.52),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              running ? (t < 0.5 ? 'Inhale' : 'Exhale') : 'Ballooning chest demo',
                              textAlign: TextAlign.center,
                              style: context.textStyles.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
                  Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCue extends StatelessWidget {
  const _MiniCue({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.textStyles.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800)),
                  Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
