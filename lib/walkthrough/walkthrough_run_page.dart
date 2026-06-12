import 'package:emscode_sim_vitals/app/app_state.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/shared/visual_training_widgets.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:emscode_sim_vitals/walkthrough/walkthrough_models.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WalkthroughRunPage extends StatefulWidget {
  const WalkthroughRunPage({super.key, required this.caseId, required this.modeOverride});
  final String caseId;
  final String? modeOverride;

  @override
  State<WalkthroughRunPage> createState() => _WalkthroughRunPageState();
}

class _WalkthroughRunPageState extends State<WalkthroughRunPage> {
  late final AssessmentCase _case;
  late WalkthroughMode _mode;
  int _index = 0;
  final Map<String, dynamic> _answersByStepId = {};
  final Map<String, bool> _correctByStepId = {};
  final Set<String> _instructorPass = {};
  final Set<String> _instructorNeedsWork = {};
  final TextEditingController _instructorNotes = TextEditingController();

  bool _showFeedback = false;
  bool _revealKey = false;

  @override
  void initState() {
    super.initState();
    final found = WalkthroughCases.byId(widget.caseId);
    _case = found ?? WalkthroughCases.all.first;

    _mode = _parseMode(widget.modeOverride) ?? _fromGlobal(context.read<AppState>().mode);
  }

  WalkthroughMode _fromGlobal(TrainingMode m) => switch (m) {
    TrainingMode.learn => WalkthroughMode.learn,
    TrainingMode.practice => WalkthroughMode.practice,
    TrainingMode.test => WalkthroughMode.test,
  };

  WalkthroughMode? _parseMode(String? s) {
    if (s == null) return null;
    return WalkthroughMode.values.cast<WalkthroughMode?>().firstWhere((m) => m?.name == s, orElse: () => null);
  }

  IconData _iconForCategory(AssessmentCategory category) => switch (category) {
    AssessmentCategory.sceneSizeUp => Icons.shield_rounded,
    AssessmentCategory.generalImpression => Icons.visibility_rounded,
    AssessmentCategory.mentalStatus => Icons.psychology_rounded,
    AssessmentCategory.primaryAssessment => Icons.rule_rounded,
    AssessmentCategory.vitalSigns => Icons.monitor_heart_rounded,
    AssessmentCategory.history => Icons.history_edu_rounded,
    AssessmentCategory.focusedAssessment => Icons.search_rounded,
    AssessmentCategory.treatment => Icons.medical_services_rounded,
    AssessmentCategory.reassessment => Icons.repeat_rounded,
    AssessmentCategory.handoffReport => Icons.record_voice_over_rounded,
  };

  Color _accentForCategory(AssessmentCategory category) => switch (category) {
    AssessmentCategory.sceneSizeUp => const Color(0xFF22C55E),
    AssessmentCategory.generalImpression => const Color(0xFF14B8A6),
    AssessmentCategory.mentalStatus => const Color(0xFF7C3AED),
    AssessmentCategory.primaryAssessment => AppColors.emsBlue,
    AssessmentCategory.vitalSigns => AppColors.danger,
    AssessmentCategory.history => const Color(0xFFF97316),
    AssessmentCategory.focusedAssessment => const Color(0xFF0EA5E9),
    AssessmentCategory.treatment => const Color(0xFF16A34A),
    AssessmentCategory.reassessment => const Color(0xFF0891B2),
    AssessmentCategory.handoffReport => const Color(0xFF64748B),
  };

