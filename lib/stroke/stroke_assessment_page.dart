import 'dart:async';
import 'dart:math';

import 'package:emscode_sim_vitals/app/app_state.dart';
import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/stroke/stroke_case.dart';
import 'package:emscode_sim_vitals/stroke/stroke_patient_figure.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/shared/training_summary_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class StrokeAssessmentPage extends StatefulWidget {
  const StrokeAssessmentPage({super.key});

  @override
  State<StrokeAssessmentPage> createState() => _StrokeAssessmentPageState();
}

class _StrokeAssessmentPageState extends State<StrokeAssessmentPage> with TickerProviderStateMixin {
  final _rng = Random();

  late StrokeCase _case;

  StrokeTest? _activeTest;
  String _instruction = 'Press a BE-FAST test to begin.';

  // Findings (student input)
  StrokeBalanceFinding? _balancePick;
  StrokeEyesFinding? _eyesPick;
  StrokeFaceFinding? _facePick;
  StrokeArmsFinding? _armsPick;
  StrokeSpeechFinding? _speechPick;
  String? _timePick;

  bool _showResults = false;
  List<_GradeLine> _gradeLines = const [];
  String? _resultsSummary;
  String? _timeSummary;
  String? _meaningText;
  bool _sideNote = false;

  late final AnimationController _balanceController;
  late final AnimationController _eyesController;
  late final AnimationController _armTimerController;
  Timer? _armStopTimer;

  FlutterTts? _tts;
  bool _ttsUnavailable = false;

