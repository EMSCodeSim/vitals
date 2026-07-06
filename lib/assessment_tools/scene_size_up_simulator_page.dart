import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SceneSizeUpSimulatorPage extends StatefulWidget {
  const SceneSizeUpSimulatorPage({super.key});

  @override
  State<SceneSizeUpSimulatorPage> createState() => _SceneSizeUpSimulatorPageState();
}

class _SceneSizeUpSimulatorPageState extends State<SceneSizeUpSimulatorPage> {
  int _caseIndex = 0;
  _SceneStep _activeStep = _SceneStep.safety;
  bool _showResults = false;

  String? _safetyPick;
  final Set<String> _resourcePicks = <String>{};
  final Set<String> _ppePicks = <String>{};
  String? _naturePick;
  String? _patientCountPick;
  String? _cSpinePick;

  _SceneCase get _case => _sceneCases[_caseIndex];

  void _resetCase({bool keepSameCase = true}) {
    setState(() {
      if (!keepSameCase) _caseIndex = (_caseIndex + 1) % _sceneCases.length;
      _activeStep = _SceneStep.safety;
      _showResults = false;
      _safetyPick = null;
      _resourcePicks.clear();
      _ppePicks.clear();
      _naturePick = null;
      _patientCountPick = null;
      _cSpinePick = null;
    });
  }

  bool get _activeStepComplete {
    return switch (_activeStep) {
      _SceneStep.safety => _safetyPick != null,
      _SceneStep.resources => _resourcePicks.isNotEmpty,
      _SceneStep.ppe => _ppePicks.isNotEmpty,
      _SceneStep.nature => _naturePick != null,
      _SceneStep.patientCount => _patientCountPick != null,
      _SceneStep.cSpine => _cSpinePick != null,
    };
  }

  void _goNext() {
    if (!_activeStepComplete) return;
    setState(() {
      if (_activeStep == _SceneStep.cSpine) {
        _showResults = true;
        return;
      }
      _activeStep = _SceneStep.values[_activeStep.index + 1];
      _showResults = false;
    });
  }

  void _goBack() {
    setState(() {
      _showResults = false;
      if (_activeStep.index > 0) {
        _activeStep = _SceneStep.values[_activeStep.index - 1];
      }
    });
  }

  int get _score {
    var earned = 0;
    if (_safetyPick == _case.correctSafetyId) earned++;
    if (_setsMatch(_resourcePicks, _case.correctResourceIds)) earned++;
    if (_setsMatch(_ppePicks, _case.correctPpeIds)) earned++;
    if (_naturePick == _case.correctNatureId) earned++;
    if (_patientCountPick == _case.correctPatientCountId) earned++;
    if (_cSpinePick == _case.correctCSpineId) earned++;
    return earned;
  }

  int get _scorePercent => (_score / 6 * 100).round();

  static bool _setsMatch(Set<String> student, Set<String> correct) {
    return student.length == correct.length && student.containsAll(correct);
  }

  void _toggleResource(String id) {
    setState(() {
      if (id == 'none') {
        _resourcePicks
          ..clear()
          ..add(id);
        return;
      }
      _resourcePicks.remove('none');
      if (!_resourcePicks.add(id)) _resourcePicks.remove(id);
    });
  }

