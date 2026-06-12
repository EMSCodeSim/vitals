import 'dart:async';
import 'dart:math';

import 'package:emscode_sim_vitals/app/app_state.dart';
import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/pulse/pulse_beep_player.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/shared/training_summary_page.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

enum PulseQuality { regular, irregular, weak, thready, bounding }

extension on PulseQuality {
  String get label => switch (this) {
    PulseQuality.regular => 'Regular',
    PulseQuality.irregular => 'Irregular',
    PulseQuality.weak => 'Weak',
    PulseQuality.thready => 'Thready',
    PulseQuality.bounding => 'Bounding',
  };
}

enum PulseRangePreset { brady, normalAdult, tachy, severeTachy, irregular }

extension on PulseRangePreset {
  String get label => switch (this) {
    PulseRangePreset.brady => 'Bradycardic',
    PulseRangePreset.normalAdult => 'Normal adult',
    PulseRangePreset.tachy => 'Tachycardic',
    PulseRangePreset.severeTachy => 'Severe tachycardia',
    PulseRangePreset.irregular => 'Irregular pulse',
  };

  (int min, int max) get bpmRange => switch (this) {
    PulseRangePreset.brady => (40, 58),
    PulseRangePreset.normalAdult => (60, 96),
    PulseRangePreset.tachy => (110, 140),
    PulseRangePreset.severeTachy => (150, 190),
    PulseRangePreset.irregular => (70, 140),
  };
}

class PulseTestPage extends StatefulWidget {
  const PulseTestPage({super.key});

  @override
  State<PulseTestPage> createState() => _PulseTestPageState();
}

