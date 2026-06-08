import 'dart:math';

import 'package:emscode_sim_vitals/app/app_state.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/shared/normal_not_normal.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FullVitalsSetPracticePage extends StatefulWidget {
  const FullVitalsSetPracticePage({super.key});

  @override
  State<FullVitalsSetPracticePage> createState() => _FullVitalsSetPracticePageState();
}

class _FullVitalsSetPracticePageState extends State<FullVitalsSetPracticePage> {
  final _rng = Random();
  late VitalsPracticeCase _case;

  final _rrController = TextEditingController();
  final _pulseController = TextEditingController();
  final _sysController = TextEditingController();
  final _diaController = TextEditingController();
  final _spo2Controller = TextEditingController();

  String? _pulseQuality;
  String? _skinSigns;
  String? _pupils;
  String? _avpu;
  String? _aao;
  double _pain = 0;
  VitalsPracticeResult? _result;

  static const _pulseQualityOptions = ['strong/regular', 'weak/regular', 'weak/irregular', 'bounding', 'thready'];
  static const _skinOptions = ['warm/pink/dry', 'pale/cool/clammy', 'hot/flushed/dry', 'cyanotic', 'mottled'];
  static const _pupilOptions = ['PERRL', 'pinpoint/sluggish', 'dilated/sluggish', 'unequal/sluggish'];
  static const _avpuOptions = ['A', 'V', 'P', 'U'];
  static const _aaoOptions = ['AAOx4', 'AAOx3', 'AAOx2', 'AAOx1', 'AAOx0'];

  @override
  void initState() {
    super.initState();
    _newCase();
  }

  @override
  void dispose() {
    _rrController.dispose();
    _pulseController.dispose();
    _sysController.dispose();
    _diaController.dispose();
    _spo2Controller.dispose();
    super.dispose();
  }

  void _newCase() {
    _case = _vitalsCases[_rng.nextInt(_vitalsCases.length)];
    _rrController.clear();
    _pulseController.clear();
    _sysController.clear();
    _diaController.clear();
    _spo2Controller.clear();
    _pulseQuality = null;
    _skinSigns = null;
    _pupils = null;
    _avpu = null;
    _aao = null;
    _pain = 0;
    _result = null;
  }

  int? _intFrom(TextEditingController c) => int.tryParse(c.text.trim());

