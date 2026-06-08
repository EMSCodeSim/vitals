import 'dart:async';
import 'dart:math';

import 'package:emscode_sim_vitals/blood_pressure/bp_beep_player.dart';
import 'package:emscode_sim_vitals/blood_pressure/bp_gauge.dart';
import 'package:emscode_sim_vitals/app/app_state.dart';
import 'package:emscode_sim_vitals/dev/dev_flags.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/shared/training_summary_page.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:emscode_sim_vitals/nav.dart';

class BloodPressureSimulatorPage extends StatefulWidget {
  const BloodPressureSimulatorPage({super.key});

  @override
  State<BloodPressureSimulatorPage> createState() => _BloodPressureSimulatorPageState();
}

class _BloodPressureSimulatorPageState extends State<BloodPressureSimulatorPage> with WidgetsBindingObserver {
  double currentPressure = 0;
  int? _hiddenSys;
  int? _hiddenDia;
  int? _hiddenPulse;
  bool scenarioActive = false;
  bool releasing = false;

  Timer? _deflationTimer;
  final BpBeepPlayer _beep = BpBeepPlayer();
  bool _beatsActive = false;

  double _deflationStep = 0.5;

  // Deflation coaching
  DateTime? _releaseStart;
  double? _releaseStartPressure;
  double _avgDeflationMmhgPerSec = 0;
  int _deflationSamples = 0;
  String? _deflationCoach;

  bool _palpatedMode = false;
  int? _palpatedSys;

  final _sysController = TextEditingController();
  final _diaController = TextEditingController();
  String? _resultText;
  bool? _resultPass;

  final _rng = Random();

  late BpPatientCase _patientCase;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _patientCase = BpPatientCase.generate(_rng);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().markModuleOpened(TrainingModule.bloodPressure);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      unawaited(_beep.stopLoop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deflationTimer?.cancel();
    _beep.dispose();
    _sysController.dispose();
    _diaController.dispose();
    super.dispose();
  }

  Future<void> _unlockAudio() => _beep.unlockFromUserGesture();

  void _pump() {
    _unlockAudio();
    setState(() {
      currentPressure = (currentPressure + 10).clamp(0.0, 280.0);
    });
    _updateBeatsForPressure();
  }

  void _toggleRelease() {
    _unlockAudio();
    if (!scenarioActive) {
      // Keep sys/dia in sync with the current patient case.
      final (sys, dia, pulse) = _generateHiddenBp();
      scenarioActive = true;
      _hiddenSys = sys;
      _hiddenDia = dia;
      _hiddenPulse = pulse;
      devLog('Generated hidden BP: $sys/$dia');
    }

    setState(() {
      releasing = !releasing;
    });

    if (releasing) {
      _releaseStart = DateTime.now();
      _releaseStartPressure = currentPressure;
      _avgDeflationMmhgPerSec = 0;
      _deflationSamples = 0;
      _deflationCoach = null;
      _startDeflationLoop();
    } else {
      // Pause deflation and silence beats.
      _stopBeats();
    }
  }

  void _startDeflationLoop() {
    _deflationTimer ??= Timer.periodic(const Duration(milliseconds: 90), (_) {
      if (!releasing) return;
      final prev = currentPressure;
      final next = (currentPressure - _deflationStep).clamp(0.0, 280.0);
      if (prev == next) return;
      setState(() => currentPressure = next);

       final inst = ((prev - next) / 0.09).clamp(0.0, 50.0); // mmHg/sec
       _deflationSamples++;
       _avgDeflationMmhgPerSec = (_avgDeflationMmhgPerSec * (_deflationSamples - 1) + inst) / _deflationSamples;
       _updateDeflationCoaching();

      // Start/stop beats based on crossing thresholds.
      _updateBeatsForPressure(prevPressure: prev);

      if (currentPressure <= 0) {
        _finishReleaseAtZero();
      }
    });
  }

