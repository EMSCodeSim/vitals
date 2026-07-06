import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ABCAssessmentSimulatorPage extends StatefulWidget {
  const ABCAssessmentSimulatorPage({super.key});

  @override
  State<ABCAssessmentSimulatorPage> createState() => _ABCAssessmentSimulatorPageState();
}

class _ABCAssessmentSimulatorPageState extends State<ABCAssessmentSimulatorPage> {
  int _caseIndex = 0;
  _ABCStep _activeStep = _ABCStep.airway;
  bool _showResults = false;

  final Map<_ABCStep, String?> _findingPicks = {
    _ABCStep.airway: null,
    _ABCStep.breathing: null,
    _ABCStep.circulation: null,
  };

  final Map<_ABCStep, String?> _actionPicks = {
    _ABCStep.airway: null,
    _ABCStep.breathing: null,
    _ABCStep.circulation: null,
  };

  String? _priorityPick;

  _ABCCase get _case => _abcCases[_caseIndex];

  void _resetCase({bool keepSameCase = true}) {
    setState(() {
      if (!keepSameCase) _caseIndex = (_caseIndex + 1) % _abcCases.length;
      _activeStep = _ABCStep.airway;
      _showResults = false;
      _priorityPick = null;
      for (final step in _findingPicks.keys.toList()) {
        _findingPicks[step] = null;
        _actionPicks[step] = null;
      }
    });
  }

  _ABCSection get _activeSection => switch (_activeStep) {
    _ABCStep.airway => _case.airway,
    _ABCStep.breathing => _case.breathing,
    _ABCStep.circulation => _case.circulation,
    _ABCStep.priority => _case.priority,
  };

  bool get _activeStepComplete {
    if (_activeStep == _ABCStep.priority) return _priorityPick != null;
    return _findingPicks[_activeStep] != null && _actionPicks[_activeStep] != null;
  }

  void _goNext() {
    if (!_activeStepComplete) return;
    setState(() {
      if (_activeStep == _ABCStep.airway) {
        _activeStep = _ABCStep.breathing;
      } else if (_activeStep == _ABCStep.breathing) {
        _activeStep = _ABCStep.circulation;
      } else if (_activeStep == _ABCStep.circulation) {
        _activeStep = _ABCStep.priority;
      } else {
        _showResults = true;
      }
    });
  }

  void _goBack() {
    setState(() {
      _showResults = false;
      if (_activeStep == _ABCStep.priority) {
        _activeStep = _ABCStep.circulation;
      } else if (_activeStep == _ABCStep.circulation) {
        _activeStep = _ABCStep.breathing;
      } else if (_activeStep == _ABCStep.breathing) {
        _activeStep = _ABCStep.airway;
      }
    });
  }

  int get _score {
    var earned = 0;
    for (final step in const [_ABCStep.airway, _ABCStep.breathing, _ABCStep.circulation]) {
      final section = _case.sectionFor(step);
      if (_findingPicks[step] == section.correctFindingId) earned++;
      if (_actionPicks[step] == section.correctActionId) earned++;
    }
    if (_priorityPick == _case.priority.correctPriorityId) earned++;
    return earned;
  }

  int get _scorePercent => (_score / 7 * 100).round();

