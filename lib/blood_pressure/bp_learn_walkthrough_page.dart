import 'dart:async';

import 'package:emscode_sim_vitals/app/app_state.dart';
import 'package:emscode_sim_vitals/blood_pressure/bp_gauge.dart';
import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class BpLearnWalkthroughPage extends StatefulWidget {
  const BpLearnWalkthroughPage({super.key});

  @override
  State<BpLearnWalkthroughPage> createState() => _BpLearnWalkthroughPageState();
}

class _BpLearnWalkthroughPageState extends State<BpLearnWalkthroughPage> {
  static const int _sys = 118;
  static const int _dia = 76;
  static const double _maxInflation = 170;

  Timer? _timer;
  double _pressure = 0;
  _WalkthroughStage _stage = _WalkthroughStage.ready;
  int _questionIndex = 0;
  final List<int?> _answers = [null, null];

  bool get _isAnimating =>
      _stage == _WalkthroughStage.inflate || _stage == _WalkthroughStage.releaseToSys || _stage == _WalkthroughStage.releaseToDia;

  int get _stepNumber => switch (_stage) {
        _WalkthroughStage.ready => 1,
        _WalkthroughStage.inflate => 2,
        _WalkthroughStage.releaseToSys => 3,
        _WalkthroughStage.systolicPause => 4,
        _WalkthroughStage.releaseToDia => 5,
        _WalkthroughStage.diastolicPause => 6,
        _WalkthroughStage.finalReading => 7,
        _WalkthroughStage.quickCheck => 8,
      };

  String get _teachingTitle => switch (_stage) {
        _WalkthroughStage.ready => 'Start with the cuff',
        _WalkthroughStage.inflate => 'Inflate above expected systolic',
        _WalkthroughStage.releaseToSys => 'Release slowly and listen',
        _WalkthroughStage.systolicPause => 'First beats = systolic',
        _WalkthroughStage.releaseToDia => 'Keep listening while releasing',
        _WalkthroughStage.diastolicPause => 'Sounds disappear = diastolic',
        _WalkthroughStage.finalReading => 'Document the reading',
        _WalkthroughStage.quickCheck => 'Quick check',
      };

  String get _teachingText => switch (_stage) {
        _WalkthroughStage.ready => 'Place the cuff correctly, find the brachial pulse, and get ready to inflate.',
        _WalkthroughStage.inflate => 'The cuff is pumped above the expected systolic pressure so blood flow is temporarily stopped.',
        _WalkthroughStage.releaseToSys => 'Open the valve slowly. In real practice, release around 2–3 mmHg per second.',
        _WalkthroughStage.systolicPause => 'The first clear Korotkoff beats you hear are the systolic pressure — the top number.',
        _WalkthroughStage.releaseToDia => 'Keep releasing slowly. Beats continue while cuff pressure is between systolic and diastolic.',
        _WalkthroughStage.diastolicPause => 'When the beats disappear, that point is the diastolic pressure — the bottom number.',
        _WalkthroughStage.finalReading => 'This reading is written as systolic over diastolic: 118/76 mmHg.',
        _WalkthroughStage.quickCheck => 'Answer two quick questions, then switch to Practice Mode to try it yourself.',
      };

  bool get _showBeats =>
      _stage == _WalkthroughStage.systolicPause ||
      _stage == _WalkthroughStage.releaseToDia ||
      (_stage == _WalkthroughStage.releaseToSys && _pressure <= _sys && _pressure > _dia);

