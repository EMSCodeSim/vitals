import 'dart:math';

import 'package:emscode_sim_vitals/burn/burn_body_diagram.dart';
import 'package:emscode_sim_vitals/burn/burn_case.dart';
import 'package:emscode_sim_vitals/burn/burn_models.dart';
import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:emscode_sim_vitals/dev/dev_flags.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RuleOfNinesPage extends StatefulWidget {
  const RuleOfNinesPage({super.key});

  @override
  State<RuleOfNinesPage> createState() => _RuleOfNinesPageState();
}

class _RuleOfNinesPageState extends State<RuleOfNinesPage> {
  final _rng = Random();

  BurnPatientType _patientType = BurnPatientType.adult;
  BurnDepth _burnDepth = BurnDepth.partialThickness;
  BurnViewSide _viewSide = BurnViewSide.front;
  final Set<BurnRegionId> _selected = <BurnRegionId>{};

  int _palms = 0;
  final TextEditingController _palmsCtrl = TextEditingController();

  final TextEditingController _weightKgCtrl = TextEditingController();
  final TextEditingController _hoursSinceCtrl = TextEditingController();
  final TextEditingController _tbsaForFluidCtrl = TextEditingController();

  bool _fluidManuallyEditedTbsa = false;

  // Burn center considerations
  final Map<String, bool> _riskChecks = {
    'Face involved': false,
    'Hands involved': false,
    'Feet involved': false,
    'Genitalia/perineum involved': false,
    'Major joint involved': false,
    'Circumferential burn': false,
    'Inhalation concern': false,
    'Chemical burn': false,
    'Electrical burn': false,
    'Pediatric patient': false,
  };

  BurnPracticeCase? _practiceCase;
  String? _practiceFeedback;
  bool? _practicePass;
  List<String> _practiceDetails = const [];

  @override
  void initState() {
    super.initState();
    _syncTbsaToFluidIfNeeded(force: true);
    _palmsCtrl.text = '';
  }

  @override
  void dispose() {
    _palmsCtrl.dispose();
    _weightKgCtrl.dispose();
    _hoursSinceCtrl.dispose();
    _tbsaForFluidCtrl.dispose();
    super.dispose();
  }

  void _showInfo() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About Rule of Nines', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'The Rule of Nines is a quick field method for estimating the percent of total body surface area burned.',
                    style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _InfoBullet(text: 'Count partial-thickness and full-thickness burns.'),
                  _InfoBullet(text: 'Do not count superficial burns.'),
                  _InfoBullet(text: 'Adult: head 9%, each arm 9%, front torso 18%, back torso 18%, each leg 18%, perineum 1%.'),
                  _InfoBullet(text: 'Pediatric patients have proportionally larger heads and smaller legs.'),
                  _InfoBullet(text: 'Patient palm including fingers is approximately 1% TBSA.'),
                  _InfoBullet(text: 'Use local protocol, medical control, and burn-center guidance.'),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ButtonStyle(
                        splashFactory: NoSplash.splashFactory,
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double get _tbsaCounted {
    if (!_burnDepth.countsTowardTbsa) return 0;
    final sum = _selected.fold<double>(0, (p, id) => p + BurnRegions.byId(id).percentFor(_patientType));
    return double.parse(sum.toStringAsFixed(2));
  }

  void _toggleRegion(BurnRegionId id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
      _practiceFeedback = null;
      _practicePass = null;
      _practiceDetails = const [];
    });