  void _updateDeflationCoaching() {
    if (!mounted) return;
    if (!scenarioActive) return;
    final mode = context.read<AppState>().mode;
    if (mode == TrainingMode.test) return;

    // Typical teaching: 2–3 mmHg/sec.
    final v = _avgDeflationMmhgPerSec;
    String? msg;
    if (v > 4.0) {
      msg = 'Deflation is fast (~${v.toStringAsFixed(1)} mmHg/sec). Try closer to 2–3 mmHg/sec so you don\'t miss the first/last beat.';
    } else if (v > 0 && v < 1.0) {
      msg = 'Deflation is very slow (~${v.toStringAsFixed(1)} mmHg/sec). In real practice you\'d usually deflate ~2–3 mmHg/sec.';
    }
    if (msg != _deflationCoach) setState(() => _deflationCoach = msg);
  }

  void _finishReleaseAtZero() {
    setState(() => releasing = false);
    _stopBeats();
  }

  void _reset() {
    _unlockAudio();
    _deflationTimer?.cancel();
    _deflationTimer = null;
    releasing = false;
    scenarioActive = false;
    _hiddenSys = null;
    _hiddenDia = null;
    _hiddenPulse = null;
    _palpatedSys = null;

    _releaseStart = null;
    _releaseStartPressure = null;
    _avgDeflationMmhgPerSec = 0;
    _deflationSamples = 0;
    _deflationCoach = null;
    _stopBeats();

    _sysController.clear();
    _diaController.clear();
    setState(() {
      currentPressure = 0;
      _resultText = null;
      _resultPass = null;
    });
  }

  void _updateBeatsForPressure({double? prevPressure}) {
    if (!scenarioActive || _hiddenSys == null || _hiddenDia == null) {
      _stopBeats();
      return;
    }

    // Palpated mode uses a radial pulse indicator instead of Korotkoff beats.
    if (_palpatedMode) {
      _stopBeats();
      return;
    }

    final sys = _hiddenSys!.toDouble();
    final dia = _hiddenDia!.toDouble();

    // Beats play between SYS -> DIA as pressure is deflating.
    final shouldBeat = currentPressure <= sys && currentPressure > dia;

    // First beat when crossing below systolic.
    if (prevPressure != null && prevPressure > sys && currentPressure <= sys) {
      _startBeats();
      return;
    }

    if (shouldBeat) {
      _startBeats();
    } else {
      _stopBeats();
    }
  }

  void _startBeats() {
    if (_beatsActive) return;
    _beatsActive = true;
    final pulse = _hiddenPulse ?? 80;
    final interval = Duration(milliseconds: ((60 / pulse) * 1000).round().clamp(240, 1400));
    _beep.startLoop(interval: interval);
  }

  void _stopBeats() {
    if (!_beatsActive) return;
    _beatsActive = false;
    _beep.stopLoop();
  }

  (int sys, int dia, int pulse) _generateHiddenBp() {
    int genEvenInRange(int min, int maxVal) {
      final start = (min.isEven) ? min : min + 1;
      final end = (maxVal.isEven) ? maxVal : maxVal - 1;
      final count = ((end - start) ~/ 2) + 1;
      return start + 2 * _rng.nextInt(max(1, count));
    }

    // Case-driven ranges.
    final type = _patientCase.type;
    final (sysMin, sysMax, diaMin, diaMax, pulseMin, pulseMax) = switch (type) {
      BpCaseType.normal => (108, 128, 66, 82, 60, 96),
      BpCaseType.hypotensiveShock => (68, 96, 38, 60, 110, 150),
      BpCaseType.hypertensive => (170, 240, 95, 140, 55, 110),
      BpCaseType.pediatric => (80, 112, 45, 72, 90, 150),
      BpCaseType.weakPulseHardToHear => (88, 124, 50, 78, 90, 140),
    };

    int sys = genEvenInRange(sysMin, sysMax);

    // DIA tends to be 55–70% of SYS but clamp within case ranges.
    final ratio = 0.56 + _rng.nextDouble() * 0.14;
    int dia = (sys * ratio).round();
    dia = (dia.isEven) ? dia : dia + 1;
    dia = dia.clamp(diaMin, min(diaMax, sys - 10));
    if (dia >= sys) dia = max(40, sys - 10);
    if (!dia.isEven) dia -= 1;
    if (dia < 40) dia = 40;
    if (dia >= sys) dia = sys - 10;
    if (!dia.isEven) dia -= 1;

    final pulse = (pulseMin + _rng.nextInt(max(1, pulseMax - pulseMin + 1))).clamp(30, 200);
    _patientCase = _patientCase.copyWith(pulseRate: pulse, hiddenSys: sys, hiddenDia: dia);
    return (sys, dia, pulse);
  }

