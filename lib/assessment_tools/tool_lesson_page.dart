import 'dart:math';

import 'package:emscode_sim_vitals/app/app_state.dart';
import 'package:emscode_sim_vitals/assessment_tools/assessment_tools_models.dart';
import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ToolLessonPage extends StatefulWidget {
  const ToolLessonPage({super.key, required this.toolId});
  final String toolId;

  @override
  State<ToolLessonPage> createState() => _ToolLessonPageState();
}

class _ToolLessonPageState extends State<ToolLessonPage> {
  // SAMPLE matching
  final Map<String, String?> _sampleAnswers = {'S': null, 'A': null, 'M': null, 'P': null, 'L': null, 'E': null};
  bool? _sampleCorrect;

  // DCAP-BTLS multi-select
  final Set<String> _dcapSel = {};
  bool? _dcapCorrect;

  // Simple single-choice practice
  int? _singleSel;
  bool? _singleCorrect;

  @override
  void initState() {
    super.initState();
    _resetPractice();
  }

  void _resetPractice() {
    for (final k in _sampleAnswers.keys) {
      _sampleAnswers[k] = null;
    }
    _sampleCorrect = null;
    _dcapSel.clear();
    _dcapCorrect = null;
    _singleSel = null;
    _singleCorrect = null;
  }