  bool get _highlightSys => _stage == _WalkthroughStage.systolicPause;
  bool get _highlightDia => _stage == _WalkthroughStage.diastolicPause;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startWalkthrough() {
    _timer?.cancel();
    setState(() {
      _pressure = 0;
      _stage = _WalkthroughStage.inflate;
      _questionIndex = 0;
      _answers[0] = null;
      _answers[1] = null;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    switch (_stage) {
      case _WalkthroughStage.inflate:
        setState(() => _pressure = (_pressure + 2.5).clamp(0.0, _maxInflation));
        if (_pressure >= _maxInflation) {
          setState(() => _stage = _WalkthroughStage.releaseToSys);
        }
        break;
      case _WalkthroughStage.releaseToSys:
        setState(() => _pressure = (_pressure - 0.65).clamp(0.0, _maxInflation));
        if (_pressure <= _sys) {
          _timer?.cancel();
          setState(() {
            _pressure = _sys.toDouble();
            _stage = _WalkthroughStage.systolicPause;
          });
        }
        break;
      case _WalkthroughStage.releaseToDia:
        setState(() => _pressure = (_pressure - 0.65).clamp(0.0, _maxInflation));
        if (_pressure <= _dia) {
          _timer?.cancel();
          setState(() {
            _pressure = _dia.toDouble();
            _stage = _WalkthroughStage.diastolicPause;
          });
        }
        break;
      case _WalkthroughStage.ready:
      case _WalkthroughStage.systolicPause:
      case _WalkthroughStage.diastolicPause:
      case _WalkthroughStage.finalReading:
      case _WalkthroughStage.quickCheck:
        break;
    }
  }

  void _continueFromPause() {
    _timer?.cancel();
    if (_stage == _WalkthroughStage.systolicPause) {
      setState(() => _stage = _WalkthroughStage.releaseToDia);
      _timer = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
    } else if (_stage == _WalkthroughStage.diastolicPause) {
      setState(() => _stage = _WalkthroughStage.finalReading);
    } else if (_stage == _WalkthroughStage.finalReading) {
      setState(() => _stage = _WalkthroughStage.quickCheck);
    }
  }

  void _pauseResume() {
    if (!_isAnimating) return;
    if (_timer?.isActive == true) {
      _timer?.cancel();
      setState(() {});
    } else {
      _timer = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
      setState(() {});
    }
  }

  void _replay() {
    _timer?.cancel();
    setState(() {
      _pressure = 0;
      _stage = _WalkthroughStage.ready;
      _questionIndex = 0;
      _answers[0] = null;
      _answers[1] = null;
    });
  }

  void _selectAnswer(int answerIndex) {
    setState(() => _answers[_questionIndex] = answerIndex);
  }

  void _nextQuestionOrFinish() {
    if (_questionIndex == 0) {
      setState(() => _questionIndex = 1);
    } else {
      context.read<AppState>().setMode(TrainingMode.practice);
      context.go(AppRoutes.bloodPressure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return EMSVitalsScaffold(
      title: 'Blood Pressure Walkthrough',
      subtitle: 'Watch the BP dial move: pump up → release → first beats = systolic → beats disappear = diastolic.',
      onInfoPressed: _showTeachingSheet,
      bodySlivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProgressHeader(step: _stepNumber, title: _teachingTitle),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 360),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    BpGauge(pressure: _pressure),
                                    if (_highlightSys) const _DialHighlight(label: 'SYS 118', alignment: Alignment.topRight),
                                    if (_highlightDia) const _DialHighlight(label: 'DIA 76', alignment: Alignment.bottomRight),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text('Cuff pressure: ${_pressure.round()} mmHg', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 10),
                            _BeatStrip(active: _showBeats, silentLabel: _stage == _WalkthroughStage.diastolicPause ? 'Sounds disappear' : 'No beats heard yet'),
                            const SizedBox(height: 14),
                            _TeachingCallout(stage: _stage, title: _teachingTitle, text: _teachingText),
                            if (_stage == _WalkthroughStage.finalReading) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  border: Border.all(color: cs.primary.withValues(alpha: 0.22)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Final BP Reading', style: context.textStyles.labelLarge?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 6),
                                    Text('118/76 mmHg', style: context.textStyles.headlineMedium?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 6),
                                    Text('Document: BP 118/76 mmHg', style: context.textStyles.bodyMedium?.copyWith(color: cs.onPrimaryContainer, height: 1.35)),
                                  ],
                                ),
                              ),
                            ],
                            if (_stage == _WalkthroughStage.quickCheck) ...[
                              const SizedBox(height: 12),
                              _QuickCheckCard(
                                questionIndex: _questionIndex,
                                selectedAnswer: _answers[_questionIndex],
                                onSelect: _selectAnswer,
                                onContinue: _answers[_questionIndex] == null ? null : _nextQuestionOrFinish,
                              ),
                            ],
                            const SizedBox(height: 16),
                            _ControlRow(
                              stage: _stage,
                              timerActive: _timer?.isActive == true,
                              onStart: _startWalkthrough,
                              onContinue: _continueFromPause,
                              onReplay: _replay,
                              onPauseResume: _pauseResume,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _CommonMistakesCard(),
                    const SizedBox(height: 12),
                    EMSResultBox(
                      title: 'Learn Mode only',
                      message: 'This screen teaches the BP dial step by step. Switch the top mode to Practice or Test to use the regular simulator.',
                      kind: EMSResultKind.info,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTeachingSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 560, maxHeight: MediaQuery.sizeOf(context).height * 0.88),
            child: Material(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('Manual BP teaching points', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                          IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _MiniTeachingPoint(text: 'Pump above the expected systolic pressure.'),
                      const _MiniTeachingPoint(text: 'Release slowly, about 2–3 mmHg/sec in real practice.'),
                      const _MiniTeachingPoint(text: 'First clear beats heard = systolic/top number.'),
                      const _MiniTeachingPoint(text: 'Beats disappear = diastolic/bottom number.'),
                      const _MiniTeachingPoint(text: 'Document as systolic over diastolic, such as BP 118/76 mmHg.'),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(onPressed: () => context.pop(), child: const Text('Got it')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _WalkthroughStage { ready, inflate, releaseToSys, systolicPause, releaseToDia, diastolicPause, finalReading, quickCheck }

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.step, required this.title});
  final int step;
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: AppColors.headerGradient.map((c) => c.withValues(alpha: 0.13)).toList()),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.72), borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text('$step/8', style: context.textStyles.labelLarge?.copyWith(color: AppColors.emsBlue, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: step / 8,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeachingCallout extends StatelessWidget {
  const _TeachingCallout({required this.stage, required this.title, required this.text});
  final _WalkthroughStage stage;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSys = stage == _WalkthroughStage.systolicPause;
    final isDia = stage == _WalkthroughStage.diastolicPause;
    final color = isSys ? Colors.green : (isDia ? AppColors.emsBlue : cs.primary);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isSys ? Icons.hearing : (isDia ? Icons.volume_off : Icons.school), color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(text, style: context.textStyles.bodyMedium?.copyWith(height: 1.42)),
                if (isSys) ...[
                  const SizedBox(height: 8),
                  Text('Systolic = top number', style: context.textStyles.titleMedium?.copyWith(color: Colors.green, fontWeight: FontWeight.w900)),
                ],
                if (isDia) ...[
                  const SizedBox(height: 8),
                  Text('Diastolic = bottom number', style: context.textStyles.titleMedium?.copyWith(color: AppColors.emsBlue, fontWeight: FontWeight.w900)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DialHighlight extends StatelessWidget {
  const _DialHighlight({required this.label, required this.alignment});
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedAlign(
          alignment: alignment,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.gaugeNeedle.withValues(alpha: 0.50), width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Text(label, style: context.textStyles.labelLarge?.copyWith(color: AppColors.gaugeNeedle, fontWeight: FontWeight.w900)),
          ),
        ),
      ),
    );
  }
}

class _BeatStrip extends StatelessWidget {
  const _BeatStrip({required this.active, required this.silentLabel});
  final bool active;
  final String silentLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: active ? Colors.green.withValues(alpha: 0.10) : cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: active ? Colors.green.withValues(alpha: 0.28) : cs.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(active ? Icons.graphic_eq : Icons.volume_off, color: active ? Colors.green : cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              active ? 'Lub… lub… lub…  Beats heard' : silentLabel,
              style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: active ? Colors.green : cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlRow extends StatelessWidget {
  const _ControlRow({required this.stage, required this.timerActive, required this.onStart, required this.onContinue, required this.onReplay, required this.onPauseResume});
  final _WalkthroughStage stage;
  final bool timerActive;
  final VoidCallback onStart;
  final VoidCallback onContinue;
  final VoidCallback onReplay;
  final VoidCallback onPauseResume;

  @override
  Widget build(BuildContext context) {
    final showStart = stage == _WalkthroughStage.ready;
    final showContinue = stage == _WalkthroughStage.systolicPause || stage == _WalkthroughStage.diastolicPause || stage == _WalkthroughStage.finalReading;
    final showPause = stage == _WalkthroughStage.inflate || stage == _WalkthroughStage.releaseToSys || stage == _WalkthroughStage.releaseToDia;

    return Column(
      children: [
        if (showStart)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text('Start Walkthrough', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ),
        if (showPause)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: onPauseResume,
              icon: Icon(timerActive ? Icons.pause : Icons.play_arrow),
              label: Text(timerActive ? 'Pause Walkthrough' : 'Resume Walkthrough'),
            ),
          ),
        if (showContinue)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: onContinue,
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
              label: Text(stage == _WalkthroughStage.finalReading ? 'Quick Check' : 'Continue', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ),
        if (stage != _WalkthroughStage.ready) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: TextButton.icon(
              onPressed: onReplay,
              icon: const Icon(Icons.replay),
              label: const Text('Replay from Beginning'),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickCheckCard extends StatelessWidget {
  const _QuickCheckCard({required this.questionIndex, required this.selectedAnswer, required this.onSelect, required this.onContinue});
  final int questionIndex;
  final int? selectedAnswer;
  final ValueChanged<int> onSelect;
  final VoidCallback? onContinue;

  static const _questions = [
    _QuizQuestion(
      text: 'What does the first beat heard represent?',
      options: ['Systolic pressure', 'Diastolic pressure', 'Pulse pressure'],
      correctIndex: 0,
      explanation: 'Correct: first clear sounds are systolic, the top number.',
    ),
    _QuizQuestion(
      text: 'What does it mean when the beats disappear?',
      options: ['Systolic pressure', 'Diastolic pressure', 'Respiratory rate'],
      correctIndex: 1,
      explanation: 'Correct: when the sounds disappear, that is diastolic, the bottom number.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final q = _questions[questionIndex];
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.16)),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Question ${questionIndex + 1} of 2', style: context.textStyles.labelMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(q.text, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          for (var i = 0; i < q.options.length; i++) ...[
            _AnswerTile(
              text: q.options[i],
              selected: selectedAnswer == i,
              correct: selectedAnswer == null ? null : i == q.correctIndex,
              onTap: () => onSelect(i),
            ),
            if (i != q.options.length - 1) const SizedBox(height: 8),
          ],
          if (selectedAnswer != null) ...[
            const SizedBox(height: 10),
            EMSResultBox(
              title: selectedAnswer == q.correctIndex ? 'Correct' : 'Review this',
              message: q.explanation,
              kind: selectedAnswer == q.correctIndex ? EMSResultKind.success : EMSResultKind.warning,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: onContinue,
                child: Text(questionIndex == 0 ? 'Next Question' : 'Go to Practice Mode'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({required this.text, required this.selected, required this.correct, required this.onTap});
  final String text;
  final bool selected;
  final bool? correct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = correct == true ? Colors.green : (selected ? AppColors.emsBlue : cs.outline);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.10) : cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color.withValues(alpha: 0.42) : cs.outline.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? color : cs.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w800))),
          ],
        ),
      ),
    );
  }
}

class _CommonMistakesCard extends StatelessWidget {
  const _CommonMistakesCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const mistakes = [
      'Releasing the valve too fast.',
      'Calling the wrong number systolic.',
      'Stopping before the sounds disappear.',
      'Rounding every BP to the nearest 10.',
      'Forgetting to reassess abnormal BP.',
    ];
    return EMSSectionCard(
      title: 'Common Student Mistakes',
      subtitle: 'Keep these in mind before moving to Practice Mode.',
      child: Column(
        children: [
          for (final mistake in mistakes) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(child: Text(mistake, style: context.textStyles.bodySmall?.copyWith(height: 1.35))),
              ],
            ),
            if (mistake != mistakes.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _MiniTeachingPoint extends StatelessWidget {
  const _MiniTeachingPoint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: context.textStyles.bodyMedium?.copyWith(height: 1.35))),
        ],
      ),
    );
  }
}

class _QuizQuestion {
  const _QuizQuestion({required this.text, required this.options, required this.correctIndex, required this.explanation});
  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}