  void _submit() {
    final answer = StudentVitalsAnswer(
      rr: _intFrom(_rrController),
      pulse: _intFrom(_pulseController),
      sys: _intFrom(_sysController),
      dia: _intFrom(_diaController),
      spo2: _intFrom(_spo2Controller),
      pulseQuality: _pulseQuality,
      skinSigns: _skinSigns,
      pupils: _pupils,
      avpu: _avpu,
      aao: _aao,
      pain: _pain.round(),
    );

    setState(() => _result = VitalsPracticeResult.grade(_case, answer));
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.select<AppState, TrainingMode>((s) => s.mode);
    final instructor = context.select<AppState, bool>((s) => s.instructorMode);
    final result = _result;

    return EMSVitalsScaffold(
      title: 'Full Vitals Set',
      subtitle: 'Collect, interpret, and document a full EMT vital set before moving into a patient assessment walkthrough.',
      onInfoPressed: () {
        EMSInfoSheet.show(
          context,
          title: 'Full Vitals Set Practice',
          children: const [
            Text('Use the patient card to decide what vitals should look like, then enter a full set.'),
            SizedBox(height: 12),
            Text('Learn mode shows hints. Practice mode gives coached feedback. Test mode keeps feedback until the final score.'),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PatientCard(vitalsCase: _case),
                    const SizedBox(height: 12),
                    if (mode == TrainingMode.learn) ...[
                      EMSResultBox(
                        title: 'Learn Mode Hint',
                        message: 'Do not just chase numbers. Tie respiratory rate, pulse, blood pressure, skin signs, SpO₂, and mental status together to decide if the patient is stable or unstable.',
                        kind: EMSResultKind.info,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (instructor) ...[
                      _InstructorKeyCard(vitalsCase: _case),
                      const SizedBox(height: 12),
                    ],
                    _VitalsEntryCard(
                      rrController: _rrController,
                      pulseController: _pulseController,
                      sysController: _sysController,
                      diaController: _diaController,
                      spo2Controller: _spo2Controller,
                      pulseQuality: _pulseQuality,
                      skinSigns: _skinSigns,
                      pupils: _pupils,
                      avpu: _avpu,
                      aao: _aao,
                      pain: _pain,
                      pulseQualityOptions: _pulseQualityOptions,
                      skinOptions: _skinOptions,
                      pupilOptions: _pupilOptions,
                      avpuOptions: _avpuOptions,
                      aaoOptions: _aaoOptions,
                      onPulseQualityChanged: (v) => setState(() => _pulseQuality = v),
                      onSkinChanged: (v) => setState(() => _skinSigns = v),
                      onPupilsChanged: (v) => setState(() => _pupils = v),
                      onAvpuChanged: (v) => setState(() => _avpu = v),
                      onAaoChanged: (v) => setState(() => _aao = v),
                      onPainChanged: (v) => setState(() => _pain = v),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _submit,
                        style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('Submit Full Vitals Set', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (result != null) ...[
                      _VitalsResultCard(vitalsCase: _case, result: result),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => setState(_newCase),
                        style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                        icon: const Icon(Icons.shuffle),
                        label: const Text('New Patient'),
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
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.vitalsCase});
  final VitalsPracticeCase vitalsCase;

  @override
  Widget build(BuildContext context) {
    return EMSSectionCard(
      title: 'Patient Card',
      subtitle: '${vitalsCase.age} • ${vitalsCase.chiefComplaint}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: 'General impression', value: vitalsCase.generalImpression),
          _InfoRow(label: 'Breathing clue', value: vitalsCase.breathingClue),
          _InfoRow(label: 'Mental status clue', value: vitalsCase.mentalStatusClue),
          _InfoRow(label: 'Skin clue', value: vitalsCase.skinClue),
        ],
      ),
    );
  }
}

class _InstructorKeyCard extends StatelessWidget {
  const _InstructorKeyCard({required this.vitalsCase});
  final VitalsPracticeCase vitalsCase;

  @override
  Widget build(BuildContext context) {
    return EMSSectionCard(
      title: 'Instructor Key',
      subtitle: 'Visible because Instructor Mode is ON.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: 'Expected vitals', value: vitalsCase.expected.documentationLine),
          _InfoRow(label: 'Critical findings', value: vitalsCase.criticalFindings.join(' • ')),
          _InfoRow(label: 'Teaching point', value: vitalsCase.teachingPoint),
        ],
      ),
    );
  }
}

class _VitalsEntryCard extends StatelessWidget {
  const _VitalsEntryCard({
    required this.rrController,
    required this.pulseController,
    required this.sysController,
    required this.diaController,
    required this.spo2Controller,
    required this.pulseQuality,
    required this.skinSigns,
    required this.pupils,
    required this.avpu,
    required this.aao,
    required this.pain,
    required this.pulseQualityOptions,
    required this.skinOptions,
    required this.pupilOptions,
    required this.avpuOptions,
    required this.aaoOptions,
    required this.onPulseQualityChanged,
    required this.onSkinChanged,
    required this.onPupilsChanged,
    required this.onAvpuChanged,
    required this.onAaoChanged,
    required this.onPainChanged,
  });

  final TextEditingController rrController;
  final TextEditingController pulseController;
  final TextEditingController sysController;
  final TextEditingController diaController;
  final TextEditingController spo2Controller;
  final String? pulseQuality;
  final String? skinSigns;
  final String? pupils;
  final String? avpu;
  final String? aao;
  final double pain;
  final List<String> pulseQualityOptions;
  final List<String> skinOptions;
  final List<String> pupilOptions;
  final List<String> avpuOptions;
  final List<String> aaoOptions;
  final ValueChanged<String?> onPulseQualityChanged;
  final ValueChanged<String?> onSkinChanged;
  final ValueChanged<String?> onPupilsChanged;
  final ValueChanged<String?> onAvpuChanged;
  final ValueChanged<String?> onAaoChanged;
  final ValueChanged<double> onPainChanged;

  @override
  Widget build(BuildContext context) {
    return EMSSectionCard(
      title: 'Enter Student Vitals',
      subtitle: 'One full set: rate, quality, perfusion, oxygenation, mental status, pain, and documentation.',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _NumberField(controller: rrController, label: 'RR /min')),
              const SizedBox(width: 10),
              Expanded(child: _NumberField(controller: pulseController, label: 'Pulse /min')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _NumberField(controller: sysController, label: 'BP SYS')),
              const SizedBox(width: 10),
              Expanded(child: _NumberField(controller: diaController, label: 'BP DIA')),
              const SizedBox(width: 10),
              Expanded(child: _NumberField(controller: spo2Controller, label: 'SpO₂ %')),
            ],
          ),
          const SizedBox(height: 10),
          _DropdownField(label: 'Pulse quality', value: pulseQuality, options: pulseQualityOptions, onChanged: onPulseQualityChanged),
          const SizedBox(height: 10),
          _DropdownField(label: 'Skin signs', value: skinSigns, options: skinOptions, onChanged: onSkinChanged),
          const SizedBox(height: 10),
          _DropdownField(label: 'Pupils', value: pupils, options: pupilOptions, onChanged: onPupilsChanged),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _DropdownField(label: 'AVPU', value: avpu, options: avpuOptions, onChanged: onAvpuChanged)),
              const SizedBox(width: 10),
              Expanded(child: _DropdownField(label: 'AAOx', value: aao, options: aaoOptions, onChanged: onAaoChanged)),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Pain score: ${pain.round()}/10', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
          ),
          Slider(value: pain, min: 0, max: 10, divisions: 10, label: pain.round().toString(), onChanged: onPainChanged),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({required this.label, required this.value, required this.options, required this.onChanged});
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: [
        for (final option in options)
          DropdownMenuItem(value: option, child: Text(option, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: onChanged,
    );
  }
}

class _VitalsResultCard extends StatelessWidget {
  const _VitalsResultCard({required this.vitalsCase, required this.result});
  final VitalsPracticeCase vitalsCase;
  final VitalsPracticeResult result;

  @override
  Widget build(BuildContext context) {
    final passed = result.scorePercent >= 80 && result.missedCriticalFindings.isEmpty;
    return EMSSectionCard(
      title: passed ? 'Pass — Full Vitals Set' : 'Needs Work — Full Vitals Set',
      subtitle: 'Score: ${result.scorePercent}% • ${result.correctCount}/${result.totalCount} categories correct',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EMSResultBox(
            title: passed ? 'Good patient picture' : 'Recheck before moving on',
            message: passed ? 'The student collected the major findings and can move into SAMPLE/OPQRST.' : 'Review missed categories and any critical findings before starting the full assessment walkthrough.',
            kind: passed ? EMSResultKind.success : EMSResultKind.warning,
          ),
          const SizedBox(height: 12),
          for (final line in result.feedbackLines) _ResultLine(text: line),
          if (result.missedCriticalFindings.isNotEmpty) ...[
            const SizedBox(height: 10),
            EMSResultBox(
              title: 'Missed Critical Finding',
              message: result.missedCriticalFindings.join('\n'),
              kind: EMSResultKind.error,
            ),
          ],
          const SizedBox(height: 12),
          FindingInterpretationBox(title: 'Expected interpretation', findings: _expectedInterpretations(vitalsCase.expected)),
          const SizedBox(height: 12),
          Text('Correct documentation line', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          SelectableText(vitalsCase.expected.documentationLine, style: context.textStyles.bodyMedium?.copyWith(height: 1.4)),
          const SizedBox(height: 12),
          Text('Teaching point', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(vitalsCase.teachingPoint, style: context.textStyles.bodyMedium?.copyWith(height: 1.4)),
        ],
      ),
    );
  }
}


List<FindingInterpretation> _expectedInterpretations(ExpectedVitals expected) {
  final pulseNormal = expected.pulse >= 60 && expected.pulse <= 100 && expected.pulseQuality.contains('regular') && !expected.pulseQuality.contains('weak') && !expected.pulseQuality.contains('thready');
  final rrNormal = expected.rr >= 12 && expected.rr <= 20;
  final bpNormal = expected.sys >= 90 && expected.sys <= 120 && expected.dia >= 60 && expected.dia <= 80;
  final spo2Normal = expected.spo2 >= 95;
  final skinNormal = expected.skinSigns == 'warm/pink/dry';
  final mentationNormal = expected.aao == 'AAOx4' && expected.avpu == 'A';

  return [
    FindingInterpretation(
      label: 'Pulse ${expected.pulse} ${expected.pulseQuality}',
      status: pulseNormal ? 'Normal: adult rate and regular/strong quality' : 'Not normal: ${_pulseReason(expected)}',
      why: pulseNormal ? 'Why: supports stable perfusion when BP, skin signs, and mentation agree.' : 'Why: pulse changes should be matched to BP, skin signs, pain, fever, dehydration, shock, or cardiac concerns.',
      isNormal: pulseNormal,
    ),
    FindingInterpretation(
      label: 'RR ${expected.rr}/min',
      status: rrNormal ? 'Normal: adult respiratory rate' : 'Not normal: ${expected.rr > 20 ? 'fast' : 'slow'} respiratory rate',
      why: rrNormal ? 'Why: rate is reassuring if effort and SpO₂ are also reassuring.' : 'Why: abnormal RR can signal respiratory distress, hypoxia, shock, pain, anxiety, CNS depression, or fatigue.',
      isNormal: rrNormal,
    ),
    FindingInterpretation(
      label: 'BP ${expected.sys}/${expected.dia}',
      status: bpNormal ? 'Normal: typical adult BP range' : 'Not normal: ${expected.sys < 90 ? 'low systolic pressure' : expected.sys > 140 ? 'elevated systolic pressure' : 'outside typical range'}',
      why: bpNormal ? 'Why: adequate only when the rest of the patient picture also fits.' : 'Why: BP must be interpreted with pulse, skin signs, mental status, complaint, and trends.',
      isNormal: bpNormal,
    ),
    FindingInterpretation(
      label: 'SpO₂ ${expected.spo2}% RA',
      status: spo2Normal ? 'Normal: typical oxygen saturation' : 'Not normal: low oxygen saturation',
      why: spo2Normal ? 'Why: reassuring only if work of breathing is also normal.' : 'Why: low SpO₂ with distress or cyanosis needs oxygenation/ventilation decision-making and reassessment per protocol.',
      isNormal: spo2Normal,
    ),
    FindingInterpretation(
      label: 'Skin ${expected.skinSigns}',
      status: skinNormal ? 'Normal: warm/pink/dry' : 'Not normal: perfusion or oxygenation concern',
      why: skinNormal ? 'Why: no obvious skin red flag when other findings agree.' : 'Why: abnormal skin signs can point to shock, hypoxia, fever, sepsis, heat illness, or poor perfusion.',
      isNormal: skinNormal,
    ),
    FindingInterpretation(
      label: 'Mental status ${expected.avpu}/${expected.aao}',
      status: mentationNormal ? 'Normal: alert and oriented' : 'Not normal: altered mental status',
      why: mentationNormal ? 'Why: patient can participate in assessment.' : 'Why: altered mentation can come from hypoxia, shock, stroke, head injury, intoxication, hypoglycemia, or sepsis.',
      isNormal: mentationNormal,
    ),
  ];
}

String _pulseReason(ExpectedVitals expected) {
  final parts = <String>[];
  if (expected.pulse > 100) parts.add('fast');
  if (expected.pulse < 60) parts.add('slow');
  if (expected.pulseQuality.contains('irregular')) parts.add('not regular');
  if (expected.pulseQuality.contains('weak') || expected.pulseQuality.contains('thready')) parts.add('weak quality');
  if (parts.isEmpty) return 'quality does not match a normal pulse picture';
  return parts.join(' and ');
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(text.startsWith('✓') ? Icons.check_circle : Icons.warning_amber_rounded, size: 18, color: text.startsWith('✓') ? Colors.green : Colors.orange),
          const SizedBox(width: 10),
          Expanded(child: Text(text.substring(2), style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35))),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurfaceVariant)),
          const SizedBox(height: 3),
          Text(value, style: context.textStyles.bodyMedium?.copyWith(height: 1.35)),
        ],
      ),
    );
  }
}

