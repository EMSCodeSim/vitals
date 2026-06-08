import 'dart:math';

import 'package:emscode_sim_vitals/app/app_state.dart';
import 'package:emscode_sim_vitals/learn_vitals/learn_vitals_models.dart';
import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class VitalLessonPage extends StatefulWidget {
  const VitalLessonPage({super.key, required this.vitalId});
  final String vitalId;

  @override
  State<VitalLessonPage> createState() => _VitalLessonPageState();
}

class _VitalLessonPageState extends State<VitalLessonPage> {
  final _rng = Random();

  int? _selectedQuizIndex;
  bool? _quizCorrect;

  // Respiratory rate practice
  int? _hiddenRr;
  int _rrGuess = 16;
  bool? _rrCorrect;

  // AVPU / AAOx mini practice
  String? _avpuAnswer;
  String? _aaoAnswer;

  @override
  void initState() {
    super.initState();
    _resetPractice();
  }

  void _resetPractice() {
    _selectedQuizIndex = null;
    _quizCorrect = null;
    _hiddenRr = 10 + _rng.nextInt(23); // 10-32
    _rrGuess = 16;
    _rrCorrect = null;
    _avpuAnswer = null;
    _aaoAnswer = null;
  }

  @override
  Widget build(BuildContext context) {
    final lesson = LearnVitalsContent.lessonFor(widget.vitalId);
    if (lesson == null) {
      return EMSVitalsScaffold(
        title: 'Vital not found',
        subtitle: 'This lesson id is not recognized.',
        bodySlivers: const [SliverToBoxAdapter(child: SizedBox(height: 1))],
      );
    }

    final mode = context.select<AppState, TrainingMode>((s) => s.mode);
    final instructor = context.select<AppState, bool>((s) => s.instructorMode);

    return EMSVitalsScaffold(
      title: lesson.vital.title,
      subtitle: mode == TrainingMode.learn ? 'Learn mode: hints are ON' : mode == TrainingMode.practice ? 'Practice mode: coached reps' : 'Test mode: self-check at the end',
      onInfoPressed: () {
        EMSInfoSheet.show(
          context,
          title: lesson.vital.title,
          children: [
            Text(lesson.whatItMeans),
            const SizedBox(height: 12),
            Text('Normal adult range: ${lesson.normalRange}'),
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
                    EMSSectionCard(title: 'What it means', child: Text(lesson.whatItMeans, style: context.textStyles.bodyMedium?.copyWith(height: 1.5))),
                    const SizedBox(height: 12),
                    EMSSectionCard(title: 'Normal adult range', child: Text(lesson.normalRange, style: context.textStyles.bodyMedium?.copyWith(height: 1.5))),
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: 'Abnormal may suggest',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final p in lesson.abnormalMaySuggest)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.check_circle, size: 18, color: AppColors.emsBlue), const SizedBox(width: 10), Expanded(child: Text(p, style: context.textStyles.bodyMedium?.copyWith(height: 1.45)))]),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    EMSSectionCard(title: 'What to document', child: Text(lesson.whatToDocument, style: context.textStyles.bodyMedium?.copyWith(height: 1.5))),
                    const SizedBox(height: 12),
                    EMSSectionCard(title: 'Common student mistake', child: Text(lesson.commonStudentMistake, style: context.textStyles.bodyMedium?.copyWith(height: 1.5))),
                    const SizedBox(height: 12),
                    _QuickQuizCard(
                      prompt: lesson.quickQuizPrompt,
                      choices: lesson.quickQuizChoices,
                      selectedIndex: _selectedQuizIndex,
                      showFeedback: _quizCorrect != null,
                      isCorrect: _quizCorrect == true,
                      onSelect: (i) {
                        if (mode == TrainingMode.test && _quizCorrect != null) return;
                        setState(() {
                          _selectedQuizIndex = i;
                          if (mode != TrainingMode.test) {
                            _quizCorrect = i == lesson.quickQuizCorrectIndex;
                          } else {
                            _quizCorrect = null;
                          }
                        });
                      },
                      onCheck: mode == TrainingMode.test
                          ? () {
                              final sel = _selectedQuizIndex;
                              if (sel == null) return;
                              setState(() => _quizCorrect = sel == lesson.quickQuizCorrectIndex);
                            }
                          : null,
                      reveal: instructor,
                      correctIndex: lesson.quickQuizCorrectIndex,
                    ),
                    const SizedBox(height: 12),

                    _practiceWidgetFor(lesson.vital, mode, instructor),

                    const SizedBox(height: 12),
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

  Widget _practiceWidgetFor(VitalId vital, TrainingMode mode, bool instructor) {
    return switch (vital) {
      VitalId.bloodPressure => EMSSectionCard(
        title: 'Practice mode',
        subtitle: 'Use the BP simulator to practice pumping/deflating + estimating systolic/diastolic.',
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: () => context.push(AppRoutes.bloodPressure),
            style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: const Text('Open BP Simulator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
      VitalId.pulseRate => EMSSectionCard(
        title: 'Practice mode',
        subtitle: 'Estimate rate from rhythm, like counting a radial pulse.',
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: () => context.push(AppRoutes.pulseTest),
            style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: const Text('Open Pulse Test', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
      VitalId.pupils => EMSSectionCard(
        title: 'Practice mode',
        subtitle: 'Document size + reactivity + patient-left vs patient-right.',
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: () => context.push(AppRoutes.pupilAssessment),
            style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: const Text('Open Pupil Assessment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
      VitalId.respiratoryRate => _RespRatePracticeCard(
        hiddenRr: _hiddenRr ?? 16,
        guess: _rrGuess,
        showHint: mode == TrainingMode.learn,
        showReveal: instructor,
        onGuessChanged: (v) => setState(() => _rrGuess = v),
        onCheck: () {
          final hidden = _hiddenRr ?? 16;
          setState(() => _rrCorrect = (hidden - _rrGuess).abs() <= 2);
        },
        result: _rrCorrect,
      ),
      VitalId.spo2 => _SpO2PracticeCard(mode: mode, reveal: instructor),
      VitalId.skinSigns => _SkinSignsPracticeCard(mode: mode, reveal: instructor),
      VitalId.avpu => _AvpuPracticeCard(
        mode: mode,
        reveal: instructor,
        selected: _avpuAnswer,
        onChanged: (v) => setState(() => _avpuAnswer = v),
      ),
      VitalId.aao => _AaoPracticeCard(
        mode: mode,
        reveal: instructor,
        selected: _aaoAnswer,
        onChanged: (v) => setState(() => _aaoAnswer = v),
      ),
    };
  }
}

class _QuickQuizCard extends StatelessWidget {
  const _QuickQuizCard({required this.prompt, required this.choices, required this.selectedIndex, required this.showFeedback, required this.isCorrect, required this.onSelect, required this.onCheck, required this.reveal, required this.correctIndex});

  final String prompt;
  final List<String> choices;
  final int? selectedIndex;
  final bool showFeedback;
  final bool isCorrect;
  final ValueChanged<int> onSelect;
  final VoidCallback? onCheck;
  final bool reveal;
  final int correctIndex;

  @override
  Widget build(BuildContext context) {
    return EMSSectionCard(
      title: 'Quick check',
      subtitle: 'Pick the best answer. Keep it practical.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(prompt, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.4)),
          const SizedBox(height: 10),
          for (int i = 0; i < choices.length; i++) ...[
            RadioListTile<int>(
              value: i,
              groupValue: selectedIndex,
              onChanged: (v) {
                if (v == null) return;
                onSelect(v);
              },
              title: Text(choices[i], style: context.textStyles.bodyMedium?.copyWith(height: 1.35)),
              contentPadding: EdgeInsets.zero,
            ),
          ],
          if (onCheck != null) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: selectedIndex == null ? null : onCheck,
                style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text('Check answer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
          if (reveal) ...[
            const SizedBox(height: 10),
            EMSResultBox(title: 'Instructor key', message: 'Correct answer: ${choices[correctIndex]}', kind: EMSResultKind.info),
          ] else if (showFeedback) ...[
            const SizedBox(height: 10),
            EMSResultBox(
              title: isCorrect ? 'Correct' : 'Needs work',
              message: isCorrect ? 'Good call. Keep correlating vitals with skin signs + mentation.' : 'Re-check what this finding means clinically. Look for perfusion clues.',
              kind: isCorrect ? EMSResultKind.success : EMSResultKind.warning,
            ),
          ],
        ],
      ),
    );
  }
}

class _RespRatePracticeCard extends StatelessWidget {
  const _RespRatePracticeCard({required this.hiddenRr, required this.guess, required this.showHint, required this.showReveal, required this.onGuessChanged, required this.onCheck, required this.result});
  final int hiddenRr;
  final int guess;
  final bool showHint;
  final bool showReveal;
  final ValueChanged<int> onGuessChanged;
  final VoidCallback onCheck;
  final bool? result;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final prompt = 'A patient is breathing with a steady pattern. Estimate the respiratory rate.';

    return EMSSectionCard(
      title: 'Practice: Respiratory rate',
      subtitle: showHint ? 'Hint: adult normal is about 12–20/min. You’re aiming within ±2.' : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(prompt, style: context.textStyles.bodyMedium?.copyWith(height: 1.45)),
          const SizedBox(height: 12),
          Center(child: _BreathMetronome(bpm: hiddenRr)),
          const SizedBox(height: 12),
          Text('Your estimate: $guess /min', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
          Slider(value: guess.toDouble(), min: 6, max: 36, divisions: 30, onChanged: (v) => onGuessChanged(v.round())),
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
          if (showReveal) ...[
            const SizedBox(height: 10),
            EMSResultBox(title: 'Instructor key', message: 'Hidden rate: $hiddenRr /min', kind: EMSResultKind.info),
          ] else if (result != null) ...[
            const SizedBox(height: 10),
            EMSResultBox(
              title: result == true ? 'Correct' : 'Needs work',
              message: result == true ? 'Nice. In real patients, also look at work of breathing + ability to speak.' : 'Try counting for 15 seconds and multiplying by 4. Also watch for irregular breathing.',
              kind: result == true ? EMSResultKind.success : EMSResultKind.warning,
            ),
          ],
          const SizedBox(height: 6),
          Text('Note: This is a training metronome — real patients can be irregular.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _BreathMetronome extends StatefulWidget {
  const _BreathMetronome({required this.bpm});
  final int bpm;

  @override
  State<_BreathMetronome> createState() => _BreathMetronomeState();
}

class _BreathMetronomeState extends State<_BreathMetronome> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: Duration(milliseconds: (60000 / widget.bpm).round()))..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _BreathMetronome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bpm != widget.bpm) {
      _c.duration = Duration(milliseconds: (60000 / widget.bpm).round());
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        final scale = 0.88 + 0.18 * t;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppColors.headerGradient.map((c) => c.withValues(alpha: 0.12)).toList()),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
            ),
            child: const Icon(Icons.air, size: 38, color: AppColors.emsBlue),
          ),
        );
      },
    );
  }
}

