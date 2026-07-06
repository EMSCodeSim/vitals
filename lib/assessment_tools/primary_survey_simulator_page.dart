import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrimarySurveySimulatorPage extends StatefulWidget {
  const PrimarySurveySimulatorPage({super.key});

  @override
  State<PrimarySurveySimulatorPage> createState() => _PrimarySurveySimulatorPageState();
}

class _PrimarySurveySimulatorPageState extends State<PrimarySurveySimulatorPage> {
  int _caseIndex = 0;
  _PrimaryStep _activeStep = _PrimaryStep.general;
  bool _showResults = false;

  String? _generalPick;
  String? _locPick;
  String? _lifeThreatPick;
  String? _abAssessmentPick;
  String? _ventilationPick;
  String? _oxygenPick;
  String? _bleedingPick;
  String? _skinPick;
  String? _pulsePick;
  String? _priorityPick;

  _PrimaryCase get _case => _primaryCases[_caseIndex];

  void _resetCase({bool keepSameCase = true}) {
    setState(() {
      if (!keepSameCase) _caseIndex = (_caseIndex + 1) % _primaryCases.length;
      _activeStep = _PrimaryStep.general;
      _showResults = false;
      _generalPick = null;
      _locPick = null;
      _lifeThreatPick = null;
      _abAssessmentPick = null;
      _ventilationPick = null;
      _oxygenPick = null;
      _bleedingPick = null;
      _skinPick = null;
      _pulsePick = null;
      _priorityPick = null;
    });
  }

  bool get _activeStepComplete {
    return switch (_activeStep) {
      _PrimaryStep.general => _generalPick != null,
      _PrimaryStep.loc => _locPick != null,
      _PrimaryStep.lifeThreat => _lifeThreatPick != null,
      _PrimaryStep.airwayBreathing => _abAssessmentPick != null && _ventilationPick != null && _oxygenPick != null,
      _PrimaryStep.circulation => _bleedingPick != null && _skinPick != null && _pulsePick != null,
      _PrimaryStep.priority => _priorityPick != null,
    };
  }

  int get _score {
    var earned = 0;
    if (_generalPick == _case.correctGeneralId) earned++;
    if (_locPick == _case.correctLocId) earned++;
    if (_lifeThreatPick == _case.correctLifeThreatId) earned++;
    if (_abAssessmentPick == _case.correctAbAssessmentId) earned++;
    if (_ventilationPick == _case.correctVentilationId) earned++;
    if (_oxygenPick == _case.correctOxygenId) earned++;
    if (_bleedingPick == _case.correctBleedingId) earned++;
    if (_skinPick == _case.correctSkinId) earned++;
    if (_pulsePick == _case.correctPulseId) earned++;
    if (_priorityPick == _case.correctPriorityId) earned++;
    return earned;
  }

  int get _scorePercent => (_score / 10 * 100).round();

  void _goNext() {
    if (!_activeStepComplete) return;
    setState(() {
      if (_activeStep == _PrimaryStep.priority) {
        _showResults = true;
      } else {
        _activeStep = _PrimaryStep.values[_activeStep.index + 1];
        _showResults = false;
      }
    });
  }

  void _goBack() {
    setState(() {
      _showResults = false;
      if (_activeStep.index > 0) _activeStep = _PrimaryStep.values[_activeStep.index - 1];
    });
  }

  bool _stepCorrect(_PrimaryStep step) {
    return switch (step) {
      _PrimaryStep.general => _generalPick == _case.correctGeneralId,
      _PrimaryStep.loc => _locPick == _case.correctLocId,
      _PrimaryStep.lifeThreat => _lifeThreatPick == _case.correctLifeThreatId,
      _PrimaryStep.airwayBreathing => _abAssessmentPick == _case.correctAbAssessmentId && _ventilationPick == _case.correctVentilationId && _oxygenPick == _case.correctOxygenId,
      _PrimaryStep.circulation => _bleedingPick == _case.correctBleedingId && _skinPick == _case.correctSkinId && _pulsePick == _case.correctPulseId,
      _PrimaryStep.priority => _priorityPick == _case.correctPriorityId,
    };
  }

  String _feedbackForStep(_PrimaryStep step) {
    if (_stepCorrect(step)) return _case.feedbackFor(step);
    return switch (step) {
      _PrimaryStep.general => 'Make a quick sick/not-sick general impression before you get pulled into details.',
      _PrimaryStep.loc => 'Responsiveness/LOC is part of the primary survey. Identify alert, verbal, pain, or unresponsive early.',
      _PrimaryStep.lifeThreat => 'Name the chief complaint and any apparent life threat before moving into SAMPLE or OPQRST.',
      _PrimaryStep.airwayBreathing => 'Airway and breathing problems must be assessed and managed before detailed history.',
      _PrimaryStep.circulation => 'Check for major bleeding, skin signs, and pulse. Do not miss hemorrhage or shock.',
      _PrimaryStep.priority => 'The transport decision should match the patient’s immediate risk and ABC findings.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return EMSVitalsScaffold(
      title: 'Primary Survey Simulator',
      subtitle: 'Practice general impression, responsiveness, chief complaint/life threats, airway/breathing, circulation, and transport priority.',
      onBackPressed: () => context.go(AppRoutes.assessmentTools),
      onInfoPressed: () {
        EMSInfoSheet.show(
          context,
          title: 'How this primary survey works',
          children: const [
            Text('This is the first patient-contact assessment after scene size-up. It is designed to find and treat immediate life threats before detailed history.'),
            SizedBox(height: 12),
            Text('The scoring mirrors common psychomotor testing logic: general impression, LOC, chief complaint/life threats, airway/breathing, ventilation, oxygen, bleeding, skin, pulse, and transport priority.'),
            SizedBox(height: 12),
            Text('Use local protocol and instructor judgment. This app is a training aid, not medical direction.'),
          ],
        );
      },
      bodySlivers: [
        SliverToBoxAdapter(
          child: EMSCentered(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PrimaryCaseHeader(caseData: _case, caseNumber: _caseIndex + 1, totalCases: _primaryCases.length),
                const SizedBox(height: 12),
                _PrimaryPatientCard(caseData: _case, activeStep: _activeStep),
                const SizedBox(height: 12),
                _PrimaryProgressBar(
                  activeStep: _activeStep,
                  completed: {
                    _PrimaryStep.general: _generalPick != null,
                    _PrimaryStep.loc: _locPick != null,
                    _PrimaryStep.lifeThreat: _lifeThreatPick != null,
                    _PrimaryStep.airwayBreathing: _abAssessmentPick != null && _ventilationPick != null && _oxygenPick != null,
                    _PrimaryStep.circulation: _bleedingPick != null && _skinPick != null && _pulsePick != null,
                    _PrimaryStep.priority: _priorityPick != null,
                  },
                  onTap: (step) => setState(() {
                    _activeStep = step;
                    _showResults = false;
                  }),
                ),
                const SizedBox(height: 12),
                if (!_showResults) ...[
                  _PrimaryDecisionCard(
                    caseData: _case,
                    step: _activeStep,
                    generalPick: _generalPick,
                    locPick: _locPick,
                    lifeThreatPick: _lifeThreatPick,
                    abAssessmentPick: _abAssessmentPick,
                    ventilationPick: _ventilationPick,
                    oxygenPick: _oxygenPick,
                    bleedingPick: _bleedingPick,
                    skinPick: _skinPick,
                    pulsePick: _pulsePick,
                    priorityPick: _priorityPick,
                    onGeneralPicked: (id) => setState(() => _generalPick = id),
                    onLocPicked: (id) => setState(() => _locPick = id),
                    onLifeThreatPicked: (id) => setState(() => _lifeThreatPick = id),
                    onAbAssessmentPicked: (id) => setState(() => _abAssessmentPick = id),
                    onVentilationPicked: (id) => setState(() => _ventilationPick = id),
                    onOxygenPicked: (id) => setState(() => _oxygenPick = id),
                    onBleedingPicked: (id) => setState(() => _bleedingPick = id),
                    onSkinPicked: (id) => setState(() => _skinPick = id),
                    onPulsePicked: (id) => setState(() => _pulsePick = id),
                    onPriorityPicked: (id) => setState(() => _priorityPick = id),
                  ),
                  const SizedBox(height: 12),
                  if (_activeStepComplete)
                    _PrimaryFeedbackCard(
                      title: _stepCorrect(_activeStep) ? 'Good primary survey decision' : 'Needs correction',
                      message: _feedbackForStep(_activeStep),
                      isCorrect: _stepCorrect(_activeStep),
                    ),
                  const SizedBox(height: 12),
                  _PrimaryNavigationControls(
                    activeStep: _activeStep,
                    canNext: _activeStepComplete,
                    onBack: _activeStep.index == 0 ? null : _goBack,
                    onNext: _goNext,
                    onReset: () => _resetCase(),
                  ),
                ] else ...[
                  _PrimaryResultsCard(
                    caseData: _case,
                    score: _score,
                    scorePercent: _scorePercent,
                    generalPick: _generalPick,
                    locPick: _locPick,
                    lifeThreatPick: _lifeThreatPick,
                    abAssessmentPick: _abAssessmentPick,
                    ventilationPick: _ventilationPick,
                    oxygenPick: _oxygenPick,
                    bleedingPick: _bleedingPick,
                    skinPick: _skinPick,
                    pulsePick: _pulsePick,
                    priorityPick: _priorityPick,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() {
                            _showResults = false;
                            _activeStep = _PrimaryStep.priority;
                          }),
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Review'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _resetCase(keepSameCase: false),
                          icon: const Icon(Icons.skip_next_rounded),
                          label: const Text('Next Case'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    onPressed: () => context.push(AppRoutes.abcAssessment),
                    icon: const Icon(Icons.air_rounded),
                    label: const Text('Focused ABC Drill'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryCaseHeader extends StatelessWidget {
  const _PrimaryCaseHeader({required this.caseData, required this.caseNumber, required this.totalCases});

  final _PrimaryCase caseData;
  final int caseNumber;
  final int totalCases;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: caseData.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: caseData.accent.withValues(alpha: 0.28)),
                  ),
                  child: Text('Case $caseNumber of $totalCases', style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w900, color: caseData.accent)),
                ),
                const Spacer(),
                Icon(caseData.icon, color: caseData.accent),
              ],
            ),
            const SizedBox(height: 10),
            Text(caseData.title, style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(caseData.dispatch, style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
          ],
        ),
      ),
    );
  }
}

