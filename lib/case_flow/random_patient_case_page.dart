import 'dart:math';

import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';

enum CaseType { possibleStroke, sepsisShock, respiratoryWheeze, burn, opioidOverdose, headInjury }

extension on CaseType {
  String get title => switch (this) {
    CaseType.possibleStroke => 'Possible Stroke',
    CaseType.sepsisShock => 'Sepsis / Shock',
    CaseType.respiratoryWheeze => 'Respiratory Distress (Wheezing)',
    CaseType.burn => 'Burn Patient',
    CaseType.opioidOverdose => 'Opioid Overdose',
    CaseType.headInjury => 'Head Injury',
  };

  IconData get icon => switch (this) {
    CaseType.possibleStroke => Icons.health_and_safety,
    CaseType.sepsisShock => Icons.water_drop,
    CaseType.respiratoryWheeze => Icons.air,
    CaseType.burn => Icons.local_fire_department,
    CaseType.opioidOverdose => Icons.medication,
    CaseType.headInjury => Icons.warning_amber_rounded,
  };
}

@immutable
class RandomPatientCase {
  const RandomPatientCase({required this.type, required this.age, required this.sex, required this.chiefComplaint, required this.presentation, required this.learningPoints});

  final CaseType type;
  final int age;
  final String sex;
  final String chiefComplaint;
  final String presentation;
  final List<String> learningPoints;

  static RandomPatientCase generate(Random rng) {
    final type = CaseType.values[rng.nextInt(CaseType.values.length)];
    final age = [18, 22, 31, 46, 57, 64, 72, 81][rng.nextInt(8)];
    final sex = rng.nextBool() ? 'Male' : 'Female';
    return switch (type) {
      CaseType.possibleStroke => RandomPatientCase(
        type: type,
        age: age,
        sex: sex,
        chiefComplaint: 'Weakness and speech change',
        presentation: 'Family reports sudden facial droop and slurred speech. Last known well is “about an hour ago.” Patient is awake but frustrated and has trouble finding words.',
        learningPoints: ['Perform BE-FAST/Cincinnati checks', 'Confirm last known well wording', 'Check blood glucose early'],
      ),
      CaseType.sepsisShock => RandomPatientCase(
        type: type,
        age: age,
        sex: sex,
        chiefComplaint: 'Weakness, fever, dizziness',
        presentation: 'Patient is warm then cool/clammy, feels “very weak,” and is tachycardic. Consider infection history and perfusion signs.',
        learningPoints: ['Look for shock indicators', 'BP + pulse quality matter', 'Reassess after interventions'],
      ),
      CaseType.respiratoryWheeze => RandomPatientCase(
        type: type,
        age: age,
        sex: sex,
        chiefComplaint: 'Shortness of breath',
        presentation: 'Patient is speaking in short phrases with audible wheeze. Work of breathing is increased. You should auscultate multiple regions and compare sides.',
        learningPoints: ['Identify wheezing vs stridor', 'Assess work of breathing', 'Consider asthma/COPD/anaphylaxis'],
      ),
      CaseType.burn => RandomPatientCase(
        type: type,
        age: age,
        sex: sex,
        chiefComplaint: 'Burn after fire/cooking accident',
        presentation: 'Partial-thickness burns to torso and arm. Consider TBSA estimate and burn-center criteria. Ask about enclosed-space fire and inhalation concerns.',
        learningPoints: ['Rule of Nines TBSA estimate', 'Inhalation injury prompts', 'Parkland is an estimate (training)'],
      ),
      CaseType.opioidOverdose => RandomPatientCase(
        type: type,
        age: age,
        sex: sex,
        chiefComplaint: 'Found unresponsive',
        presentation: 'Patient is somnolent with slow respirations. Pupils may be pinpoint. Assess breathing first; pupils can support the differential.',
        learningPoints: ['Pinpoint pupils + hypoventilation', 'Recheck pupils after interventions', 'Training only: follow protocol'],
      ),
      CaseType.headInjury => RandomPatientCase(
        type: type,
        age: age,
        sex: sex,
        chiefComplaint: 'Fall with head strike',
        presentation: 'Patient had a fall and is now confused. Pupil findings may be unequal or sluggish. Consider stroke mimic vs trauma.',
        learningPoints: ['Clearly document patient-left vs patient-right', 'Recheck neuro findings', 'Glucose can mimic neuro deficits'],
      ),
    };
  }
}

/// Version 1: a simple guided “scenario card” flow.
///
/// This is intentionally lightweight; it provides a coherent cross-module story
/// without forcing the user through every module UI in one session.
class RandomPatientCasePage extends StatefulWidget {
  const RandomPatientCasePage({super.key});

  @override
  State<RandomPatientCasePage> createState() => _RandomPatientCasePageState();
}

class _RandomPatientCasePageState extends State<RandomPatientCasePage> {
  final _rng = Random();
  late RandomPatientCase _case;

  @override
  void initState() {
    super.initState();
    _case = RandomPatientCase.generate(_rng);
  }

  void _newCase() => setState(() => _case = RandomPatientCase.generate(_rng));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return EMSVitalsScaffold(
      title: 'Random Skill Challenge',
      subtitle: 'A quick scenario to frame your assessment. Educational use only (not medical advice).',
      onInfoPressed: () {
        EMSInfoSheet.show(
          context,
          title: 'How to use this challenge',
          children: const [
            Text('Read the presentation, then open the relevant modules to practice assessment steps.\n\nVersion 1 keeps this lightweight and fast; future versions can chain steps and scoring across modules.'),
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
                    EMSSectionCard(
                      title: _case.type.title,
                      subtitle: '${_case.age}y/o ${_case.sex} • Chief complaint: ${_case.chiefComplaint}',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(999), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(_case.type.icon, size: 16, color: cs.onSurfaceVariant), const SizedBox(width: 8), Text('Scenario', style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w900))]),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_case.presentation, style: context.textStyles.bodyMedium?.copyWith(height: 1.5)),
                          const SizedBox(height: 12),
                          Text('Learning points', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          for (final p in _case.learningPoints)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_circle, size: 18, color: AppColors.emsBlue),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(p, style: context.textStyles.bodyMedium?.copyWith(height: 1.4))),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    EMSSectionCard(
                      title: 'Suggested practice',
                      subtitle: 'Open the modules that match the scenario. You can stay in Learn/Practice/Test mode across the whole app.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('• Pulse Test: estimate rate + quality\n• Blood Pressure: pump/release + estimate SYS/DIA\n• Pupil Assessment: document PERRL vs abnormal\n• Stroke Assessment: BE-FAST/Cincinnati + glucose\n• Breath Sounds / Rule of Nines: as scenario requires'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _newCase,
                        style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                        icon: const Icon(Icons.shuffle, color: Colors.white),
                        label: const Text('New random scenario', style: TextStyle(color: Colors.white)),
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