class _SpO2PracticeCard extends StatefulWidget {
  const _SpO2PracticeCard({required this.mode, required this.reveal});
  final TrainingMode mode;
  final bool reveal;

  @override
  State<_SpO2PracticeCard> createState() => _SpO2PracticeCardState();
}

class _SpO2PracticeCardState extends State<_SpO2PracticeCard> {
  final _rng = Random();
  late int _spo2;
  int? _sel;
  bool? _correct;

  @override
  void initState() {
    super.initState();
    _newCase();
  }

  void _newCase() {
    final options = [98, 95, 92, 88, 84];
    _spo2 = options[_rng.nextInt(options.length)];
    _sel = null;
    _correct = null;
  }

  @override
  Widget build(BuildContext context) {
    final choices = const ['Normal', 'Mildly low — evaluate', 'Urgent hypoxemia'];
    int correctIndex;
    if (_spo2 >= 95) correctIndex = 0;
    else if (_spo2 >= 90) correctIndex = 1;
    else correctIndex = 2;

    return EMSSectionCard(
      title: 'Practice: SpO₂ interpretation',
      subtitle: widget.mode == TrainingMode.learn ? 'Hint: typical adult normal is ~95–100%.' : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SpO₂ reading: $_spo2%', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          for (int i = 0; i < choices.length; i++)
            RadioListTile<int>(
              value: i,
              groupValue: _sel,
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _sel = v;
                  if (widget.mode != TrainingMode.test) _correct = v == correctIndex;
                });
              },
              title: Text(choices[i]),
              contentPadding: EdgeInsets.zero,
            ),
          if (widget.mode == TrainingMode.test) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _sel == null
                    ? null
                    : () {
                        setState(() => _correct = _sel == correctIndex);
                      },
                style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text('Check', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
          if (widget.reveal) ...[
            const SizedBox(height: 10),
            EMSResultBox(title: 'Instructor key', message: 'Best answer: ${choices[correctIndex]}', kind: EMSResultKind.info),
          ] else if (_correct != null) ...[
            const SizedBox(height: 10),
            EMSResultBox(
              title: _correct == true ? 'Correct' : 'Needs work',
              message: _correct == true ? 'Good. Always correlate with work of breathing and mental status.' : 'Remember: <90% is a big red flag. Treat the patient per protocol.',
              kind: _correct == true ? EMSResultKind.success : EMSResultKind.warning,
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => setState(_newCase),
              style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
              icon: const Icon(Icons.shuffle),
              label: const Text('New reading'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkinSignsPracticeCard extends StatefulWidget {
  const _SkinSignsPracticeCard({required this.mode, required this.reveal});
  final TrainingMode mode;
  final bool reveal;

  @override
  State<_SkinSignsPracticeCard> createState() => _SkinSignsPracticeCardState();
}

class _SkinSignsPracticeCardState extends State<_SkinSignsPracticeCard> {
  final _rng = Random();
  late String _scenario;
  late String _correct;
  String? _sel;
  bool? _correctFlag;

  @override
  void initState() {
    super.initState();
    _newCase();
  }

  void _newCase() {
    final cases = <(String scenario, String correct)>[
      ('After a long run on a hot day, patient is flushed and hot.', 'Hot / flushed'),
      ('Patient is pale, sweaty, and dizzy after a GI bleed.', 'Cool / clammy'),
      ('Patient is comfortable, no distress, normal perfusion.', 'Warm / dry'),
      ('Patient has blue lips and looks severely short of breath.', 'Cyanotic'),
    ];
    final c = cases[_rng.nextInt(cases.length)];
    _scenario = c.$1;
    _correct = c.$2;
    _sel = null;
    _correctFlag = null;
  }

  @override
  Widget build(BuildContext context) {
    const options = ['Warm / dry', 'Cool / clammy', 'Hot / flushed', 'Cyanotic'];
    return EMSSectionCard(
      title: 'Practice: Skin signs quick read',
      subtitle: widget.mode == TrainingMode.learn ? 'Hint: think perfusion + oxygenation.' : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_scenario, style: context.textStyles.bodyMedium?.copyWith(height: 1.45)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final o in options)
                ChoiceChip(
                  label: Text(o),
                  selected: _sel == o,
                  onSelected: (_) {
                    setState(() {
                      _sel = o;
                      if (widget.mode != TrainingMode.test) _correctFlag = o == _correct;
                    });
                  },
                ),
            ],
          ),
          if (widget.mode == TrainingMode.test) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _sel == null
                    ? null
                    : () {
                        setState(() => _correctFlag = _sel == _correct);
                      },
                style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text('Check', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
          if (widget.reveal) ...[
            const SizedBox(height: 10),
            EMSResultBox(title: 'Instructor key', message: 'Best answer: $_correct', kind: EMSResultKind.info),
          ] else if (_correctFlag != null) ...[
            const SizedBox(height: 10),
            EMSResultBox(
              title: _correctFlag == true ? 'Correct' : 'Needs work',
              message: _correctFlag == true ? 'Good. Skin signs are a fast perfusion clue.' : 'Re-check: cool/clammy often signals poor perfusion or shock; cyanosis is oxygenation.',
              kind: _correctFlag == true ? EMSResultKind.success : EMSResultKind.warning,
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => setState(_newCase),
              style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
              icon: const Icon(Icons.shuffle),
              label: const Text('New scenario'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvpuPracticeCard extends StatelessWidget {
  const _AvpuPracticeCard({required this.mode, required this.reveal, required this.selected, required this.onChanged});
  final TrainingMode mode;
  final bool reveal;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    const correct = 'P';
    final showHint = mode == TrainingMode.learn;
    final showFeedback = mode != TrainingMode.test && selected != null;
    final ok = selected == correct;

    return EMSSectionCard(
      title: 'Practice: AVPU',
      subtitle: showHint ? 'Hint: Verbal = responds to being spoken to; Pain = responds only to painful stimulus.' : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Patient does not open eyes to voice, but withdraws to a sternal rub.', style: context.textStyles.bodyMedium?.copyWith(height: 1.45)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final o in const ['A', 'V', 'P', 'U'])
                ChoiceChip(
                  label: Text(o),
                  selected: selected == o,
                  onSelected: (_) => onChanged(o),
                ),
            ],
          ),
          if (reveal) ...[
            const SizedBox(height: 10),
            const EMSResultBox(title: 'Instructor key', message: 'Correct answer: P', kind: EMSResultKind.info),
          ] else if (showFeedback) ...[
            const SizedBox(height: 10),
            EMSResultBox(
              title: ok ? 'Correct' : 'Needs work',
              message: ok ? 'Yes — responds only to pain.' : 'Remember: “V” is any appropriate response to voice. If only pain works, it’s “P.”',
              kind: ok ? EMSResultKind.success : EMSResultKind.warning,
            ),
          ],
        ],
      ),
    );
  }
}

class _AaoPracticeCard extends StatelessWidget {
  const _AaoPracticeCard({required this.mode, required this.reveal, required this.selected, required this.onChanged});
  final TrainingMode mode;
  final bool reveal;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    const correct = 'AAOx2';
    final showHint = mode == TrainingMode.learn;
    final showFeedback = mode != TrainingMode.test && selected != null;
    final ok = selected == correct;

    return EMSSectionCard(
      title: 'Practice: AAOx status',
      subtitle: showHint ? 'Hint: AAOx4 = person/place/time/event.' : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Patient knows their name and where they are, but not the date and not what happened.', style: context.textStyles.bodyMedium?.copyWith(height: 1.45)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final o in const ['AAOx1', 'AAOx2', 'AAOx3', 'AAOx4'])
                ChoiceChip(
                  label: Text(o),
                  selected: selected == o,
                  onSelected: (_) => onChanged(o),
                ),
            ],
          ),
          if (reveal) ...[
            const SizedBox(height: 10),
            const EMSResultBox(title: 'Instructor key', message: 'Correct answer: AAOx2', kind: EMSResultKind.info),
          ] else if (showFeedback) ...[
            const SizedBox(height: 10),
            EMSResultBox(
              title: ok ? 'Correct' : 'Needs work',
              message: ok ? 'Right — person + place only.' : 'They’re oriented to person + place, but not time or event = AAOx2.',
              kind: ok ? EMSResultKind.success : EMSResultKind.warning,
            ),
          ],
        ],
      ),
    );
  }
}