    _syncTbsaToFluidIfNeeded();
  }

  void _resetRegions() {
    setState(() {
      _selected.clear();
      _practiceFeedback = null;
      _practicePass = null;
      _practiceDetails = const [];
    });
    _syncTbsaToFluidIfNeeded(force: true);
  }

  void _newPracticeCase() {
    final c = BurnPracticeCase.generate(_rng);
    devLog('Generated burn practice case: ${c.describe()}');
    setState(() {
      _practiceCase = c;
      _patientType = c.patientType;
      _riskChecks['Pediatric patient'] = c.patientType == BurnPatientType.pediatric;
      _selected.clear();
      _burnDepth = BurnDepth.partialThickness;
      _viewSide = BurnViewSide.front;
      _practiceFeedback = null;
      _practicePass = null;
      _practiceDetails = const [];

      _weightKgCtrl.text = c.weightKg.toString();
      _hoursSinceCtrl.text = '';
      _fluidManuallyEditedTbsa = false;
    });
    _syncTbsaToFluidIfNeeded(force: true);
  }

  void _checkPracticeAnswer() {
    final c = _practiceCase;
    if (c == null) return;

    final correctRegions = c.regions;
    final correctDepth = c.depth;
    final correctTbsa = c.correctTbsa();

    final selectedRegions = Set<BurnRegionId>.from(_selected);
    final missed = correctRegions.difference(selectedRegions);
    final extra = selectedRegions.difference(correctRegions);

    final studentTbsa = _tbsaCounted;

    final tol = c.patientType == BurnPatientType.adult ? 1.0 : 2.0;
    final tbsaClose = (studentTbsa - correctTbsa).abs() <= tol;
    final depthMatch = _burnDepth == correctDepth;
    final regionMatch = missed.isEmpty && extra.isEmpty;

    final pass = depthMatch && regionMatch && tbsaClose;
    final closeEnough = !pass && tbsaClose && regionMatch;

    final details = <String>[];
    if (missed.isNotEmpty) {
      final missedLabels = missed.map((r) => BurnRegions.byId(r).shortLabel).toList()..sort();
      details.add('Missed: ${missedLabels.join(', ')}');
    }
    if (extra.isNotEmpty) {
      final extraLabels = extra.map((r) => BurnRegions.byId(r).shortLabel).toList()..sort();
      details.add('Extra: ${extraLabels.join(', ')}');
    }

    String teaching;
    if (correctDepth == BurnDepth.superficial) {
      teaching = 'Teaching point: superficial redness alone is not counted toward TBSA.';
    } else if (_burnDepth == BurnDepth.superficial) {
      teaching = 'Teaching point: superficial burns are not counted; switch to partial/full thickness when appropriate.';
    } else {
      teaching = 'Teaching point: add the selected region percentages for the correct patient type.';
    }
    final correctLong = correctRegions.map((r) => BurnRegions.byId(r).longLabel).toList()..sort();
    details.add('Correct regions: ${correctLong.join(', ')}');
    details.add('Correct depth: ${correctDepth.label}');
    details.add('Correct TBSA: ${_fmtPct(correctTbsa)} (tolerance ±${tol.toStringAsFixed(0)}%)');
    details.add(teaching);

    setState(() {
      _practicePass = pass || closeEnough;
      if (pass) {
        _practiceFeedback = '✅ Correct TBSA estimate.';
      } else if (closeEnough) {
        _practiceFeedback = '✅ Close enough. Correct TBSA: ${_fmtPct(correctTbsa)}.';
      } else {
        _practiceFeedback = '❌ Not quite. Correct TBSA: ${_fmtPct(correctTbsa)}.';
      }
      _practiceDetails = details;
    });
  }

  void _syncTbsaToFluidIfNeeded({bool force = false}) {
    if (_fluidManuallyEditedTbsa && !force) return;
    final v = _tbsaCounted;
    _tbsaForFluidCtrl.text = v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  }

  double? _parseDouble(String s) {
    final cleaned = s.trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selectedRegions = _selected.map((id) => BurnRegions.byId(id)).toList()..sort((a, b) => a.longLabel.compareTo(b.longLabel));

    final isTablet = MediaQuery.sizeOf(context).width >= 900;

    return EMSVitalsScaffold(
      title: 'Rule of Nines',
      subtitle: 'Tap burn regions to estimate %TBSA and review burn center criteria.',
      onInfoPressed: _showInfo,
      bodySlivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: _ReminderBanner(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xxl),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                _PatientTypeCard(
                  value: _patientType,
                  onChanged: (v) {
                    setState(() {
                      _patientType = v;
                      _riskChecks['Pediatric patient'] = v == BurnPatientType.pediatric;
                    });
                    _syncTbsaToFluidIfNeeded();
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _DiagramCard(
                  patientType: _patientType,
                  viewSide: _viewSide,
                  onViewSideChanged: (v) => setState(() => _viewSide = v),
                  selected: _selected,
                  onToggle: _toggleRegion,
                ),
                const SizedBox(height: AppSpacing.md),
                _BurnDepthCard(
                  value: _burnDepth,
                  onChanged: (v) {
                    setState(() => _burnDepth = v);
                    _syncTbsaToFluidIfNeeded();
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                if (isTablet)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _TbsaResultsCard(
                          patientType: _patientType,
                          depth: _burnDepth,
                          selectedRegions: selectedRegions,
                          tbsaCounted: _tbsaCounted,
                          onReset: _resetRegions,
                          onNewPractice: _newPracticeCase,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _PracticeCaseCard(
                          currentCase: _practiceCase,
                          feedback: _practiceFeedback,
                          pass: _practicePass,
                          details: _practiceDetails,
                          onGenerate: _newPracticeCase,
                          onCheck: _checkPracticeAnswer,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _TbsaResultsCard(
                    patientType: _patientType,
                    depth: _burnDepth,
                    selectedRegions: selectedRegions,
                    tbsaCounted: _tbsaCounted,
                    onReset: _resetRegions,
                    onNewPractice: _newPracticeCase,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _PracticeCaseCard(
                    currentCase: _practiceCase,
                    feedback: _practiceFeedback,
                    pass: _practicePass,
                    details: _practiceDetails,
                    onGenerate: _newPracticeCase,
                    onCheck: _checkPracticeAnswer,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _PalmarMethodCard(
                  palms: _palms,
                  controller: _palmsCtrl,
                  onChanged: (v) => setState(() => _palms = v),
                ),
                const SizedBox(height: AppSpacing.md),
                _FluidEstimateCard(
                  weightKgCtrl: _weightKgCtrl,
                  hoursSinceCtrl: _hoursSinceCtrl,
                  tbsaCtrl: _tbsaForFluidCtrl,
                  onTbsaChanged: () => _fluidManuallyEditedTbsa = true,
                  tbsaCounted: _tbsaCounted,
                  parseDouble: _parseDouble,
                ),
                const SizedBox(height: AppSpacing.md),
                _BurnCenterConsiderationsCard(
                  patientType: _patientType,
                  tbsaCounted: _tbsaCounted,
                  depth: _burnDepth,
                  checks: _riskChecks,
                  onChanged: (k, v) => setState(() => _riskChecks[k] = v),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Totals check: adult=${BurnRegions.totalFor(BurnPatientType.adult)}%, pediatric=${BurnRegions.totalFor(BurnPatientType.pediatric)}%',
                  style: context.textStyles.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReminderBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.22)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Only partial-thickness and full-thickness burns count toward TBSA. Do not count superficial burns.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface, height: 1.35, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientTypeCard extends StatelessWidget {
  const _PatientTypeCard({required this.value, required this.onChanged});
  final BurnPatientType value;
  final ValueChanged<BurnPatientType> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pediatricNote = 'Pediatric proportions vary by age. This is a quick field estimate. Use local protocol or a Lund-Browder chart when more precision is needed.';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient Type', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<BurnPatientType>(
                segments: const [
                  ButtonSegment(value: BurnPatientType.adult, label: Text('Adult'), icon: Icon(Icons.person)),
                  ButtonSegment(value: BurnPatientType.pediatric, label: Text('Pediatric / Small Child'), icon: Icon(Icons.child_care)),
                ],
                selected: {value},
                onSelectionChanged: (s) => onChanged(s.first),
                showSelectedIcon: false,
                style: ButtonStyle(splashFactory: NoSplash.splashFactory),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Rule totals: ${_fmtPct(BurnRegions.totalFor(value))}', style: context.textStyles.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            if (value == BurnPatientType.pediatric) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(pediatricNote, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.45)),
            ],
          ],
        ),
      ),
    );
  }
}

class _DiagramCard extends StatelessWidget {
  const _DiagramCard({required this.patientType, required this.viewSide, required this.onViewSideChanged, required this.selected, required this.onToggle});

  final BurnPatientType patientType;
  final BurnViewSide viewSide;
  final ValueChanged<BurnViewSide> onViewSideChanged;
  final Set<BurnRegionId> selected;
  final ValueChanged<BurnRegionId> onToggle;

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
                Expanded(child: Text('Burn Body Diagram', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<BurnViewSide>(
                        segments: const [
                          ButtonSegment(value: BurnViewSide.front, label: Text('Front')),
                          ButtonSegment(value: BurnViewSide.back, label: Text('Back')),
                        ],
                        selected: {viewSide},
                        onSelectionChanged: (s) => onViewSideChanged(s.first),
                        showSelectedIcon: false,
                        style: ButtonStyle(splashFactory: NoSplash.splashFactory),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Tap burned areas to add or remove them.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.md),
            BurnBodyDiagram(patientType: patientType, viewSide: viewSide, selected: selected, onToggle: onToggle),
          ],
        ),
      ),
    );
  }
}

class _BurnDepthCard extends StatelessWidget {
  const _BurnDepthCard({required this.value, required this.onChanged});
  final BurnDepth value;
  final ValueChanged<BurnDepth> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Burn Depth', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: BurnDepth.values
                  .map(
                    (d) => ChoiceChip(
                      label: Text(d.label),
                      selected: d == value,
                      onSelected: (_) => onChanged(d),
                      labelStyle: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: BorderSide(color: cs.outline.withValues(alpha: 0.18))),
                      selectedColor: AppColors.emsBlue.withValues(alpha: 0.16),
                      showCheckmark: false,
                    ),
                  )
                  .toList(),
            ),
            if (value == BurnDepth.superficial) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text('Superficial burns are not counted in TBSA.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TbsaResultsCard extends StatelessWidget {
  const _TbsaResultsCard({required this.patientType, required this.depth, required this.selectedRegions, required this.tbsaCounted, required this.onReset, required this.onNewPractice});

  final BurnPatientType patientType;
  final BurnDepth depth;
  final List<BurnRegion> selectedRegions;
  final double tbsaCounted;
  final VoidCallback onReset;
  final VoidCallback onNewPractice;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TBSA Estimate', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            Text('Estimated TBSA: ${_fmtPct(tbsaCounted)}', style: context.textStyles.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: AppSpacing.xs),
            Text('${patientType.label} patient', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            Text('Depth counted: ${depth.countsTowardTbsa ? depth.label : 'None (superficial)'}', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.md),
            Text('Selected regions', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            if (selectedRegions.isEmpty)
              Text('None selected.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant))
            else
              Column(
                children: selectedRegions
                    .map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(child: Text(r.longLabel, style: context.textStyles.bodySmall?.copyWith(height: 1.25))),
                            const SizedBox(width: AppSpacing.sm),
                            Text(_fmtPct(r.percentFor(patientType)), style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: onReset,
                      style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                      child: const Text('Reset'),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: onNewPractice,
                      style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                      child: const Text('New Practice Case'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PalmarMethodCard extends StatelessWidget {
  const _PalmarMethodCard({required this.palms, required this.controller, required this.onChanged});
  final int palms;
  final TextEditingController controller;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final est = palms.clamp(0, 99);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Small Burn / Palmar Method', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            Text('Patient\'s palm including fingers is approximately 1% TBSA.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.45)),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Number of patient palms', prefixIcon: Icon(Icons.back_hand)),
                    onChanged: (v) => onChanged(int.tryParse(v.trim()) ?? 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('${est} palms ≈ ${est}% TBSA', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _FluidEstimateCard extends StatelessWidget {
  const _FluidEstimateCard({required this.weightKgCtrl, required this.hoursSinceCtrl, required this.tbsaCtrl, required this.onTbsaChanged, required this.tbsaCounted, required this.parseDouble});

  final TextEditingController weightKgCtrl;
  final TextEditingController hoursSinceCtrl;
  final TextEditingController tbsaCtrl;
  final VoidCallback onTbsaChanged;
  final double tbsaCounted;
  final double? Function(String) parseDouble;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final weight = parseDouble(weightKgCtrl.text);
    final tbsa = parseDouble(tbsaCtrl.text);
    final hoursSince = parseDouble(hoursSinceCtrl.text);

    double? total;
    if (weight != null && tbsa != null) total = 4.0 * weight * tbsa;
    final firstHalf = total == null ? null : total / 2.0;
    final secondHalf = total == null ? null : total / 2.0;

    final warn = <String>[];
    if (tbsa != null && tbsa < 10) warn.add('Major fluid resuscitation is usually associated with larger burns. Follow local protocol.');
    if (tbsa != null && tbsa >= 20) warn.add('Large TBSA burn. Consider early IV access, fluid guidance, and burn-center consultation per protocol.');

    String? timing;
    if (hoursSince != null && hoursSince >= 0 && firstHalf != null) {
      timing = 'First half (${_fmtMl(firstHalf)}) should be given over the first 8 hours from time of burn.\nTime since burn: ${hoursSince.toStringAsFixed(1)}h.';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fluid Estimate — Training Only', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            Text('Parkland: 4 mL × body weight (kg) × TBSA %', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: weightKgCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Patient weight (kg)', prefixIcon: Icon(Icons.scale)),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: hoursSinceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Time since burn (hours)', prefixIcon: Icon(Icons.schedule)),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: tbsaCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'TBSA % (auto-filled)',
                prefixIcon: const Icon(Icons.percent),
                helperText: 'Current counted TBSA: ${_fmtPct(tbsaCounted)}',
              ),
              onChanged: (_) => onTbsaChanged(),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estimated fluid (first 24h): ${total == null ? '—' : _fmtMl(total)}', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('First half over first 8 hours: ${firstHalf == null ? '—' : _fmtMl(firstHalf)}', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  Text('Second half over next 16 hours: ${secondHalf == null ? '—' : _fmtMl(secondHalf)}', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  if (timing != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(timing, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Training estimate only. Follow local protocols, medical control, and burn center guidance.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
            if (warn.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              ...warn.map((t) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(t, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35))),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _BurnCenterConsiderationsCard extends StatelessWidget {
  const _BurnCenterConsiderationsCard({required this.patientType, required this.tbsaCounted, required this.depth, required this.checks, required this.onChanged});

  final BurnPatientType patientType;
  final double tbsaCounted;
  final BurnDepth depth;
  final Map<String, bool> checks;
  final void Function(String key, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final anyHighRisk = checks.values.any((v) => v);
    final basePrompts = <String>[
      'Partial-thickness burns around 10% TBSA or greater may need burn-center consultation.',
      'Full-thickness burns should prompt burn-center consultation.',
      'Burns involving face, hands, feet, genitalia, perineum, or major joints are higher concern.',
      'Chemical, electrical, inhalation injury, or pediatric burns may need burn-center consultation.',
      'Always follow local EMS protocol and medical control.',
    ];

    final autoFlags = <String>[];
    if (depth == BurnDepth.fullThickness) autoFlags.add('Full-thickness selected.');
    if (tbsaCounted >= 10 && depth != BurnDepth.superficial) autoFlags.add('TBSA ≥ 10% counted.');
    if (patientType == BurnPatientType.pediatric) autoFlags.add('Pediatric patient.');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Burn Center Considerations', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            ...basePrompts.map((t) => _InfoBullet(text: t)),
            if (autoFlags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Auto prompts: ${autoFlags.join('  •  ')}', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
            ],
            const SizedBox(height: AppSpacing.md),
            ...checks.entries.map(
              (e) => CheckboxListTile(
                value: e.value,
                onChanged: (v) => onChanged(e.key, v ?? false),
                title: Text(e.key, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            if (anyHighRisk) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.22)),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.local_hospital, color: AppColors.danger),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Higher-risk burn pattern. Consider burn-center consultation/transport per protocol.',
                        style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PracticeCaseCard extends StatelessWidget {
  const _PracticeCaseCard({required this.currentCase, required this.feedback, required this.pass, required this.details, required this.onGenerate, required this.onCheck});

  final BurnPracticeCase? currentCase;
  final String? feedback;
  final bool? pass;
  final List<String> details;
  final VoidCallback onGenerate;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = currentCase;
    final statusColor = pass == null
        ? cs.outline.withValues(alpha: 0.22)
        : (pass! ? Colors.green : AppColors.danger).withValues(alpha: 0.22);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Practice Case', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              c == null ? 'Generate a case, then tap regions + select depth + estimate TBSA.' : c.describe(),
              style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: onGenerate,
                      style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                      child: const Text('Generate Burn Case'),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: c == null ? null : onCheck,
                      style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                      child: const Text('Check Answer'),
                    ),
                  ),
                ),
              ],
            ),
            if (feedback != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: statusColor),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(feedback!, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      ...details.map((t) => Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('• $t', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                          )),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoBullet extends StatelessWidget {
  const _InfoBullet({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(999)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.45))),
        ],
      ),
    );
  }
}

String _fmtPct(double v) => '${v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2)}%';

String _fmtMl(double v) {
  final rounded = v.round();
  return '${rounded.toString()} mL';
}