  @override
  void dispose() {
    _instructorNotes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final instructor = context.select<AppState, bool>((s) => s.instructorMode);

    if (_case.locked) {
      return EMSVitalsScaffold(
        title: 'Locked case',
        subtitle: 'This case is a placeholder for a future pack.',
        bodySlivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: EMSResultBox(title: 'Coming Soon', message: '“${_case.packTitle ?? 'Advanced pack'}” is not available yet.', kind: EMSResultKind.info),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_index >= _case.steps.length) {
      final score = _computeScore();
      return _WalkthroughSummaryView(
        c: _case,
        mode: _mode,
        score: score,
        instructor: instructor,
        notesController: _instructorNotes,
        onToggleReveal: instructor ? () => setState(() => _revealKey = !_revealKey) : null,
        revealKey: _revealKey,
        instructorPass: _instructorPass,
        instructorNeedsWork: _instructorNeedsWork,
      );
    }

    final step = _case.steps[_index];
    final progressText = 'Step ${_index + 1} of ${_case.steps.length}';
    final hasAnswered = _answersByStepId.containsKey(step.id);

    return EMSVitalsScaffold(
      title: 'Walkthrough',
      subtitle: '${_case.title} • $progressText • Mode: ${_mode.label}',
      onInfoPressed: () {
        EMSInfoSheet.show(
          context,
          title: _case.title,
          children: [
            Text('${_case.age}y/o ${_case.sex} • CC: ${_case.chiefComplaint}'),
            const SizedBox(height: 12),
            Text(_case.presentation),
          ],
        );
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
                    _AnimatedWalkthroughProgress(
                      current: _index + 1,
                      total: _case.steps.length,
                      category: step.category.label,
                      accent: _accentForCategory(step.category),
                    ),
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: step.title,
                      subtitle: step.critical ? 'Critical step' : null,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(999), border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.14))),
                        child: Text(step.category.label, style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w900)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EMSVideoPromptCard(
                            title: 'Scene prompt',
                            prompt: step.prompt,
                            icon: _iconForCategory(step.category),
                            accent: _accentForCategory(step.category),
                            caption: step.critical ? 'Critical decision' : 'Tap the best answer',
                          ),
                          const SizedBox(height: 12),
                          if (_mode == WalkthroughMode.learn && step.learnHint != null)
                            EMSResultBox(title: 'Hint', message: step.learnHint!, kind: EMSResultKind.info),
                          if (_mode == WalkthroughMode.learn && step.learnHint != null) const SizedBox(height: 12),
                          _StepAnswerWidget(
                            step: step,
                            value: _answersByStepId[step.id],
                            onChanged: (v) {
                              setState(() {
                                _answersByStepId[step.id] = v;
                                _showFeedback = false;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: OutlinedButton.icon(
                                    onPressed: _index == 0
                                        ? null
                                        : () {
                                            setState(() {
                                              _index = (_index - 1).clamp(0, _case.steps.length);
                                              _showFeedback = false;
                                            });
                                          },
                                    style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                                    icon: const Icon(Icons.chevron_left),
                                    label: const Text('Back'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: FilledButton.icon(
                                    onPressed: hasAnswered
                                        ? () {
                                            _gradeStep(step);
                                            setState(() {
                                              if (_mode == WalkthroughMode.test) {
                                                _index++;
                                                _showFeedback = false;
                                              } else {
                                                _showFeedback = true;
                                              }
                                            });
                                          }
                                        : null,
                                    style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                                    icon: Icon(_mode == WalkthroughMode.test ? Icons.chevron_right : Icons.check, color: Colors.white),
                                    label: Text(_mode == WalkthroughMode.test ? 'Next' : 'Check', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (_mode != WalkthroughMode.test && _showFeedback) ...[
                            const SizedBox(height: 12),
                            _FeedbackBox(step: step, ok: _correctByStepId[step.id] == true),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: FilledButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _index++;
                                    _showFeedback = false;
                                  });
                                },
                                style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                                icon: const Icon(Icons.chevron_right, color: Colors.white),
                                label: const Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ],

                          if (instructor) ...[
                            const SizedBox(height: 12),
                            EMSSectionCard(
                              title: 'Instructor controls',
                              subtitle: 'Reveal key, mark Pass/Needs Work for skills-lab style coaching.',
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 48,
                                          child: OutlinedButton.icon(
                                            onPressed: () => setState(() => _revealKey = !_revealKey),
                                            style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                                            icon: Icon(_revealKey ? Icons.visibility_off : Icons.visibility),
                                            label: Text(_revealKey ? 'Hide key' : 'Reveal key'),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: SizedBox(
                                          height: 48,
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _instructorPass.add(step.id);
                                                _instructorNeedsWork.remove(step.id);
                                              });
                                            },
                                            style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                                            icon: const Icon(Icons.check_circle_outline),
                                            label: const Text('Mark Pass'),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _instructorNeedsWork.add(step.id);
                                          _instructorPass.remove(step.id);
                                        });
                                      },
                                      style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                                      icon: const Icon(Icons.warning_amber_rounded),
                                      label: const Text('Mark Needs Work'),
                                    ),
                                  ),
                                  if (_revealKey) ...[
                                    const SizedBox(height: 10),
                                    EMSResultBox(title: 'Key', message: _keyText(step), kind: EMSResultKind.info),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
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

  void _gradeStep(WalkthroughStep step) {
    final ans = _answersByStepId[step.id];
    final ok = _isCorrect(step, ans);
    _correctByStepId[step.id] = ok;
  }

  bool _isCorrect(WalkthroughStep step, dynamic ans) {
    switch (step.kind) {
      case StepKind.multiChoice:
        if (ans is! int) return false;
        return step.correctChoiceIndexes.length == 1 && ans == step.correctChoiceIndexes.first;
      case StepKind.multiSelect:
        if (ans is! Set<int>) return false;
        final correct = step.correctChoiceIndexes.toSet();
        return ans.containsAll(correct) && correct.containsAll(ans);
      case StepKind.number:
        if (ans is! int) return false;
        final target = step.numberTarget ?? 0;
        final tol = step.numberTolerance ?? 0;
        return (target - ans).abs() <= tol;
    }
  }

  String _keyText(WalkthroughStep step) {
    return switch (step.kind) {
      StepKind.number => 'Target: ${step.numberTarget} (±${step.numberTolerance ?? 0})',
      StepKind.multiChoice => 'Correct: ${step.choices[step.correctChoiceIndexes.first]}',
      StepKind.multiSelect => 'Correct: ${step.correctChoiceIndexes.map((i) => step.choices[i]).join(', ')}',
    };
  }

  WalkthroughScore _computeScore() {
    final byCatTotal = <AssessmentCategory, int>{};
    final byCatCorrect = <AssessmentCategory, int>{};
    final missedCritical = <String>[];

    int total = 0;
    int correct = 0;
    for (final s in _case.steps) {
      total++;
      byCatTotal[s.category] = (byCatTotal[s.category] ?? 0) + 1;
      final ok = _correctByStepId[s.id] == true;
      if (ok) {
        correct++;
        byCatCorrect[s.category] = (byCatCorrect[s.category] ?? 0) + 1;
      } else {
        byCatCorrect[s.category] = (byCatCorrect[s.category] ?? 0);
        if (s.critical) missedCritical.add(s.id);
      }
    }
    return WalkthroughScore(total: total, correct: correct, byCategoryCorrect: byCatCorrect, byCategoryTotal: byCatTotal, missedCriticalStepIds: missedCritical);
  }
}


class _AnimatedWalkthroughProgress extends StatelessWidget {
  const _AnimatedWalkthroughProgress({required this.current, required this.total, required this.category, required this.accent});

  final int current;
  final int total;
  final String category;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = total == 0 ? 0.0 : current / total;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.movie_filter_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Walkthrough clip $current of $total', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(category, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Text('${(progress * 100).round()}%', style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w900, color: accent)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0).toDouble()),
              duration: const Duration(milliseconds: 420),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 9,
                backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepAnswerWidget extends StatelessWidget {
  const _StepAnswerWidget({required this.step, required this.value, required this.onChanged});
  final WalkthroughStep step;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    return switch (step.kind) {
      StepKind.multiChoice => Column(
        children: [
          for (int i = 0; i < step.choices.length; i++)
            RadioListTile<int>(
              value: i,
              groupValue: value is int ? value as int : null,
              onChanged: (v) {
                if (v == null) return;
                onChanged(v);
              },
              title: Text(step.choices[i], style: context.textStyles.bodyMedium?.copyWith(height: 1.35)),
              contentPadding: EdgeInsets.zero,
            ),
        ],
      ),
      StepKind.multiSelect => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (int i = 0; i < step.choices.length; i++)
            FilterChip(
              label: Text(step.choices[i]),
              selected: (value is Set<int>) ? (value as Set<int>).contains(i) : false,
              onSelected: (_) {
                final current = (value is Set<int>) ? (value as Set<int>) : <int>{};
                final next = {...current};
                if (next.contains(i)) {
                  next.remove(i);
                } else {
                  next.add(i);
                }
                onChanged(next);
              },
            ),
        ],
      ),
      StepKind.number => _NumberAnswer(step: step, value: value is int ? value as int : null, onChanged: (v) => onChanged(v)),
    };
  }
}

class _NumberAnswer extends StatefulWidget {
  const _NumberAnswer({required this.step, required this.value, required this.onChanged});
  final WalkthroughStep step;
  final int? value;
  final ValueChanged<int> onChanged;