  @override
  void initState() {
    super.initState();
    _case = StrokeCase.generate(_rng);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().markModuleOpened(TrainingModule.stroke);
    });

    _balanceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
    _eyesController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();
    _armTimerController = AnimationController(vsync: this, duration: const Duration(seconds: 10));
  }

  @override
  void dispose() {
    _armStopTimer?.cancel();
    _safeStopSpeech();
    _tts?.stop();
    _balanceController.dispose();
    _eyesController.dispose();
    _armTimerController.dispose();
    super.dispose();
  }

  void _showInfo() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About this Simulator', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'This tool simulates BE-FAST stroke checks: Balance, Eyes, Face, Arm Drift, and Speech.',
                    style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _InfoBullet(text: 'Press a test to start the animation.'),
                  _InfoBullet(text: 'Use Reset View to return to neutral.'),
                  _InfoBullet(text: 'Use the findings panel to record findings and show results.'),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ButtonStyle(
                        splashFactory: NoSplash.splashFactory,
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      ),
                      child: const Text('Close'),
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

  void _resetView() {
    _armStopTimer?.cancel();
    _armStopTimer = null;
    _armTimerController.stop();
    _armTimerController.value = 0;
    _safeStopSpeech();
    setState(() {
      _activeTest = null;
      _instruction = 'Press a BE-FAST test to begin.';
    });
  }

  Future<void> _ensureTts() async {
    if (_ttsUnavailable) return;
    if (_tts != null) return;
    try {
      final tts = FlutterTts();
      await tts.setSpeechRate(0.48);
      await tts.setPitch(1.0);
      await tts.awaitSpeakCompletion(false);
      _tts = tts;
    } catch (e) {
      debugPrint('Speech synthesis unavailable: $e');
      _ttsUnavailable = true;
    }
  }

  Future<void> _safeStopSpeech() async {
    try {
      await _tts?.stop();
    } catch (e) {
      debugPrint('TTS stop failed (ignored): $e');
    }
  }

  Future<void> _speak(String text) async {
    await _ensureTts();
    if (_ttsUnavailable || _tts == null) return;
    try {
      await _tts!.stop();
      await _tts!.speak(text);
    } catch (e) {
      debugPrint('TTS speak failed (ignored): $e');
      _ttsUnavailable = true;
    }
  }

  void _selectTest(StrokeTest test) {
    _armStopTimer?.cancel();
    _armStopTimer = null;
    _armTimerController.stop();
    _armTimerController.value = 0;
    _safeStopSpeech();

    final instruction = switch (test) {
      StrokeTest.balance =>
        'Balance: Ask the person to stand with feet together and arms at the sides. Watch the whole body. It may lean or sway. The feet stay on the ground.',
      StrokeTest.eyes =>
        'Eyes: Ask the person to follow your finger left and right. Look for slow eye movement or eyes pulled to one side.',
      StrokeTest.face =>
        'Face: Ask the person to smile. Look to see if one side of the mouth is lower. The eyebrow on that side may also look lower.',
      StrokeTest.armDrift =>
        'Arm Drift: Ask the person to close their eyes and hold both arms out, palms up, for ten seconds. Watch if one arm drops.',
      StrokeTest.speech =>
        'Speech: Ask the person to repeat a simple sentence. Listen for slurred words, trouble getting words out, trouble understanding, or no speech.',
    };

    setState(() {
      _activeTest = test;
      _instruction = instruction;
    });

    if (test == StrokeTest.armDrift) {
      _armTimerController.forward(from: 0);
      _armStopTimer = Timer(const Duration(seconds: 10), () {
        if (!mounted) return;
        _armTimerController.stop();
      });
    }

    if (test == StrokeTest.speech) {
      final text = _speechTextFor(_case.speech);
      _speak(text);
    }
  }

  void _nextCase() {
    _resetFormOnly();
    _resetView();
    setState(() {
      _case = StrokeCase.generate(_rng);
    });
  }

  void _resetFormOnly() {
    setState(() {
      _balancePick = null;
      _eyesPick = null;
      _facePick = null;
      _armsPick = null;
      _speechPick = null;
      _timePick = null;
      _showResults = false;
      _gradeLines = const [];
      _resultsSummary = null;
      _timeSummary = null;
      _meaningText = null;
      _sideNote = false;
    });
  }

  void _showResultsNow() {
    final lines = <_GradeLine>[];
    bool sideNote = false;
    int matched = 0;

    void grade<T>({
      required String name,
      required T expected,
      required T? selected,
      required String Function(T v) label,
      required bool Function(T selected) isOppositeSide,
    }) {
      final sel = selected;
      if (sel == null) {
        lines.add(_GradeLine(text: '❌ $name missing: expected ${label(expected)}.'));
        return;
      }
      if (sel == expected) {
        matched++;
        lines.add(_GradeLine(text: '✅ $name correct.'));
        return;
      }
      lines.add(_GradeLine(text: '❌ $name expected: ${label(expected)}.'));
      if (isOppositeSide(sel)) sideNote = true;
    }

    grade<StrokeBalanceFinding>(
      name: 'Balance',
      expected: _case.balance,
      selected: _balancePick,
      label: _labelBalance,
      isOppositeSide: (_) => false,
    );
    grade<StrokeEyesFinding>(
      name: 'Eyes',
      expected: _case.eyes,
      selected: _eyesPick,
      label: _labelEyes,
      isOppositeSide: (sel) => _isOppositeEyeSide(expected: _case.eyes, selected: sel),
    );
    grade<StrokeFaceFinding>(
      name: 'Face',
      expected: _case.face,
      selected: _facePick,
      label: _labelFace,
      isOppositeSide: (sel) => _isOppositeFaceSide(expected: _case.face, selected: sel),
    );
    grade<StrokeArmsFinding>(
      name: 'Arms',
      expected: _case.arms,
      selected: _armsPick,
      label: _labelArms,
      isOppositeSide: (sel) => _isOppositeArmsSide(expected: _case.arms, selected: sel),
    );
    grade<StrokeSpeechFinding>(
      name: 'Speech',
      expected: _case.speech,
      selected: _speechPick,
      label: _labelSpeech,
      isOppositeSide: (_) => false,
    );

    final signs = _case.strokeSignsCount;
    final resultsSummary = 'Results: You matched $matched/5 areas. Stroke signs found: $signs.';
    final timeSummary = 'Time: last known well was about ${_case.lastKnownWellMinutes} minutes ago.';

    final meaning = _meaningFeedback(case_: _case);

    final mode = context.read<AppState>().mode;
    if (mode == TrainingMode.test) {
      final timeBucketCorrect = _timePick != null && _timePick == _timeBucketForMinutes(_case.lastKnownWellMinutes);
      final total = 6;
      final correct = matched + (timeBucketCorrect ? 1 : 0);
      final score = ((correct / total) * 100).round();
      unawaited(
        TrainingSummaryPage.recordAndShow(
          context,
          args: TrainingSummaryArgs(
            module: TrainingModule.stroke,
            scorePercent: score,
            correct: correct,
            total: total,
            timeSpent: const Duration(seconds: 0),
            recommendedReview: 'Teaching point: Always check glucose early; hypoglycemia can mimic stroke. Use BE-FAST/Cincinnati findings + last-known-well wording to guide stroke alert decisions per protocol.',
            missedTeachingPoints: [
              if (!timeBucketCorrect) 'Clarify last known well timing and decide if the patient is within a likely treatment window.',
              if (sideNote) 'Remember: patient-left vs patient-right can be reversed from your screen perspective.',
            ],
          ),
        ),
      );
      return;
    }

    setState(() {
      _showResults = true;
      _gradeLines = lines;
      _resultsSummary = resultsSummary;
      _timeSummary = timeSummary;
      _meaningText = meaning;
      _sideNote = sideNote;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mode = context.select<AppState, TrainingMode>((s) => s.mode);
    final width = MediaQuery.sizeOf(context).width;
    final bool twoCol = width >= 920;

    return Scaffold(
      bottomNavigationBar: const EMSBottomNav(),
      body: CustomScrollView(
        slivers: [
          EMSVitalsHeader(
            title: 'Stroke Assessment',
            onInfoPressed: _showInfo,
            onBackPressed: () {
              _safeStopSpeech();
              context.go(AppRoutes.home);
            },
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxl),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _PatientInfoCard(strokeCase: _case, mode: mode),
                  const SizedBox(height: AppSpacing.md),
                  if (!twoCol) ...[
                    _SimulatorCard(
                      cs: cs,
                      strokeCase: _case,
                      activeTest: _activeTest,
                      instruction: _instruction,
                      balanceController: _balanceController,
                      eyesController: _eyesController,
                      armTimerController: _armTimerController,
                      onSelectTest: _selectTest,
                      onResetView: _resetView,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FindingsCard(
                      cs: cs,
                      balancePick: _balancePick,
                      eyesPick: _eyesPick,
                      facePick: _facePick,
                      armsPick: _armsPick,
                      speechPick: _speechPick,
                      timePick: _timePick,
                      onBalanceChanged: (v) => setState(() => _balancePick = v),
                      onEyesChanged: (v) => setState(() => _eyesPick = v),
                      onFaceChanged: (v) => setState(() => _facePick = v),
                      onArmsChanged: (v) => setState(() => _armsPick = v),
                      onSpeechChanged: (v) => setState(() => _speechPick = v),
                      onTimeChanged: (v) => setState(() => _timePick = v),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ActionButtons(
                      onShowResults: _showResultsNow,
                      onNextCase: _nextCase,
                      onReset: _resetFormOnly,
                    ),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _SimulatorCard(
                            cs: cs,
                            strokeCase: _case,
                            activeTest: _activeTest,
                            instruction: _instruction,
                            balanceController: _balanceController,
                            eyesController: _eyesController,
                            armTimerController: _armTimerController,
                            onSelectTest: _selectTest,
                            onResetView: _resetView,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        SizedBox(
                          width: 420,
                          child: Column(
                            children: [
                              _FindingsCard(
                                cs: cs,
                                balancePick: _balancePick,
                                eyesPick: _eyesPick,
                                facePick: _facePick,
                                armsPick: _armsPick,
                                speechPick: _speechPick,
                                timePick: _timePick,
                                onBalanceChanged: (v) => setState(() => _balancePick = v),
                                onEyesChanged: (v) => setState(() => _eyesPick = v),
                                onFaceChanged: (v) => setState(() => _facePick = v),
                                onArmsChanged: (v) => setState(() => _armsPick = v),
                                onSpeechChanged: (v) => setState(() => _speechPick = v),
                                onTimeChanged: (v) => setState(() => _timePick = v),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _ActionButtons(
                                onShowResults: _showResultsNow,
                                onNextCase: _nextCase,
                                onReset: _resetFormOnly,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_showResults) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ResultsCard(
                      cs: cs,
                      gradeLines: _gradeLines,
                      resultsSummary: _resultsSummary,
                      timeSummary: _timeSummary,
                      meaningText: _meaningText,
                      showSideNote: _sideNote,
                      correctTimeBucket: _timeBucketForMinutes(_case.lastKnownWellMinutes),
                      studentTimeBucket: _timePick,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientInfoCard extends StatelessWidget {
  const _PatientInfoCard({required this.strokeCase, required this.mode});

  final StrokeCase strokeCase;
  final TrainingMode mode;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    TextStyle lineStyle() => context.textStyles.bodyMedium!.copyWith(height: 1.5);
    TextStyle kStyle() => lineStyle().copyWith(color: cs.onSurfaceVariant);
    TextStyle vStyle() => lineStyle().copyWith(fontWeight: FontWeight.w700);

    Widget line(String k, String v) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 140, child: Text('$k:', style: kStyle())),
            Expanded(child: Text(v, style: vStyle())),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: AppColors.headerGradient.map((c) => c.withValues(alpha: 0.18)).toList()),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
                  ),
                  child: const Icon(Icons.badge, color: AppColors.emsBlue),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text('Patient Information', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            line('Age/Sex', '${strokeCase.age} / ${strokeCase.sex}'),
            line('Main concern', strokeCase.mainConcern),
            line('Last known well', mode == TrainingMode.test ? _lkwWording(strokeCase.lastKnownWellMinutes) : '${strokeCase.lastKnownWellMinutes} minutes ago'),
            line('Blood sugar', mode == TrainingMode.test ? 'Check performed (value available after submission)' : '${strokeCase.bloodSugarMgDl} mg/dL'),
            line('History', strokeCase.history),
          ],
        ),
      ),
    );
  }

  String _lkwWording(int minutes) {
    if (minutes <= 15) return '“Just now / within the last 15 minutes” (reported)';
    if (minutes <= 60) return '“About an hour ago” (reported)';
    if (minutes <= 180) return '“A few hours ago” (reported)';
    return '“Unknown / >3 hours” (reported)';
  }
}

class _SimulatorCard extends StatelessWidget {
  const _SimulatorCard({
    required this.cs,
    required this.strokeCase,
    required this.activeTest,
    required this.instruction,
    required this.balanceController,
    required this.eyesController,
    required this.armTimerController,
    required this.onSelectTest,
    required this.onResetView,
  });

  final ColorScheme cs;
  final StrokeCase strokeCase;
  final StrokeTest? activeTest;
  final String instruction;
  final AnimationController balanceController;
  final AnimationController eyesController;
  final AnimationController armTimerController;
  final ValueChanged<StrokeTest> onSelectTest;
  final VoidCallback onResetView;

  @override
  Widget build(BuildContext context) {
    final timerSeconds = (armTimerController.value * 10.0).clamp(0, 10.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('BE-FAST Simulator', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ),
                AnimatedBuilder(
                  animation: armTimerController,
                  builder: (context, _) {
                    final v = timerSeconds.toStringAsFixed(1);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
                      ),
                      child: Text('Timer: ${activeTest == StrokeTest.armDrift ? v : '0.0'}s', style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AnimatedBuilder(
              animation: Listenable.merge([balanceController, eyesController, armTimerController]),
              builder: (context, _) {
                return StrokePatientFigure(
                  activeTest: activeTest,
                  strokeCase: strokeCase,
                  balancePhase: balanceController.value,
                  eyePhase: eyesController.value,
                  armTimerValue: armTimerController.value,
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Text(instruction, style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5)),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _TestChip(
                  label: 'Balance',
                  isActive: activeTest == StrokeTest.balance,
                  onTap: () => onSelectTest(StrokeTest.balance),
                ),
                _TestChip(
                  label: 'Eyes',
                  isActive: activeTest == StrokeTest.eyes,
                  onTap: () => onSelectTest(StrokeTest.eyes),
                ),
                _TestChip(
                  label: 'Face',
                  isActive: activeTest == StrokeTest.face,
                  onTap: () => onSelectTest(StrokeTest.face),
                ),
                _TestChip(
                  label: 'Arm Drift',
                  isActive: activeTest == StrokeTest.armDrift,
                  onTap: () => onSelectTest(StrokeTest.armDrift),
                ),
                _TestChip(
                  label: 'Speech',
                  isActive: activeTest == StrokeTest.speech,
                  onTap: () => onSelectTest(StrokeTest.speech),
                ),
                SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: onResetView,
                    style: ButtonStyle(
                      splashFactory: NoSplash.splashFactory,
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset View'),
                  ),
                ),
              ],
            ),
            if (activeTest == StrokeTest.speech) ...[
              const SizedBox(height: AppSpacing.md),
              _SpeechStrip(text: _speechTextFor(strokeCase.speech)),
            ],
          ],
        ),
      ),
    );
  }
}

class _FindingsCard extends StatelessWidget {
  const _FindingsCard({
    required this.cs,
    required this.balancePick,
    required this.eyesPick,
    required this.facePick,
    required this.armsPick,
    required this.speechPick,
    required this.timePick,
    required this.onBalanceChanged,
    required this.onEyesChanged,
    required this.onFaceChanged,
    required this.onArmsChanged,
    required this.onSpeechChanged,
    required this.onTimeChanged,
  });

  final ColorScheme cs;
  final StrokeBalanceFinding? balancePick;
  final StrokeEyesFinding? eyesPick;
  final StrokeFaceFinding? facePick;
  final StrokeArmsFinding? armsPick;
  final StrokeSpeechFinding? speechPick;
  final String? timePick;

  final ValueChanged<StrokeBalanceFinding?> onBalanceChanged;
  final ValueChanged<StrokeEyesFinding?> onEyesChanged;
  final ValueChanged<StrokeFaceFinding?> onFaceChanged;
  final ValueChanged<StrokeArmsFinding?> onArmsChanged;
  final ValueChanged<StrokeSpeechFinding?> onSpeechChanged;
  final ValueChanged<String?> onTimeChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Findings', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.md),
            _DropdownField<StrokeBalanceFinding>(
              label: 'Balance',
              value: balancePick,
              items: StrokeBalanceFinding.values,
              itemLabel: _labelBalance,
              onChanged: onBalanceChanged,
            ),
            const SizedBox(height: AppSpacing.sm),
            _DropdownField<StrokeEyesFinding>(
              label: 'Eyes',
              value: eyesPick,
              items: StrokeEyesFinding.values,
              itemLabel: _labelEyes,
              onChanged: onEyesChanged,
            ),
            const SizedBox(height: AppSpacing.sm),
            _DropdownField<StrokeFaceFinding>(
              label: 'Face',
              value: facePick,
              items: StrokeFaceFinding.values,
              itemLabel: _labelFace,
              onChanged: onFaceChanged,
            ),
            const SizedBox(height: AppSpacing.sm),
            _DropdownField<StrokeArmsFinding>(
              label: 'Arms',
              value: armsPick,
              items: StrokeArmsFinding.values,
              itemLabel: _labelArms,
              onChanged: onArmsChanged,
            ),
            const SizedBox(height: AppSpacing.sm),
            _DropdownField<StrokeSpeechFinding>(
              label: 'Speech',
              value: speechPick,
              items: StrokeSpeechFinding.values,
              itemLabel: _labelSpeech,
              onChanged: onSpeechChanged,
            ),
            const SizedBox(height: AppSpacing.sm),
            _DropdownStringField(
              label: 'Time / Last Known Well',
              value: timePick,
              items: const [
                'Less than 3 hours',
                '3 to 6 hours',
                '6 to 24 hours',
                'More than 24 hours',
                'Not sure',
              ],
              onChanged: onTimeChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.onShowResults, required this.onNextCase, required this.onReset});
  final VoidCallback onShowResults;
  final VoidCallback onNextCase;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: onShowResults,
            style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
            child: const Text('Show Results'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: onNextCase,
            style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
            child: const Text('Next Case'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: TextButton(
            onPressed: onReset,
            style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
            child: const Text('Reset'),
          ),
        ),
      ],
    );
  }
}

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({
    required this.cs,
    required this.gradeLines,
    required this.resultsSummary,
    required this.timeSummary,
    required this.meaningText,
    required this.showSideNote,
    required this.correctTimeBucket,
    required this.studentTimeBucket,
  });

  final ColorScheme cs;
  final List<_GradeLine> gradeLines;
  final String? resultsSummary;
  final String? timeSummary;
  final String? meaningText;
  final bool showSideNote;
  final String correctTimeBucket;
  final String? studentTimeBucket;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Results', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            for (final line in gradeLines) ...[
              Text(line.text, style: context.textStyles.bodyMedium?.copyWith(height: 1.55)),
            ],
            if (showSideNote) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                "Note: Sides are from the patient’s perspective. Patient’s right appears on the left side of the screen, and patient’s left appears on the right.",
                style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (resultsSummary != null) Text(resultsSummary!, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
            if (timeSummary != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(timeSummary!, style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.4)),
            ],
            const SizedBox(height: AppSpacing.md),
            Text('Time bucket', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.xs),
            Text('Correct: $correctTimeBucket', style: context.textStyles.bodyMedium),
            Text('You picked: ${studentTimeBucket ?? '—'}', style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.md),
            Text('What this can mean:', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.xs),
            Text(meaningText ?? '', style: context.textStyles.bodyMedium?.copyWith(height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _TestChip extends StatelessWidget {
  const _TestChip({required this.label, required this.isActive, required this.onTap});

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 44,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashFactory: NoSplash.splashFactory,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isActive ? AppColors.emsBlue.withValues(alpha: 0.14) : cs.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isActive ? AppColors.emsBlue.withValues(alpha: 0.35) : cs.outline.withValues(alpha: 0.12)),
          ),
          child: Center(
            child: Text(
              label,
              style: context.textStyles.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: isActive ? AppColors.emsBlue : cs.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeechStrip extends StatelessWidget {
  const _SpeechStrip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Text(text, style: context.textStyles.bodyMedium?.copyWith(height: 1.5)),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({required this.label, required this.value, required this.items, required this.itemLabel, required this.onChanged});

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T v) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.18))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Text('Select', style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          items: items
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text(itemLabel(e), style: context.textStyles.bodyMedium),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DropdownStringField extends StatelessWidget {
  const _DropdownStringField({required this.label, required this.value, required this.items, required this.onChanged});
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.18))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text('Select', style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          items: items
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e, style: context.textStyles.bodyMedium),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _InfoBullet extends StatelessWidget {
  const _InfoBullet({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.45)),
          Expanded(child: Text(text, style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.45))),
        ],
      ),
    );
  }
}

