import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

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

enum PulseRhythm { regular, irregular }

extension on PulseRhythm {
  String get label => switch (this) {
    PulseRhythm.regular => 'Regular',
    PulseRhythm.irregular => 'Irregular',
  };
}

class PulseTestPage extends StatefulWidget {
  const PulseTestPage({super.key});

  @override
  State<PulseTestPage> createState() => _PulseTestPageState();
}

enum _PulsePatternType {
  regular,
  afib,
  bigeminy,
  trigeminy,
  sinusArrhythmia,
}

class _PulseIntervalGenerator {
  _PulseIntervalGenerator({required Random rng, required int baseIntervalMs, required _PulsePatternType type})
      : _rng = rng,
        _base = baseIntervalMs,
        _type = type;

  final Random _rng;
  final int _base;
  final _PulsePatternType _type;

  int _i = 0;
  double _phase = 0;

  int nextIntervalMs() {
    _i++;
    return switch (_type) {
      _PulsePatternType.regular => _base,
      _PulsePatternType.afib => _afibInterval(),
      _PulsePatternType.bigeminy => _bigeminyInterval(),
      _PulsePatternType.trigeminy => _trigeminyInterval(),
      _PulsePatternType.sinusArrhythmia => _sinusArrhythmiaInterval(),
    };
  }

  int _afibInterval() {
    // Irregularly irregular: wide variability around baseline.
    // Use a pseudo-normal distribution (sum of uniforms) to avoid extremes being too common.
    final n = (_rng.nextDouble() + _rng.nextDouble() + _rng.nextDouble() + _rng.nextDouble()) / 4;
    // Map n ~ [0..1] into a multiplier ~ [0.60..1.45] with more density near ~1.0.
    final mult = 0.60 + (n * (1.45 - 0.60));
    var ms = (_base * mult).round();

    // Occasionally insert a longer pause (missed/weak beat feeling).
    if (_rng.nextDouble() < 0.06) ms = (ms * 1.8).round();

    return ms.clamp(180, 2200);
  }

  int _bigeminyInterval() {
    // Regularly irregular: alternating premature beat + compensatory pause.
    final isPremature = _i.isOdd;
    final mult = isPremature ? 0.62 : 1.38;
    return (_base * mult).round().clamp(180, 2200);
  }

  int _trigeminyInterval() {
    // Every 3rd beat is premature with a compensatory pause after.
    final pos = _i % 3;
    final mult = switch (pos) {
      1 => 0.70, // premature
      2 => 1.30, // compensatory
      _ => 1.00,
    };
    return (_base * mult).round().clamp(180, 2200);
  }

  int _sinusArrhythmiaInterval() {
    // Slow in/out breathing-like variability (feels "not perfectly regular").
    _phase += 0.35; // speed of cycle
    final wave = sin(_phase);
    final mult = 1.0 + (wave * 0.18); // ±18%
    // Add a touch of jitter so it doesn't feel too "patterned".
    final jitter = (_rng.nextInt(90) - 45) / 1000.0; // ±45ms-ish at ~1s base
    return (_base * mult + (jitter * 1000)).round().clamp(180, 2200);
  }
}

