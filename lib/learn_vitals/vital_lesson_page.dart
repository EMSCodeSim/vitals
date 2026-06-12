import 'dart:math';

import 'package:emscode_sim_vitals/app/app_state.dart';
import 'package:emscode_sim_vitals/learn_vitals/learn_vitals_models.dart';
import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/shared/normal_not_normal.dart';
import 'package:emscode_sim_vitals/shared/visual_training_widgets.dart';
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
      subtitle: 'Visual demo first, then normal/not-normal practice.',
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
                    _VitalVisualSnapshot(lesson: lesson),
                    const SizedBox(height: 12),
                    _NormalNotNormalForVital(vital: lesson.vital),
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: 'Instructor notes',
                      subtitle: 'Collapsed into short visual cards instead of long paragraphs.',
                      child: EMSInsightGrid(
                        items: [
                          EMSInsightItem(icon: Icons.lightbulb_rounded, label: 'Meaning', value: lesson.whatItMeans, accent: AppColors.emsBlue),
                          EMSInsightItem(icon: Icons.warning_amber_rounded, label: 'Watch for', value: lesson.abnormalMaySuggest.first, accent: Colors.orange),
                          EMSInsightItem(icon: Icons.edit_note_rounded, label: 'Document', value: lesson.whatToDocument, accent: const Color(0xFF22C55E)),
                          EMSInsightItem(icon: Icons.school_rounded, label: 'Mistake', value: lesson.commonStudentMistake, accent: AppColors.danger),
                        ],
                      ),
                    ),
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

                    EMSSectionCard(title: 'Practice', subtitle: 'Apply the skill, then answer: normal or not normal, and why?'),
                    const SizedBox(height: 12),
                    _practiceWidgetFor(lesson.vital, mode, instructor),
                    const SizedBox(height: 12),
                    _OptionalVitalFollowUpCard(vitalTitle: lesson.vital.title),

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



class _VitalVisualSnapshot extends StatelessWidget {
  const _VitalVisualSnapshot({required this.lesson});

  final VitalLesson lesson;

  @override
  Widget build(BuildContext context) {
    return EMSVisualHero(
      title: lesson.vital.title,
      subtitle: lesson.normalRange,
      icon: lesson.vital.icon,
      accent: _accentFor(lesson.vital),
      imageAsset: _imageFor(lesson.vital),
      steps: _stepsFor(lesson.vital),
      actionLabel: _actionFor(lesson.vital),
      onAction: _routeFor(lesson.vital) == null ? null : () => context.push(_routeFor(lesson.vital)!),
    );
  }

  Color _accentFor(VitalId vital) => switch (vital) {
    VitalId.bloodPressure => AppColors.emsBlue,
    VitalId.pulseRate => AppColors.danger,
    VitalId.respiratoryRate => const Color(0xFF0EA5E9),
    VitalId.pupils => const Color(0xFF7C3AED),
    VitalId.skinSigns => const Color(0xFFF97316),
    VitalId.spo2 => const Color(0xFF06B6D4),
    VitalId.avpu => const Color(0xFF22C55E),
    VitalId.aao => const Color(0xFF14B8A6),
  };

  String? _imageFor(VitalId vital) => switch (vital) {
    VitalId.bloodPressure => 'assets/images/bp_cuff_stethoscope_placement.png',
    VitalId.pulseRate => 'assets/images/pulse_points_diagram.png',
    VitalId.respiratoryRate => 'assets/images/respirations_tutorial.png',
    _ => null,
  };

  List<String> _stepsFor(VitalId vital) => switch (vital) {
    VitalId.bloodPressure => const ['Place cuff', 'Listen', 'Record BP'],
    VitalId.pulseRate => const ['Find pulse', 'Count 30 sec', 'Rate x2'],
    VitalId.respiratoryRate => const ['Watch chest', 'Count quietly', 'Rate/min'],
    VitalId.pupils => const ['Size', 'Equal?', 'Reactive?'],
    VitalId.skinSigns => const ['Color', 'Temp', 'Moisture'],
    VitalId.spo2 => const ['Probe', 'Waveform', 'Treat patient'],
    VitalId.avpu => const ['Alert', 'Voice', 'Pain'],
    VitalId.aao => const ['Person', 'Place', 'Time/Event'],
  };

  String? _actionFor(VitalId vital) => switch (vital) {
    VitalId.bloodPressure => 'Open BP simulator',
    VitalId.pulseRate => 'Open pulse drill',
    VitalId.pupils => 'Open pupil demo',
    _ => null,
  };