class _PulseTestPageState extends State<PulseTestPage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _rng = Random();
  final PulseBeepPlayer _beep = PulseBeepPlayer();

  PulseRangePreset _preset = PulseRangePreset.normalAdult;
  int _countSeconds = 30;

  int _walkthroughScreen = 0;
  bool _guidedRun = false;
  int _liveBeatCount = 0;

  PulseQuality? _qualityPick;

  int? _actualBpm;
  PulseQuality? _actualQuality;

  Timer? _beatTimer;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  int _tapCount = 0;
  bool _running = false;

  String? _feedback;
  EMSResultKind? _feedbackKind;

  late final AnimationController _heartController;
  late final Animation<double> _heartScale;

  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _heartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.20).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 28),
      TweenSequenceItem(tween: Tween(begin: 1.20, end: 1.0).chain(CurveTween(curve: Curves.easeInOutCubic)), weight: 72),
    ]).animate(_heartController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().markModuleOpened(TrainingModule.pulse);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAll();
    _heartController.dispose();
    _beep.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _stopAll();
    }
  }

  Future<void> _unlockAudio() => _beep.unlockFromUserGesture();

  void _stopAll() {
    _beatTimer?.cancel();
    _beatTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _heartController.stop();
    _beep.stop();
    _running = false;
  }

  int _randIn(int min, int maxVal) => min + _rng.nextInt(max(1, maxVal - min + 1));

  PulseQuality _randomQualityForPreset(PulseRangePreset p) {
    // Keep it simple but realistic.
    if (p == PulseRangePreset.irregular) return PulseQuality.irregular;
    final roll = _rng.nextDouble();
    if (roll < 0.10) return PulseQuality.weak;
    if (roll < 0.18) return PulseQuality.thready;
    if (roll < 0.26) return PulseQuality.bounding;
    return PulseQuality.regular;
  }

  Future<void> _start() async {
    await _unlockAudio();
    _stopAll();

    final (minBpm, maxBpm) = _preset.bpmRange;
    final bpm = _randIn(minBpm, maxBpm);
    final q = _randomQualityForPreset(_preset);

    setState(() {
      _actualBpm = bpm;
      _actualQuality = q;
      _tapCount = 0;
      _liveBeatCount = 0;
      _guidedRun = false;
      _remainingSeconds = _countSeconds;
      _running = true;
      _feedback = null;
      _feedbackKind = null;
      _qualityPick = null;
      _startTime = DateTime.now();
    });

    _scheduleBeats(bpm: bpm, quality: q);

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

  Future<void> _startGuidedRadialPulse() async {
    await _unlockAudio();
    _stopAll();

    const bpm = 72;
    const q = PulseQuality.regular;

    setState(() {
      _actualBpm = bpm;
      _actualQuality = q;
      _countSeconds = 30;
      _tapCount = 0;
      _liveBeatCount = 0;
      _remainingSeconds = 30;
      _running = true;
      _guidedRun = true;
      _feedback = null;
      _feedbackKind = null;
      _qualityPick = q;
      _startTime = DateTime.now();
    });

    _scheduleBeats(bpm: bpm, quality: q);

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

  void _stopAndRefresh() {
    _stopAll();
    if (!mounted) return;
    setState(() {
      _guidedRun = false;
      _remainingSeconds = 0;
    });
  }

  void _goToWalkthroughScreen(int screen) {
    _stopAll();
    setState(() {
      _walkthroughScreen = screen.clamp(0, 2).toInt();
      _feedback = null;
      _feedbackKind = null;
      _tapCount = 0;
      _liveBeatCount = 0;
      _remainingSeconds = 0;
    });
  }

  void _scheduleBeats({required int bpm, required PulseQuality quality}) {
    // Regular rhythm = fixed interval. Irregular = jitter.
    final baseIntervalMs = ((60 / bpm) * 1000).round().clamp(220, 1800);
    _heartController.duration = Duration(milliseconds: baseIntervalMs);

    Future<void> tickOnce() async {
      if (!mounted || !_running) return;
      _heartController.forward(from: 0);
      setState(() => _liveBeatCount++);
      unawaited(HapticFeedback.lightImpact());
      try {
        // Subtle volume cue for weak/thready.
        final vol = switch (quality) {
          PulseQuality.weak => 0.45,
          PulseQuality.thready => 0.35,
          PulseQuality.bounding => 1.0,
          _ => 0.85,
        };
        await _beep.playOnce(volume: vol);
      } catch (e) {
        debugPrint('Pulse beep failed: $e');
      }
    }

    void scheduleNext() {
      if (!_running) return;
      final jitter = quality == PulseQuality.irregular ? (_rng.nextInt(260) - 130) : 0;
      final nextMs = (baseIntervalMs + jitter).clamp(180, 2200);
      _beatTimer = Timer(Duration(milliseconds: nextMs), () async {
        await tickOnce();
        scheduleNext();
      });
    }

    unawaited(tickOnce());
    scheduleNext();
  }

  void _registerTap() {
    if (!_running) return;
    setState(() => _tapCount++);
  }

  void _finish() {
    final wasGuidedRun = _guidedRun;
    final countedBeats = _liveBeatCount;
    _stopAll();
    final bpm = _actualBpm;
    if (bpm == null) return;

    if (wasGuidedRun) {
      final estimated = ((countedBeats * 60) / 30).round();
      setState(() {
        _guidedRun = false;
        _feedbackKind = EMSResultKind.success;
        _feedback = '30-second radial pulse walkthrough complete.\nLive count: $countedBeats beats in 30 seconds.\nEstimated pulse: $countedBeats × 2 = $estimated BPM.\n\nTeaching point: Use two fingers on the thumb-side wrist, count for 30 seconds, then multiply by 2. Document rate, rhythm, location, and quality.';
      });
      return;
    }

    final estimated = ((_tapCount * 60) / _countSeconds).round();
    final diff = (estimated - bpm).abs();
    final tol = _countSeconds == 30 ? 4 : 6;
    final within = diff <= tol;

    final mode = context.read<AppState>().mode;
    final qualityOk = _qualityPick == null ? false : (_qualityPick == _actualQuality || (_actualQuality == PulseQuality.irregular && _qualityPick == PulseQuality.irregular));

    final totalPoints = 2;
    final points = (within ? 1 : 0) + (qualityOk ? 1 : 0);
    final scorePercent = ((points / totalPoints) * 100).round();
    final explanation = 'Teaching point: A 15-second count is faster but less precise; multiply by 4. A 30-second count improves accuracy. Always document rhythm regularity and pulse quality.';

    if (mode == TrainingMode.test) {
      unawaited(
        TrainingSummaryPage.recordAndShow(
          context,
          args: TrainingSummaryArgs(
            module: TrainingModule.pulse,
            scorePercent: scorePercent,
            correct: points,
            total: totalPoints,
            timeSpent: _startTime == null ? Duration.zero : DateTime.now().difference(_startTime!),
            recommendedReview: explanation,
            missedTeachingPoints: [
              if (!within) 'Recount with a longer interval (30s) when possible to reduce error.',
              if (!qualityOk) 'Pulse quality matters: regular vs irregular changes your interpretation.',
            ],
          ),
        ),
      );
      return;
    }

    setState(() {
      _feedbackKind = within ? EMSResultKind.success : EMSResultKind.warning;
      _feedback = 'Actual: $bpm BPM (${_actualQuality?.label ?? '—'})\nYour estimate: $estimated BPM\nDifference: $diff BPM (tolerance ±$tol)\n\n${within ? '✅ Within tolerance.' : '❌ Outside tolerance.'}\n\n$explanation';
    });
  }

  void _showInfo() {
    EMSInfoSheet.show(
      context,
      title: 'Pulse Trainer: counting + quality',
      children: const [
        Text('Follow the pulse-point screen, then use the radial pulse walkthrough. The guided demo runs for 30 seconds with a beep and phone vibration for each pulse. Practice mode lets students tap each pulse and compare their count.'),
        SizedBox(height: 12),
        Text('Training only — not medical advice.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mode = context.select<AppState, TrainingMode>((s) => s.mode);
    final bpm = _actualBpm;
    final running = _running;

    return EMSVitalsScaffold(
      title: 'Pulse Test',
      subtitle: 'Tap-to-count a realistic EMS pulse (training only, not medical advice)',
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
                    _PulseWalkthroughStepHeader(
                      current: _walkthroughScreen,
                      running: running,
                      onSelect: _goToWalkthroughScreen,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_walkthroughScreen == 0)
                      _PulsePointsPanel(
                        onNext: () => _goToWalkthroughScreen(1),
                      )
                    else if (_walkthroughScreen == 1)
                      _RadialPulseGuidedPanel(
                        running: running,
                        remainingSeconds: _remainingSeconds,
                        liveBeatCount: _liveBeatCount,
                        heartScale: _heartScale,
                        onStart: _startGuidedRadialPulse,
                        onStop: _stopAndRefresh,
                        onNextPractice: () => _goToWalkthroughScreen(2),
                      )
                    else
                      _PulsePracticePanel(
                        mode: mode,
                        running: running,
                        preset: _preset,
                        countSeconds: _countSeconds,
                        remainingSeconds: _remainingSeconds,
                        tapCount: _tapCount,
                        liveBeatCount: _liveBeatCount,
                        qualityPick: _qualityPick,
                        actualBpm: bpm,
                        actualQuality: _actualQuality,
                        heartScale: _heartScale,
                        onPresetChanged: running ? null : (v) => setState(() => _preset = v ?? _preset),
                        onStart: _start,
                        onTapPulse: _registerTap,
                        onQualityChanged: (v) => setState(() => _qualityPick = v),
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

class _PulseWalkthroughStepHeader extends StatelessWidget {
  const _PulseWalkthroughStepHeader({required this.current, required this.running, required this.onSelect});

  final int current;
  final bool running;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final steps = const [
      (Icons.touch_app_rounded, 'Pulse points'),
      (Icons.play_circle_fill_rounded, 'Radial demo'),
      (Icons.timer_rounded, 'Practice'),
    ];

    return EMSSectionCard(
      title: 'Pulse walkthrough',
      subtitle: 'Step ${current + 1} of 3 • Short screens keep students from scrolling.',
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
              labelStyle: TextStyle(
                color: current == i ? cs.onPrimary : cs.onSurface,
                fontWeight: FontWeight.w800,
              ),
              selectedColor: cs.primary,
              showCheckmark: false,
              side: BorderSide(color: cs.outline.withValues(alpha: 0.18)),
            ),
        ],
      ),
    );
  }
}

class _PulsePointsPanel extends StatelessWidget {
  const _PulsePointsPanel({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return EMSSectionCard(
      title: 'Pulse point diagram',
      subtitle: 'Use 2 fingers. Do not use your thumb.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: Image.asset(
                'assets/images/pulse_points_diagram.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Primary focus: radial pulse at the wrist. Brachial pulse is often used in infants.',
            style: context.textStyles.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: onNext,
              style: ButtonStyle(
                splashFactory: NoSplash.splashFactory,
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              label: const Text('Next: radial pulse demo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadialPulseGuidedPanel extends StatelessWidget {
  const _RadialPulseGuidedPanel({
    required this.running,
    required this.remainingSeconds,
    required this.liveBeatCount,
    required this.heartScale,
    required this.onStart,
    required this.onStop,
    required this.onNextPractice,
  });

  final bool running;
  final int remainingSeconds;
  final int liveBeatCount;
  final Animation<double> heartScale;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onNextPractice;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final estimatedBpm = liveBeatCount * 2;

    return EMSSectionCard(
      title: 'Radial pulse walkthrough',
      subtitle: '30-second demo with beep + phone vibration for each pulse.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: Image.asset(
                'assets/images/radial_pulse_close_up.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          EMSResultBox(
            title: 'Hand placement',
            message: 'Place the index and middle fingers on the thumb-side wrist. Feel the pulse gently — do not press with the thumb.',
            kind: EMSResultKind.info,
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
            ),
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: running
                      ? ScaleTransition(scale: heartScale, child: Icon(Icons.favorite, key: const ValueKey('radial-heart'), size: 76, color: AppColors.danger))
                      : Icon(Icons.favorite_border, key: const ValueKey('radial-empty'), size: 76, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                  running ? '$remainingSeconds seconds left' : 'Ready for 30-second timer',
                  style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Live count: $liveBeatCount beats',
                  style: context.textStyles.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: AppColors.danger),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  liveBeatCount == 0 ? 'Estimated BPM will show after pulses begin.' : 'Estimated BPM: $liveBeatCount × 2 = $estimatedBpm',
                  style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: running ? null : onStart,
                    style: ButtonStyle(
                      splashFactory: NoSplash.splashFactory,
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text('Start 30 sec', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: running ? onStop : onNextPractice,
                    style: ButtonStyle(
                      splashFactory: NoSplash.splashFactory,
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                    icon: Icon(running ? Icons.stop_rounded : Icons.chevron_right),
                    label: Text(running ? 'Stop' : 'Practice'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulsePracticePanel extends StatelessWidget {
  const _PulsePracticePanel({
    required this.mode,
    required this.running,
    required this.preset,
    required this.countSeconds,
    required this.remainingSeconds,
    required this.tapCount,
    required this.liveBeatCount,
    required this.qualityPick,
    required this.actualBpm,
    required this.actualQuality,
    required this.heartScale,
    required this.onPresetChanged,
    required this.onStart,
    required this.onTapPulse,
    required this.onQualityChanged,
  });

  final TrainingMode mode;
  final bool running;
  final PulseRangePreset preset;
  final int countSeconds;
  final int remainingSeconds;
  final int tapCount;
  final int liveBeatCount;
  final PulseQuality? qualityPick;
  final int? actualBpm;
  final PulseQuality? actualQuality;
  final Animation<double> heartScale;
  final ValueChanged<PulseRangePreset?>? onPresetChanged;
  final VoidCallback onStart;
  final VoidCallback onTapPulse;
  final ValueChanged<PulseQuality?> onQualityChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        EMSSectionCard(
          title: 'Practice setup',
          subtitle: 'Student counts the pulse and documents quality.',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<PulseRangePreset>(
                      value: preset,
                      decoration: const InputDecoration(labelText: 'Range'),
                      items: [for (final p in PulseRangePreset.values) DropdownMenuItem(value: p, child: Text(p.label))],
                      onChanged: onPresetChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Timer'),
                      child: Text('$countSeconds seconds', style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: running ? null : onStart,
                  style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: Text(running ? 'Running…' : 'Start 30-second count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
              if (mode == TrainingMode.learn) ...[
                const SizedBox(height: 12),
                EMSResultBox(
                  title: 'Learn mode hint',
                  message: 'Brady <60 • Normal 60–100 • Tachy >100.\nCount method: beats in 30 seconds × 2.',
                  kind: EMSResultKind.info,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        EMSSectionCard(
          title: running ? 'Count now' : 'Ready',
          subtitle: running ? 'Tap each beat. Time remaining: $remainingSeconds s' : 'Start a rhythm, then tap each beat you feel/hear.',
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: running
                    ? ScaleTransition(scale: heartScale, child: Icon(Icons.favorite, key: const ValueKey('heart'), size: 88, color: AppColors.danger))
                    : Icon(Icons.favorite_border, key: const ValueKey('empty'), size: 88, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              if (running)
                Text('Pulse cues heard/felt: $liveBeatCount', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton(
                  onPressed: running ? onTapPulse : null,
                  style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)))),
                  child: Text(running ? 'Tap Pulse  •  Your Count: $tapCount' : 'Tap disabled (start first)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<PulseQuality>(
                value: qualityPick,
                decoration: const InputDecoration(labelText: 'Pulse quality (your documentation)'),
                items: [for (final q in PulseQuality.values) DropdownMenuItem(value: q, child: Text(q.label))],
                onChanged: onQualityChanged,
              ),
              if (mode == TrainingMode.learn && actualBpm != null && actualQuality != null) ...[
                const SizedBox(height: 12),
                EMSResultBox(title: 'Instructor hint (Learn mode)', message: 'Actual: $actualBpm BPM • ${actualQuality!.label}', kind: EMSResultKind.info),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
