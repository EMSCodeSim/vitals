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
  int _countSeconds = 15;

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

  void _scheduleBeats({required int bpm, required PulseQuality quality}) {
    // Regular rhythm = fixed interval. Irregular = jitter.
    final baseIntervalMs = ((60 / bpm) * 1000).round().clamp(220, 1800);
    _heartController.duration = Duration(milliseconds: baseIntervalMs);

    Future<void> tickOnce() async {
      if (!mounted) return;
      _heartController.forward(from: 0);
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
    _stopAll();
    final bpm = _actualBpm;
    if (bpm == null) return;

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
        Text('Pick a counting interval (15s or 30s). Tap each pulse you feel/hear. The app estimates BPM and compares to the hidden actual rate.'),
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
                    EMSSectionCard(
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
                            style: context.textStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    EMSSectionCard(
                      title: 'Setup',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<PulseRangePreset>(
                                  value: _preset,
                                  decoration: const InputDecoration(labelText: 'Range'),
                                  items: [for (final p in PulseRangePreset.values) DropdownMenuItem(value: p, child: Text(p.label))],
                                  onChanged: running ? null : (v) => setState(() => _preset = v ?? _preset),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _countSeconds,
                                  decoration: const InputDecoration(labelText: 'Count interval'),
                                  items: const [
                                    DropdownMenuItem(value: 15, child: Text('15 seconds')),
                                    DropdownMenuItem(value: 30, child: Text('30 seconds')),
                                  ],
                                  onChanged: running ? null : (v) => setState(() => _countSeconds = v ?? _countSeconds),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton.icon(
                              onPressed: running ? null : _start,
                              style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                              icon: const Icon(Icons.play_arrow, color: Colors.white),
                              label: Text(running ? 'Running…' : 'Start', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                            ),
                          ),
                          if (mode == TrainingMode.learn) ...[
                            const SizedBox(height: 12),
                            EMSResultBox(
                              title: 'Learn mode hint',
                              message: 'Brady <60 • Normal 60–100 • Tachy >100.\nCount method: taps × (60 / seconds).',
                              kind: EMSResultKind.info,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    EMSSectionCard(
                      title: running ? 'Count now' : 'Ready',
                      subtitle: running ? 'Tap each beat. Time remaining: $_remainingSeconds s' : 'Start a rhythm, then tap each beat you feel/hear.',
                      child: Column(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: running
                                ? ScaleTransition(scale: _heartScale, child: Icon(Icons.favorite, key: const ValueKey('heart'), size: 88, color: AppColors.danger))
                                : Icon(Icons.favorite_border, key: const ValueKey('empty'), size: 88, color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 64,
                            child: FilledButton(
                              onPressed: running ? _registerTap : null,
                              style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)))),
                              child: Text(running ? 'Tap Pulse  •  Count: $_tapCount' : 'Tap disabled (start first)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<PulseQuality>(
                            value: _qualityPick,
                            decoration: const InputDecoration(labelText: 'Pulse quality (your documentation)'),
                            items: [for (final q in PulseQuality.values) DropdownMenuItem(value: q, child: Text(q.label))],
                            onChanged: (v) => setState(() => _qualityPick = v),
                          ),
                          if (mode == TrainingMode.learn && bpm != null && _actualQuality != null) ...[
                            const SizedBox(height: 12),
                            EMSResultBox(title: 'Instructor hint (Learn mode)', message: 'Actual: $bpm BPM • ${_actualQuality!.label}', kind: EMSResultKind.info),
                          ],
                        ],
                      ),
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