  @override
  Widget build(BuildContext context) {
    return EMSVitalsScaffold(
      title: 'ABC Assessment Simulator',
      subtitle: 'Tap the patient zones, identify airway/breathing/circulation problems, choose the first action, then set transport priority.',
      onInfoPressed: () {
        EMSInfoSheet.show(
          context,
          title: 'How this ABC simulator works',
          children: const [
            Text('This is a primary assessment drill. The student should move in order: Airway, Breathing, Circulation, then decide priority.'),
            SizedBox(height: 12),
            Text('Each section has two decisions: what you found and what you should do first. The final screen gives a score and flags critical misses.'),
            SizedBox(height: 12),
            Text('Keep local protocols in mind. This is a training aid and not a replacement for instructor judgment or medical direction.'),
          ],
        );
      },
      onBackPressed: () => context.go(AppRoutes.assessmentTools),
      bodySlivers: [
        SliverToBoxAdapter(
          child: EMSCentered(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CaseHeader(caseData: _case, caseNumber: _caseIndex + 1, totalCases: _abcCases.length),
                const SizedBox(height: 12),
                _PatientSceneCard(
                  caseData: _case,
                  activeStep: _activeStep,
                  onStepTap: (step) => setState(() {
                    _activeStep = step;
                    _showResults = false;
                  }),
                ),
                const SizedBox(height: 12),
                _StepProgressBar(
                  activeStep: _activeStep,
                  completed: {
                    _ABCStep.airway: _findingPicks[_ABCStep.airway] != null && _actionPicks[_ABCStep.airway] != null,
                    _ABCStep.breathing: _findingPicks[_ABCStep.breathing] != null && _actionPicks[_ABCStep.breathing] != null,
                    _ABCStep.circulation: _findingPicks[_ABCStep.circulation] != null && _actionPicks[_ABCStep.circulation] != null,
                    _ABCStep.priority: _priorityPick != null,
                  },
                  onTap: (step) => setState(() {
                    _activeStep = step;
                    _showResults = false;
                  }),
                ),
                const SizedBox(height: 12),
                if (!_showResults) ...[
                  _DecisionCard(
                    step: _activeStep,
                    section: _activeSection,
                    findingPick: _findingPicks[_activeStep],
                    actionPick: _actionPicks[_activeStep],
                    priorityPick: _priorityPick,
                    onFindingPicked: (id) => setState(() => _findingPicks[_activeStep] = id),
                    onActionPicked: (id) => setState(() => _actionPicks[_activeStep] = id),
                    onPriorityPicked: (id) => setState(() => _priorityPick = id),
                  ),
                  const SizedBox(height: 12),
                  if (_activeStepComplete) _FeedbackCard(step: _activeStep, section: _activeSection, findingPick: _findingPicks[_activeStep], actionPick: _actionPicks[_activeStep], priorityPick: _priorityPick),
                  const SizedBox(height: 12),
                  _NavigationControls(
                    activeStep: _activeStep,
                    canNext: _activeStepComplete,
                    onBack: _activeStep == _ABCStep.airway ? null : _goBack,
                    onNext: _goNext,
                    onReset: () => _resetCase(),
                  ),
                ] else ...[
                  _ResultsCard(
                    caseData: _case,
                    score: _score,
                    scorePercent: _scorePercent,
                    findingPicks: Map<_ABCStep, String?>.from(_findingPicks),
                    actionPicks: Map<_ABCStep, String?>.from(_actionPicks),
                    priorityPick: _priorityPick,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() {
                            _showResults = false;
                            _activeStep = _ABCStep.priority;
                          }),
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Review Answers'),
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
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CaseHeader extends StatelessWidget {
  const _CaseHeader({required this.caseData, required this.caseNumber, required this.totalCases});

  final _ABCCase caseData;
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
                    color: caseData.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: caseData.accent.withValues(alpha: 0.28)),
                  ),
                  child: Text('CASE $caseNumber / $totalCases', style: context.textStyles.labelSmall?.copyWith(color: caseData.accent, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(caseData.title, style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
              ],
            ),
            const SizedBox(height: 10),
            Text(caseData.dispatch, style: context.textStyles.bodyMedium?.copyWith(height: 1.4, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(caseData.scene, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in caseData.tags) _SmallChip(label: tag, color: caseData.accent),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientSceneCard extends StatelessWidget {
  const _PatientSceneCard({required this.caseData, required this.activeStep, required this.onStepTap});

  final _ABCCase caseData;
  final _ABCStep activeStep;
  final ValueChanged<_ABCStep> onStepTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [caseData.accent.withValues(alpha: 0.16), cs.surfaceContainerHighest.withValues(alpha: 0.28)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.touch_app_rounded, color: caseData.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Tap the patient: Airway → Breathing → Circulation', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: AspectRatio(
                      aspectRatio: 1.05,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _ABCPatientPainter(accent: caseData.accent, activeStep: activeStep),
                            ),
                          ),
                          Positioned(
                            top: 18,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: _ZoneButton(
                                step: _ABCStep.airway,
                                activeStep: activeStep,
                                icon: Icons.record_voice_over_rounded,
                                label: 'Airway',
                                onTap: onStepTap,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 148,
                            left: 16,
                            right: 16,
                            child: Center(
                              child: _ZoneButton(
                                step: _ABCStep.breathing,
                                activeStep: activeStep,
                                icon: Icons.air_rounded,
                                label: 'Breathing',
                                onTap: onStepTap,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 36,
                            left: 16,
                            right: 16,
                            child: Center(
                              child: _ZoneButton(
                                step: _ABCStep.circulation,
                                activeStep: activeStep,
                                icon: Icons.favorite_rounded,
                                label: 'Circulation',
                                onTap: onStepTap,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _VitalsStrip(caseData: caseData),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ABCPatientPainter extends CustomPainter {
  const _ABCPatientPainter({required this.accent, required this.activeStep});

  final Color accent;
  final _ABCStep activeStep;

  Color _zoneColor(_ABCStep step) => activeStep == step ? accent.withValues(alpha: 0.30) : Colors.blueGrey.withValues(alpha: 0.08);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withValues(alpha: 0.92), Colors.blueGrey.withValues(alpha: 0.08)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    final bgRect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(22));
    canvas.drawRRect(bgRect, bgPaint);

    final centerX = size.width / 2;
    final outline = Paint()
      ..color = Colors.blueGrey.withValues(alpha: 0.35)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final body = Paint()..color = Colors.blueGrey.withValues(alpha: 0.16);
    final skin = Paint()..color = const Color(0xFFFFD6B5).withValues(alpha: 0.90);
    final shirt = Paint()..color = accent.withValues(alpha: 0.16);

    final airwayPaint = Paint()..color = _zoneColor(_ABCStep.airway);
    final breathingPaint = Paint()..color = _zoneColor(_ABCStep.breathing);
    final circulationPaint = Paint()..color = _zoneColor(_ABCStep.circulation);

    canvas.drawCircle(Offset(centerX, size.height * 0.20), 56, airwayPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(centerX, size.height * 0.48), width: size.width * 0.52, height: size.height * 0.30), breathingPaint);
    canvas.drawCircle(Offset(centerX, size.height * 0.75), 62, circulationPaint);

    canvas.drawLine(Offset(centerX - 70, size.height * 0.42), Offset(centerX - 128, size.height * 0.60), outline);
    canvas.drawLine(Offset(centerX + 70, size.height * 0.42), Offset(centerX + 128, size.height * 0.60), outline);
    canvas.drawLine(Offset(centerX - 40, size.height * 0.69), Offset(centerX - 82, size.height * 0.91), outline);
    canvas.drawLine(Offset(centerX + 40, size.height * 0.69), Offset(centerX + 82, size.height * 0.91), outline);

    final torso = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(centerX, size.height * 0.48), width: size.width * 0.38, height: size.height * 0.40), const Radius.circular(44));
    canvas.drawRRect(torso, shirt);
    canvas.drawRRect(torso, outline);
    canvas.drawCircle(Offset(centerX, size.height * 0.19), 44, skin);
    canvas.drawCircle(Offset(centerX, size.height * 0.19), 44, outline);

    final eyePaint = Paint()..color = Colors.blueGrey.shade700;
    canvas.drawCircle(Offset(centerX - 14, size.height * 0.17), 4, eyePaint);
    canvas.drawCircle(Offset(centerX + 14, size.height * 0.17), 4, eyePaint);
    final mouth = Paint()
      ..color = Colors.blueGrey.shade700
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromCenter(center: Offset(centerX, size.height * 0.215), width: 28, height: 14), 0.15, 2.85, false, mouth);

    final lungPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.70)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(centerX - 28, size.height * 0.45), width: 42, height: 86), const Radius.circular(24)), lungPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(centerX + 28, size.height * 0.45), width: 42, height: 86), const Radius.circular(24)), lungPaint);

    final heartPaint = Paint()..color = Colors.redAccent.withValues(alpha: 0.72);
    final heart = Path()
      ..moveTo(centerX, size.height * 0.66)
      ..cubicTo(centerX - 38, size.height * 0.62, centerX - 45, size.height * 0.70, centerX, size.height * 0.76)
      ..cubicTo(centerX + 45, size.height * 0.70, centerX + 38, size.height * 0.62, centerX, size.height * 0.66);
    canvas.drawPath(heart, heartPaint);
  }

  @override
  bool shouldRepaint(covariant _ABCPatientPainter oldDelegate) => oldDelegate.accent != accent || oldDelegate.activeStep != activeStep;
}

class _ZoneButton extends StatelessWidget {
  const _ZoneButton({required this.step, required this.activeStep, required this.icon, required this.label, required this.onTap});

  final _ABCStep step;
  final _ABCStep activeStep;
  final IconData icon;
  final String label;
  final ValueChanged<_ABCStep> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = activeStep == step;
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? AppColors.emsBlue : cs.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () => onTap(step),
        borderRadius: BorderRadius.circular(999),
        splashFactory: NoSplash.splashFactory,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? AppColors.emsBlue : cs.outline.withValues(alpha: 0.18)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : AppColors.emsBlue),
              const SizedBox(width: 7),
              Text(label, style: context.textStyles.labelLarge?.copyWith(color: selected ? Colors.white : cs.onSurface, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

class _VitalsStrip extends StatelessWidget {
  const _VitalsStrip({required this.caseData});

  final _ABCCase caseData;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _VitalPill(icon: Icons.monitor_heart_rounded, label: caseData.pulse),
        _VitalPill(icon: Icons.air_rounded, label: caseData.respirations),
        _VitalPill(icon: Icons.bloodtype_rounded, label: caseData.skin),
        _VitalPill(icon: Icons.sensors_rounded, label: caseData.spo2),
      ],
    );
  }
}

class _VitalPill extends StatelessWidget {
  const _VitalPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.emsBlue),
          const SizedBox(width: 6),
          Text(label, style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({required this.activeStep, required this.completed, required this.onTap});

  final _ABCStep activeStep;
  final Map<_ABCStep, bool> completed;
  final ValueChanged<_ABCStep> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final step in _ABCStep.values)
          _StepChip(
            step: step,
            selected: activeStep == step,
            done: completed[step] ?? false,
            onTap: onTap,
          ),
      ],
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.step, required this.selected, required this.done, required this.onTap});

  final _ABCStep step;
  final bool selected;
  final bool done;
  final ValueChanged<_ABCStep> onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = selected ? AppColors.emsBlue : done ? Colors.green.withValues(alpha: 0.12) : cs.surface;
    final fg = selected ? Colors.white : done ? Colors.green.shade700 : cs.onSurface;
    return InkWell(
      onTap: () => onTap(step),
      borderRadius: BorderRadius.circular(999),
      splashFactory: NoSplash.splashFactory,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.emsBlue : cs.outline.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(done ? Icons.check_circle_rounded : step.icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(step.label, style: context.textStyles.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({required this.step, required this.section, required this.findingPick, required this.actionPick, required this.priorityPick, required this.onFindingPicked, required this.onActionPicked, required this.onPriorityPicked});

  final _ABCStep step;
  final _ABCSection section;
  final String? findingPick;
  final String? actionPick;
  final String? priorityPick;
  final ValueChanged<String> onFindingPicked;
  final ValueChanged<String> onActionPicked;
  final ValueChanged<String> onPriorityPicked;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return EMSSectionCard(
      title: section.title,
      subtitle: section.prompt,
      trailing: Icon(step.icon, color: AppColors.emsBlue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.visibility_rounded, color: AppColors.emsBlue),
                const SizedBox(width: 10),
                Expanded(child: Text(section.visualCue, style: context.textStyles.bodySmall?.copyWith(height: 1.35, fontWeight: FontWeight.w700))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (step == _ABCStep.priority) ...[
            Text('Set the patient priority', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            for (final choice in section.priorityChoices) ...[
              _ChoiceTile(choice: choice, selected: priorityPick == choice.id, onTap: () => onPriorityPicked(choice.id)),
              if (choice != section.priorityChoices.last) const SizedBox(height: 8),
            ],
          ] else ...[
            Text('1. What did you find?', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            for (final choice in section.findingChoices) ...[
              _ChoiceTile(choice: choice, selected: findingPick == choice.id, onTap: () => onFindingPicked(choice.id)),
              if (choice != section.findingChoices.last) const SizedBox(height: 8),
            ],
            const SizedBox(height: 14),
            Text('2. What should you do first?', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            for (final choice in section.actionChoices) ...[
              _ChoiceTile(choice: choice, selected: actionPick == choice.id, onTap: () => onActionPicked(choice.id)),
              if (choice != section.actionChoices.last) const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.choice, required this.selected, required this.onTap});

  final _ABCChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashFactory: NoSplash.splashFactory,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.emsBlue.withValues(alpha: 0.10) : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.emsBlue : cs.outline.withValues(alpha: 0.16), width: selected ? 2 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: selected ? AppColors.emsBlue : cs.surfaceContainerHighest.withValues(alpha: 0.45), shape: BoxShape.circle),
              child: Icon(choice.icon, size: 19, color: selected ? Colors.white : AppColors.emsBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(choice.label, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(choice.detail, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.emsBlue),
          ],
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.step, required this.section, required this.findingPick, required this.actionPick, required this.priorityPick});

  final _ABCStep step;
  final _ABCSection section;
  final String? findingPick;
  final String? actionPick;
  final String? priorityPick;

  @override
  Widget build(BuildContext context) {
    final isCorrect = step == _ABCStep.priority ? priorityPick == section.correctPriorityId : findingPick == section.correctFindingId && actionPick == section.correctActionId;
    final message = isCorrect ? section.correctFeedback : section.needsWorkFeedback;
    return EMSResultBox(
      title: isCorrect ? 'Good ABC decision' : 'Needs work',
      message: message,
      kind: isCorrect ? EMSResultKind.success : EMSResultKind.warning,
    );
  }
}

class _NavigationControls extends StatelessWidget {
  const _NavigationControls({required this.activeStep, required this.canNext, required this.onBack, required this.onNext, required this.onReset});

  final _ABCStep activeStep;
  final bool canNext;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onReset;

  String get _nextLabel => switch (activeStep) {
    _ABCStep.airway => 'Next: Breathing',
    _ABCStep.breathing => 'Next: Circulation',
    _ABCStep.circulation => 'Next: Priority',
    _ABCStep.priority => 'Show Results',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.chevron_left_rounded),
                label: const Text('Back'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: canNext ? onNext : null,
                icon: const Icon(Icons.chevron_right_rounded),
                label: Text(_nextLabel),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reset This Case'),
        ),
      ],
    );
  }
}

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({required this.caseData, required this.score, required this.scorePercent, required this.findingPicks, required this.actionPicks, required this.priorityPick});

  final _ABCCase caseData;
  final int score;
  final int scorePercent;
  final Map<_ABCStep, String?> findingPicks;
  final Map<_ABCStep, String?> actionPicks;
  final String? priorityPick;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final criticalMisses = _criticalMisses;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: AppColors.headerGradient),
                    boxShadow: [BoxShadow(color: AppColors.emsBlue.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 8))],
                  ),
                  child: Center(child: Text('$scorePercent%', style: context.textStyles.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ABC Summary', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('$score of 7 decisions correct', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (criticalMisses.isEmpty)
              const EMSResultBox(title: 'No critical misses', message: 'Student handled the immediate life threats in the correct primary assessment order.', kind: EMSResultKind.success)
            else
              EMSResultBox(title: 'Critical miss review', message: criticalMisses.join(' '), kind: EMSResultKind.error),
            const SizedBox(height: 14),
            _ResultLine(step: _ABCStep.airway, label: 'Airway', correctFinding: findingPicks[_ABCStep.airway] == caseData.airway.correctFindingId, correctAction: actionPicks[_ABCStep.airway] == caseData.airway.correctActionId, correctText: caseData.airway.expectedSummary),
            _ResultLine(step: _ABCStep.breathing, label: 'Breathing', correctFinding: findingPicks[_ABCStep.breathing] == caseData.breathing.correctFindingId, correctAction: actionPicks[_ABCStep.breathing] == caseData.breathing.correctActionId, correctText: caseData.breathing.expectedSummary),
            _ResultLine(step: _ABCStep.circulation, label: 'Circulation', correctFinding: findingPicks[_ABCStep.circulation] == caseData.circulation.correctFindingId, correctAction: actionPicks[_ABCStep.circulation] == caseData.circulation.correctActionId, correctText: caseData.circulation.expectedSummary),
            _PriorityResultLine(correct: priorityPick == caseData.priority.correctPriorityId, correctText: caseData.priority.expectedSummary),
            const SizedBox(height: 14),
            EMSResultBox(title: 'Instructor teaching point', message: caseData.teachingPoint, kind: EMSResultKind.info),
          ],
        ),
      ),
    );
  }

  List<String> get _criticalMisses {
    final misses = <String>[];
    if (actionPicks[_ABCStep.airway] != caseData.airway.correctActionId && caseData.airway.criticalMiss != null) misses.add(caseData.airway.criticalMiss!);
    if (actionPicks[_ABCStep.breathing] != caseData.breathing.correctActionId && caseData.breathing.criticalMiss != null) misses.add(caseData.breathing.criticalMiss!);
    if (actionPicks[_ABCStep.circulation] != caseData.circulation.correctActionId && caseData.circulation.criticalMiss != null) misses.add(caseData.circulation.criticalMiss!);
    if (priorityPick != caseData.priority.correctPriorityId && caseData.priority.criticalMiss != null) misses.add(caseData.priority.criticalMiss!);
    return misses;
  }
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({required this.step, required this.label, required this.correctFinding, required this.correctAction, required this.correctText});

  final _ABCStep step;
  final String label;
  final bool correctFinding;
  final bool correctAction;
  final String correctText;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(step.icon, color: AppColors.emsBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(correctText, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    _SmallStatus(label: 'Finding', correct: correctFinding),
                    _SmallStatus(label: 'Action', correct: correctAction),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityResultLine extends StatelessWidget {
  const _PriorityResultLine({required this.correct, required this.correctText});

  final bool correct;
  final String correctText;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.priority_high_rounded, color: AppColors.emsBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Priority', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(correctText, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                const SizedBox(height: 6),
                _SmallStatus(label: 'Priority decision', correct: correct),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallStatus extends StatelessWidget {
  const _SmallStatus({required this.label, required this.correct});

  final String label;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: correct ? Colors.green.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(correct ? Icons.check_rounded : Icons.close_rounded, size: 14, color: correct ? Colors.green.shade700 : Colors.orange.shade800),
          const SizedBox(width: 4),
          Text(label, style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: correct ? Colors.green.shade700 : Colors.orange.shade800)),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(label, style: context.textStyles.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w900)),
    );
  }
}