class VitalsPracticeCase {
  const VitalsPracticeCase({
    required this.age,
    required this.chiefComplaint,
    required this.generalImpression,
    required this.breathingClue,
    required this.mentalStatusClue,
    required this.skinClue,
    required this.expected,
    required this.criticalFindings,
    required this.teachingPoint,
  });

  final String age;
  final String chiefComplaint;
  final String generalImpression;
  final String breathingClue;
  final String mentalStatusClue;
  final String skinClue;
  final ExpectedVitals expected;
  final List<String> criticalFindings;
  final String teachingPoint;
}

class ExpectedVitals {
  const ExpectedVitals({
    required this.rr,
    required this.pulse,
    required this.sys,
    required this.dia,
    required this.spo2,
    required this.pulseQuality,
    required this.skinSigns,
    required this.pupils,
    required this.avpu,
    required this.aao,
    required this.pain,
  });

  final int rr;
  final int pulse;
  final int sys;
  final int dia;
  final int spo2;
  final String pulseQuality;
  final String skinSigns;
  final String pupils;
  final String avpu;
  final String aao;
  final int pain;

  String get documentationLine => 'Vitals: BP $sys/$dia, pulse $pulse $pulseQuality, RR $rr, SpO₂ $spo2% RA, skin $skinSigns, pupils $pupils, LOC $avpu/$aao, pain $pain/10.';
}