class _GradeLine {
  const _GradeLine({required this.text});
  final String text;
}

String _labelBalance(StrokeBalanceFinding v) => switch (v) {
  StrokeBalanceFinding.normal => 'Normal',
  StrokeBalanceFinding.unsteady => 'Unsteady or wide stance',
  StrokeBalanceFinding.leansLeft => 'Leans or falls to the left',
  StrokeBalanceFinding.leansRight => 'Leans or falls to the right',
};

String _labelEyes(StrokeEyesFinding v) => switch (v) {
  StrokeEyesFinding.followsBothWays => 'Follows finger both ways',
  StrokeEyesFinding.followsSlowly => 'Follows slowly',
  StrokeEyesFinding.pulledLeft => 'Eyes pulled to the left',
  StrokeEyesFinding.pulledRight => 'Eyes pulled to the right',
};

String _labelFace(StrokeFaceFinding v) => switch (v) {
  StrokeFaceFinding.noDroop => 'No droop',
  StrokeFaceFinding.leftDroops => 'Left side droops',
  StrokeFaceFinding.rightDroops => 'Right side droops',
};

String _labelArms(StrokeArmsFinding v) => switch (v) {
  StrokeArmsFinding.noDrift => 'No arm drift',
  StrokeArmsFinding.leftDriftsDown => 'Left arm drifts down',
  StrokeArmsFinding.rightDriftsDown => 'Right arm drifts down',
};