  void _submit() {
    _unlockAudio();

    if (_palpatedMode) {
      _submitPalpated();
      return;
    }

    final sysText = _sysController.text.trim();
    final diaText = _diaController.text.trim();
    if (sysText.isEmpty || diaText.isEmpty) {
      setState(() {
        _resultPass = false;
        _resultText = 'Enter both SYS and DIA.';
      });
      return;
    }

    final sysAns = int.tryParse(sysText);
    final diaAns = int.tryParse(diaText);
    if (sysAns == null || diaAns == null) {
      setState(() {
        _resultPass = false;
        _resultText = 'Enter both SYS and DIA.';
      });
      return;
    }

    if (_hiddenSys == null || _hiddenDia == null) {
      setState(() {
        _resultPass = false;
        _resultText = 'Start a scenario by pressing Release, then submit.';
      });
      return;
    }

    final sys = _hiddenSys!;
    final dia = _hiddenDia!;
    final tol = 4;

    final sysDiff = (sysAns - sys).abs();
    final diaDiff = (diaAns - dia).abs();
    final within = sysDiff <= tol && diaDiff <= tol;
    final exact = sysDiff == 0 && diaDiff == 0;

    final mode = context.read<AppState>().mode;

    String closeness(int diff) {
      if (diff == 0) return 'exact';
      if (diff <= 2) return 'very close';
      if (diff <= 6) return 'close';
      return 'off';
    }

    final deflationHint = _avgDeflationMmhgPerSec <= 0
        ? ''
        : (_avgDeflationMmhgPerSec > 4.0)
            ? ' You deflated fast (~${_avgDeflationMmhgPerSec.toStringAsFixed(1)} mmHg/sec).'
            : (_avgDeflationMmhgPerSec < 1.0)
                ? ' You deflated very slow (~${_avgDeflationMmhgPerSec.toStringAsFixed(1)} mmHg/sec).'
                : ' Your deflation speed looked good (~${_avgDeflationMmhgPerSec.toStringAsFixed(1)} mmHg/sec).';

    final explanation = _bpExplanation(sys: sys, dia: dia, caseType: _patientCase.type);

    if (mode == TrainingMode.test) {
      final score = within ? 100 : (sysDiff <= 6 && diaDiff <= 6 ? 60 : 0);
      unawaited(
        TrainingSummaryPage.recordAndShow(
          context,
          args: TrainingSummaryArgs(
            module: TrainingModule.bloodPressure,
            scorePercent: score,
            correct: within ? 1 : 0,
            total: 1,
            timeSpent: _timeSpent(),
            recommendedReview: explanation,
            missedTeachingPoints: within
                ? const []
                : [
                    'Deflate ~2–3 mmHg/sec to avoid missing the first/last Korotkoff sound.',
                    'Systolic = first sound; diastolic = disappearance of sound (adult).',
                  ],
          ),
        ),
      );
      return;
    }

    setState(() {
      _resultPass = within;
      _resultText = within
          ? (exact ? '✅ Correct!' : '✅ Within tolerance (±4). Correct: $sys/$dia.')
          : '❌ Not quite. Correct: $sys/$dia.';
      _resultText = '${_resultText!}\n\nYour SYS was ${closeness(sysDiff)} (${sysDiff} mmHg). Your DIA was ${closeness(diaDiff)} (${diaDiff} mmHg).$deflationHint\n\n$explanation';
    });
  }

  Duration _timeSpent() {
    final start = _releaseStart;
    if (start == null) return Duration.zero;
    return DateTime.now().difference(start);
  }

  String _bpExplanation({required int sys, required int dia, required BpCaseType caseType}) {
    final category = switch (caseType) {
      BpCaseType.normal => 'This is in a typical adult range (context matters).',
      BpCaseType.hypotensiveShock => 'This pattern can suggest poor perfusion/shock—correlate with skin signs, mentation, and pulse quality.',
      BpCaseType.hypertensive => 'Severe hypertension can be symptomatic (headache, neuro deficits, chest pain) but treat per protocol and context.',
      BpCaseType.pediatric => 'Pediatric BPs vary by age/size; use local references and clinical presentation.',
      BpCaseType.weakPulseHardToHear => 'Weak pulses can make Korotkoff sounds subtle—slow your deflation and ensure good stethoscope placement.',
    };
    return 'Teaching point: SYS is the first Korotkoff sound; DIA is when sounds disappear (adult). $category';
  }