  void _togglePpe(String id) {
    setState(() {
      if (id == 'standard') {
        _ppePicks
          ..clear()
          ..add(id);
        return;
      }
      _ppePicks.remove('standard');
      if (!_ppePicks.add(id)) _ppePicks.remove(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return EMSVitalsScaffold(
      title: 'Scene Size-Up Simulator',
      subtitle: 'Show the scene, read dispatch info, decide if it is safe, request resources, select PPE, determine illness/injury, count patients, and consider C-spine.',
      onBackPressed: () => context.go(AppRoutes.assessmentTools),
      onInfoPressed: () {
        EMSInfoSheet.show(
          context,
          title: 'How this simulator works',
          children: const [
            Text('This drill practices the first part of patient assessment before ABC: scene safety, PPE, resources, nature of illness/mechanism of injury, patient count, and spinal precautions.'),
            SizedBox(height: 12),
            Text('Students should not touch the patient until they make a safe-entry decision and choose reasonable PPE. Use instructor judgment and local protocols for final grading.'),
          ],
        );
      },
      bodySlivers: [
        SliverToBoxAdapter(
          child: EMSCentered(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SceneCaseHeader(caseData: _case, caseNumber: _caseIndex + 1, totalCases: _sceneCases.length),
                const SizedBox(height: 12),
                _SceneImageCard(caseData: _case),
                const SizedBox(height: 12),
                _SceneProgressBar(
                  activeStep: _activeStep,
                  completed: {
                    _SceneStep.safety: _safetyPick != null,
                    _SceneStep.resources: _resourcePicks.isNotEmpty,
                    _SceneStep.ppe: _ppePicks.isNotEmpty,
                    _SceneStep.nature: _naturePick != null,
                    _SceneStep.patientCount: _patientCountPick != null,
                    _SceneStep.cSpine: _cSpinePick != null,
                  },
                  onTap: (step) => setState(() {
                    _activeStep = step;
                    _showResults = false;
                  }),
                ),
                const SizedBox(height: 12),
                if (!_showResults) ...[
                  _SceneDecisionCard(
                    step: _activeStep,
                    caseData: _case,
                    safetyPick: _safetyPick,
                    resourcePicks: _resourcePicks,
                    ppePicks: _ppePicks,
                    naturePick: _naturePick,
                    patientCountPick: _patientCountPick,
                    cSpinePick: _cSpinePick,
                    onSafetyPicked: (id) => setState(() => _safetyPick = id),
                    onResourceToggled: _toggleResource,
                    onPpeToggled: _togglePpe,
                    onNaturePicked: (id) => setState(() => _naturePick = id),
                    onPatientCountPicked: (id) => setState(() => _patientCountPick = id),
                    onCSpinePicked: (id) => setState(() => _cSpinePick = id),
                  ),
                  const SizedBox(height: 12),
                  if (_activeStepComplete)
                    _InlineFeedback(
                      title: _feedbackTitleForStep(_activeStep),
                      message: _feedbackMessageForStep(_activeStep),
                      isCorrect: _stepIsCorrect(_activeStep),
                    ),
                  const SizedBox(height: 12),
                  _SceneNavigationControls(
                    activeStep: _activeStep,
                    canNext: _activeStepComplete,
                    onBack: _activeStep.index == 0 ? null : _goBack,
                    onNext: _goNext,
                    onReset: () => _resetCase(),
                  ),
                ] else ...[
                  _SceneResultsCard(
                    caseData: _case,
                    score: _score,
                    scorePercent: _scorePercent,
                    safetyPick: _safetyPick,
                    resourcePicks: _resourcePicks,
                    ppePicks: _ppePicks,
                    naturePick: _naturePick,
                    patientCountPick: _patientCountPick,
                    cSpinePick: _cSpinePick,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() {
                            _showResults = false;
                            _activeStep = _SceneStep.cSpine;
                          }),
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Review'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.push(AppRoutes.abcAssessment),
                          icon: const Icon(Icons.air_rounded),
                          label: const Text('Continue to ABC'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    onPressed: () => _resetCase(keepSameCase: false),
                    icon: const Icon(Icons.skip_next_rounded),
                    label: const Text('Try Next Scene'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _stepIsCorrect(_SceneStep step) {
    return switch (step) {
      _SceneStep.safety => _safetyPick == _case.correctSafetyId,
      _SceneStep.resources => _setsMatch(_resourcePicks, _case.correctResourceIds),
      _SceneStep.ppe => _setsMatch(_ppePicks, _case.correctPpeIds),
      _SceneStep.nature => _naturePick == _case.correctNatureId,
      _SceneStep.patientCount => _patientCountPick == _case.correctPatientCountId,
      _SceneStep.cSpine => _cSpinePick == _case.correctCSpineId,
    };
  }

  String _feedbackTitleForStep(_SceneStep step) => _stepIsCorrect(step) ? 'Good scene-size-up decision' : 'Needs correction';

  String _feedbackMessageForStep(_SceneStep step) {
    final correct = _stepIsCorrect(step);
    if (correct) return _case.feedbackFor(step);
    return switch (step) {
      _SceneStep.safety => 'Recheck the hazards in the image before entry. Scene safety comes before patient contact.',
      _SceneStep.resources => 'Pick the resources that make the scene safe or help manage the patient problem. Avoid adding unnecessary resources if none are needed.',
      _SceneStep.ppe => 'Match PPE to the hazard: body substances, respiratory risk, roadway visibility, and environmental danger.',
      _SceneStep.nature => 'Use dispatch information and visual clues to decide if this is medical, trauma, environmental, behavioral, or unknown.',
      _SceneStep.patientCount => 'Count all obvious patients and consider whether additional patients may be hidden or walking wounded.',
      _SceneStep.cSpine => 'Consider C-spine/spinal motion restriction when there is trauma, fall, MVC, axial load, altered mental status with trauma, or concerning mechanism.',
    };
  }
}

class _SceneCaseHeader extends StatelessWidget {
  const _SceneCaseHeader({required this.caseData, required this.caseNumber, required this.totalCases});

  final _SceneCase caseData;
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
                  decoration: BoxDecoration(color: AppColors.emsBlue.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                  child: Text('Scene $caseNumber of $totalCases', style: context.textStyles.labelMedium?.copyWith(color: AppColors.emsBlue, fontWeight: FontWeight.w900)),
                ),
                const Spacer(),
                Icon(caseData.icon, color: caseData.accent),
              ],
            ),
            const SizedBox(height: 10),
            Text(caseData.title, style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(caseData.dispatchInfo, style: context.textStyles.bodyMedium?.copyWith(height: 1.4, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _SceneImageCard extends StatelessWidget {
  const _SceneImageCard({required this.caseData});

  final _SceneCase caseData;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [caseData.accent.withValues(alpha: 0.20), AppColors.emsCyan.withValues(alpha: 0.10)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: _SceneBackdropPainter(caseData.accent))),
                  Positioned(left: 22, bottom: 22, child: _PersonFigure(color: caseData.accent, label: caseData.patientLabel)),
                  for (final marker in caseData.markers)
                    Positioned(
                      left: marker.x,
                      top: marker.y,
                      child: _SceneMarkerChip(marker: marker),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Visible scene information', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                for (final clue in caseData.visibleClues) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 7, color: cs.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(child: Text(clue, style: context.textStyles.bodySmall?.copyWith(height: 1.35, color: cs.onSurfaceVariant))),
                    ],
                  ),
                  const SizedBox(height: 5),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneBackdropPainter extends CustomPainter {
  const _SceneBackdropPainter(this.accent);

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()..color = Colors.black.withValues(alpha: 0.08);
    final floorPaint = Paint()..color = Colors.white.withValues(alpha: 0.20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.05, size.height * 0.66, size.width * 0.90, size.height * 0.20), const Radius.circular(20)),
      roadPaint,
    );
    canvas.drawCircle(Offset(size.width * 0.86, size.height * 0.18), size.width * 0.12, Paint()..color = accent.withValues(alpha: 0.08));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.08, size.height * 0.12, size.width * 0.38, size.height * 0.18), const Radius.circular(18)),
      floorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SceneBackdropPainter oldDelegate) => oldDelegate.accent != accent;
}

class _PersonFigure extends StatelessWidget {
  const _PersonFigure({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 76,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.74), borderRadius: BorderRadius.circular(28), border: Border.all(color: color.withValues(alpha: 0.28), width: 2)),
          child: Icon(Icons.accessibility_new_rounded, color: color, size: 48),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.86), borderRadius: BorderRadius.circular(999)),
          child: Text(label, style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: color)),
        ),
      ],
    );
  }
}