class _PrimaryPatientCard extends StatelessWidget {
  const _PrimaryPatientCard({required this.caseData, required this.activeStep});

  final _PrimaryCase caseData;
  final _PrimaryStep activeStep;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 210,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [caseData.accent.withValues(alpha: 0.18), AppColors.emsCyan.withValues(alpha: 0.10)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(right: 14, top: 14, child: Icon(caseData.icon, size: 56, color: caseData.accent.withValues(alpha: 0.22))),
                Center(child: _PrimaryPatientFigure(caseData: caseData, activeStep: activeStep)),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SceneChip(icon: Icons.visibility_rounded, label: caseData.visualCue),
                      _SceneChip(icon: Icons.record_voice_over_rounded, label: caseData.patientCue),
                      _SceneChip(icon: Icons.monitor_heart_rounded, label: caseData.quickVitals),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Primary survey target', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(caseData.primaryTarget, style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryPatientFigure extends StatelessWidget {
  const _PrimaryPatientFigure({required this.caseData, required this.activeStep});

  final _PrimaryCase caseData;
  final _PrimaryStep activeStep;

  @override
  Widget build(BuildContext context) {
    final color = caseData.accent;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.38), width: 2),
          ),
          child: Icon(
            activeStep.icon,
            size: 42,
            color: color,
          ),
        ),
        const SizedBox(height: 12),
        Text(activeStep.shortLabel, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}

class _SceneChip extends StatelessWidget {
  const _SceneChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.emsBlue),
          const SizedBox(width: 6),
          Text(label, style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _PrimaryProgressBar extends StatelessWidget {
  const _PrimaryProgressBar({required this.activeStep, required this.completed, required this.onTap});

  final _PrimaryStep activeStep;
  final Map<_PrimaryStep, bool> completed;
  final ValueChanged<_PrimaryStep> onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final step in _PrimaryStep.values) ...[
                _ProgressPill(
                  step: step,
                  active: activeStep == step,
                  complete: completed[step] ?? false,
                  onTap: () => onTap(step),
                ),
                if (step != _PrimaryStep.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.step, required this.active, required this.complete, required this.onTap});

  final _PrimaryStep step;
  final bool active;
  final bool complete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = active ? AppColors.emsBlue : (complete ? const Color(0xFF22C55E) : cs.surfaceContainerHighest);
    final fg = active || complete ? Colors.white : cs.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      splashFactory: NoSplash.splashFactory,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(complete ? Icons.check_circle_rounded : step.icon, color: fg, size: 16),
            const SizedBox(width: 6),
            Text(step.shortLabel, style: context.textStyles.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _PrimaryDecisionCard extends StatelessWidget {
  const _PrimaryDecisionCard({
    required this.caseData,
    required this.step,
    required this.generalPick,
    required this.locPick,
    required this.lifeThreatPick,
    required this.abAssessmentPick,
    required this.ventilationPick,
    required this.oxygenPick,
    required this.bleedingPick,
    required this.skinPick,
    required this.pulsePick,
    required this.priorityPick,
    required this.onGeneralPicked,
    required this.onLocPicked,
    required this.onLifeThreatPicked,
    required this.onAbAssessmentPicked,
    required this.onVentilationPicked,
    required this.onOxygenPicked,
    required this.onBleedingPicked,
    required this.onSkinPicked,
    required this.onPulsePicked,
    required this.onPriorityPicked,
  });

  final _PrimaryCase caseData;
  final _PrimaryStep step;
  final String? generalPick;
  final String? locPick;
  final String? lifeThreatPick;
  final String? abAssessmentPick;
  final String? ventilationPick;
  final String? oxygenPick;
  final String? bleedingPick;
  final String? skinPick;
  final String? pulsePick;
  final String? priorityPick;
  final ValueChanged<String> onGeneralPicked;
  final ValueChanged<String> onLocPicked;
  final ValueChanged<String> onLifeThreatPicked;
  final ValueChanged<String> onAbAssessmentPicked;
  final ValueChanged<String> onVentilationPicked;
  final ValueChanged<String> onOxygenPicked;
  final ValueChanged<String> onBleedingPicked;
  final ValueChanged<String> onSkinPicked;
  final ValueChanged<String> onPulsePicked;
  final ValueChanged<String> onPriorityPicked;

  @override
  Widget build(BuildContext context) {
    return EMSSectionCard(
      title: step.title,
      subtitle: step.prompt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (step == _PrimaryStep.general)
            _ChoiceGroup(choices: caseData.generalOptions, selectedId: generalPick, correctId: caseData.correctGeneralId, onPicked: onGeneralPicked),
          if (step == _PrimaryStep.loc)
            _ChoiceGroup(choices: caseData.locOptions, selectedId: locPick, correctId: caseData.correctLocId, onPicked: onLocPicked),
          if (step == _PrimaryStep.lifeThreat)
            _ChoiceGroup(choices: caseData.lifeThreatOptions, selectedId: lifeThreatPick, correctId: caseData.correctLifeThreatId, onPicked: onLifeThreatPicked),
          if (step == _PrimaryStep.airwayBreathing) ...[
            _SubQuestion(title: '1. Assess airway and breathing', choices: caseData.abAssessmentOptions, selectedId: abAssessmentPick, correctId: caseData.correctAbAssessmentId, onPicked: onAbAssessmentPicked),
            const SizedBox(height: 12),
            _SubQuestion(title: '2. Assure adequate ventilation', choices: caseData.ventilationOptions, selectedId: ventilationPick, correctId: caseData.correctVentilationId, onPicked: onVentilationPicked),
            const SizedBox(height: 12),
            _SubQuestion(title: '3. Initiate appropriate oxygen decision', choices: caseData.oxygenOptions, selectedId: oxygenPick, correctId: caseData.correctOxygenId, onPicked: onOxygenPicked),
          ],
          if (step == _PrimaryStep.circulation) ...[
            _SubQuestion(title: '1. Major bleeding', choices: caseData.bleedingOptions, selectedId: bleedingPick, correctId: caseData.correctBleedingId, onPicked: onBleedingPicked),
            const SizedBox(height: 12),
            _SubQuestion(title: '2. Skin color / temperature / condition', choices: caseData.skinOptions, selectedId: skinPick, correctId: caseData.correctSkinId, onPicked: onSkinPicked),
            const SizedBox(height: 12),
            _SubQuestion(title: '3. Pulse', choices: caseData.pulseOptions, selectedId: pulsePick, correctId: caseData.correctPulseId, onPicked: onPulsePicked),
          ],
          if (step == _PrimaryStep.priority)
            _ChoiceGroup(choices: caseData.priorityOptions, selectedId: priorityPick, correctId: caseData.correctPriorityId, onPicked: onPriorityPicked),
        ],
      ),
    );
  }
}