  @override
  State<_NumberAnswer> createState() => _NumberAnswerState();
}

class _NumberAnswerState extends State<_NumberAnswer> {
  late double _v;

  @override
  void initState() {
    super.initState();
    _v = (widget.value ?? (widget.step.numberTarget ?? 10)).toDouble();
  }

  @override
  void didUpdateWidget(covariant _NumberAnswer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != null) {
      _v = widget.value!.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final min = 0.0;
    final max = 200.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Value: ${_v.round()}', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
        Slider(
          value: _v.clamp(min, max),
          min: min,
          max: max,
          divisions: 200,
          onChanged: (v) {
            setState(() => _v = v);
            widget.onChanged(v.round());
          },
        ),
      ],
    );
  }
}

class _FeedbackBox extends StatelessWidget {
  const _FeedbackBox({required this.step, required this.ok});
  final WalkthroughStep step;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final title = ok ? 'Correct' : (step.critical ? 'Missed Critical Step' : 'Needs work');
    final message = ok
        ? 'Good. Keep moving in order.'
        : (step.whyItMatters ?? 'This step helps you avoid missing life threats and improves your handoff report.');
    final kind = ok
        ? EMSResultKind.success
        : (step.critical ? EMSResultKind.error : EMSResultKind.warning);
    return EMSResultBox(title: title, message: message, kind: kind);
  }
}