class _SceneMarkerChip extends StatelessWidget {
  const _SceneMarkerChip({required this.marker});

  final _SceneMarker marker;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.88), borderRadius: BorderRadius.circular(999), border: Border.all(color: marker.color.withValues(alpha: 0.28))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(marker.icon, color: marker.color, size: 18),
          const SizedBox(width: 5),
          Text(marker.label, style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: marker.color)),
        ],
      ),
    );
  }
}

class _SceneProgressBar extends StatelessWidget {
  const _SceneProgressBar({required this.activeStep, required this.completed, required this.onTap});

  final _SceneStep activeStep;
  final Map<_SceneStep, bool> completed;
  final ValueChanged<_SceneStep> onTap;

  @override
  Widget build(BuildContext context) {
    return EMSSectionCard(
      title: 'Scene size-up flow',
      subtitle: 'Tap any step to review. The simulator scores all six decisions.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final step in _SceneStep.values)
            ChoiceChip(
              selected: activeStep == step,
              showCheckmark: false,
              avatar: Icon(completed[step] == true ? Icons.check_circle : step.icon, size: 18, color: completed[step] == true ? Colors.green : null),
              label: Text(step.shortLabel),
              onSelected: (_) => onTap(step),
            ),
        ],
      ),
    );
  }
}

class _SceneDecisionCard extends StatelessWidget {
  const _SceneDecisionCard({
    required this.step,
    required this.caseData,
    required this.safetyPick,
    required this.resourcePicks,
    required this.ppePicks,
    required this.naturePick,
    required this.patientCountPick,
    required this.cSpinePick,
    required this.onSafetyPicked,
    required this.onResourceToggled,
    required this.onPpeToggled,
    required this.onNaturePicked,
    required this.onPatientCountPicked,
    required this.onCSpinePicked,
  });

  final _SceneStep step;
  final _SceneCase caseData;
  final String? safetyPick;
  final Set<String> resourcePicks;
  final Set<String> ppePicks;
  final String? naturePick;
  final String? patientCountPick;
  final String? cSpinePick;
  final ValueChanged<String> onSafetyPicked;
  final ValueChanged<String> onResourceToggled;
  final ValueChanged<String> onPpeToggled;
  final ValueChanged<String> onNaturePicked;
  final ValueChanged<String> onPatientCountPicked;
  final ValueChanged<String> onCSpinePicked;

  @override
  Widget build(BuildContext context) {
    return EMSSectionCard(
      title: step.title,
      subtitle: step.prompt,
      child: switch (step) {
        _SceneStep.safety => _SingleChoiceList(options: _safetyOptions, selectedId: safetyPick, onPicked: onSafetyPicked),
        _SceneStep.resources => _MultiChoiceList(options: _resourceOptions, selectedIds: resourcePicks, onToggled: onResourceToggled),
        _SceneStep.ppe => _MultiChoiceList(options: _ppeOptions, selectedIds: ppePicks, onToggled: onPpeToggled),
        _SceneStep.nature => _SingleChoiceList(options: _natureOptions, selectedId: naturePick, onPicked: onNaturePicked),
        _SceneStep.patientCount => _SingleChoiceList(options: _patientCountOptions, selectedId: patientCountPick, onPicked: onPatientCountPicked),
        _SceneStep.cSpine => _SingleChoiceList(options: _cSpineOptions, selectedId: cSpinePick, onPicked: onCSpinePicked),
      },
    );
  }
}

class _SingleChoiceList extends StatelessWidget {
  const _SingleChoiceList({required this.options, required this.selectedId, required this.onPicked});