class _SubQuestion extends StatelessWidget {
  const _SubQuestion({required this.title, required this.choices, required this.selectedId, required this.correctId, required this.onPicked});

  final String title;
  final List<_PrimaryChoice> choices;
  final String? selectedId;
  final String correctId;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        _ChoiceGroup(choices: choices, selectedId: selectedId, correctId: correctId, onPicked: onPicked),
      ],
    );
  }
}

class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({required this.choices, required this.selectedId, required this.correctId, required this.onPicked});

  final List<_PrimaryChoice> choices;
  final String? selectedId;
  final String correctId;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final choice in choices) ...[
          _ChoiceTile(
            choice: choice,
            selected: selectedId == choice.id,
            showCorrect: selectedId != null,
            correct: choice.id == correctId,
            onTap: () => onPicked(choice.id),
          ),
          if (choice != choices.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.choice, required this.selected, required this.showCorrect, required this.correct, required this.onTap});

  final _PrimaryChoice choice;
  final bool selected;
  final bool showCorrect;
  final bool correct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = selected ? (correct ? const Color(0xFF22C55E) : AppColors.danger) : cs.outline.withValues(alpha: 0.18);
    final bg = selected ? borderColor.withValues(alpha: 0.12) : cs.surface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      splashFactory: NoSplash.splashFactory,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? (correct ? Icons.check_circle_rounded : Icons.cancel_rounded) : choice.icon,
              color: selected ? borderColor : AppColors.emsBlue,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(choice.label, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w900)),
                  if (choice.detail != null) ...[
                    const SizedBox(height: 4),
                    Text(choice.detail!, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.3)),
                  ],
                ],
              ),
            ),
            if (showCorrect && correct) ...[
              const SizedBox(width: 8),
              const Icon(Icons.flag_circle_rounded, color: Color(0xFF22C55E), size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrimaryFeedbackCard extends StatelessWidget {
  const _PrimaryFeedbackCard({required this.title, required this.message, required this.isCorrect});

  final String title;
  final String message;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? const Color(0xFF22C55E) : AppColors.danger;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(isCorrect ? Icons.check_circle_rounded : Icons.warning_rounded, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: color)),
                  const SizedBox(height: 4),
                  Text(message, style: context.textStyles.bodyMedium?.copyWith(height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryNavigationControls extends StatelessWidget {
  const _PrimaryNavigationControls({required this.activeStep, required this.canNext, required this.onBack, required this.onNext, required this.onReset});

  final _PrimaryStep activeStep;
  final bool canNext;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.outlined(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded), tooltip: 'Back'),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Reset'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            onPressed: canNext ? onNext : null,
            icon: Icon(activeStep == _PrimaryStep.priority ? Icons.fact_check_rounded : Icons.arrow_forward_rounded),
            label: Text(activeStep == _PrimaryStep.priority ? 'Score' : 'Next'),
          ),
        ),
      ],
    );
  }
}

class _PrimaryResultsCard extends StatelessWidget {
  const _PrimaryResultsCard({
    required this.caseData,
    required this.score,
    required this.scorePercent,
    required this.generalPick,
    required this.locPick,
    required this.lifeThreatPick,
    required this.abAssessmentPick,
    required this.ventilationPick,
    required this.oxygenPick,
    required this.bleedingPick,
    required this.skinPick,
    required this.pulsePick,
    required this.priorityPick,
  });