enum _ABCStep { airway, breathing, circulation, priority }

extension _ABCStepInfo on _ABCStep {
  String get label => switch (this) {
    _ABCStep.airway => 'Airway',
    _ABCStep.breathing => 'Breathing',
    _ABCStep.circulation => 'Circulation',
    _ABCStep.priority => 'Priority',
  };

  IconData get icon => switch (this) {
    _ABCStep.airway => Icons.record_voice_over_rounded,
    _ABCStep.breathing => Icons.air_rounded,
    _ABCStep.circulation => Icons.favorite_rounded,
    _ABCStep.priority => Icons.priority_high_rounded,
  };
}

class _ABCCase {
  const _ABCCase({required this.title, required this.dispatch, required this.scene, required this.tags, required this.accent, required this.pulse, required this.respirations, required this.skin, required this.spo2, required this.airway, required this.breathing, required this.circulation, required this.priority, required this.teachingPoint});

  final String title;
  final String dispatch;
  final String scene;
  final List<String> tags;
  final Color accent;
  final String pulse;
  final String respirations;
  final String skin;
  final String spo2;
  final _ABCSection airway;
  final _ABCSection breathing;
  final _ABCSection circulation;
  final _ABCSection priority;
  final String teachingPoint;

  _ABCSection sectionFor(_ABCStep step) => switch (step) {
    _ABCStep.airway => airway,
    _ABCStep.breathing => breathing,
    _ABCStep.circulation => circulation,
    _ABCStep.priority => priority,
  };
}