  final List<_ChoiceOption> options;
  final String? selectedId;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final option in options) ...[
          _ChoiceTile(
            title: option.title,
            subtitle: option.subtitle,
            icon: option.icon,
            selected: selectedId == option.id,
            onTap: () => onPicked(option.id),
          ),
          if (option != options.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _MultiChoiceList extends StatelessWidget {
  const _MultiChoiceList({required this.options, required this.selectedIds, required this.onToggled});

  final List<_ChoiceOption> options;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final option in options) ...[
          _ChoiceTile(
            title: option.title,
            subtitle: option.subtitle,
            icon: option.icon,
            selected: selectedIds.contains(option.id),
            multiSelect: true,
            onTap: () => onToggled(option.id),
          ),
          if (option != options.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.title, required this.subtitle, required this.icon, required this.selected, required this.onTap, this.multiSelect = false});

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool multiSelect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashFactory: NoSplash.splashFactory,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer.withValues(alpha: 0.60) : cs.surfaceContainerHighest.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? cs.primary : cs.outline.withValues(alpha: 0.16), width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? cs.primary : cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: context.textStyles.bodySmall?.copyWith(height: 1.3, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(selected ? (multiSelect ? Icons.check_box_rounded : Icons.radio_button_checked_rounded) : (multiSelect ? Icons.check_box_outline_blank_rounded : Icons.radio_button_unchecked_rounded), color: selected ? cs.primary : cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _InlineFeedback extends StatelessWidget {
  const _InlineFeedback({required this.title, required this.message, required this.isCorrect});

  final String title;
  final String message;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return EMSResultBox(title: title, message: message, kind: isCorrect ? EMSResultKind.success : EMSResultKind.warning);
  }
}

class _SceneNavigationControls extends StatelessWidget {
  const _SceneNavigationControls({required this.activeStep, required this.canNext, required this.onBack, required this.onNext, required this.onReset});

  final _SceneStep activeStep;
  final bool canNext;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.outlined(onPressed: onReset, icon: const Icon(Icons.refresh_rounded), tooltip: 'Reset scene'),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: canNext ? onNext : null,
            icon: Icon(activeStep == _SceneStep.cSpine ? Icons.fact_check_rounded : Icons.arrow_forward_rounded),
            label: Text(activeStep == _SceneStep.cSpine ? 'Score Scene' : 'Next'),
          ),
        ),
      ],
    );
  }
}

class _SceneResultsCard extends StatelessWidget {
  const _SceneResultsCard({
    required this.caseData,
    required this.score,
    required this.scorePercent,
    required this.safetyPick,
    required this.resourcePicks,
    required this.ppePicks,
    required this.naturePick,
    required this.patientCountPick,
    required this.cSpinePick,
  });