  void _submitPalpated() {
    final sysText = _sysController.text.trim();
    if (sysText.isEmpty) {
      setState(() {
        _resultPass = false;
        _resultText = 'Enter your palpated systolic estimate.';
      });
      return;
    }
    final ans = int.tryParse(sysText);
    if (ans == null) {
      setState(() {
        _resultPass = false;
        _resultText = 'Enter a valid number.';
      });
      return;
    }
    final sys = _hiddenSys;
    if (sys == null) {
      setState(() {
        _resultPass = false;
        _resultText = 'Start a scenario by pressing Release (to generate a case), then estimate palpated systolic.';
      });
      return;
    }

    final diff = (ans - sys).abs();
    final within = diff <= 6;
    final mode = context.read<AppState>().mode;
    final explanation = 'Palpated systolic is the pressure where the radial pulse returns as you deflate. This is an estimate—auscultation is preferred when possible.';

    if (mode == TrainingMode.test) {
      final score = within ? 100 : (diff <= 10 ? 60 : 0);
      unawaited(
        TrainingSummaryPage.recordAndShow(
          context,
          args: TrainingSummaryArgs(
            module: TrainingModule.bloodPressure,
            scorePercent: score,
            correct: within ? 1 : 0,
            total: 1,
            timeSpent: _timeSpent(),
            recommendedReview: explanation,
            missedTeachingPoints: within ? const [] : ['Try to deflate slowly and watch for the first return of a palpable radial pulse.'],
          ),
        ),
      );
      return;
    }

    setState(() {
      _resultPass = within;
      _resultText = within ? '✅ Good estimate. Palpated SYS: $sys.' : '❌ Not quite. Palpated SYS: $sys.';
      _resultText = '${_resultText!}\n\nDifference: $diff mmHg.\n\n$explanation';
    });
  }