  final _PrimaryCase caseData;
  final int score;
  final int scorePercent;
  final String? generalPick;
  final String? locPick;
  final String? lifeThreatPick;
  final String? abAssessmentPick;
  final String? ventilationPick;
  final String? oxygenPick;
  final String? bleedingPick;
  final String? skinPick;
  final String? pulsePick;
  final String? priorityPick;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final critical = _criticalMisses;
    return EMSSectionCard(
      title: 'Primary Survey Summary',
      subtitle: '$score / 10 points • $scorePercent%',
      trailing: CircleAvatar(
        backgroundColor: (scorePercent >= 80 ? const Color(0xFF22C55E) : AppColors.danger).withValues(alpha: 0.16),
        child: Text('$score', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ResultRow(title: 'General impression', picked: caseData.labelFor(generalPick, caseData.generalOptions), correct: caseData.labelFor(caseData.correctGeneralId, caseData.generalOptions), ok: generalPick == caseData.correctGeneralId),
          _ResultRow(title: 'Responsiveness / LOC', picked: caseData.labelFor(locPick, caseData.locOptions), correct: caseData.labelFor(caseData.correctLocId, caseData.locOptions), ok: locPick == caseData.correctLocId),
          _ResultRow(title: 'Chief complaint / life threats', picked: caseData.labelFor(lifeThreatPick, caseData.lifeThreatOptions), correct: caseData.labelFor(caseData.correctLifeThreatId, caseData.lifeThreatOptions), ok: lifeThreatPick == caseData.correctLifeThreatId),
          _ResultRow(title: 'Airway / breathing assessment', picked: caseData.labelFor(abAssessmentPick, caseData.abAssessmentOptions), correct: caseData.labelFor(caseData.correctAbAssessmentId, caseData.abAssessmentOptions), ok: abAssessmentPick == caseData.correctAbAssessmentId),
          _ResultRow(title: 'Adequate ventilation', picked: caseData.labelFor(ventilationPick, caseData.ventilationOptions), correct: caseData.labelFor(caseData.correctVentilationId, caseData.ventilationOptions), ok: ventilationPick == caseData.correctVentilationId),
          _ResultRow(title: 'Oxygen decision', picked: caseData.labelFor(oxygenPick, caseData.oxygenOptions), correct: caseData.labelFor(caseData.correctOxygenId, caseData.oxygenOptions), ok: oxygenPick == caseData.correctOxygenId),
          _ResultRow(title: 'Major bleeding', picked: caseData.labelFor(bleedingPick, caseData.bleedingOptions), correct: caseData.labelFor(caseData.correctBleedingId, caseData.bleedingOptions), ok: bleedingPick == caseData.correctBleedingId),
          _ResultRow(title: 'Skin signs', picked: caseData.labelFor(skinPick, caseData.skinOptions), correct: caseData.labelFor(caseData.correctSkinId, caseData.skinOptions), ok: skinPick == caseData.correctSkinId),
          _ResultRow(title: 'Pulse', picked: caseData.labelFor(pulsePick, caseData.pulseOptions), correct: caseData.labelFor(caseData.correctPulseId, caseData.pulseOptions), ok: pulsePick == caseData.correctPulseId),
          _ResultRow(title: 'Priority / transport', picked: caseData.labelFor(priorityPick, caseData.priorityOptions), correct: caseData.labelFor(caseData.correctPriorityId, caseData.priorityOptions), ok: priorityPick == caseData.correctPriorityId),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Instructor teaching point', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(caseData.instructorPoint, style: context.textStyles.bodyMedium?.copyWith(height: 1.35)),
              ],
            ),
          ),
          if (critical.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_rounded, color: AppColors.danger, size: 20),
                      const SizedBox(width: 8),
                      Text('Critical miss review', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: AppColors.danger)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final miss in critical) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $miss', style: context.textStyles.bodySmall?.copyWith(height: 1.3))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<String> get _criticalMisses {
    final misses = <String>[];
    if (abAssessmentPick != caseData.correctAbAssessmentId || ventilationPick != caseData.correctVentilationId) misses.add('Recheck airway/breathing and adequate ventilation.');
    if (oxygenPick != caseData.correctOxygenId && caseData.requiresOxygenAction) misses.add('Oxygen or ventilation support was not matched to the patient presentation.');
    if (bleedingPick != caseData.correctBleedingId && caseData.requiresBleedingControl) misses.add('Major bleeding was not controlled early.');
    if ((skinPick != caseData.correctSkinId || pulsePick != caseData.correctPulseId) && caseData.shockConcern) misses.add('Shock/hypoperfusion clues were missed.');
    if (priorityPick != caseData.correctPriorityId && caseData.highPriority) misses.add('Transport priority did not match the life threat.');
    return misses;
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.title, required this.picked, required this.correct, required this.ok});

  final String title;
  final String picked;
  final String correct;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = ok ? const Color(0xFF22C55E) : AppColors.danger;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text('Picked: $picked', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                if (!ok) Text('Correct: $correct', style: context.textStyles.bodySmall?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _PrimaryStep { general, loc, lifeThreat, airwayBreathing, circulation, priority }

extension _PrimaryStepX on _PrimaryStep {
  String get shortLabel => switch (this) {
    _PrimaryStep.general => 'General',
    _PrimaryStep.loc => 'LOC',
    _PrimaryStep.lifeThreat => 'Life threats',
    _PrimaryStep.airwayBreathing => 'A/B',
    _PrimaryStep.circulation => 'C',
    _PrimaryStep.priority => 'Priority',
  };

  String get title => switch (this) {
    _PrimaryStep.general => 'General impression',
    _PrimaryStep.loc => 'Responsiveness / Level of consciousness',
    _PrimaryStep.lifeThreat => 'Chief complaint / Apparent life threats',
    _PrimaryStep.airwayBreathing => 'Airway and breathing',
    _PrimaryStep.circulation => 'Circulation',
    _PrimaryStep.priority => 'Priority patient / Transport decision',
  };

  String get prompt => switch (this) {
    _PrimaryStep.general => 'What is your first sick/not-sick impression from the doorway?',
    _PrimaryStep.loc => 'How responsive is this patient right now?',
    _PrimaryStep.lifeThreat => 'What primary problem or obvious life threat should you verbalize?',
    _PrimaryStep.airwayBreathing => 'Assess airway and breathing, assure ventilation, and choose the correct oxygen decision.',
    _PrimaryStep.circulation => 'Assess/control major bleeding, evaluate skin signs, and assess pulse.',
    _PrimaryStep.priority => 'Decide whether this patient needs immediate transport or continued assessment/treatment on scene.',
  };

  IconData get icon => switch (this) {
    _PrimaryStep.general => Icons.visibility_rounded,
    _PrimaryStep.loc => Icons.psychology_rounded,
    _PrimaryStep.lifeThreat => Icons.report_problem_rounded,
    _PrimaryStep.airwayBreathing => Icons.air_rounded,
    _PrimaryStep.circulation => Icons.monitor_heart_rounded,
    _PrimaryStep.priority => Icons.local_shipping_rounded,
  };
}

@immutable
class _PrimaryChoice {
  const _PrimaryChoice({required this.id, required this.label, this.detail, this.icon = Icons.radio_button_unchecked_rounded});

  final String id;
  final String label;
  final String? detail;
  final IconData icon;
}

@immutable
class _PrimaryCase {
  const _PrimaryCase({
    required this.title,
    required this.dispatch,
    required this.visualCue,
    required this.patientCue,
    required this.quickVitals,
    required this.primaryTarget,
    required this.instructorPoint,
    required this.accent,
    required this.icon,
    required this.generalOptions,
    required this.correctGeneralId,
    required this.locOptions,
    required this.correctLocId,
    required this.lifeThreatOptions,
    required this.correctLifeThreatId,
    required this.abAssessmentOptions,
    required this.correctAbAssessmentId,
    required this.ventilationOptions,
    required this.correctVentilationId,
    required this.oxygenOptions,
    required this.correctOxygenId,
    required this.bleedingOptions,
    required this.correctBleedingId,
    required this.skinOptions,
    required this.correctSkinId,
    required this.pulseOptions,
    required this.correctPulseId,
    required this.priorityOptions,
    required this.correctPriorityId,
    this.requiresOxygenAction = false,
    this.requiresBleedingControl = false,
    this.shockConcern = false,
    this.highPriority = false,
  });

  final String title;
  final String dispatch;
  final String visualCue;
  final String patientCue;
  final String quickVitals;
  final String primaryTarget;
  final String instructorPoint;
  final Color accent;
  final IconData icon;
  final List<_PrimaryChoice> generalOptions;
  final String correctGeneralId;
  final List<_PrimaryChoice> locOptions;
  final String correctLocId;
  final List<_PrimaryChoice> lifeThreatOptions;
  final String correctLifeThreatId;
  final List<_PrimaryChoice> abAssessmentOptions;
  final String correctAbAssessmentId;
  final List<_PrimaryChoice> ventilationOptions;
  final String correctVentilationId;
  final List<_PrimaryChoice> oxygenOptions;
  final String correctOxygenId;
  final List<_PrimaryChoice> bleedingOptions;
  final String correctBleedingId;
  final List<_PrimaryChoice> skinOptions;
  final String correctSkinId;
  final List<_PrimaryChoice> pulseOptions;
  final String correctPulseId;
  final List<_PrimaryChoice> priorityOptions;
  final String correctPriorityId;
  final bool requiresOxygenAction;
  final bool requiresBleedingControl;
  final bool shockConcern;
  final bool highPriority;

  String labelFor(String? id, List<_PrimaryChoice> choices) {
    if (id == null) return 'No answer';
    for (final choice in choices) {
      if (choice.id == id) return choice.label;
    }
    return 'Unknown';
  }

  String feedbackFor(_PrimaryStep step) {
    return switch (step) {
      _PrimaryStep.general => 'Good. You verbalized the doorway impression before moving into detailed assessment.',
      _PrimaryStep.loc => 'Good. LOC/responsiveness gives an early neurologic and perfusion clue.',
      _PrimaryStep.lifeThreat => 'Good. You identified the chief complaint or apparent life threat early.',
      _PrimaryStep.airwayBreathing => 'Good. Airway, breathing, ventilation, and oxygen decisions come before history.',
      _PrimaryStep.circulation => 'Good. Circulation includes bleeding, skin signs, and pulse quality.',
      _PrimaryStep.priority => 'Good. Your transport decision matches the primary survey findings.',
    };
  }
}

const List<_PrimaryChoice> _generalOptions = [
  _PrimaryChoice(id: 'stable', label: 'Appears stable / not sick', detail: 'No obvious distress; continue with primary survey.', icon: Icons.sentiment_satisfied_rounded),
  _PrimaryChoice(id: 'potentially_unstable', label: 'Potentially unstable', detail: 'Concerning symptoms but no immediate ABC failure seen yet.', icon: Icons.warning_amber_rounded),
  _PrimaryChoice(id: 'sick', label: 'Sick / unstable appearance', detail: 'Immediate life threat may be present; move quickly through ABC.', icon: Icons.emergency_rounded),
];

const List<_PrimaryChoice> _locOptions = [
  _PrimaryChoice(id: 'alert', label: 'Alert', detail: 'Awake and answers appropriately.', icon: Icons.record_voice_over_rounded),
  _PrimaryChoice(id: 'verbal', label: 'Responds to verbal', detail: 'Not fully alert but responds when spoken to.', icon: Icons.hearing_rounded),
  _PrimaryChoice(id: 'pain', label: 'Responds to pain only', detail: 'Significantly altered mental status.', icon: Icons.front_hand_rounded),
  _PrimaryChoice(id: 'unresponsive', label: 'Unresponsive', detail: 'No response to voice or pain; check airway, breathing, pulse quickly.', icon: Icons.report_rounded),
];

const List<_PrimaryChoice> _priorityOptions = [
  _PrimaryChoice(id: 'continue_scene', label: 'Continue assessment/treatment on scene', detail: 'No immediate ABC threat after primary survey.', icon: Icons.fact_check_rounded),
  _PrimaryChoice(id: 'rapid_transport', label: 'Priority patient — rapid transport / ALS', detail: 'High-risk findings require fast transport and/or ALS.', icon: Icons.local_shipping_rounded),
  _PrimaryChoice(id: 'resuscitate', label: 'Immediate resuscitation: CPR/AED/BVM', detail: 'Cardiac arrest or peri-arrest care starts now.', icon: Icons.electric_bolt_rounded),
];

const List<_PrimaryCase> _primaryCases = [
  _PrimaryCase(
    title: 'Stable chest discomfort',
    dispatch: '56-year-old male in a living room with chest pressure. Scene size-up complete and safe.',
    visualCue: 'Sitting upright',
    patientCue: 'Speaks full sentences',
    quickVitals: 'SpO₂ 97%, pulse strong',
    primaryTarget: 'Do not skip the primary survey just because the patient can talk. Confirm LOC, ABC, circulation, and priority.',
    instructorPoint: 'A stable medical patient still gets a complete primary survey before SAMPLE/OPQRST and vitals.',
    accent: Color(0xFF2563EB),
    icon: Icons.favorite_rounded,
    generalOptions: _generalOptions,
    correctGeneralId: 'potentially_unstable',
    locOptions: _locOptions,
    correctLocId: 'alert',
    lifeThreatOptions: [
      _PrimaryChoice(id: 'chest_pain_no_abc', label: 'Chief complaint: chest pressure; no immediate ABC life threat', detail: 'Continue primary survey and prepare cardiac-focused assessment.', icon: Icons.favorite_rounded),
      _PrimaryChoice(id: 'airway_obstructed', label: 'Apparent life threat: obstructed airway', detail: 'Would be suggested by choking, gurgling, snoring, or inability to speak.', icon: Icons.air_rounded),
      _PrimaryChoice(id: 'major_bleeding', label: 'Apparent life threat: major bleeding', detail: 'No visible major bleeding is present.', icon: Icons.bloodtype_rounded),
    ],
    correctLifeThreatId: 'chest_pain_no_abc',
    abAssessmentOptions: [
      _PrimaryChoice(id: 'patent_adequate', label: 'Airway patent; breathing adequate', detail: 'Speaks full sentences, normal work of breathing.', icon: Icons.check_circle_rounded),
      _PrimaryChoice(id: 'inadequate_breathing', label: 'Breathing inadequate', detail: 'Would require immediate ventilation support.', icon: Icons.air_rounded),
      _PrimaryChoice(id: 'obstructed', label: 'Airway obstructed', detail: 'Not supported by the scene cues.', icon: Icons.warning_rounded),
    ],
    correctAbAssessmentId: 'patent_adequate',
    ventilationOptions: [
      _PrimaryChoice(id: 'monitor', label: 'Ventilation adequate — monitor', detail: 'No BVM needed right now.', icon: Icons.visibility_rounded),
      _PrimaryChoice(id: 'bvm', label: 'Assist ventilations with BVM', detail: 'Too aggressive for this presentation.', icon: Icons.masks_rounded),
      _PrimaryChoice(id: 'ignore', label: 'Skip breathing because patient is talking', detail: 'Talking is useful, but you still assess breathing.', icon: Icons.skip_next_rounded),
    ],
    correctVentilationId: 'monitor',
    oxygenOptions: [
      _PrimaryChoice(id: 'not_indicated', label: 'No immediate oxygen; monitor SpO₂ per protocol', detail: 'SpO₂ is normal and breathing is adequate.', icon: Icons.monitor_heart_rounded),
      _PrimaryChoice(id: 'nrb', label: 'High-flow oxygen by non-rebreather', detail: 'Usually reserved for hypoxia/respiratory distress per protocol.', icon: Icons.airline_seat_flat_rounded),
      _PrimaryChoice(id: 'bvm_o2', label: 'BVM with oxygen', detail: 'Used for inadequate ventilation or apnea.', icon: Icons.masks_rounded),
    ],
    correctOxygenId: 'not_indicated',
    bleedingOptions: [
      _PrimaryChoice(id: 'none', label: 'No major bleeding seen', detail: 'Continue circulation assessment.', icon: Icons.check_circle_outline_rounded),
      _PrimaryChoice(id: 'tourniquet', label: 'Apply tourniquet immediately', detail: 'No extremity hemorrhage is present.', icon: Icons.bloodtype_rounded),
      _PrimaryChoice(id: 'skip_bleeding', label: 'Skip bleeding check on medical calls', detail: 'Major bleeding check is still part of circulation.', icon: Icons.skip_next_rounded),
    ],
    correctBleedingId: 'none',
    skinOptions: [
      _PrimaryChoice(id: 'normal', label: 'Skin warm, pink, dry', detail: 'No shock clue in skin signs right now.', icon: Icons.wb_sunny_rounded),
      _PrimaryChoice(id: 'shock', label: 'Skin pale, cool, diaphoretic', detail: 'This would raise shock concern.', icon: Icons.ac_unit_rounded),
      _PrimaryChoice(id: 'cyanotic', label: 'Cyanotic skin', detail: 'Would strongly suggest hypoxia.', icon: Icons.water_drop_rounded),
    ],
    correctSkinId: 'normal',
    pulseOptions: [
      _PrimaryChoice(id: 'strong_regular', label: 'Pulse present, strong, regular', detail: 'Document quality and rate trend.', icon: Icons.monitor_heart_rounded),
      _PrimaryChoice(id: 'weak_rapid', label: 'Pulse rapid and weak', detail: 'Would suggest shock or poor perfusion.', icon: Icons.show_chart_rounded),
      _PrimaryChoice(id: 'absent', label: 'No pulse', detail: 'Would trigger CPR/AED.', icon: Icons.heart_broken_rounded),
    ],
    correctPulseId: 'strong_regular',
    priorityOptions: _priorityOptions,
    correctPriorityId: 'continue_scene',
  ),
  _PrimaryCase(
    title: 'Severe respiratory distress',
    dispatch: '68-year-old female with shortness of breath. She is tripod, anxious, and speaking 2-word sentences.',
    visualCue: 'Tripod position',
    patientCue: '2-word sentences',
    quickVitals: 'RR 34, SpO₂ 86%',
    primaryTarget: 'Recognize breathing as the immediate problem and support oxygenation/ventilation early.',
    instructorPoint: 'A patient who cannot speak full sentences with low SpO₂ is high priority. Treat breathing before extended history.',
    accent: Color(0xFFF97316),
    icon: Icons.air_rounded,
    generalOptions: _generalOptions,
    correctGeneralId: 'sick',
    locOptions: _locOptions,
    correctLocId: 'alert',
    lifeThreatOptions: [
      _PrimaryChoice(id: 'resp_distress', label: 'Apparent life threat: respiratory distress', detail: 'Short phrases, increased work of breathing, and low SpO₂.', icon: Icons.air_rounded),
      _PrimaryChoice(id: 'isolated_pain', label: 'Chief complaint: mild pain only', detail: 'This misses the breathing problem.', icon: Icons.sentiment_satisfied_rounded),
      _PrimaryChoice(id: 'major_bleeding', label: 'Apparent life threat: major bleeding', detail: 'No hemorrhage is described.', icon: Icons.bloodtype_rounded),
    ],
    correctLifeThreatId: 'resp_distress',
    abAssessmentOptions: [
      _PrimaryChoice(id: 'distress', label: 'Airway open; breathing severely distressed', detail: 'She can speak but is not breathing adequately enough.', icon: Icons.warning_rounded),
      _PrimaryChoice(id: 'patent_adequate', label: 'Airway patent; breathing normal', detail: 'Low SpO₂ and short phrases are abnormal.', icon: Icons.check_circle_rounded),
      _PrimaryChoice(id: 'obstructed', label: 'Complete airway obstruction', detail: 'She is still speaking, so not complete obstruction.', icon: Icons.block_rounded),
    ],
    correctAbAssessmentId: 'distress',
    ventilationOptions: [
      _PrimaryChoice(id: 'support_position_prepare_bvm', label: 'Position of comfort; prepare to assist ventilations if fatigue/poor tidal volume', detail: 'Support breathing and reassess closely.', icon: Icons.event_seat_rounded),
      _PrimaryChoice(id: 'monitor_only', label: 'Monitor only; no immediate action', detail: 'Misses severe respiratory distress.', icon: Icons.visibility_rounded),
      _PrimaryChoice(id: 'cpr', label: 'Start CPR immediately', detail: 'She has a pulse and is breathing, though poorly.', icon: Icons.electric_bolt_rounded),
    ],
    correctVentilationId: 'support_position_prepare_bvm',
    oxygenOptions: [
      _PrimaryChoice(id: 'high_flow_o2', label: 'Administer oxygen per protocol', detail: 'Low SpO₂ and distress require oxygen decision now.', icon: Icons.air_rounded),
      _PrimaryChoice(id: 'not_indicated', label: 'No oxygen; SpO₂ can wait until vitals', detail: 'Oxygenation is a primary survey issue here.', icon: Icons.skip_next_rounded),
      _PrimaryChoice(id: 'room_air', label: 'Room air only', detail: 'Not appropriate for hypoxia.', icon: Icons.close_rounded),
    ],
    correctOxygenId: 'high_flow_o2',
    bleedingOptions: [
      _PrimaryChoice(id: 'none', label: 'No major bleeding seen', detail: 'Continue circulation assessment.', icon: Icons.check_circle_outline_rounded),
      _PrimaryChoice(id: 'tourniquet', label: 'Apply tourniquet immediately', detail: 'No bleeding is present.', icon: Icons.bloodtype_rounded),
      _PrimaryChoice(id: 'skip', label: 'Skip circulation because breathing is the only issue', detail: 'You still assess circulation.', icon: Icons.skip_next_rounded),
    ],
    correctBleedingId: 'none',
    skinOptions: [
      _PrimaryChoice(id: 'pale_diaphoretic', label: 'Skin pale and diaphoretic', detail: 'Concerning perfusion/respiratory distress clue.', icon: Icons.ac_unit_rounded),
      _PrimaryChoice(id: 'normal', label: 'Warm, pink, dry', detail: 'Does not match the cue.', icon: Icons.wb_sunny_rounded),
      _PrimaryChoice(id: 'rash', label: 'Hives/rash only', detail: 'No rash is described.', icon: Icons.grain_rounded),
    ],
    correctSkinId: 'pale_diaphoretic',
    pulseOptions: [
      _PrimaryChoice(id: 'rapid_present', label: 'Pulse rapid and present', detail: 'Expected with respiratory distress.', icon: Icons.show_chart_rounded),
      _PrimaryChoice(id: 'absent', label: 'No pulse', detail: 'Would be cardiac arrest.', icon: Icons.heart_broken_rounded),
      _PrimaryChoice(id: 'normal_slow', label: 'Slow regular pulse', detail: 'Does not match distress.', icon: Icons.monitor_heart_rounded),
    ],
    correctPulseId: 'rapid_present',
    priorityOptions: _priorityOptions,
    correctPriorityId: 'rapid_transport',
    requiresOxygenAction: true,
    shockConcern: true,
    highPriority: true,
  ),
  _PrimaryCase(
    title: 'Unresponsive with snoring respirations',
    dispatch: 'Adult found on bedroom floor. No trauma signs. Patient does not answer questions and has loud snoring respirations.',
    visualCue: 'Supine on floor',
    patientCue: 'No verbal response',
    quickVitals: 'Slow noisy breathing',
    primaryTarget: 'Unresponsive patients need immediate airway positioning and ventilation assessment before history.',
    instructorPoint: 'Snoring suggests partial upper-airway obstruction. Open the airway, reassess breathing, and support ventilation/oxygenation as indicated.',
    accent: Color(0xFF7C3AED),
    icon: Icons.psychology_alt_rounded,
    generalOptions: _generalOptions,
    correctGeneralId: 'sick',
    locOptions: _locOptions,
    correctLocId: 'unresponsive',
    lifeThreatOptions: [
      _PrimaryChoice(id: 'airway_breathing', label: 'Apparent life threat: airway/breathing problem', detail: 'Unresponsive with snoring respirations.', icon: Icons.air_rounded),
      _PrimaryChoice(id: 'stable_sleeping', label: 'Appears asleep; no immediate life threat', detail: 'Unresponsive is not the same as sleeping.', icon: Icons.bedtime_rounded),
      _PrimaryChoice(id: 'isolated_leg_pain', label: 'Chief complaint: leg pain', detail: 'No leg complaint is available.', icon: Icons.accessibility_new_rounded),
    ],
    correctLifeThreatId: 'airway_breathing',
    abAssessmentOptions: [
      _PrimaryChoice(id: 'partial_obstruction', label: 'Airway partially obstructed; breathing inadequate/noisy', detail: 'Snoring respirations and unresponsive presentation.', icon: Icons.warning_rounded),
      _PrimaryChoice(id: 'normal', label: 'Airway and breathing normal', detail: 'Snoring and unresponsive is abnormal.', icon: Icons.check_circle_rounded),
      _PrimaryChoice(id: 'complete_obstruction', label: 'Complete obstruction', detail: 'There is still air movement/noisy breathing.', icon: Icons.block_rounded),
    ],
    correctAbAssessmentId: 'partial_obstruction',
    ventilationOptions: [
      _PrimaryChoice(id: 'open_airway_reassess_bvm', label: 'Open airway, reassess breathing, support with BVM if inadequate', detail: 'Treat the airway first.', icon: Icons.air_rounded),
      _PrimaryChoice(id: 'history_first', label: 'Ask SAMPLE from bystanders first', detail: 'Do not delay airway management.', icon: Icons.history_edu_rounded),
      _PrimaryChoice(id: 'sit_patient_up', label: 'Sit the patient up and wait', detail: 'Unresponsive airway needs positioning and reassessment.', icon: Icons.event_seat_rounded),
    ],
    correctVentilationId: 'open_airway_reassess_bvm',
    oxygenOptions: [
      _PrimaryChoice(id: 'oxygen_with_ventilation', label: 'Use oxygen with airway/ventilation support as indicated', detail: 'Oxygenation is addressed during airway/breathing care.', icon: Icons.masks_rounded),
      _PrimaryChoice(id: 'not_indicated', label: 'No oxygen because skin is not cyanotic yet', detail: 'Do not wait for cyanosis.', icon: Icons.close_rounded),
      _PrimaryChoice(id: 'only_nc', label: 'Nasal cannula only and move on', detail: 'May be inadequate if ventilation is poor.', icon: Icons.air_rounded),
    ],
    correctOxygenId: 'oxygen_with_ventilation',
    bleedingOptions: [
      _PrimaryChoice(id: 'none', label: 'No major bleeding seen', detail: 'Continue circulation assessment.', icon: Icons.check_circle_outline_rounded),
      _PrimaryChoice(id: 'pressure', label: 'Direct pressure for major hemorrhage', detail: 'No hemorrhage seen.', icon: Icons.bloodtype_rounded),
      _PrimaryChoice(id: 'skip', label: 'Skip bleeding check', detail: 'Major bleeding still must be checked.', icon: Icons.skip_next_rounded),
    ],
    correctBleedingId: 'none',
    skinOptions: [
      _PrimaryChoice(id: 'cool_pale', label: 'Skin cool/pale', detail: 'Abnormal perfusion/oxygenation clue.', icon: Icons.ac_unit_rounded),
      _PrimaryChoice(id: 'normal', label: 'Warm, pink, dry', detail: 'Does not match the case cue.', icon: Icons.wb_sunny_rounded),
      _PrimaryChoice(id: 'flushed_hot', label: 'Flushed and hot', detail: 'Not the best match.', icon: Icons.local_fire_department_rounded),
    ],
    correctSkinId: 'cool_pale',
    pulseOptions: [
      _PrimaryChoice(id: 'present_weak', label: 'Pulse present but weak', detail: 'Continue to manage airway/breathing and transport priority.', icon: Icons.monitor_heart_rounded),
      _PrimaryChoice(id: 'absent', label: 'No pulse', detail: 'This case has a pulse present.', icon: Icons.heart_broken_rounded),
      _PrimaryChoice(id: 'bounding_normal', label: 'Strong bounding normal pulse', detail: 'Not the best match for this sick presentation.', icon: Icons.show_chart_rounded),
    ],
    correctPulseId: 'present_weak',
    priorityOptions: _priorityOptions,
    correctPriorityId: 'rapid_transport',
    requiresOxygenAction: true,
    shockConcern: true,
    highPriority: true,
  ),
  _PrimaryCase(
    title: 'Major bleeding and shock',
    dispatch: '32-year-old with deep arm laceration from broken glass. Blood is pooling on the floor. Scene is now safe.',
    visualCue: 'Large blood pool',
    patientCue: 'Confused, weak voice',
    quickVitals: 'Rapid weak pulse',
    primaryTarget: 'Recognize hemorrhage as a life threat during circulation and control it immediately.',
    instructorPoint: 'Major bleeding is a primary survey problem. Control hemorrhage before detailed history or secondary assessment.',
    accent: Color(0xFFE5484D),
    icon: Icons.bloodtype_rounded,
    generalOptions: _generalOptions,
    correctGeneralId: 'sick',
    locOptions: _locOptions,
    correctLocId: 'verbal',
    lifeThreatOptions: [
      _PrimaryChoice(id: 'hemorrhage', label: 'Apparent life threat: uncontrolled major bleeding', detail: 'Blood pooling and weak/confused patient.', icon: Icons.bloodtype_rounded),
      _PrimaryChoice(id: 'minor_cut', label: 'Chief complaint: minor cut only', detail: 'This misses the severity.', icon: Icons.healing_rounded),
      _PrimaryChoice(id: 'normal_breathing_only', label: 'Only breathing needs assessment', detail: 'Breathing matters, but hemorrhage is obvious here.', icon: Icons.air_rounded),
    ],
    correctLifeThreatId: 'hemorrhage',
    abAssessmentOptions: [
      _PrimaryChoice(id: 'patent_fast', label: 'Airway patent; breathing fast but adequate', detail: 'Tachypnea can be from shock/pain.', icon: Icons.air_rounded),
      _PrimaryChoice(id: 'obstructed', label: 'Airway obstructed', detail: 'No obstruction cue.', icon: Icons.block_rounded),
      _PrimaryChoice(id: 'apnea', label: 'No breathing', detail: 'Patient is speaking weakly.', icon: Icons.close_rounded),
    ],
    correctAbAssessmentId: 'patent_fast',
    ventilationOptions: [
      _PrimaryChoice(id: 'monitor', label: 'Ventilation currently adequate — monitor closely', detail: 'No BVM unless ventilation becomes inadequate.', icon: Icons.visibility_rounded),
      _PrimaryChoice(id: 'bvm', label: 'Assist ventilations immediately', detail: 'No inadequate ventilation cue.', icon: Icons.masks_rounded),
      _PrimaryChoice(id: 'skip_ab', label: 'Skip A/B because bleeding is obvious', detail: 'A/B still come before C, but keep it fast.', icon: Icons.skip_next_rounded),
    ],
    correctVentilationId: 'monitor',
    oxygenOptions: [
      _PrimaryChoice(id: 'oxygen_for_shock', label: 'Consider oxygen per protocol for shock/poor perfusion', detail: 'Treating shock includes oxygen decision per protocol.', icon: Icons.air_rounded),
      _PrimaryChoice(id: 'not_indicated', label: 'No oxygen decision needed', detail: 'Shock is a high-risk condition.', icon: Icons.close_rounded),
      _PrimaryChoice(id: 'bvm_o2', label: 'BVM with oxygen immediately', detail: 'Not needed unless ventilation is inadequate.', icon: Icons.masks_rounded),
    ],
    correctOxygenId: 'oxygen_for_shock',
    bleedingOptions: [
      _PrimaryChoice(id: 'control_bleeding', label: 'Control major bleeding now', detail: 'Direct pressure/tourniquet/hemostatic dressing per protocol.', icon: Icons.front_hand_rounded),
      _PrimaryChoice(id: 'later', label: 'Leave bleeding until after SAMPLE', detail: 'Critical miss: hemorrhage control cannot wait.', icon: Icons.history_edu_rounded),
      _PrimaryChoice(id: 'none', label: 'No major bleeding seen', detail: 'Blood pooling is major bleeding.', icon: Icons.close_rounded),
    ],
    correctBleedingId: 'control_bleeding',
    skinOptions: [
      _PrimaryChoice(id: 'pale_cool_diaphoretic', label: 'Skin pale, cool, diaphoretic', detail: 'Shock/hypoperfusion clue.', icon: Icons.ac_unit_rounded),
      _PrimaryChoice(id: 'normal', label: 'Warm, pink, dry', detail: 'Does not match shock.', icon: Icons.wb_sunny_rounded),
      _PrimaryChoice(id: 'rash', label: 'Hives/rash', detail: 'Not described.', icon: Icons.grain_rounded),
    ],
    correctSkinId: 'pale_cool_diaphoretic',
    pulseOptions: [
      _PrimaryChoice(id: 'rapid_weak', label: 'Pulse rapid and weak', detail: 'Shock/hypoperfusion sign.', icon: Icons.show_chart_rounded),
      _PrimaryChoice(id: 'strong_regular', label: 'Strong regular pulse', detail: 'Does not match shock.', icon: Icons.monitor_heart_rounded),
      _PrimaryChoice(id: 'absent', label: 'No pulse', detail: 'Not cardiac arrest in this case.', icon: Icons.heart_broken_rounded),
    ],
    correctPulseId: 'rapid_weak',
    priorityOptions: _priorityOptions,
    correctPriorityId: 'rapid_transport',
    requiresOxygenAction: true,
    requiresBleedingControl: true,
    shockConcern: true,
    highPriority: true,
  ),
  _PrimaryCase(
    title: 'Cardiac arrest recognition',
    dispatch: 'Bystanders report an adult collapsed in a gym. Scene is safe. Patient is supine and motionless.',
    visualCue: 'No movement',
    patientCue: 'No response',
    quickVitals: 'No normal breathing',
    primaryTarget: 'Rapidly recognize unresponsive, no normal breathing, no pulse — start CPR/AED and ventilations.',
    instructorPoint: 'Do not continue a normal assessment flow after recognizing cardiac arrest. CPR/AED and ventilation support take priority.',
    accent: Color(0xFFDC2626),
    icon: Icons.electric_bolt_rounded,
    generalOptions: _generalOptions,
    correctGeneralId: 'sick',
    locOptions: _locOptions,
    correctLocId: 'unresponsive',
    lifeThreatOptions: [
      _PrimaryChoice(id: 'cardiac_arrest', label: 'Apparent life threat: cardiac arrest', detail: 'Unresponsive with no normal breathing.', icon: Icons.electric_bolt_rounded),
      _PrimaryChoice(id: 'stable_syncope', label: 'Likely stable syncope; take history first', detail: 'Do not delay pulse/breathing assessment.', icon: Icons.history_edu_rounded),
      _PrimaryChoice(id: 'minor_injury', label: 'Chief complaint: minor injury', detail: 'No response/no normal breathing is life threatening.', icon: Icons.healing_rounded),
    ],
    correctLifeThreatId: 'cardiac_arrest',
    abAssessmentOptions: [
      _PrimaryChoice(id: 'no_normal_breathing', label: 'Airway check; no normal breathing/agonal', detail: 'Move quickly to pulse check and resuscitation.', icon: Icons.warning_rounded),
      _PrimaryChoice(id: 'normal', label: 'Breathing normal', detail: 'No normal breathing is stated.', icon: Icons.check_circle_rounded),
      _PrimaryChoice(id: 'speaking', label: 'Airway patent because patient can speak', detail: 'Patient is unresponsive and not speaking.', icon: Icons.record_voice_over_rounded),
    ],
    correctAbAssessmentId: 'no_normal_breathing',
    ventilationOptions: [
      _PrimaryChoice(id: 'bvm_cpr', label: 'Begin CPR/AED pathway and provide ventilations with BVM/oxygen', detail: 'Resuscitation actions start immediately.', icon: Icons.masks_rounded),
      _PrimaryChoice(id: 'wait', label: 'Wait for ALS before ventilating', detail: 'Do not delay BLS resuscitation.', icon: Icons.hourglass_empty_rounded),
      _PrimaryChoice(id: 'ask_sample', label: 'Ask SAMPLE before touching patient', detail: 'History comes after immediate life threats.', icon: Icons.history_edu_rounded),
    ],
    correctVentilationId: 'bvm_cpr',
    oxygenOptions: [
      _PrimaryChoice(id: 'oxygen_bvm', label: 'Oxygen with BVM during resuscitation', detail: 'Appropriate for cardiac arrest ventilation support.', icon: Icons.air_rounded),
      _PrimaryChoice(id: 'not_indicated', label: 'No oxygen because patient has no pulse', detail: 'Ventilation/oxygenation are part of arrest care.', icon: Icons.close_rounded),
      _PrimaryChoice(id: 'nasal_cannula', label: 'Nasal cannula only', detail: 'Insufficient for apnea/agonal breathing.', icon: Icons.air_rounded),
    ],
    correctOxygenId: 'oxygen_bvm',
    bleedingOptions: [
      _PrimaryChoice(id: 'none', label: 'No major bleeding seen', detail: 'Proceed to pulse assessment and CPR/AED.', icon: Icons.check_circle_outline_rounded),
      _PrimaryChoice(id: 'tourniquet', label: 'Apply tourniquet', detail: 'No bleeding described.', icon: Icons.bloodtype_rounded),
      _PrimaryChoice(id: 'ignore_c', label: 'Skip circulation assessment', detail: 'Pulse assessment is essential.', icon: Icons.skip_next_rounded),
    ],
    correctBleedingId: 'none',
    skinOptions: [
      _PrimaryChoice(id: 'poor', label: 'Skin pale/cyanotic/poor perfusion', detail: 'Consistent with arrest.', icon: Icons.water_drop_rounded),
      _PrimaryChoice(id: 'normal', label: 'Warm, pink, dry', detail: 'Not expected in this presentation.', icon: Icons.wb_sunny_rounded),
      _PrimaryChoice(id: 'rash', label: 'Hives/rash', detail: 'Not described.', icon: Icons.grain_rounded),
    ],
    correctSkinId: 'poor',
    pulseOptions: [
      _PrimaryChoice(id: 'absent', label: 'No pulse', detail: 'Start/continue CPR and AED.', icon: Icons.heart_broken_rounded),
      _PrimaryChoice(id: 'rapid_weak', label: 'Pulse rapid and weak', detail: 'This would be shock, not arrest.', icon: Icons.show_chart_rounded),
      _PrimaryChoice(id: 'strong_regular', label: 'Pulse strong and regular', detail: 'Does not match arrest.', icon: Icons.monitor_heart_rounded),
    ],
    correctPulseId: 'absent',
    priorityOptions: _priorityOptions,
    correctPriorityId: 'resuscitate',
    requiresOxygenAction: true,
    shockConcern: true,
    highPriority: true,
  ),
  _PrimaryCase(
    title: 'Fall with possible spinal injury',
    dispatch: '44-year-old fell from a ladder. Scene is safe. Patient is awake, complaining of neck pain and tingling in both hands.',
    visualCue: 'Fall mechanism',
    patientCue: 'Neck pain + tingling',
    quickVitals: 'Breathing normal',
    primaryTarget: 'Primary survey stays ABC-focused while you protect spine and recognize neurologic red flags.',
    instructorPoint: 'Spinal protection is considered during scene size-up, but the primary survey still checks life threats and priority.',
    accent: Color(0xFF0EA5E9),
    icon: Icons.personal_injury_rounded,
    generalOptions: _generalOptions,
    correctGeneralId: 'potentially_unstable',
    locOptions: _locOptions,
    correctLocId: 'alert',
    lifeThreatOptions: [
      _PrimaryChoice(id: 'trauma_neuro', label: 'Chief complaint: fall with possible spine/neurologic injury', detail: 'Neck pain and hand tingling are concerning.', icon: Icons.personal_injury_rounded),
      _PrimaryChoice(id: 'resp_failure', label: 'Apparent life threat: respiratory failure', detail: 'Breathing is currently normal.', icon: Icons.air_rounded),
      _PrimaryChoice(id: 'cardiac_arrest', label: 'Apparent life threat: cardiac arrest', detail: 'Patient is awake and speaking.', icon: Icons.electric_bolt_rounded),
    ],
    correctLifeThreatId: 'trauma_neuro',
    abAssessmentOptions: [
      _PrimaryChoice(id: 'patent_adequate', label: 'Airway patent; breathing adequate', detail: 'Patient speaks and has normal breathing.', icon: Icons.check_circle_rounded),
      _PrimaryChoice(id: 'obstructed', label: 'Airway obstructed', detail: 'No obstruction cues.', icon: Icons.block_rounded),
      _PrimaryChoice(id: 'inadequate', label: 'Breathing inadequate', detail: 'No distress/inadequate breathing cues.', icon: Icons.warning_rounded),
    ],
    correctAbAssessmentId: 'patent_adequate',
    ventilationOptions: [
      _PrimaryChoice(id: 'monitor', label: 'Ventilation adequate — monitor', detail: 'Continue spinal precautions and reassess.', icon: Icons.visibility_rounded),
      _PrimaryChoice(id: 'bvm', label: 'Assist ventilations immediately', detail: 'Not indicated unless ventilation becomes inadequate.', icon: Icons.masks_rounded),
      _PrimaryChoice(id: 'skip', label: 'Skip A/B because trauma is orthopedic', detail: 'A/B must still be assessed.', icon: Icons.skip_next_rounded),
    ],
    correctVentilationId: 'monitor',
    oxygenOptions: [
      _PrimaryChoice(id: 'not_indicated', label: 'No immediate oxygen; monitor SpO₂ per protocol', detail: 'Breathing is adequate and no hypoxia cue is present.', icon: Icons.monitor_heart_rounded),
      _PrimaryChoice(id: 'nrb', label: 'High-flow oxygen for every fall', detail: 'Use patient findings and protocol.', icon: Icons.air_rounded),
      _PrimaryChoice(id: 'bvm_o2', label: 'BVM with oxygen', detail: 'For inadequate ventilation/apnea.', icon: Icons.masks_rounded),
    ],
    correctOxygenId: 'not_indicated',
    bleedingOptions: [
      _PrimaryChoice(id: 'none', label: 'No major bleeding seen', detail: 'Continue circulation assessment.', icon: Icons.check_circle_outline_rounded),
      _PrimaryChoice(id: 'pressure', label: 'Direct pressure for major hemorrhage', detail: 'No hemorrhage described.', icon: Icons.bloodtype_rounded),
      _PrimaryChoice(id: 'skip', label: 'Skip bleeding check', detail: 'Major bleeding check is always quick and early.', icon: Icons.skip_next_rounded),
    ],
    correctBleedingId: 'none',
    skinOptions: [
      _PrimaryChoice(id: 'normal', label: 'Skin warm, pink, dry', detail: 'No shock clue is given.', icon: Icons.wb_sunny_rounded),
      _PrimaryChoice(id: 'shock', label: 'Pale, cool, diaphoretic', detail: 'Would increase concern for shock.', icon: Icons.ac_unit_rounded),
      _PrimaryChoice(id: 'cyanotic', label: 'Cyanotic', detail: 'Would suggest oxygenation problem.', icon: Icons.water_drop_rounded),
    ],
    correctSkinId: 'normal',
    pulseOptions: [
      _PrimaryChoice(id: 'strong_regular', label: 'Pulse present, strong, regular', detail: 'No shock/arrest cue.', icon: Icons.monitor_heart_rounded),
      _PrimaryChoice(id: 'rapid_weak', label: 'Rapid weak pulse', detail: 'Would suggest shock.', icon: Icons.show_chart_rounded),
      _PrimaryChoice(id: 'absent', label: 'No pulse', detail: 'Not supported by awake patient.', icon: Icons.heart_broken_rounded),
    ],
    correctPulseId: 'strong_regular',
    priorityOptions: _priorityOptions,
    correctPriorityId: 'rapid_transport',
    highPriority: true,
  ),
];