  final _SceneCase caseData;
  final int score;
  final int scorePercent;
  final String? safetyPick;
  final Set<String> resourcePicks;
  final Set<String> ppePicks;
  final String? naturePick;
  final String? patientCountPick;
  final String? cSpinePick;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final criticalMisses = _criticalMisses;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _scoreColor.withValues(alpha: 0.12),
                    border: Border.all(color: _scoreColor.withValues(alpha: 0.32), width: 3),
                  ),
                  child: Text('$scorePercent%', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: _scoreColor)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Scene Size-Up Score', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('$score of 6 decisions correct', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (criticalMisses.isEmpty)
              const EMSResultBox(title: 'No critical scene-safety miss', message: 'Student can move into general impression and ABC assessment.', kind: EMSResultKind.success)
            else
              EMSResultBox(title: 'Critical miss to review', message: criticalMisses.join('\n'), kind: EMSResultKind.error),
            const SizedBox(height: 12),
            _ResultLine(label: 'Scene safe?', student: _labelFor(_safetyOptions, safetyPick), correct: _labelFor(_safetyOptions, caseData.correctSafetyId), correctMatch: safetyPick == caseData.correctSafetyId),
            _ResultLine(label: 'Resources', student: _labelsFor(_resourceOptions, resourcePicks), correct: _labelsFor(_resourceOptions, caseData.correctResourceIds), correctMatch: _setsMatch(resourcePicks, caseData.correctResourceIds)),
            _ResultLine(label: 'PPE', student: _labelsFor(_ppeOptions, ppePicks), correct: _labelsFor(_ppeOptions, caseData.correctPpeIds), correctMatch: _setsMatch(ppePicks, caseData.correctPpeIds)),
            _ResultLine(label: 'NOI/MOI', student: _labelFor(_natureOptions, naturePick), correct: _labelFor(_natureOptions, caseData.correctNatureId), correctMatch: naturePick == caseData.correctNatureId),
            _ResultLine(label: 'Patients', student: _labelFor(_patientCountOptions, patientCountPick), correct: _labelFor(_patientCountOptions, caseData.correctPatientCountId), correctMatch: patientCountPick == caseData.correctPatientCountId),
            _ResultLine(label: 'C-spine', student: _labelFor(_cSpineOptions, cSpinePick), correct: _labelFor(_cSpineOptions, caseData.correctCSpineId), correctMatch: cSpinePick == caseData.correctCSpineId),
            const SizedBox(height: 12),
            EMSResultBox(title: 'Instructor teaching point', message: caseData.teachingPoint, kind: EMSResultKind.info),
          ],
        ),
      ),
    );
  }

  Color get _scoreColor {
    if (scorePercent >= 85) return Colors.green.shade700;
    if (scorePercent >= 70) return Colors.orange.shade700;
    return AppColors.danger;
  }

  List<String> get _criticalMisses {
    final misses = <String>[];
    if (safetyPick != caseData.correctSafetyId && caseData.correctSafetyId == 'unsafe') {
      misses.add('Entered or declared the scene safe when hazards still required control.');
    }
    if (!_ppePicksContainsMinimum()) {
      misses.add('PPE selection did not cover the likely exposure risk.');
    }
    if (cSpinePick != caseData.correctCSpineId && caseData.correctCSpineId == 'consider') {
      misses.add('Did not consider C-spine/spinal motion restriction for a concerning trauma mechanism.');
    }
    return misses;
  }

  bool _ppePicksContainsMinimum() => ppePicks.containsAll(caseData.minimumCriticalPpeIds);

  static bool _setsMatch(Set<String> student, Set<String> correct) {
    return student.length == correct.length && student.containsAll(correct);
  }

  static String _labelFor(List<_ChoiceOption> options, String? id) {
    if (id == null) return 'No answer';
    return options.firstWhere((o) => o.id == id, orElse: () => _ChoiceOption(id: id, title: id, subtitle: '', icon: Icons.help)).title;
  }

  static String _labelsFor(List<_ChoiceOption> options, Set<String> ids) {
    if (ids.isEmpty) return 'No answer';
    return options.where((o) => ids.contains(o.id)).map((o) => o.title).join(', ');
  }
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({required this.label, required this.student, required this.correct, required this.correctMatch});

  final String label;
  final String student;
  final String correct;
  final bool correctMatch;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: correctMatch ? Colors.green.withValues(alpha: 0.08) : AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: correctMatch ? Colors.green.withValues(alpha: 0.22) : AppColors.danger.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(correctMatch ? Icons.check_circle : Icons.cancel, color: correctMatch ? Colors.green : AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text('Student: $student', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.3)),
                if (!correctMatch) Text('Correct: $correct', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _SceneStep {
  safety,
  resources,
  ppe,
  nature,
  patientCount,
  cSpine;

  String get title => switch (this) {
    _SceneStep.safety => 'Scene safe or not safe?',
    _SceneStep.resources => 'Request additional resources',
    _SceneStep.ppe => 'Choose PPE for the scene',
    _SceneStep.nature => 'Nature of illness or injury',
    _SceneStep.patientCount => 'Number of patients',
    _SceneStep.cSpine => 'Consider C-spine',
  };

  String get shortLabel => switch (this) {
    _SceneStep.safety => 'Safety',
    _SceneStep.resources => 'Resources',
    _SceneStep.ppe => 'PPE',
    _SceneStep.nature => 'NOI/MOI',
    _SceneStep.patientCount => 'Patients',
    _SceneStep.cSpine => 'C-spine',
  };

  String get prompt => switch (this) {
    _SceneStep.safety => 'Based on the image and dispatch information, can the crew enter now?',
    _SceneStep.resources => 'Choose the extra resources needed before or during patient contact.',
    _SceneStep.ppe => 'Choose all PPE that should be used for this specific scene.',
    _SceneStep.nature => 'Decide the main nature of illness or mechanism of injury.',
    _SceneStep.patientCount => 'Determine how many patients need assessment.',
    _SceneStep.cSpine => 'Decide whether spinal precautions should be considered early.',
  };

  IconData get icon => switch (this) {
    _SceneStep.safety => Icons.shield_rounded,
    _SceneStep.resources => Icons.local_fire_department_rounded,
    _SceneStep.ppe => Icons.masks_rounded,
    _SceneStep.nature => Icons.manage_search_rounded,
    _SceneStep.patientCount => Icons.groups_rounded,
    _SceneStep.cSpine => Icons.accessibility_new_rounded,
  };
}

class _SceneCase {
  const _SceneCase({
    required this.title,
    required this.dispatchInfo,
    required this.patientLabel,
    required this.icon,
    required this.accent,
    required this.visibleClues,
    required this.markers,
    required this.correctSafetyId,
    required this.correctResourceIds,
    required this.correctPpeIds,
    required this.minimumCriticalPpeIds,
    required this.correctNatureId,
    required this.correctPatientCountId,
    required this.correctCSpineId,
    required this.stepFeedback,
    required this.teachingPoint,
  });

  final String title;
  final String dispatchInfo;
  final String patientLabel;
  final IconData icon;
  final Color accent;
  final List<String> visibleClues;
  final List<_SceneMarker> markers;
  final String correctSafetyId;
  final Set<String> correctResourceIds;
  final Set<String> correctPpeIds;
  final Set<String> minimumCriticalPpeIds;
  final String correctNatureId;
  final String correctPatientCountId;
  final String correctCSpineId;
  final Map<_SceneStep, String> stepFeedback;
  final String teachingPoint;

  String feedbackFor(_SceneStep step) => stepFeedback[step] ?? 'Correct for this scene.';
}

class _SceneMarker {
  const _SceneMarker({required this.label, required this.icon, required this.color, required this.x, required this.y});

  final String label;
  final IconData icon;
  final Color color;
  final double x;
  final double y;
}

class _ChoiceOption {
  const _ChoiceOption({required this.id, required this.title, required this.subtitle, required this.icon});

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
}

const List<_ChoiceOption> _safetyOptions = [
  _ChoiceOption(id: 'safe', title: 'Scene safe to enter', subtitle: 'No immediate hazard preventing patient contact.', icon: Icons.check_circle_rounded),
  _ChoiceOption(id: 'unsafe', title: 'Not safe yet / stage', subtitle: 'Hazard needs control before entering or touching patient.', icon: Icons.warning_amber_rounded),
];

const List<_ChoiceOption> _resourceOptions = [
  _ChoiceOption(id: 'none', title: 'No additional resources', subtitle: 'Crew can safely continue with available resources.', icon: Icons.check_rounded),
  _ChoiceOption(id: 'law', title: 'Law enforcement', subtitle: 'Violence, weapon, unsafe bystander, or scene security concern.', icon: Icons.local_police_rounded),
  _ChoiceOption(id: 'fire', title: 'Fire / rescue', subtitle: 'Extrication, fire, CO, ventilation, unstable vehicle, or rescue hazard.', icon: Icons.local_fire_department_rounded),
  _ChoiceOption(id: 'traffic', title: 'Traffic control', subtitle: 'Roadway, low visibility, blocked lane, or vehicle hazard.', icon: Icons.traffic_rounded),
  _ChoiceOption(id: 'als', title: 'ALS / additional EMS', subtitle: 'High-acuity patient, multiple patients, or need for more hands.', icon: Icons.medical_services_rounded),
  _ChoiceOption(id: 'hazmat', title: 'HazMat / utility', subtitle: 'Chemical, gas, CO, power line, or unknown substance hazard.', icon: Icons.science_rounded),
];

const List<_ChoiceOption> _ppeOptions = [
  _ChoiceOption(id: 'standard', title: 'Standard gloves only', subtitle: 'Basic medical contact with no splash or respiratory hazard expected.', icon: Icons.front_hand_rounded),
  _ChoiceOption(id: 'gloves', title: 'Gloves', subtitle: 'Body substance isolation for patient contact.', icon: Icons.front_hand_rounded),
  _ChoiceOption(id: 'eye', title: 'Eye protection', subtitle: 'Blood, vomit, coughing, splashing, or debris risk.', icon: Icons.visibility_rounded),
  _ChoiceOption(id: 'mask', title: 'Surgical mask', subtitle: 'Droplet or respiratory secretion risk.', icon: Icons.masks_rounded),
  _ChoiceOption(id: 'n95', title: 'N95 / respirator', subtitle: 'Airborne, smoke, dust, unknown respiratory hazard, or local protocol.', icon: Icons.health_and_safety_rounded),
  _ChoiceOption(id: 'vest', title: 'Reflective vest', subtitle: 'Roadway, parking lot, traffic, or low-visibility scene.', icon: Icons.emoji_transportation_rounded),
  _ChoiceOption(id: 'gown', title: 'Gown / turnout gear', subtitle: 'Heavy contamination, fire/rescue environment, or body-fluid splash risk.', icon: Icons.checkroom_rounded),
];

const List<_ChoiceOption> _natureOptions = [
  _ChoiceOption(id: 'medical', title: 'Medical illness', subtitle: 'Primary problem appears medical or non-traumatic.', icon: Icons.monitor_heart_rounded),
  _ChoiceOption(id: 'trauma', title: 'Trauma / mechanism of injury', subtitle: 'Fall, MVC, assault, penetrating/blunt injury, or bleeding.', icon: Icons.personal_injury_rounded),
  _ChoiceOption(id: 'environmental', title: 'Environmental / CO / exposure', subtitle: 'CO, heat, cold, smoke, gas, or environmental exposure.', icon: Icons.device_thermostat_rounded),
  _ChoiceOption(id: 'behavioral', title: 'Behavioral / violence concern', subtitle: 'Unsafe behavior, assault, weapon, intoxication, or security issue.', icon: Icons.psychology_alt_rounded),
  _ChoiceOption(id: 'unknown', title: 'Unknown until further assessment', subtitle: 'Insufficient information; stay alert for both medical and trauma.', icon: Icons.help_rounded),
];

const List<_ChoiceOption> _patientCountOptions = [
  _ChoiceOption(id: 'one', title: 'One patient', subtitle: 'Only one patient is obvious from scene size-up.', icon: Icons.person_rounded),
  _ChoiceOption(id: 'two', title: 'Two patients', subtitle: 'Two obvious patients need assessment.', icon: Icons.people_rounded),
  _ChoiceOption(id: 'multiple', title: 'Multiple patients / MCI possible', subtitle: 'More than two, unknown count, or need for triage resources.', icon: Icons.groups_rounded),
];

const List<_ChoiceOption> _cSpineOptions = [
  _ChoiceOption(id: 'consider', title: 'Consider C-spine precautions', subtitle: 'Mechanism or presentation makes spinal injury possible.', icon: Icons.accessibility_new_rounded),
  _ChoiceOption(id: 'not_needed', title: 'C-spine not indicated from scene size-up', subtitle: 'No trauma mechanism or spinal concern is apparent yet.', icon: Icons.check_circle_rounded),
];

final List<_SceneCase> _sceneCases = [
  _SceneCase(
    title: 'Chest Pain in Living Room',
    dispatchInfo: 'Dispatch: 58-year-old male with chest pressure and shortness of breath. Caller says he is awake and sitting on the couch.',
    patientLabel: 'Awake patient',
    icon: Icons.weekend_rounded,
    accent: Colors.green.shade700,
    visibleClues: const ['Clean living room.', 'No weapons, traffic, fire, or obvious environmental hazard.', 'One patient sitting upright and talking.'],
    markers: const [
      _SceneMarker(label: 'Family', icon: Icons.person_rounded, color: Colors.green, x: 170, y: 42),
      _SceneMarker(label: 'Couch', icon: Icons.chair_rounded, color: Colors.blueGrey, x: 250, y: 120),
    ],
    correctSafetyId: 'safe',
    correctResourceIds: const {'als'},
    correctPpeIds: const {'standard'},
    minimumCriticalPpeIds: const {'standard'},
    correctNatureId: 'medical',
    correctPatientCountId: 'one',
    correctCSpineId: 'not_needed',
    stepFeedback: const {
      _SceneStep.safety: 'No immediate scene hazard is visible. Enter with PPE and continue assessment.',
      _SceneStep.resources: 'ALS/additional EMS is reasonable for chest pain and possible cardiac emergency.',
      _SceneStep.ppe: 'Standard gloves are appropriate for initial contact when no splash or respiratory hazard is apparent.',
      _SceneStep.nature: 'This presents as a medical illness.',
      _SceneStep.patientCount: 'Only one patient is apparent.',
      _SceneStep.cSpine: 'No trauma mechanism is apparent from the scene size-up.',
    },
    teachingPoint: 'A safe medical scene still requires PPE and a quick resource decision. Do not skip scene size-up just because the call sounds routine.',
  ),
  _SceneCase(
    title: 'Roadside MVC',
    dispatchInfo: 'Dispatch: two-car crash on a busy road. Caller reports one driver still inside a vehicle and another person walking around.',
    patientLabel: 'Driver',
    icon: Icons.car_crash_rounded,
    accent: Colors.orange.shade700,
    visibleClues: const ['Traffic is moving near the scene.', 'Vehicle appears damaged with fluid under the front end.', 'At least two people may be involved.'],
    markers: const [
      _SceneMarker(label: 'Traffic', icon: Icons.traffic_rounded, color: Colors.orange, x: 190, y: 30),
      _SceneMarker(label: 'Fluid', icon: Icons.water_drop_rounded, color: Colors.red, x: 285, y: 150),
      _SceneMarker(label: '2nd person', icon: Icons.directions_walk_rounded, color: Colors.purple, x: 330, y: 70),
    ],
    correctSafetyId: 'unsafe',
    correctResourceIds: const {'fire', 'traffic', 'als'},
    correctPpeIds: const {'gloves', 'eye', 'vest'},
    minimumCriticalPpeIds: const {'gloves', 'vest'},
    correctNatureId: 'trauma',
    correctPatientCountId: 'two',
    correctCSpineId: 'consider',
    stepFeedback: const {
      _SceneStep.safety: 'Traffic and vehicle hazards must be controlled before patient contact.',
      _SceneStep.resources: 'Fire/rescue, traffic control, and ALS/additional EMS are reasonable for a roadway MVC with two possible patients.',
      _SceneStep.ppe: 'Gloves, eye protection, and reflective vest match body-fluid, debris, and traffic risk.',
      _SceneStep.nature: 'This is trauma from an MVC mechanism.',
      _SceneStep.patientCount: 'There are at least two possible patients: the driver and walking person.',
      _SceneStep.cSpine: 'C-spine should be considered with MVC mechanism until ruled out by assessment/protocol.',
    },
    teachingPoint: 'For MVCs, scene safety is not just “is the patient visible?” It includes traffic control, vehicle stability, fluids, fire risk, and patient count.',
  ),
  _SceneCase(
    title: 'Unresponsive in Garage',
    dispatchInfo: 'Dispatch: person down in a closed garage. Caller reports a generator running nearby and the patient is not responding.',
    patientLabel: 'Unresponsive',
    icon: Icons.garage_rounded,
    accent: Colors.red.shade700,
    visibleClues: const ['Closed garage with possible exhaust exposure.', 'Generator or running engine nearby.', 'Unresponsive patient visible from doorway.'],
    markers: const [
      _SceneMarker(label: 'Generator', icon: Icons.electrical_services_rounded, color: Colors.red, x: 190, y: 45),
      _SceneMarker(label: 'CO risk', icon: Icons.cloud_rounded, color: Colors.red, x: 300, y: 85),
      _SceneMarker(label: 'Doorway', icon: Icons.door_front_door_rounded, color: Colors.blueGrey, x: 360, y: 155),
    ],
    correctSafetyId: 'unsafe',
    correctResourceIds: const {'fire', 'hazmat', 'als'},
    correctPpeIds: const {'gloves', 'n95'},
    minimumCriticalPpeIds: const {'gloves', 'n95'},
    correctNatureId: 'environmental',
    correctPatientCountId: 'one',
    correctCSpineId: 'not_needed',
    stepFeedback: const {
      _SceneStep.safety: 'Do not enter a possible CO/exhaust environment until it is made safe.',
      _SceneStep.resources: 'Fire/rescue or HazMat/utility resources plus ALS are appropriate for possible CO exposure and an unresponsive patient.',
      _SceneStep.ppe: 'Gloves and respiratory protection are selected here for training purposes. Follow local protocol and do not rely on PPE alone for CO atmospheres.',
      _SceneStep.nature: 'The main nature is environmental exposure, possible CO/exhaust.',
      _SceneStep.patientCount: 'One patient is obvious, but crews should stay alert for additional exposed occupants.',
      _SceneStep.cSpine: 'No trauma mechanism is shown yet; reassess if history changes.',
    },
    teachingPoint: 'The patient may need immediate care, but an unsafe atmosphere can create more patients. Make the environment safe before entry.',
  ),
  _SceneCase(
    title: 'Fall From Ladder',
    dispatchInfo: 'Dispatch: 42-year-old fell from a ladder while working on a roof. Coworkers lowered him to the ground. Patient complains of severe leg pain.',
    patientLabel: 'Fall patient',
    icon: Icons.construction_rounded,
    accent: Colors.blue.shade700,
    visibleClues: const ['Ladder and tools nearby.', 'Patient on ground after fall from height.', 'Coworkers report leg deformity and pain.'],
    markers: const [
      _SceneMarker(label: 'Ladder', icon: Icons.format_line_spacing_rounded, color: Colors.orange, x: 200, y: 30),
      _SceneMarker(label: 'Tools', icon: Icons.handyman_rounded, color: Colors.blueGrey, x: 310, y: 130),
      _SceneMarker(label: 'Leg injury', icon: Icons.personal_injury_rounded, color: Colors.red, x: 260, y: 80),
    ],
    correctSafetyId: 'safe',
    correctResourceIds: const {'als'},
    correctPpeIds: const {'gloves', 'eye'},
    minimumCriticalPpeIds: const {'gloves'},
    correctNatureId: 'trauma',
    correctPatientCountId: 'one',
    correctCSpineId: 'consider',
    stepFeedback: const {
      _SceneStep.safety: 'The ground scene appears safe after coworkers lowered the patient, but tools/ladder remain hazards to manage.',
      _SceneStep.resources: 'ALS/additional EMS is reasonable for severe trauma and pain control needs.',
      _SceneStep.ppe: 'Gloves and eye protection are reasonable around a trauma scene with possible blood/debris.',
      _SceneStep.nature: 'This is trauma from a fall mechanism.',
      _SceneStep.patientCount: 'Only one patient is apparent.',
      _SceneStep.cSpine: 'A fall from height should trigger early C-spine consideration.',
    },
    teachingPoint: 'The obvious femur injury can distract students. Scene size-up should still catch mechanism, patient count, PPE, and spinal consideration.',
  ),
  _SceneCase(
    title: 'Assault / Unknown Violence',
    dispatchInfo: 'Dispatch: person bleeding outside a convenience store. Caller says another person is yelling nearby and may still be involved.',
    patientLabel: 'Bleeding patient',
    icon: Icons.warning_rounded,
    accent: Colors.purple.shade700,
    visibleClues: const ['Aggressive bystander close to the patient.', 'Possible weapon on the ground.', 'Blood visible near patient.'],
    markers: const [
      _SceneMarker(label: 'Bystander', icon: Icons.record_voice_over_rounded, color: Colors.purple, x: 190, y: 36),
      _SceneMarker(label: 'Weapon?', icon: Icons.dangerous_rounded, color: Colors.red, x: 310, y: 92),
      _SceneMarker(label: 'Blood', icon: Icons.bloodtype_rounded, color: Colors.red, x: 250, y: 150),
    ],
    correctSafetyId: 'unsafe',
    correctResourceIds: const {'law', 'als'},
    correctPpeIds: const {'gloves', 'eye'},
    minimumCriticalPpeIds: const {'gloves'},
    correctNatureId: 'behavioral',
    correctPatientCountId: 'one',
    correctCSpineId: 'consider',
    stepFeedback: const {
      _SceneStep.safety: 'The scene is not safe until law enforcement controls the violence/weapon concern.',
      _SceneStep.resources: 'Law enforcement is needed for safety; ALS/additional EMS may be needed for bleeding trauma.',
      _SceneStep.ppe: 'Gloves and eye protection are reasonable for bleeding/trauma exposure.',
      _SceneStep.nature: 'Scene size-up should flag behavioral/violence concern even though the patient has trauma.',
      _SceneStep.patientCount: 'One patient is obvious. The bystander is a safety concern, not automatically a patient.',
      _SceneStep.cSpine: 'Assault/unknown mechanism can include head/neck trauma, so C-spine should be considered.',
    },
    teachingPoint: 'Students often want to rush to bleeding control. The safer answer is to stage until the violence/weapon hazard is controlled.',
  ),
  _SceneCase(
    title: 'Overdose With Sharps',
    dispatchInfo: 'Dispatch: possible overdose in a bathroom. Caller reports slow breathing and drug paraphernalia nearby.',
    patientLabel: 'Slow breathing',
    icon: Icons.medication_liquid_rounded,
    accent: Colors.teal.shade700,
    visibleClues: const ['Small bathroom with limited space.', 'Sharps/drug paraphernalia visible.', 'One patient on the floor with slow breathing.'],
    markers: const [
      _SceneMarker(label: 'Sharps', icon: Icons.vaccines_rounded, color: Colors.red, x: 190, y: 50),
      _SceneMarker(label: 'Small space', icon: Icons.meeting_room_rounded, color: Colors.blueGrey, x: 315, y: 135),
      _SceneMarker(label: 'Bystander', icon: Icons.person_rounded, color: Colors.teal, x: 335, y: 52),
    ],
    correctSafetyId: 'safe',
    correctResourceIds: const {'als'},
    correctPpeIds: const {'gloves', 'eye', 'mask'},
    minimumCriticalPpeIds: const {'gloves'},
    correctNatureId: 'medical',
    correctPatientCountId: 'one',
    correctCSpineId: 'not_needed',
    stepFeedback: const {
      _SceneStep.safety: 'The scene can be entered cautiously if no violence is present, but sharps must be avoided.',
      _SceneStep.resources: 'ALS/additional EMS is reasonable for slow breathing/possible overdose.',
      _SceneStep.ppe: 'Gloves, eye protection, and mask are reasonable for close airway care and possible body fluid exposure.',
      _SceneStep.nature: 'This presents primarily as a medical overdose/respiratory problem.',
      _SceneStep.patientCount: 'One patient is obvious.',
      _SceneStep.cSpine: 'No trauma mechanism is apparent yet; reassess if fall/trauma history appears.',
    },
    teachingPoint: 'Overdose scenes require fast airway/breathing care, but the student still needs BSI, sharps awareness, and a quick safety scan first.',
  ),
];