class _PulseTestPageState extends State<PulseTestPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  static const int _bpmTolerance = 4;

  final _rng = Random();
  final PulseBeepPlayer _beep = PulseBeepPlayer();
  final TextEditingController _rateController = TextEditingController();

  int? _actualBpm;
  PulseRhythm? _actualRhythm;

  PulseRhythm? _rhythmPick;

  Timer? _beatTimer;
  bool _running = false;

  bool _beepEnabled = false;
  bool _hapticsEnabled = true;
  bool _showHeartCue = true;

  String? _feedback;
  EMSResultKind? _feedbackKind;

  late final AnimationController _heartController;
  late final Animation<double> _heartScale;

  late final AnimationController _stopwatchController;

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

    _stopwatchController = AnimationController(vsync: this, duration: const Duration(seconds: 60));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().markModuleOpened(TrainingModule.pulse);
      unawaited(_start(autoStart: true));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAll();
    _heartController.dispose();
    _stopwatchController.dispose();
    _rateController.dispose();
    unawaited(_beep.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _stopAll();
    }
  }

  void _stopAll() {
    _beatTimer?.cancel();
    _beatTimer = null;
    _heartController.stop();
    _stopwatchController.stop();
    unawaited(_beep.stop());
    _running = false;
  }

  int _randIn(int min, int maxVal) => min + _rng.nextInt(max(1, maxVal - min + 1));

  PulseRhythm _randomRhythm() => _rng.nextDouble() < 0.28 ? PulseRhythm.irregular : PulseRhythm.regular;

  _PulsePatternType _pickPatternType(PulseRhythm rhythm) {
    if (rhythm == PulseRhythm.regular) return _PulsePatternType.regular;
    final roll = _rng.nextDouble();
    if (roll < 0.45) return _PulsePatternType.afib;
    if (roll < 0.72) return _PulsePatternType.bigeminy;
    if (roll < 0.88) return _PulsePatternType.trigeminy;
    return _PulsePatternType.sinusArrhythmia;
  }

  Future<void> _start({required bool autoStart}) async {
    _stopAll();

    final bpm = _randIn(48, 148);
    final rhythm = _randomRhythm();
    final patternType = _pickPatternType(rhythm);

    setState(() {
      _actualBpm = bpm;
      _actualRhythm = rhythm;
      _running = true;
      _feedback = null;
      _feedbackKind = null;
      _rhythmPick = null;
      if (!autoStart) _rateController.clear();
      _startTime = DateTime.now();
    });

    _stopwatchController
      ..reset()
      ..repeat();

    _scheduleBeats(bpm: bpm, patternType: patternType);
  }

  void _scheduleBeats({required int bpm, required _PulsePatternType patternType}) {
    final baseIntervalMs = ((60 / bpm) * 1000).round().clamp(220, 1800);
    final generator = _PulseIntervalGenerator(rng: _rng, baseIntervalMs: baseIntervalMs, type: patternType);
    _heartController.duration = Duration(milliseconds: baseIntervalMs);

    Future<void> tickOnce() async {
      if (!mounted) return;
      _heartController.forward(from: 0);
      try {
        if (_hapticsEnabled && !kIsWeb) {
          unawaited(HapticFeedback.selectionClick());
        }
        if (_beepEnabled) {
          await _beep.playOnce(volume: 0.85);
        }
      } catch (e) {
        debugPrint('Pulse cue failed: $e');
      }
    }

    void scheduleNext() {
      if (!_running) return;
      final nextMs = generator.nextIntervalMs();
      // Match the heart animation envelope to the current interval so the cue feels natural
      // when it is visible (and doesn't look like a constant-rate animation).
      _heartController.duration = Duration(milliseconds: nextMs);
      _beatTimer = Timer(Duration(milliseconds: nextMs), () async {
        await tickOnce();
        scheduleNext();
      });
    }

    unawaited(tickOnce());
    scheduleNext();
  }

  Future<void> _setBeepEnabled(bool v) async {
    setState(() => _beepEnabled = v);
    if (v) {
      await _beep.unlockFromUserGesture();
    }
  }

  void _checkAnswer() {
    final bpm = _actualBpm;
    final rhythm = _actualRhythm;
    if (bpm == null || rhythm == null) return;

    final raw = _rateController.text.trim();
    final userBpm = int.tryParse(raw);
    if (userBpm == null || userBpm <= 0 || userBpm > 260) {
      setState(() {
        _feedbackKind = EMSResultKind.warning;
        _feedback = 'Enter a valid heart rate (BPM).';
      });
      return;
    }
    if (_rhythmPick == null) {
      setState(() {
        _feedbackKind = EMSResultKind.warning;
        _feedback = 'Select rhythm (regular vs irregular).';
      });
      return;
    }

    // User has committed to an answer — stop cues and stopwatch.
    _stopAll();

    final diff = (userBpm - bpm).abs();
    final within = diff <= _bpmTolerance;
    final rhythmOk = _rhythmPick == rhythm;

    final mode = context.read<AppState>().mode;
    final totalPoints = 2;
    final points = (within ? 1 : 0) + (rhythmOk ? 1 : 0);
    final scorePercent = ((points / totalPoints) * 100).round();
    const explanation = 'Teaching point: Confirm pulse presence, count for 30 seconds, multiply by 2 for BPM, then document BPM and rhythm (regular vs irregular).';

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
              if (!within) 'Count carefully for a full 30 seconds (or repeat the count).',
              if (!rhythmOk) 'Rhythm matters: document whether it is regular or irregular.',
            ],
          ),
        ),
      );
      return;
    }

    setState(() {
      final bothOk = within && rhythmOk;
      _feedbackKind = bothOk ? EMSResultKind.success : EMSResultKind.warning;
      _feedback = 'Actual: $bpm BPM (${rhythm.label})\nYour entry: $userBpm BPM (${_rhythmPick!.label})\nDifference: $diff BPM (tolerance ±$_bpmTolerance)\n\n${bothOk ? '✅ Correct.' : '❌ Not quite.'}\n\n$explanation';
    });
  }

  void _showInfo() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Pulse walk-through', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                      IconButton(
                        onPressed: () => context.pop(),
                        style: const ButtonStyle(splashFactory: NoSplash.splashFactory),
                        icon: Icon(Icons.close, color: cs.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const _PulseHowToChecklist(),
                  const SizedBox(height: 12),
                  Text('Tip: Many providers count for 30 seconds and multiply by 2. If you want more accuracy, count for 60 seconds.', style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.45)),
                  const SizedBox(height: 12),
                  Text('Educational use only • Not medical advice', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () => context.pop(),
                      style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Got it', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Duration get _elapsed {
    final s = _startTime;
    if (s == null) return Duration.zero;
    final d = DateTime.now().difference(s);
    return d.isNegative ? Duration.zero : d;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final running = _running;

    return EMSVitalsScaffold(
      title: 'Pulse Trainer',
      subtitle: 'Use the stopwatch to count beats, then document rate + rhythm.',
      onInfoPressed: _showInfo,
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
                      title: 'Pulse check',
                      subtitle: running ? 'Stopwatch is running — count beats and record your findings.' : 'Start a new pulse, then count and document your findings.',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: _showInfo,
                                  style: const ButtonStyle(splashFactory: NoSplash.splashFactory),
                                  icon: Icon(Icons.menu_book_outlined, color: cs.primary),
                                  label: Text('Directions', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900)),
                                ),
                              ),
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () => context.push(AppRoutes.pulseDiagram),
                                  style: const ButtonStyle(splashFactory: NoSplash.splashFactory),
                                  icon: Icon(Icons.map_outlined, color: cs.primary),
                                  label: Text('Pulse points', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          PulseStopwatchDial(
                            animation: _stopwatchController,
                            running: running,
                            elapsed: _elapsed,
                            heartScale: _heartScale,
                            showHeartCue: _showHeartCue,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _HeartVisibilityTile(
                                  value: _showHeartCue,
                                  onChanged: (v) => setState(() => _showHeartCue = v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SwitchListTile.adaptive(
                                  value: _beepEnabled,
                                  onChanged: (v) => unawaited(_setBeepEnabled(v)),
                                  title: const Text('Beep'),
                                  subtitle: const Text('Sound cue each beat'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _rateController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(labelText: 'Rate (BPM)', hintText: 'Example: 84'),
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<PulseRhythm>(
                            value: _rhythmPick,
                            decoration: const InputDecoration(labelText: 'Rhythm'),
                            items: [for (final r in PulseRhythm.values) DropdownMenuItem(value: r, child: Text(r.label))],
                            onChanged: (v) => setState(() => _rhythmPick = v),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton.icon(
                              onPressed: _checkAnswer,
                              style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)))),
                              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                              label: const Text('Check answer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton.icon(
                              onPressed: () => unawaited(_start(autoStart: false)),
                              style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              label: const Text('New pulse', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                            ),
                          ),
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

class _PulseHowToChecklist extends StatelessWidget {
  const _PulseHowToChecklist();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textStyle = context.textStyles.bodyMedium?.copyWith(height: 1.45);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('1) Check pulse point location and confirm presence of a pulse.', style: textStyle),
          const SizedBox(height: 8),
          Text('2) Count the pulse for 30 seconds.', style: textStyle),
          const SizedBox(height: 8),
          Text('3) Multiply the number by 2 to get a 1-minute rate (BPM).', style: textStyle),
          const SizedBox(height: 8),
          Text('4) Document the rate and whether it is regular or not regular.', style: textStyle),
        ],
      ),
    );
  }
}