  String? _routeFor(VitalId vital) => switch (vital) {
    VitalId.bloodPressure => AppRoutes.bloodPressure,
    VitalId.pulseRate => AppRoutes.pulseTest,
    VitalId.pupils => AppRoutes.pupilAssessment,
    _ => null,
  };
}

class _NormalNotNormalForVital extends StatelessWidget {
  const _NormalNotNormalForVital({required this.vital});

  final VitalId vital;

  @override
  Widget build(BuildContext context) {
    final findings = switch (vital) {
      VitalId.bloodPressure => const [
        FindingInterpretation(label: 'BP 118/76', status: 'Normal: within typical adult range', why: 'Why: supports adequate perfusion when skin, pulse, and mentation also look good.', isNormal: true),
        FindingInterpretation(label: 'BP 84/50', status: 'Not normal: low systolic pressure', why: 'Why: with weak pulse, cool/clammy skin, or altered mental status, this suggests poor perfusion/shock.', isNormal: false),
      ],
      VitalId.pulseRate => const [
        FindingInterpretation(label: 'Pulse 78 strong and regular', status: 'Normal: adult rate and regular rhythm', why: 'Why: supports stable perfusion when BP, skin signs, and mentation also match.', isNormal: true),
        FindingInterpretation(label: 'Pulse 110 weak and irregular', status: 'Not normal: fast and not regular', why: 'Why: could be pain, fever, dehydration, anxiety, shock, or cardiac rhythm issue. Correlate with BP, skin, complaint, and mental status.', isNormal: false),
      ],
      VitalId.respiratoryRate => const [
        FindingInterpretation(label: 'RR 16, unlabored', status: 'Normal: adult rate and effort', why: 'Why: patient is ventilating at a typical rate without obvious distress.', isNormal: true),
        FindingInterpretation(label: 'RR 32, shallow/labored', status: 'Not normal: fast with increased work', why: 'Why: may indicate hypoxia, respiratory distress, shock, pain, fever, anxiety, or fatigue.', isNormal: false),
      ],
      VitalId.skinSigns => const [
        FindingInterpretation(label: 'Warm, pink, dry', status: 'Normal: good basic perfusion picture', why: 'Why: no immediate skin sign of shock or hypoxia when other findings agree.', isNormal: true),
        FindingInterpretation(label: 'Pale, cool, clammy', status: 'Not normal: poor perfusion/stress response', why: 'Why: with rapid weak pulse or low BP, this is a shock concern until proven otherwise.', isNormal: false),
      ],
      VitalId.pupils => const [
        FindingInterpretation(label: 'PERRL', status: 'Normal: equal and reactive', why: 'Why: no obvious pupil red flag, but still compare with mental status and complaint.', isNormal: true),
        FindingInterpretation(label: 'Unequal/sluggish pupils', status: 'Not normal: neuro red flag', why: 'Why: may indicate head injury, stroke, or other neurologic problem. Document patient-left vs patient-right.', isNormal: false),
      ],
      VitalId.spo2 => const [
        FindingInterpretation(label: 'SpO₂ 97% on room air', status: 'Normal: typical oxygen saturation', why: 'Why: reassuring only if breathing effort and mental status also look okay.', isNormal: true),
        FindingInterpretation(label: 'SpO₂ 86% with cyanosis', status: 'Not normal: significant hypoxia', why: 'Why: this is an oxygenation problem. Treat the patient and reassess response per protocol.', isNormal: false),
      ],
      VitalId.avpu => const [
        FindingInterpretation(label: 'Alert', status: 'Normal: responds normally without stimulation', why: 'Why: patient can participate in assessment if orientation also makes sense.', isNormal: true),
        FindingInterpretation(label: 'Responds to pain only', status: 'Not normal: decreased level of consciousness', why: 'Why: consider hypoxia, shock, head injury, stroke, intoxication, or hypoglycemia.', isNormal: false),
      ],
      VitalId.aao => const [
        FindingInterpretation(label: 'AAOx4', status: 'Normal: person, place, time, event', why: 'Why: patient is oriented to the expected questions.', isNormal: true),
        FindingInterpretation(label: 'AAOx2', status: 'Not normal: missed time and event', why: 'Why: altered mentation can be from hypoxia, shock, stroke, head injury, sepsis, intoxication, or hypoglycemia.', isNormal: false),
      ],
    };
    return FindingInterpretationBox(title: 'Normal / Not Normal / Why', findings: findings);
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

class _RespRatePracticeCard extends StatefulWidget {
  const _RespRatePracticeCard({required this.hiddenRr, required this.guess, required this.showHint, required this.showReveal, required this.onGuessChanged, required this.onCheck, required this.result});
  final int hiddenRr;
  final int guess;
  final bool showHint;
  final bool showReveal;
  final ValueChanged<int> onGuessChanged;
  final VoidCallback onCheck;
  final bool? result;

  @override
  State<_RespRatePracticeCard> createState() => _RespRatePracticeCardState();
}

class _RespRatePracticeCardState extends State<_RespRatePracticeCard> {
  bool _showDemo = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final prompt = 'A patient is breathing with a steady pattern. Estimate the respiratory rate.';

    if (!_showDemo) {
      return EMSSectionCard(
        title: 'Tutorial: Respirations',
        subtitle: 'Visual first: observe breathing before you count.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/respirations_tutorial.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            EMSResultBox(
              title: 'Key point',
              message: 'Watch the chest or abdomen rise and fall. Count respirations for 30 seconds. One full rise and fall = 1 breath. Multiply by 2 to get breaths per minute.',
              kind: EMSResultKind.info,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => setState(() => _showDemo = true),
                style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text('Next: Watch Demo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      );
    }

    return EMSSectionCard(
      title: 'Demo + Practice: Respiratory rate',
      subtitle: widget.showHint ? 'Hint: adult normal is about 12–20/min. You’re aiming within ±2.' : 'Count the breathing pattern, then document your estimate.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(prompt, style: context.textStyles.bodyMedium?.copyWith(height: 1.45)),
          const SizedBox(height: 12),
          Center(child: _BreathMetronome(bpm: widget.hiddenRr)),
          const SizedBox(height: 12),
          EMSResultBox(
            title: 'Demo reminder',
            message: 'Watch the rise and fall. Count for 30 seconds, then multiply by 2.',
            kind: EMSResultKind.info,
          ),
          const SizedBox(height: 12),
          Text('Your estimate: ${widget.guess} /min', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
          Slider(value: widget.guess.toDouble(), min: 6, max: 36, divisions: 30, onChanged: (v) => widget.onGuessChanged(v.round())),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: widget.onCheck,
              style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('Check', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _showDemo = false),
              style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to tutorial photo'),
            ),
          ),
          if (widget.showReveal) ...[
            const SizedBox(height: 10),
            EMSResultBox(title: 'Instructor key', message: 'Hidden rate: ${widget.hiddenRr} /min', kind: EMSResultKind.info),
          ] else if (widget.result != null) ...[
            const SizedBox(height: 10),
            EMSResultBox(
              title: widget.result == true ? 'Correct' : 'Needs work',
              message: widget.result == true ? 'Nice. In real patients, also look at work of breathing + ability to speak.' : 'Try counting for 30 seconds and multiplying by 2. Also watch for irregular breathing.',
              kind: widget.result == true ? EMSResultKind.success : EMSResultKind.warning,
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

class _OptionalVitalFollowUpCard extends StatefulWidget {
  const _OptionalVitalFollowUpCard({required this.vitalTitle});
  final String vitalTitle;

  @override
  State<_OptionalVitalFollowUpCard> createState() => _OptionalVitalFollowUpCardState();
}

class _OptionalVitalFollowUpCardState extends State<_OptionalVitalFollowUpCard> {
  bool _showQuestions = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return EMSSectionCard(
      title: 'Optional follow-up questions',
      subtitle: 'Use these after practice if the student wants one more step.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _showQuestions = !_showQuestions),
              icon: Icon(_showQuestions ? Icons.expand_less : Icons.expand_more),
              label: Text(_showQuestions ? 'Hide follow-up questions' : 'Show follow-up questions'),
            ),
          ),
          if (_showQuestions) ...[
            const SizedBox(height: 12),
            _QuestionLine(text: 'Is this ${widget.vitalTitle} finding normal or not normal?'),
            const _QuestionLine(text: 'If it is not normal, what word describes the problem: fast, slow, weak, irregular, low, high, labored, or altered?'),
            const _QuestionLine(text: 'Why does this matter for perfusion, oxygenation, mental status, or transport priority?'),
            const _QuestionLine(text: 'What should you reassess next?'),
            const SizedBox(height: 8),
            Text('Example language: “Not normal: pulse 110 and irregular. It is fast and not regular, so I would compare it with BP, skin signs, complaint, and mental status.”', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}

class _QuestionLine extends StatelessWidget {
  const _QuestionLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.help_outline, size: 18, color: AppColors.emsBlue),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: context.textStyles.bodySmall?.copyWith(height: 1.35))),
        ],
      ),
    );
  }
}