String _labelSpeech(StrokeSpeechFinding v) => switch (v) {
  StrokeSpeechFinding.normal => 'Normal',
  StrokeSpeechFinding.slurred => 'Slurred',
  StrokeSpeechFinding.troubleSpeaking => 'Trouble speaking',
  StrokeSpeechFinding.troubleUnderstanding => 'Trouble understanding',
  StrokeSpeechFinding.noSpeech => 'No speech',
};

bool _isOppositeFaceSide({required StrokeFaceFinding expected, required StrokeFaceFinding selected}) {
  return (expected == StrokeFaceFinding.leftDroops && selected == StrokeFaceFinding.rightDroops) ||
      (expected == StrokeFaceFinding.rightDroops && selected == StrokeFaceFinding.leftDroops);
}

bool _isOppositeArmsSide({required StrokeArmsFinding expected, required StrokeArmsFinding selected}) {
  return (expected == StrokeArmsFinding.leftDriftsDown && selected == StrokeArmsFinding.rightDriftsDown) ||
      (expected == StrokeArmsFinding.rightDriftsDown && selected == StrokeArmsFinding.leftDriftsDown);
}

bool _isOppositeEyeSide({required StrokeEyesFinding expected, required StrokeEyesFinding selected}) {
  return (expected == StrokeEyesFinding.pulledLeft && selected == StrokeEyesFinding.pulledRight) ||
      (expected == StrokeEyesFinding.pulledRight && selected == StrokeEyesFinding.pulledLeft);
}