/// Large stopwatch + pulse cue display (second-hand dial + beat heart).
class PulseStopwatchDial extends StatelessWidget {
  const PulseStopwatchDial({super.key, required this.animation, required this.running, required this.elapsed, required this.heartScale, required this.showHeartCue});

  final Animation<double> animation;
  final bool running;
  final Duration elapsed;
  final Animation<double> heartScale;
  final bool showHeartCue;

  String _formatElapsed(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final handT = running ? animation.value : 0.0;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 164,
                height: 164,
                child: CustomPaint(
                  painter: _StopwatchDialPainter(
                    colorScheme: cs,
                    handT: handT,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Stopwatch', style: context.textStyles.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(_formatElapsed(elapsed), style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pulse cues', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: !showHeartCue
                          ? Icon(Icons.visibility_off, key: const ValueKey('hidden'), size: 54, color: cs.onSurfaceVariant)
                          : (running
                              ? ScaleTransition(scale: heartScale, child: const Icon(Icons.favorite, key: ValueKey('heart'), size: 58, color: AppColors.danger))
                              : Icon(Icons.favorite_border, key: const ValueKey('empty'), size: 58, color: cs.onSurfaceVariant)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      running ? 'Count each beat. When ready, enter BPM + rhythm below.' : 'Tap “New pulse” to start.',
                      style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeartVisibilityTile extends StatelessWidget {
  const _HeartVisibilityTile({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => onChanged(!value),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Icon(value ? Icons.favorite : Icons.favorite_border, color: value ? AppColors.danger : cs.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Heart', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(value ? 'Visible cue on' : 'Hidden — feel or listen', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(value ? Icons.visibility : Icons.visibility_off, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}


class _StopwatchDialPainter extends CustomPainter {
  const _StopwatchDialPainter({required this.colorScheme, required this.handT});

  final ColorScheme colorScheme;
  final double handT;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) / 2;

    final bgPaint = Paint()..color = colorScheme.surface;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.65);

    canvas.drawCircle(center, r, bgPaint);
    canvas.drawCircle(center, r - 1, ringPaint);

    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = colorScheme.onSurfaceVariant.withValues(alpha: 0.55);

    for (var i = 0; i < 12; i++) {
      final a = (i / 12) * (2 * pi) - (pi / 2);
      final p1 = center + Offset(cos(a), sin(a)) * (r * 0.78);
      final p2 = center + Offset(cos(a), sin(a)) * (r * 0.90);
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Second hand.
    final handPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(
        Offset(center.dx, center.dy - r),
        Offset(center.dx, center.dy + r),
        [AppColors.emsBlue, AppColors.emsCyan],
      );

    final handAngle = (handT * 2 * pi) - (pi / 2);
    final handEnd = center + Offset(cos(handAngle), sin(handAngle)) * (r * 0.72);
    canvas.drawLine(center, handEnd, handPaint);
    canvas.drawCircle(center, 4.5, Paint()..color = colorScheme.onSurface);
  }

  @override
  bool shouldRepaint(covariant _StopwatchDialPainter oldDelegate) => oldDelegate.handT != handT || oldDelegate.colorScheme != colorScheme;
}