class _ABCSection {
  const _ABCSection({required this.title, required this.prompt, required this.visualCue, required this.findingChoices, required this.actionChoices, required this.priorityChoices, required this.correctFindingId, required this.correctActionId, required this.correctPriorityId, required this.correctFeedback, required this.needsWorkFeedback, required this.expectedSummary, this.criticalMiss});

  final String title;
  final String prompt;
  final String visualCue;
  final List<_ABCChoice> findingChoices;
  final List<_ABCChoice> actionChoices;
  final List<_ABCChoice> priorityChoices;
  final String? correctFindingId;
  final String? correctActionId;
  final String? correctPriorityId;
  final String correctFeedback;
  final String needsWorkFeedback;
  final String expectedSummary;
  final String? criticalMiss;
}

class _ABCChoice {
  const _ABCChoice({required this.id, required this.label, required this.detail, required this.icon});

  final String id;
  final String label;
  final String detail;
  final IconData icon;
}

const _airwayFindings = [
  _ABCChoice(id: 'patent-clear', label: 'Patent / clear', detail: 'Patient can speak or has clear air movement with no obstruction sounds.', icon: Icons.check_circle_rounded),
  _ABCChoice(id: 'threatened', label: 'Threatened airway', detail: 'Snoring, gurgling, vomiting, poor positioning, or decreasing mental status.', icon: Icons.warning_amber_rounded),
  _ABCChoice(id: 'obstructed', label: 'Obstructed airway', detail: 'No effective air movement, visible obstruction, or unable to maintain airway.', icon: Icons.report_rounded),
];