class _WalkthroughSummaryView extends StatelessWidget {
  const _WalkthroughSummaryView({required this.c, required this.mode, required this.score, required this.instructor, required this.notesController, required this.onToggleReveal, required this.revealKey, required this.instructorPass, required this.instructorNeedsWork});
  final AssessmentCase c;
  final WalkthroughMode mode;
  final WalkthroughScore score;
  final bool instructor;
  final TextEditingController notesController;
  final VoidCallback? onToggleReveal;
  final bool revealKey;
  final Set<String> instructorPass;
  final Set<String> instructorNeedsWork;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pass = score.missedCriticalStepIds.isEmpty && score.percent >= 80;

    final studyAreas = <String>[];
    for (final cat in AssessmentCategory.values) {
      final total = score.byCategoryTotal[cat] ?? 0;
      if (total == 0) continue;
      final corr = score.byCategoryCorrect[cat] ?? 0;
      final pct = ((corr / total) * 100).round();
      if (pct < 80) studyAreas.add(cat.label);
    }

    return EMSVitalsScaffold(
      title: 'Walkthrough Summary',
      subtitle: '${c.title} • Mode: ${mode.label}',
      onInfoPressed: null,
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
                      title: 'Result',
                      subtitle: '${score.correct}/${score.total} correct',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: AppColors.headerGradient.map((c) => c.withValues(alpha: 0.12)).toList()),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
                                ),
                                child: Text('${score.percent}%', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: EMSResultBox(
                                  title: pass ? 'Pass' : (score.missedCriticalStepIds.isNotEmpty ? 'Missed Critical Step' : 'Needs Work'),
                                  message: pass ? 'Nice work. Now repeat in Practice/Test to build speed.' : 'Review the study areas and try again.',
                                  kind: pass ? EMSResultKind.success : (score.missedCriticalStepIds.isNotEmpty ? EMSResultKind.error : EMSResultKind.warning),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: score.total == 0 ? 0 : score.correct / score.total,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(999),
                            backgroundColor: cs.outline.withValues(alpha: 0.16),
                            color: AppColors.emsBlue,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: 'Suggested study areas',
                      child: studyAreas.isEmpty
                          ? Text('No weak areas detected. Keep practicing for speed and consistency.', style: context.textStyles.bodyMedium?.copyWith(height: 1.5))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final s in studyAreas)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(children: [Icon(Icons.menu_book, size: 18, color: AppColors.emsBlue), const SizedBox(width: 10), Expanded(child: Text(s, style: context.textStyles.bodyMedium?.copyWith(height: 1.45)))]),
                                  ),
                              ],
                            ),
                    ),
                    if (score.missedCriticalStepIds.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      EMSSectionCard(
                        title: 'Missed critical steps',
                        subtitle: 'These are “don’t miss” items in real calls.',
                        child: Text('Critical steps missed: ${score.missedCriticalStepIds.length}', style: context.textStyles.bodyMedium?.copyWith(height: 1.5)),
                      ),
                    ],
                    if (instructor) ...[
                      const SizedBox(height: 12),
                      EMSSectionCard(
                        title: 'Instructor Mode',
                        subtitle: 'Use this as a skills lab checklist.',
                        trailing: onToggleReveal == null
                            ? null
                            : TextButton.icon(
                                onPressed: onToggleReveal,
                                style: const ButtonStyle(splashFactory: NoSplash.splashFactory),
                                icon: Icon(revealKey ? Icons.visibility_off : Icons.visibility),
                                label: Text(revealKey ? 'Hide key' : 'Reveal key'),
                              ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: notesController,
                              minLines: 2,
                              maxLines: 6,
                              decoration: const InputDecoration(labelText: 'Instructor notes'),
                            ),
                            const SizedBox(height: 10),
                            Text('Marked Pass: ${instructorPass.length} • Needs Work: ${instructorNeedsWork.length}', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                            if (revealKey) ...[
                              const SizedBox(height: 10),
                              EMSResultBox(title: 'Key (summary)', message: 'Use the Reveal Key per-step during a run for the full answer key.', kind: EMSResultKind.info),
                            ],
                          ],
                        ),
                      ),
                    ],
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