  void _showInfo() {
    _unlockAudio();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.pop(),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 560, maxHeight: MediaQuery.sizeOf(context).height * 0.88),
                child: Material(
                  color: cs.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                  clipBehavior: Clip.antiAlias,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Understanding Blood Pressure', style: context.textStyles.titleLarge),
                              ),
                              IconButton(
                                onPressed: () => context.pop(),
                                icon: const Icon(Icons.close),
                                style: ButtonStyle(
                                  splashFactory: NoSplash.splashFactory,
                                  foregroundColor: WidgetStatePropertyAll(cs.onSurface),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text('SYS/DIA (mmHg)', style: context.textStyles.labelMedium?.copyWith(color: cs.onPrimaryContainer)),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Systolic (SYS) is the pressure when the heart contracts. Diastolic (DIA) is the pressure when the heart relaxes. In this simulator, you’ll hear beats while the cuff pressure is between the patient’s SYS and DIA.',
                              style: context.textStyles.bodyMedium?.copyWith(height: 1.5),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Adult categories', style: context.textStyles.titleMedium),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _CategoryCard(title: 'Normal', subtitle: '<120 and <80'),
                          _CategoryCard(title: 'Elevated', subtitle: '120–129 and <80'),
                          _CategoryCard(title: 'Stage 1 HTN', subtitle: '130–139 or 80–89'),
                          _CategoryCard(title: 'Stage 2 HTN', subtitle: '≥140 or ≥90'),
                          _CategoryCard(title: 'Crisis', subtitle: '≥180 and/or ≥120 → evaluate promptly'),
                          const SizedBox(height: AppSpacing.md),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Notes: Single readings don’t diagnose; use clinical context.',
                              style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Training use only. Always follow your local protocols and device instructions.',
                              style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              onPressed: () => context.pop(),
                              style: ButtonStyle(
                                splashFactory: NoSplash.splashFactory,
                                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                              ),
                              child: const Text('Got it'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mode = context.select<AppState, TrainingMode>((s) => s.mode);

    final releaseLabel = !scenarioActive
        ? 'Release'
        : releasing
            ? 'Pause Release'
            : 'Resume Release';

    return EMSVitalsScaffold(
      title: 'Blood Pressure',
      subtitle: 'Pump to inflate • Toggle release • Beats occur SYS→DIA (training only, not medical advice)',
      onInfoPressed: _showInfo,
      bodySlivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: EMSSectionCard(
                  title: 'Patient case',
                  subtitle: mode == TrainingMode.learn ? 'Learn mode: use the case to build a differential.' : 'Case details are for training realism.',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(999), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
                    child: Text(_patientCase.type.label, style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w900)),
                  ),
                  child: _PatientCaseCard(case_: _patientCase),
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                value: _palpatedMode,
                                onChanged: (v) {
                                  setState(() {
                                    _palpatedMode = v;
                                    _resultText = null;
                                    _resultPass = null;
                                    _sysController.clear();
                                    _diaController.clear();
                                  });
                                  _stopBeats();
                                },
                                title: Text('Palpated systolic practice', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                                subtitle: Text('Estimate SYS by radial pulse return (no Korotkoff sounds).', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: Align(
                            alignment: Alignment.center,
                            child: FractionalTranslation(
                              translation: MediaQuery.sizeOf(context).width < 360 ? const Offset(-0.02, 0) : Offset.zero,
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: BpGauge(pressure: currentPressure),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text('Pressure: ${currentPressure.toStringAsFixed(1)} mmHg', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        if (_palpatedMode) ...[
                          const SizedBox(height: 8),
                          _RadialPulseIndicator(isPresent: _hiddenSys == null ? true : currentPressure < _hiddenSys!),
                        ],
                        if (_deflationCoach != null) ...[
                          const SizedBox(height: 12),
                          EMSResultBox(title: 'Coaching', message: _deflationCoach!, kind: EMSResultKind.info),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 54,
                                child: FilledButton.icon(
                                  onPressed: _pump,
                                  style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                                  icon: const Icon(Icons.add, color: Colors.white),
                                  label: const Text('Pump', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: SizedBox(
                                height: 54,
                                child: OutlinedButton.icon(
                                  onPressed: _toggleRelease,
                                  style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                                  icon: Icon(releasing ? Icons.pause : Icons.south),
                                  label: Text(releaseLabel),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: Text('Deflation speed', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900))),
                            Text('${_deflationStep.toStringAsFixed(1)} mmHg/tick', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(overlayShape: SliderComponentShape.noOverlay, activeTrackColor: cs.primary, inactiveTrackColor: cs.outline.withValues(alpha: 0.18), thumbColor: cs.primary),
                          child: Slider(
                            value: _deflationStep,
                            min: 0.2,
                            max: 1.4,
                            divisions: 12,
                            onChanged: (v) => setState(() => _deflationStep = v),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!_palpatedMode)
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _sysController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: const InputDecoration(labelText: 'Systolic (SYS)'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _diaController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: const InputDecoration(labelText: 'Diastolic (DIA)'),
                                ),
                              ),
                            ],
                          )
                        else
                          TextField(
                            controller: _sysController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(labelText: 'Palpated systolic (SYS)'),
                          ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 54,
                                child: FilledButton.icon(
                                  onPressed: _submit,
                                  style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                                  icon: const Icon(Icons.check, color: Colors.white),
                                  label: const Text('Submit', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 54,
                                child: OutlinedButton.icon(
                                  onPressed: _reset,
                                  style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                                  icon: const Icon(Icons.restart_alt),
                                  label: const Text('Reset'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_resultText != null) ...[
                          const SizedBox(height: 12),
                          EMSResultBox(title: _resultPass == true ? 'Result' : 'Try again', message: _resultText!, kind: _resultPass == true ? EMSResultKind.success : EMSResultKind.warning),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum BpCaseType { normal, hypotensiveShock, hypertensive, pediatric, weakPulseHardToHear }

extension on BpCaseType {
  String get label => switch (this) {
    BpCaseType.normal => 'Normal',
    BpCaseType.hypotensiveShock => 'Hypotensive / Shock',
    BpCaseType.hypertensive => 'Hypertensive',
    BpCaseType.pediatric => 'Pediatric',
    BpCaseType.weakPulseHardToHear => 'Weak pulse / Hard to hear',
  };
}

@immutable
class BpPatientCase {
  const BpPatientCase({required this.type, required this.age, required this.chiefComplaint, required this.skinSigns, required this.generalCondition, required this.pulseRate, this.hiddenSys, this.hiddenDia});

  final BpCaseType type;
  final int age;
  final String chiefComplaint;
  final String skinSigns;
  final String generalCondition;
  final int pulseRate;
  final int? hiddenSys;
  final int? hiddenDia;

  BpPatientCase copyWith({BpCaseType? type, int? age, String? chiefComplaint, String? skinSigns, String? generalCondition, int? pulseRate, int? hiddenSys, int? hiddenDia}) => BpPatientCase(
    type: type ?? this.type,
    age: age ?? this.age,
    chiefComplaint: chiefComplaint ?? this.chiefComplaint,
    skinSigns: skinSigns ?? this.skinSigns,
    generalCondition: generalCondition ?? this.generalCondition,
    pulseRate: pulseRate ?? this.pulseRate,
    hiddenSys: hiddenSys ?? this.hiddenSys,
    hiddenDia: hiddenDia ?? this.hiddenDia,
  );

  static BpPatientCase generate(Random rng) {
    final type = BpCaseType.values[rng.nextInt(BpCaseType.values.length)];
    return switch (type) {
      BpCaseType.normal => BpPatientCase(
        type: type,
        age: [22, 34, 41, 55][rng.nextInt(4)],
        chiefComplaint: 'Routine assessment',
        skinSigns: 'Warm, dry',
        generalCondition: 'Alert, speaking full sentences',
        pulseRate: 78,
      ),
      BpCaseType.hypotensiveShock => BpPatientCase(
        type: type,
        age: [46, 57, 64, 72][rng.nextInt(4)],
        chiefComplaint: 'Weakness / dizziness',
        skinSigns: 'Cool, pale, clammy',
        generalCondition: 'Ill-appearing, anxious',
        pulseRate: 128,
      ),
      BpCaseType.hypertensive => BpPatientCase(
        type: type,
        age: [55, 62, 69, 79][rng.nextInt(4)],
        chiefComplaint: 'Headache / high BP concern',
        skinSigns: 'Warm, dry',
        generalCondition: 'Alert; may be uncomfortable',
        pulseRate: 84,
      ),
      BpCaseType.pediatric => BpPatientCase(
        type: type,
        age: [4, 6, 9, 12][rng.nextInt(4)],
        chiefComplaint: 'Sick child assessment',
        skinSigns: 'Warm, pink',
        generalCondition: 'Anxious; responds appropriately',
        pulseRate: 120,
      ),
      BpCaseType.weakPulseHardToHear => BpPatientCase(
        type: type,
        age: [62, 71, 78, 84][rng.nextInt(4)],
        chiefComplaint: 'Weakness',
        skinSigns: 'Cool, mottled',
        generalCondition: 'Tired; slow responses',
        pulseRate: 112,
      ),
    };
  }
}

class _PatientCaseCard extends StatelessWidget {
  const _PatientCaseCard({required this.case_});
  final BpPatientCase case_;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kvRow(context, 'Age', '${case_.age}'),
        const SizedBox(height: 6),
        _kvRow(context, 'Chief complaint', case_.chiefComplaint),
        const SizedBox(height: 6),
        _kvRow(context, 'Skin signs', case_.skinSigns),
        const SizedBox(height: 6),
        _kvRow(context, 'Pulse rate', '${case_.pulseRate} BPM'),
        const SizedBox(height: 6),
        _kvRow(context, 'General condition', case_.generalCondition),
        const SizedBox(height: 10),
        Text('Educational use only — not medical advice.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
      ],
    );
  }

  Widget _kvRow(BuildContext context, String k, String v) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: Text(k, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
        Expanded(child: Text(v, style: context.textStyles.bodyMedium?.copyWith(height: 1.35))),
      ],
    );
  }
}

class _RadialPulseIndicator extends StatelessWidget {
  const _RadialPulseIndicator({required this.isPresent});
  final bool isPresent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (isPresent ? Colors.green : AppColors.danger).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: (isPresent ? Colors.green : AppColors.danger).withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(isPresent ? Icons.favorite : Icons.heart_broken, color: isPresent ? Colors.green : AppColors.danger),
          const SizedBox(width: 10),
          Expanded(child: Text(isPresent ? 'Radial pulse present' : 'Radial pulse absent', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900))),
          Text('Palpation', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(title, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w700))),
            const SizedBox(width: AppSpacing.md),
            Text(subtitle, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