  @override
  Widget build(BuildContext context) {
    final lesson = AssessmentToolsContent.lessonFor(widget.toolId);
    if (lesson == null) {
      return EMSVitalsScaffold(title: 'Tool not found', subtitle: 'This tool id is not recognized.', bodySlivers: const [SliverToBoxAdapter(child: SizedBox(height: 1))]);
    }

    final mode = context.select<AppState, TrainingMode>((s) => s.mode);
    final instructor = context.select<AppState, bool>((s) => s.instructorMode);

    return EMSVitalsScaffold(
      title: lesson.tool.title,
      subtitle: mode == TrainingMode.learn ? 'Learn mode: hints are ON' : mode == TrainingMode.practice ? 'Practice mode: coached reps' : 'Test mode: self-check at the end',
      onInfoPressed: () {
        EMSInfoSheet.show(
          context,
          title: lesson.tool.title,
          children: [
            Text(lesson.usedFor),
            const SizedBox(height: 12),
            Text('When to use it: ${lesson.whenToUse}'),
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
                    EMSSectionCard(title: 'Used for', child: Text(lesson.usedFor, style: context.textStyles.bodyMedium?.copyWith(height: 1.5))),
                    const SizedBox(height: 12),
                    EMSSectionCard(title: 'When to use it', child: Text(lesson.whenToUse, style: context.textStyles.bodyMedium?.copyWith(height: 1.5))),
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: 'What to ask / check',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final q in lesson.whatToAsk)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.arrow_right, color: Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(width: 8), Expanded(child: Text(q, style: context.textStyles.bodyMedium?.copyWith(height: 1.4)))]),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: 'Abnormal findings may mean',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final p in lesson.abnormalMeans)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.check_circle, size: 18, color: AppColors.emsBlue), const SizedBox(width: 10), Expanded(child: Text(p, style: context.textStyles.bodyMedium?.copyWith(height: 1.45)))]),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _practiceFor(lesson.tool, mode, instructor),
                    const SizedBox(height: 12),
                    if (_launcherRouteFor(lesson.tool) case final String route)
                      EMSSectionCard(
                        title: 'Open simulator',
                        subtitle: 'This tool has an interactive module available.',
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: () => context.push(route),
                            style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                            icon: const Icon(Icons.play_arrow, color: Colors.white),
                            label: const Text('Start module', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => setState(_resetPractice),
                        style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset practice'),
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

  String? _launcherRouteFor(ToolId tool) => switch (tool) {
    ToolId.stroke => AppRoutes.strokeAssessment,
    ToolId.pupils => AppRoutes.pupilAssessment,
    ToolId.ruleOfNines => AppRoutes.ruleOfNines,
    ToolId.breathSounds => AppRoutes.breathSound,
    _ => null,
  };

  Widget _practiceFor(ToolId tool, TrainingMode mode, bool instructor) {
    return switch (tool) {
      ToolId.sample => _SamplePracticeCard(mode: mode, reveal: instructor, answers: _sampleAnswers, correct: _sampleCorrect, onChanged: (k, v) => setState(() => _sampleAnswers[k] = v), onCheck: () {
        final key = const {
          'S': 'Signs/Symptoms',
          'A': 'Allergies',
          'M': 'Medications',
          'P': 'Past medical history',
          'L': 'Last oral intake',
          'E': 'Events leading up',
        };
        final ok = _sampleAnswers.entries.every((e) => e.value == key[e.key]);
        setState(() => _sampleCorrect = ok);
      }),
      ToolId.dcapbtls => _DcapPracticeCard(mode: mode, reveal: instructor, selected: _dcapSel, correct: _dcapCorrect, onToggle: (s) {
        setState(() {
          if (_dcapSel.contains(s)) {
            _dcapSel.remove(s);
          } else {
            _dcapSel.add(s);
          }
          if (mode != TrainingMode.test) {
            // Only compute after check in test; in learn/practice show live guidance.
            _dcapCorrect = null;
          }
        });
      }, onCheck: () {
        const correct = {'Deformities', 'Contusions', 'Abrasions', 'Punctures/Penetrations', 'Burns', 'Tenderness', 'Lacerations', 'Swelling'};
        final ok = _dcapSel.containsAll(correct) && correct.containsAll(_dcapSel);
        setState(() => _dcapCorrect = ok);
      }),
      _ => _SinglePracticeCard(tool: tool, mode: mode, reveal: instructor, sel: _singleSel, correct: _singleCorrect, onSelect: (i, ok) {
        setState(() {
          _singleSel = i;
          if (mode != TrainingMode.test) _singleCorrect = ok;
        });
      }, onCheck: () {
        final ok = _singleOk(tool, _singleSel);
        setState(() => _singleCorrect = ok);
      }),
    };
  }

  bool _singleOk(ToolId tool, int? sel) {
    if (sel == null) return false;
    return switch (tool) {
      ToolId.opqrst => sel == 3, // Severity
      ToolId.avpu => sel == 2, // P
      ToolId.aao => sel == 1, // AAOx2
      ToolId.painScale => sel == 2, // 10/10
      ToolId.generalImpression => sel == 2, // sick finding
      ToolId.primaryAssessment => sel == 0, // Airway
      ToolId.secondaryAssessment => sel == 1, // after life threats
      _ => false,
    };
  }
}

class _SamplePracticeCard extends StatelessWidget {
  const _SamplePracticeCard({required this.mode, required this.reveal, required this.answers, required this.correct, required this.onChanged, required this.onCheck});
  final TrainingMode mode;
  final bool reveal;
  final Map<String, String?> answers;
  final bool? correct;
  final void Function(String letter, String? value) onChanged;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    const options = ['Signs/Symptoms', 'Allergies', 'Medications', 'Past medical history', 'Last oral intake', 'Events leading up'];
    const key = {
      'S': 'Signs/Symptoms',
      'A': 'Allergies',
      'M': 'Medications',
      'P': 'Past medical history',
      'L': 'Last oral intake',
      'E': 'Events leading up',
    };

    final showHint = mode == TrainingMode.learn;
    return EMSSectionCard(
      title: 'Practice: SAMPLE matching',
      subtitle: showHint ? 'Hint: This is a memory tool — don’t overthink it.' : null,
      child: Column(
        children: [
          for (final letter in const ['S', 'A', 'M', 'P', 'L', 'E']) ...[
            DropdownButtonFormField<String>(
              value: answers[letter],
              decoration: InputDecoration(labelText: '$letter —'),
              items: [for (final o in options) DropdownMenuItem(value: o, child: Text(o))],
              onChanged: (v) => onChanged(letter, v),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: onCheck,
              style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('Check', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ),
          if (reveal) ...[
            const SizedBox(height: 10),
            EMSResultBox(title: 'Instructor key', message: 'S: ${key['S']} • A: ${key['A']} • M: ${key['M']} • P: ${key['P']} • L: ${key['L']} • E: ${key['E']}', kind: EMSResultKind.info),
          ] else if (correct != null) ...[
            const SizedBox(height: 10),
            EMSResultBox(
              title: correct == true ? 'Correct' : 'Needs work',
              message: correct == true ? 'Nice. Now practice asking these quickly in your own words.' : 'Quick fix: memorize the letters first, then practice the questions.',
              kind: correct == true ? EMSResultKind.success : EMSResultKind.warning,
            ),
          ],
        ],
      ),
    );
  }
}

class _DcapPracticeCard extends StatelessWidget {
  const _DcapPracticeCard({required this.mode, required this.reveal, required this.selected, required this.correct, required this.onToggle, required this.onCheck});
  final TrainingMode mode;
  final bool reveal;
  final Set<String> selected;
  final bool? correct;
  final ValueChanged<String> onToggle;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    const dcap = ['Deformities', 'Contusions', 'Abrasions', 'Punctures/Penetrations', 'Burns', 'Tenderness', 'Lacerations', 'Swelling'];
    const distractors = ['Blood pressure', 'Allergies', 'Temperature', 'Medications'];
    final options = [...dcap, ...distractors];
    final showHint = mode == TrainingMode.learn;

    return EMSSectionCard(
      title: 'Practice: DCAP-BTLS selection',
      subtitle: showHint ? 'Hint: it’s all trauma findings — not vitals/history.' : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final o in options)
                FilterChip(
                  label: Text(o),
                  selected: selected.contains(o),
                  onSelected: (_) => onToggle(o),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: onCheck,
              style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('Check', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ),
          if (reveal) ...[
            const SizedBox(height: 10),
            const EMSResultBox(title: 'Instructor key', message: 'DCAP-BTLS = Deformities, Contusions, Abrasions, Punctures/Penetrations, Burns, Tenderness, Lacerations, Swelling.', kind: EMSResultKind.info),
          ] else if (correct != null) ...[
            const SizedBox(height: 10),
            EMSResultBox(
              title: correct == true ? 'Correct' : 'Needs work',
              message: correct == true ? 'Good — that’s a complete trauma scan checklist.' : 'Re-check the letters: DCAP = findings; BTLS = more findings. Ignore vitals/history.',
              kind: correct == true ? EMSResultKind.success : EMSResultKind.warning,
            ),
          ],
        ],
      ),
    );
  }
}