class StudentVitalsAnswer {
  const StudentVitalsAnswer({required this.rr, required this.pulse, required this.sys, required this.dia, required this.spo2, required this.pulseQuality, required this.skinSigns, required this.pupils, required this.avpu, required this.aao, required this.pain});

  final int? rr;
  final int? pulse;
  final int? sys;
  final int? dia;
  final int? spo2;
  final String? pulseQuality;
  final String? skinSigns;
  final String? pupils;
  final String? avpu;
  final String? aao;
  final int pain;
}

class VitalsPracticeResult {
  const VitalsPracticeResult({required this.correctCount, required this.totalCount, required this.feedbackLines, required this.missedCriticalFindings});

  final int correctCount;
  final int totalCount;
  final List<String> feedbackLines;
  final List<String> missedCriticalFindings;

  int get scorePercent => ((correctCount / totalCount) * 100).round();

  static VitalsPracticeResult grade(VitalsPracticeCase vitalsCase, StudentVitalsAnswer answer) {
    final expected = vitalsCase.expected;
    final feedback = <String>[];
    var correct = 0;
    const total = 10;

    void addCheck(bool ok, String good, String miss) {
      if (ok) {
        correct++;
        feedback.add('✓ $good');
      } else {
        feedback.add('! $miss');
      }
    }

    addCheck(_within(answer.rr, expected.rr, 2), 'Respiratory rate matched expected patient picture.', 'Respiratory rate should be about ${expected.rr}/min. Watch effort and ability to speak.');
    addCheck(_within(answer.pulse, expected.pulse, 8), 'Pulse rate matched expected patient picture.', 'Pulse rate should be about ${expected.pulse}/min and documented with quality.');
    addCheck(_within(answer.sys, expected.sys, 10) && _within(answer.dia, expected.dia, 10), 'Blood pressure was within expected range.', 'Blood pressure should be about ${expected.sys}/${expected.dia}. Recheck abnormal values.');
    addCheck(_within(answer.spo2, expected.spo2, 3), 'SpO₂ matched the patient context.', 'SpO₂ should be about ${expected.spo2}%. Treat the patient, not just the number.');
    addCheck(answer.pulseQuality == expected.pulseQuality, 'Pulse quality was documented correctly.', 'Pulse quality should be ${expected.pulseQuality}.');
    addCheck(answer.skinSigns == expected.skinSigns, 'Skin signs matched perfusion picture.', 'Skin signs should be ${expected.skinSigns}.');
    addCheck(answer.pupils == expected.pupils, 'Pupils were documented correctly.', 'Pupils should be ${expected.pupils}.');
    addCheck(answer.avpu == expected.avpu, 'AVPU was correct.', 'AVPU should be ${expected.avpu}.');
    addCheck(answer.aao == expected.aao, 'AAOx status was correct.', 'AAOx status should be ${expected.aao}.');
    addCheck((answer.pain - expected.pain).abs() <= 2, 'Pain score was reasonable for the complaint.', 'Pain score should be close to ${expected.pain}/10.');

    final missedCritical = <String>[];
    if (expected.spo2 < 90 && (answer.spo2 == null || answer.spo2! >= 90)) missedCritical.add('SpO₂ below 90% was not recognized.');
    if (expected.sys < 90 && (answer.sys == null || answer.sys! >= 90)) missedCritical.add('Systolic BP under 90 was not recognized.');
    if ((expected.rr < 8 || expected.rr > 30) && (answer.rr == null || (answer.rr! >= 8 && answer.rr! <= 30))) missedCritical.add('Critical respiratory rate was not recognized.');
    if (expected.aao != 'AAOx4' && answer.aao == 'AAOx4') missedCritical.add('Altered mental status was missed.');
    if ((expected.skinSigns == 'cyanotic' || expected.skinSigns == 'pale/cool/clammy') && answer.skinSigns == 'warm/pink/dry') missedCritical.add('Abnormal skin signs were missed.');

    return VitalsPracticeResult(correctCount: correct, totalCount: total, feedbackLines: feedback, missedCriticalFindings: missedCritical);
  }