String _speechTextFor(StrokeSpeechFinding f) {
  switch (f) {
    case StrokeSpeechFinding.normal:
      return 'The early bird catches the worm. Today is a sunny day.';
    case StrokeSpeechFinding.slurred:
      return 'Thuhh earrly burd catchezz the werm. Tuhday ishh a shunny day.';
    case StrokeSpeechFinding.troubleSpeaking:
      return 'Uh... sky... uh... blue... um... grass... uh... uh...';
    case StrokeSpeechFinding.troubleUnderstanding:
      return 'Yes, okay, I understand. Happy sofa banana elbow, absolutely.';
    case StrokeSpeechFinding.noSpeech:
      return '…';
  }
}

String _meaningFeedback({required StrokeCase case_}) {
  final signs = case_.strokeSignsCount;
  final b = StringBuffer();

  if (signs == 0) {
    b.write('No stroke signs found here. Think about other causes like low blood sugar, a seizure, a migraine, or a drug or medicine problem.');
    return b.toString();
  }

  b.write('This pattern can mean a stroke. Find the last time the person was well and call a stroke alert. Go to a hospital that treats strokes.');
  if (signs >= 2) b.write(' More than one sign makes a stroke more likely.');
  final bigArtery = (case_.eyes == StrokeEyesFinding.pulledLeft || case_.eyes == StrokeEyesFinding.pulledRight) ||
      (case_.speech == StrokeSpeechFinding.troubleSpeaking || case_.speech == StrokeSpeechFinding.troubleUnderstanding || case_.speech == StrokeSpeechFinding.noSpeech);
  if (bigArtery) b.write(' Eye pulled to one side or trouble with speech can mean a big artery blockage.');
  return b.toString();
}

String _timeBucketForMinutes(int minutes) {
  if (minutes < 180) return 'Less than 3 hours';
  if (minutes < 360) return '3 to 6 hours';
  if (minutes < 1440) return '6 to 24 hours';
  return 'More than 24 hours';
}