const _airwayActions = [
  _ABCChoice(id: 'continue-assess', label: 'Airway clear — move to breathing', detail: 'Do not delay at airway when it is patent; continue the primary assessment.', icon: Icons.arrow_forward_rounded),
  _ABCChoice(id: 'open-airway', label: 'Open/reposition airway', detail: 'Use head tilt-chin lift, jaw thrust if trauma suspected, and position as appropriate.', icon: Icons.open_in_full_rounded),
  _ABCChoice(id: 'suction-clear', label: 'Suction or remove visible obstruction', detail: 'Clear fluid, vomit, or a visible obstruction before moving on.', icon: Icons.cleaning_services_rounded),
];

const _breathingFindings = [
  _ABCChoice(id: 'adequate', label: 'Adequate breathing', detail: 'Normal rate, depth, chest rise, effort, and oxygenation for the patient.', icon: Icons.check_circle_rounded),
  _ABCChoice(id: 'distress', label: 'Respiratory distress / inadequate', detail: 'Fast, slow, shallow, labored, wheezing, poor SpO₂, or tiring.', icon: Icons.warning_amber_rounded),
  _ABCChoice(id: 'absent-agonal', label: 'Absent or agonal breathing', detail: 'No normal breathing. Gasping is not adequate breathing.', icon: Icons.report_rounded),
];

const _breathingActions = [
  _ABCChoice(id: 'monitor-breathing', label: 'Monitor breathing and continue', detail: 'Breathing is adequate. Continue to circulation and reassess later.', icon: Icons.arrow_forward_rounded),
  _ABCChoice(id: 'oxygen-position', label: 'Position, oxygen, and prepare treatment', detail: 'Support oxygenation, position of comfort, and treat per level/protocol.', icon: Icons.air_rounded),
  _ABCChoice(id: 'assist-ventilations', label: 'Assist ventilations with BVM', detail: 'Use when breathing is inadequate, very slow, shallow, or the patient is tiring.', icon: Icons.masks_rounded),
  _ABCChoice(id: 'cpr-aed-breathing', label: 'Recognize arrest pathway', detail: 'No normal breathing in an unresponsive patient should trigger pulse check and CPR/AED decision.', icon: Icons.offline_bolt_rounded),
];

const _circulationFindings = [
  _ABCChoice(id: 'adequate-perfusion', label: 'Adequate circulation', detail: 'Pulse present and strong, skin acceptable, no major bleeding.', icon: Icons.check_circle_rounded),
  _ABCChoice(id: 'poor-perfusion', label: 'Poor perfusion / shock signs', detail: 'Weak or rapid pulse, pale/cool/diaphoretic skin, altered mental status, or hypotension clues.', icon: Icons.warning_amber_rounded),
  _ABCChoice(id: 'major-bleeding', label: 'Major bleeding', detail: 'Life-threatening external bleeding must be controlled immediately.', icon: Icons.bloodtype_rounded),
  _ABCChoice(id: 'no-pulse', label: 'No pulse', detail: 'Unresponsive with no normal breathing and no pulse.', icon: Icons.report_rounded),
];

const _circulationActions = [
  _ABCChoice(id: 'continue-history', label: 'Continue assessment', detail: 'No immediate circulation life threat found. Move toward priority/history.', icon: Icons.arrow_forward_rounded),
  _ABCChoice(id: 'treat-shock', label: 'Treat for shock and rapid transport', detail: 'Keep warm, manage position as appropriate, request help, and reassess.', icon: Icons.emergency_rounded),
  _ABCChoice(id: 'control-bleeding', label: 'Control major bleeding', detail: 'Direct pressure, wound packing, tourniquet, or hemostatic dressing per protocol.', icon: Icons.health_and_safety_rounded),
  _ABCChoice(id: 'start-cpr-aed', label: 'Start CPR and attach AED', detail: 'No pulse with no normal breathing is a cardiac arrest pathway.', icon: Icons.offline_bolt_rounded),
];

const _priorityChoices = [
  _ABCChoice(id: 'stable-continue', label: 'Stable — continue full assessment', detail: 'No immediate ABC life threats. Continue SAMPLE/OPQRST and focused assessment.', icon: Icons.check_circle_rounded),
  _ABCChoice(id: 'unstable-rapid', label: 'Unstable — rapid transport / ALS', detail: 'Life threat or poor perfusion is present. Treat immediately and reassess often.', icon: Icons.priority_high_rounded),
  _ABCChoice(id: 'arrest-cpr', label: 'Cardiac arrest — CPR/AED now', detail: 'Unresponsive, no normal breathing, and no pulse.', icon: Icons.offline_bolt_rounded),
];