  static bool _within(int? answer, int expected, int tolerance) => answer != null && (answer - expected).abs() <= tolerance;
}

const List<VitalsPracticeCase> _vitalsCases = [
  VitalsPracticeCase(
    age: '45-year-old adult',
    chiefComplaint: 'Chest pressure after exertion',
    generalImpression: 'Sitting upright, anxious, speaking in full sentences.',
    breathingClue: 'Mildly increased work of breathing but no obvious distress.',
    mentalStatusClue: 'Knows name, location, date, and what happened.',
    skinClue: 'Pale and slightly sweaty.',
    expected: ExpectedVitals(rr: 22, pulse: 112, sys: 148, dia: 88, spo2: 94, pulseQuality: 'strong/regular', skinSigns: 'pale/cool/clammy', pupils: 'PERRL', avpu: 'A', aao: 'AAOx4', pain: 7),
    criticalFindings: ['Chest pain with pale/diaphoretic skin', 'Tachycardia', 'Needs ongoing reassessment'],
    teachingPoint: 'Chest pain assessment should not stop at the BP. Correlate skin signs, pulse, pain, history, and transport priority.',
  ),
  VitalsPracticeCase(
    age: '72-year-old adult',
    chiefComplaint: 'Shortness of breath',
    generalImpression: 'Tripod position, only speaking two to three words at a time.',
    breathingClue: 'Labored breathing with audible wheezing.',
    mentalStatusClue: 'Alert but anxious and tiring.',
    skinClue: 'Cool and pale around the mouth.',
    expected: ExpectedVitals(rr: 32, pulse: 124, sys: 158, dia: 92, spo2: 86, pulseQuality: 'weak/regular', skinSigns: 'cyanotic', pupils: 'PERRL', avpu: 'A', aao: 'AAOx4', pain: 3),
    criticalFindings: ['SpO₂ below 90%', 'RR over 30', 'Cyanosis', 'High work of breathing'],
    teachingPoint: 'For respiratory patients, document rate plus work of breathing, speech, skin color, SpO₂, and response to treatment.',
  ),
  VitalsPracticeCase(
    age: '28-year-old adult',
    chiefComplaint: 'Dizziness after vomiting all day',
    generalImpression: 'Weak, slow to sit up, looks dehydrated.',
    breathingClue: 'Breathing is regular and non-labored.',
    mentalStatusClue: 'Knows name and place but is confused about the date and event.',
    skinClue: 'Cool, pale, clammy skin.',
    expected: ExpectedVitals(rr: 24, pulse: 132, sys: 84, dia: 50, spo2: 96, pulseQuality: 'weak/regular', skinSigns: 'pale/cool/clammy', pupils: 'PERRL', avpu: 'A', aao: 'AAOx2', pain: 4),
    criticalFindings: ['Systolic BP under 90', 'Rapid weak pulse', 'Altered mental status', 'Cool/pale/clammy skin'],
    teachingPoint: 'Low BP plus rapid weak pulse and altered mental status is a poor perfusion picture until proven otherwise.',
  ),
  VitalsPracticeCase(
    age: '19-year-old adult',
    chiefComplaint: 'Ankle pain after sports injury',
    generalImpression: 'Sitting on ground, uncomfortable but calm.',
    breathingClue: 'Breathing regular, no respiratory distress.',
    mentalStatusClue: 'Fully oriented and answers questions clearly.',
    skinClue: 'Warm, pink, dry skin.',
    expected: ExpectedVitals(rr: 18, pulse: 88, sys: 118, dia: 74, spo2: 99, pulseQuality: 'strong/regular', skinSigns: 'warm/pink/dry', pupils: 'PERRL', avpu: 'A', aao: 'AAOx4', pain: 6),
    criticalFindings: ['No immediate life threat based on vitals'],
    teachingPoint: 'Normal vitals still need documentation. Use them as a baseline for later reassessment.',
  ),
  VitalsPracticeCase(
    age: '63-year-old adult',
    chiefComplaint: 'Confusion and slurred speech',
    generalImpression: 'Sitting in chair, facial droop noted by family.',
    breathingClue: 'Breathing regular without distress.',
    mentalStatusClue: 'Knows name only, cannot state place, date, or event.',
    skinClue: 'Warm and dry.',
    expected: ExpectedVitals(rr: 16, pulse: 96, sys: 178, dia: 98, spo2: 97, pulseQuality: 'strong/regular', skinSigns: 'warm/pink/dry', pupils: 'unequal/sluggish', avpu: 'A', aao: 'AAOx1', pain: 0),
    criticalFindings: ['Altered mental status', 'Possible stroke findings', 'Hypertension with neuro complaint'],
    teachingPoint: 'Neuro patients may have normal breathing and oxygenation. Mental status, pupils, speech, and last known well matter.',
  ),
];