class _SinglePracticeCard extends StatelessWidget {
  const _SinglePracticeCard({required this.tool, required this.mode, required this.reveal, required this.sel, required this.correct, required this.onSelect, required this.onCheck});
  final ToolId tool;
  final TrainingMode mode;
  final bool reveal;
  final int? sel;
  final bool? correct;
  final void Function(int index, bool ok) onSelect;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final (prompt, choices, correctIndex, hint, instructorKey) = _prompt(tool);
    final showFeedback = mode != TrainingMode.test && sel != null;
    final ok = sel == correctIndex;

    return EMSSectionCard(
      title: 'Practice',
      subtitle: mode == TrainingMode.learn ? hint : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(prompt, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.4)),
          const SizedBox(height: 10),
          for (int i = 0; i < choices.length; i++)
            RadioListTile<int>(
              value: i,
              groupValue: sel,
              onChanged: (v) {
                if (v == null) return;
                onSelect(v, v == correctIndex);
              },
              title: Text(choices[i]),
              contentPadding: EdgeInsets.zero,
            ),
          if (mode == TrainingMode.test) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: sel == null ? null : onCheck,
                style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text('Check', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
          if (reveal) ...[
            const SizedBox(height: 10),
            EMSResultBox(title: 'Instructor key', message: instructorKey, kind: EMSResultKind.info),
          ] else if (showFeedback || correct != null) ...[
            const SizedBox(height: 10),
            EMSResultBox(
              title: ok ? 'Correct' : 'Needs work',
              message: ok ? 'Good. Keep the sequence in your head — it prevents missed steps.' : 'Try again — pick the best field answer, not a textbook paragraph.',
              kind: ok ? EMSResultKind.success : EMSResultKind.warning,
            ),
          ],
        ],
      ),
    );
  }

  (String, List<String>, int, String, String) _prompt(ToolId tool) => switch (tool) {
    ToolId.opqrst => ('Which OPQRST letter asks about “severity 0–10”?', const ['O', 'P', 'Q', 'S', 'T'], 3, 'Hint: it’s literally “Severity”.', 'Correct: S (Severity)'),
    ToolId.avpu => ('Patient opens eyes only to painful stimulus. AVPU is:', const ['A', 'V', 'P', 'U'], 2, 'Hint: If voice doesn’t work but pain does, it’s “P”.', 'Correct: P'),
    ToolId.aao => ('Patient knows person + place only. This is:', const ['AAOx4', 'AAOx2', 'AAOx1', 'AAOx3'], 1, 'Hint: Count the things they are oriented to.', 'Correct: AAOx2'),
    ToolId.painScale => ('“Worst pain imaginable” is best scored as:', const ['3/10', '6/10', '10/10'], 2, 'Hint: 10 = worst pain imaginable.', 'Correct: 10/10'),
    ToolId.generalImpression => ('Which finding is most “sick” on first glance?', const ['Sitting comfortably, speaking full sentences', 'Warm, pink, dry skin', 'Tripoding, one-word answers, diaphoretic'], 2, 'Hint: Look at work of breathing + distress.', 'Correct: Tripoding, one-word answers, diaphoretic'),
    ToolId.primaryAssessment => ('In primary assessment, what comes first?', const ['Airway', 'History', 'Detailed head-to-toe'], 0, 'Hint: ABC — treat life threats first.', 'Correct: Airway'),
    ToolId.secondaryAssessment => ('Secondary assessment happens:', const ['Before primary assessment', 'After immediate life threats are managed', 'Only at the hospital'], 1, 'Hint: Secondary = detailed, after urgent threats.', 'Correct: After immediate life threats are managed'),
    _ => ('Quick check', const ['Option A', 'Option B', 'Option C'], 0, 'Hint', 'Correct: Option A'),
  };
}