const _abcCases = [
  _ABCCase(
    title: 'Stable Adult Assessment',
    dispatch: '28-year-old male after a minor fall. He is sitting upright and talking with you.',
    scene: 'Patient speaks in full sentences. No obvious major bleeding. Chest rise is equal and unlabored.',
    tags: ['Stable', 'Good first drill', 'No life threat'],
    accent: Color(0xFF22C55E),
    pulse: 'Pulse 76 strong',
    respirations: 'RR 16 easy',
    skin: 'Pink/warm/dry',
    spo2: 'SpO₂ 98%',
    airway: _ABCSection(
      title: 'A — Airway',
      prompt: 'Check if the airway is open before moving on.',
      visualCue: 'He answers questions clearly with no gurgling, snoring, vomiting, or obstruction.',
      findingChoices: _airwayFindings,
      actionChoices: _airwayActions,
      priorityChoices: [],
      correctFindingId: 'patent-clear',
      correctActionId: 'continue-assess',
      correctPriorityId: null,
      correctFeedback: 'Correct. Speaking clearly is a strong sign the airway is currently patent.',
      needsWorkFeedback: 'Recheck the clue: a patient speaking clearly usually has a patent airway. Move to breathing.',
      expectedSummary: 'Airway patent; continue to breathing.',
    ),
    breathing: _ABCSection(
      title: 'B — Breathing',
      prompt: 'Assess rate, depth, effort, chest rise, and oxygenation.',
      visualCue: 'Respirations are easy and equal. No accessory muscle use. SpO₂ is normal.',
      findingChoices: _breathingFindings,
      actionChoices: _breathingActions,
      priorityChoices: [],
      correctFindingId: 'adequate',
      correctActionId: 'monitor-breathing',
      correctPriorityId: null,
      correctFeedback: 'Correct. Breathing is adequate; continue to circulation.',
      needsWorkFeedback: 'This patient is not showing distress or inadequate breathing. Continue and reassess later.',
      expectedSummary: 'Breathing adequate; monitor and continue.',
    ),
    circulation: _ABCSection(
      title: 'C — Circulation',
      prompt: 'Check pulse, skin, and major bleeding.',
      visualCue: 'Strong radial pulse, good skin signs, and no major external bleeding.',
      findingChoices: _circulationFindings,
      actionChoices: _circulationActions,
      priorityChoices: [],
      correctFindingId: 'adequate-perfusion',
      correctActionId: 'continue-history',
      correctPriorityId: null,
      correctFeedback: 'Correct. No circulation life threat found; continue the assessment.',
      needsWorkFeedback: 'No poor perfusion, no major bleed, and pulse is present. Continue to priority/history.',
      expectedSummary: 'Circulation adequate; continue to full assessment.',
    ),
    priority: _ABCSection(
      title: 'Priority Decision',
      prompt: 'Based on ABC, decide if this patient is stable or unstable.',
      visualCue: 'All ABC findings are adequate and no immediate life threat is found.',
      findingChoices: [],
      actionChoices: [],
      priorityChoices: _priorityChoices,
      correctFindingId: null,
      correctActionId: null,
      correctPriorityId: 'stable-continue',
      correctFeedback: 'Correct. This patient can continue into SAMPLE/OPQRST and a focused exam.',
      needsWorkFeedback: 'No immediate ABC life threat is present, so this is a stable primary assessment.',
      expectedSummary: 'Stable; continue full assessment.',
    ),
    teachingPoint: 'Stable does not mean finished. It means no immediate ABC life threat was found, so move into history, focused exam, vitals, and reassessment.',
  ),
  _ABCCase(
    title: 'Respiratory Distress',
    dispatch: '64-year-old female with shortness of breath. She is sitting forward on the couch.',
    scene: 'She speaks in 2–3 word phrases. Audible wheezes. Accessory muscle use. Pale and sweaty.',
    tags: ['Breathing problem', 'Wheezing', 'Unstable'],
    accent: Color(0xFFF97316),
    pulse: 'Pulse 118 weak',
    respirations: 'RR 32 labored',
    skin: 'Pale/diaphoretic',
    spo2: 'SpO₂ 88%',
    airway: _ABCSection(
      title: 'A — Airway',
      prompt: 'Check if air can move before deciding this is only a breathing problem.',
      visualCue: 'She can speak short phrases. There is no gurgling or visible obstruction.',
      findingChoices: _airwayFindings,
      actionChoices: _airwayActions,
      priorityChoices: [],
      correctFindingId: 'patent-clear',
      correctActionId: 'continue-assess',
      correctPriorityId: null,
      correctFeedback: 'Correct. Airway is open, but short phrases warn you breathing is not adequate.',
      needsWorkFeedback: 'She can speak, so air is moving. Continue quickly to breathing.',
      expectedSummary: 'Airway patent but monitor closely; continue to breathing.',
    ),
    breathing: _ABCSection(
      title: 'B — Breathing',
      prompt: 'Decide if breathing is adequate or if she needs immediate support.',
      visualCue: 'RR 32, labored, wheezes, short phrases, and SpO₂ 88%. She is working hard to breathe.',
      findingChoices: _breathingFindings,
      actionChoices: _breathingActions,
      priorityChoices: [],
      correctFindingId: 'distress',
      correctActionId: 'oxygen-position',
      correctPriorityId: null,
      correctFeedback: 'Correct. Support oxygenation, position of comfort, and prepare treatment per protocol while reassessing.',
      needsWorkFeedback: 'The low SpO₂, accessory muscle use, and short phrases make this respiratory distress, not normal breathing.',
      expectedSummary: 'Breathing inadequate/distressed; position, oxygen, treatment per protocol, and reassess.',
      criticalMiss: 'Missed respiratory distress: low SpO₂ and labored breathing require immediate support.',
    ),
    circulation: _ABCSection(
      title: 'C — Circulation',
      prompt: 'Look for perfusion problems caused by respiratory distress.',
      visualCue: 'Rapid weak pulse and pale, sweaty skin. No major external bleeding.',
      findingChoices: _circulationFindings,
      actionChoices: _circulationActions,
      priorityChoices: [],
      correctFindingId: 'poor-perfusion',
      correctActionId: 'treat-shock',
      correctPriorityId: null,
      correctFeedback: 'Correct. Poor perfusion signs make this an unstable patient who needs rapid treatment/transport planning.',
      needsWorkFeedback: 'Weak rapid pulse and pale/diaphoretic skin are poor perfusion clues even without bleeding.',
      expectedSummary: 'Poor perfusion; treat for shock, request help, and plan rapid transport.',
    ),
    priority: _ABCSection(
      title: 'Priority Decision',
      prompt: 'Set priority from the ABC findings.',
      visualCue: 'Breathing and perfusion are not normal. She needs immediate intervention and frequent reassessment.',
      findingChoices: [],
      actionChoices: [],
      priorityChoices: _priorityChoices,
      correctFindingId: null,
      correctActionId: null,
      correctPriorityId: 'unstable-rapid',
      correctFeedback: 'Correct. Respiratory distress with poor perfusion is unstable.',
      needsWorkFeedback: 'This is not a stable patient. Breathing and circulation findings are abnormal.',
      expectedSummary: 'Unstable; immediate support, ALS/rapid transport depending on system.',
      criticalMiss: 'Priority miss: respiratory distress with poor perfusion should not be treated as stable.',
    ),
    teachingPoint: 'Respiratory distress is not only an SpO₂ number. Short phrases, accessory muscles, wheezing, and skin signs tell you how hard the patient is working.',
  ),
  _ABCCase(
    title: 'Unresponsive with Snoring Respirations',
    dispatch: '48-year-old male found unresponsive in a bedroom. Family reports possible overdose.',
    scene: 'Patient is supine, not responding to voice. Loud snoring respirations. No obvious trauma or major bleeding.',
    tags: ['Airway problem', 'Unresponsive', 'Ventilation support'],
    accent: Color(0xFF7C3AED),
    pulse: 'Pulse 54 present',
    respirations: 'RR 8 snoring',
    skin: 'Cool/clammy',
    spo2: 'SpO₂ 86%',
    airway: _ABCSection(
      title: 'A — Airway',
      prompt: 'Unresponsive patients cannot reliably protect their airway.',
      visualCue: 'Snoring respirations suggest the tongue/soft tissue is partially blocking the airway.',
      findingChoices: _airwayFindings,
      actionChoices: _airwayActions,
      priorityChoices: [],
      correctFindingId: 'threatened',
      correctActionId: 'open-airway',
      correctPriorityId: null,
      correctFeedback: 'Correct. Open/reposition the airway first, then reassess breathing.',
      needsWorkFeedback: 'Snoring in an unresponsive patient is an airway problem. Open and reposition the airway.',
      expectedSummary: 'Threatened airway; open/reposition and reassess.',
      criticalMiss: 'Missed airway problem: snoring respirations in an unresponsive patient require airway repositioning.',
    ),
    breathing: _ABCSection(
      title: 'B — Breathing',
      prompt: 'After opening the airway, decide if breathing is adequate.',
      visualCue: 'Slow respirations at 8/min, poor oxygenation, and decreased mental status.',
      findingChoices: _breathingFindings,
      actionChoices: _breathingActions,
      priorityChoices: [],
      correctFindingId: 'distress',
      correctActionId: 'assist-ventilations',
      correctPriorityId: null,
      correctFeedback: 'Correct. Slow/inadequate breathing with low SpO₂ requires assisted ventilations.',
      needsWorkFeedback: 'A rate of 8 with poor oxygenation is not adequate. Assist ventilations with BVM.',
      expectedSummary: 'Inadequate breathing; assist ventilations and reassess pulse/airway.',
      criticalMiss: 'Missed inadequate breathing: slow respirations and low SpO₂ need assisted ventilations.',
    ),
    circulation: _ABCSection(
      title: 'C — Circulation',
      prompt: 'Check pulse and perfusion before moving to history.',
      visualCue: 'Pulse is present but slow. Skin is cool and clammy. No major external bleeding.',
      findingChoices: _circulationFindings,
      actionChoices: _circulationActions,
      priorityChoices: [],
      correctFindingId: 'poor-perfusion',
      correctActionId: 'treat-shock',
      correctPriorityId: null,
      correctFeedback: 'Correct. Pulse is present, but perfusion is poor. Keep reassessing; this patient can deteriorate.',
      needsWorkFeedback: 'Pulse is present, so CPR is not started, but poor perfusion needs rapid management and reassessment.',
      expectedSummary: 'Pulse present with poor perfusion; support airway/breathing and transport priority.',
    ),
    priority: _ABCSection(
      title: 'Priority Decision',
      prompt: 'Set priority after ABC interventions.',
      visualCue: 'Unresponsive with airway and breathing problems. This patient needs immediate support.',
      findingChoices: [],
      actionChoices: [],
      priorityChoices: _priorityChoices,
      correctFindingId: null,
      correctActionId: null,
      correctPriorityId: 'unstable-rapid',
      correctFeedback: 'Correct. Airway/breathing instability makes this an unstable patient.',
      needsWorkFeedback: 'This patient is not stable. Airway and ventilation support are immediate priorities.',
      expectedSummary: 'Unstable; airway/ventilation support and rapid transport/ALS.',
      criticalMiss: 'Priority miss: an unresponsive patient needing ventilatory support is unstable.',
    ),
    teachingPoint: 'Snoring respirations are an airway clue. First open/reposition the airway, then decide whether the patient can ventilate adequately.',
  ),
  _ABCCase(
    title: 'Cardiac Arrest Recognition',
    dispatch: '72-year-old male collapsed at home. Bystanders say he is not waking up.',
    scene: 'Unresponsive. Occasional gasping. No purposeful movement. Family is panicked.',
    tags: ['No pulse', 'Agonal gasps', 'CPR/AED'],
    accent: Color(0xFFE5484D),
    pulse: 'No pulse felt',
    respirations: 'Agonal gasps',
    skin: 'Gray/cool',
    spo2: 'No reliable SpO₂',
    airway: _ABCSection(
      title: 'A — Airway',
      prompt: 'Open airway enough to assess breathing, but do not delay arrest care.',
      visualCue: 'Unresponsive and not protecting airway. No visible obstruction.',
      findingChoices: _airwayFindings,
      actionChoices: _airwayActions,
      priorityChoices: [],
      correctFindingId: 'threatened',
      correctActionId: 'open-airway',
      correctPriorityId: null,
      correctFeedback: 'Correct. Open the airway and immediately assess breathing/pulse.',
      needsWorkFeedback: 'An unresponsive patient has a threatened airway. Open enough to assess breathing and pulse quickly.',
      expectedSummary: 'Threatened airway; open airway briefly while checking breathing/pulse.',
    ),
    breathing: _ABCSection(
      title: 'B — Breathing',
      prompt: 'Decide if gasping counts as normal breathing.',
      visualCue: 'Occasional gasps only. No normal chest rise or regular respirations.',
      findingChoices: _breathingFindings,
      actionChoices: _breathingActions,
      priorityChoices: [],
      correctFindingId: 'absent-agonal',
      correctActionId: 'cpr-aed-breathing',
      correctPriorityId: null,
      correctFeedback: 'Correct. Agonal gasping is not normal breathing; move directly to pulse/CPR-AED decision.',
      needsWorkFeedback: 'Do not treat agonal gasps as adequate breathing. This is an arrest warning sign.',
      expectedSummary: 'Absent/agonal breathing; check pulse and move to CPR/AED if pulseless.',
      criticalMiss: 'Missed arrest breathing: agonal gasps are not normal breathing.',
    ),
    circulation: _ABCSection(
      title: 'C — Circulation',
      prompt: 'Check pulse. Do not delay compressions if no pulse is found.',
      visualCue: 'No pulse felt. Patient is unresponsive with no normal breathing.',
      findingChoices: _circulationFindings,
      actionChoices: _circulationActions,
      priorityChoices: [],
      correctFindingId: 'no-pulse',
      correctActionId: 'start-cpr-aed',
      correctPriorityId: null,
      correctFeedback: 'Correct. Start CPR and attach AED immediately.',
      needsWorkFeedback: 'No pulse + no normal breathing = cardiac arrest. Start CPR/AED now.',
      expectedSummary: 'No pulse; start CPR and apply AED.',
      criticalMiss: 'Missed cardiac arrest: no pulse requires CPR/AED immediately.',
    ),
    priority: _ABCSection(
      title: 'Priority Decision',
      prompt: 'Choose the correct pathway.',
      visualCue: 'Unresponsive, no normal breathing, no pulse.',
      findingChoices: [],
      actionChoices: [],
      priorityChoices: _priorityChoices,
      correctFindingId: null,
      correctActionId: null,
      correctPriorityId: 'arrest-cpr',
      correctFeedback: 'Correct. This is cardiac arrest. Start CPR/AED and manage per protocol.',
      needsWorkFeedback: 'This is not just unstable. It is a cardiac arrest pathway.',
      expectedSummary: 'Cardiac arrest; CPR/AED now.',
      criticalMiss: 'Priority miss: cardiac arrest should be routed to CPR/AED, not routine transport decision.',
    ),
    teachingPoint: 'Agonal gasps can fool students. In an unresponsive pulseless patient, gasping is not normal breathing—start CPR/AED.',
  ),
  _ABCCase(
    title: 'Major Bleeding and Shock',
    dispatch: '36-year-old male cut his forearm with a saw. Coworkers wrapped the arm before you arrived.',
    scene: 'He is awake but anxious. Blood is soaking through the towel. He looks pale and says he feels dizzy.',
    tags: ['Major bleeding', 'Shock signs', 'Control bleeding'],
    accent: Color(0xFFDC2626),
    pulse: 'Pulse 132 weak',
    respirations: 'RR 24 fast',
    skin: 'Pale/cool/sweaty',
    spo2: 'SpO₂ 97%',
    airway: _ABCSection(
      title: 'A — Airway',
      prompt: 'Do not get tunnel vision on the injury before checking airway.',
      visualCue: 'He is awake and answers questions. No airway sounds or obstruction.',
      findingChoices: _airwayFindings,
      actionChoices: _airwayActions,
      priorityChoices: [],
      correctFindingId: 'patent-clear',
      correctActionId: 'continue-assess',
      correctPriorityId: null,
      correctFeedback: 'Correct. Airway is patent; move quickly to breathing and circulation.',
      needsWorkFeedback: 'He is talking clearly, so the airway is currently patent.',
      expectedSummary: 'Airway patent; continue quickly.',
    ),
    breathing: _ABCSection(
      title: 'B — Breathing',
      prompt: 'Assess whether fast breathing is a primary breathing failure or compensation.',
      visualCue: 'Breathing is fast but chest rise is equal, SpO₂ is normal, and no labored breathing is noted.',
      findingChoices: _breathingFindings,
      actionChoices: _breathingActions,
      priorityChoices: [],
      correctFindingId: 'adequate',
      correctActionId: 'monitor-breathing',
      correctPriorityId: null,
      correctFeedback: 'Correct. Breathing is fast but currently adequate; continue immediately to circulation.',
      needsWorkFeedback: 'The biggest life threat is not ventilation here. Continue to circulation and bleeding control.',
      expectedSummary: 'Breathing currently adequate but fast; monitor and continue to circulation.',
    ),
    circulation: _ABCSection(
      title: 'C — Circulation',
      prompt: 'Identify and manage the circulation life threat.',
      visualCue: 'Blood soaking through the towel, weak rapid pulse, pale/cool/diaphoretic skin, dizziness.',
      findingChoices: _circulationFindings,
      actionChoices: _circulationActions,
      priorityChoices: [],
      correctFindingId: 'major-bleeding',
      correctActionId: 'control-bleeding',
      correctPriorityId: null,
      correctFeedback: 'Correct. Control life-threatening bleeding immediately, then treat for shock and reassess.',
      needsWorkFeedback: 'Major external bleeding is a circulation life threat. Control bleeding before moving to history.',
      expectedSummary: 'Major bleeding; control bleeding immediately, then treat for shock.',
      criticalMiss: 'Missed hemorrhage control: life-threatening bleeding must be controlled immediately.',
    ),
    priority: _ABCSection(
      title: 'Priority Decision',
      prompt: 'Set priority after bleeding control is started.',
      visualCue: 'Major bleeding plus shock signs means unstable even if airway and breathing are acceptable.',
      findingChoices: [],
      actionChoices: [],
      priorityChoices: _priorityChoices,
      correctFindingId: null,
      correctActionId: null,
      correctPriorityId: 'unstable-rapid',
      correctFeedback: 'Correct. This is unstable because of bleeding and shock signs.',
      needsWorkFeedback: 'Major bleeding and poor perfusion make this unstable.',
      expectedSummary: 'Unstable; bleeding control, shock care, rapid transport/ALS as appropriate.',
      criticalMiss: 'Priority miss: major bleeding with shock signs is not stable.',
    ),
    teachingPoint: 'Students often rush to SAMPLE on bleeding patients. In primary assessment, control life-threatening bleeding before moving into history.',
  ),
];
