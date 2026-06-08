import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:emscode_sim_vitals/treatments/treatment_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TreatmentsHubPage extends StatefulWidget {
  const TreatmentsHubPage({super.key});

  @override
  State<TreatmentsHubPage> createState() => _TreatmentsHubPageState();
}

class _TreatmentsHubPageState extends State<TreatmentsHubPage> {
  int _scenarioIndex = 0;
  final Set<TreatmentId> _selected = {};
  bool _checked = false;

  DecisionScenario get _scenario => DecisionScenarios.all[_scenarioIndex];

  void _reset({int? index}) {
    setState(() {
      _scenarioIndex = index ?? _scenarioIndex;
      _selected.clear();
      _checked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return EMSVitalsScaffold(
      title: 'EMT Treatments & Meds',
      subtitle: 'Learn when to consider common EMT treatments, what to check first, and what to reassess after treatment.',
      onInfoPressed: () {
        EMSInfoSheet.show(
          context,
          title: 'Protocol note',
          children: const [
            Text('Medication and treatment rules vary by state, agency, and medical direction.'),
            SizedBox(height: 10),
            Text('This section teaches EMT decision-making. It is not a universal medication order set.'),
            SizedBox(height: 10),
            Text('Use wording like “consider per local protocol” and always follow your instructor and agency rules.'),
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
                    const EMSWarningNote(text: 'Medication/treatment rules vary by local protocol and medical direction. This app is for EMT education and decision practice.'),
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: 'How this section works',
                      subtitle: 'Each card teaches: when to consider it, what findings support it, what to check first, what not to miss, and what to reassess.',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          _MiniChip(icon: Icons.search, label: 'Findings'),
                          _MiniChip(icon: Icons.rule, label: 'Protocol checks'),
                          _MiniChip(icon: Icons.warning_amber, label: 'Red flags'),
                          _MiniChip(icon: Icons.repeat, label: 'Reassessment'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionHeader(title: 'Treatments', subtitle: 'Core EMT care decisions.'),
                    const SizedBox(height: 8),
                    for (final id in TreatmentContent.treatments) ...[
                      _TreatmentTile(id: id),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 6),
                    _SectionHeader(title: 'Medications', subtitle: 'Common EMT-level medication decision cards. Protocol dependent.'),
                    const SizedBox(height: 8),
                    for (final id in TreatmentContent.medications) ...[
                      _TreatmentTile(id: id),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: 'Treatment Decision Builder',
                      subtitle: 'Pick the treatments that fit this patient. The app uses “consider” language so students learn protocol-aware thinking.',
                      child: _DecisionBuilder(
                        scenario: _scenario,
                        selected: _selected,
                        checked: _checked,
                        onToggle: (id) {
                          setState(() {
                            if (_selected.contains(id)) {
                              _selected.remove(id);
                            } else {
                              _selected.add(id);
                            }
                          });
                        },
                        onCheck: () => setState(() => _checked = true),
                        onNext: () => _reset(index: (_scenarioIndex + 1) % DecisionScenarios.all.length),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: cs.primary.withValues(alpha: 0.16))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('How this connects to patient assessments', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Text('After students collect vitals and complete SAMPLE/OPQRST, they should choose treatment, check contraindications, request ALS/rapid transport when needed, and reassess.', style: context.textStyles.bodySmall?.copyWith(height: 1.35, color: cs.onSurfaceVariant)),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => context.push(AppRoutes.walkthrough),
                              icon: const Icon(Icons.route),
                              label: const Text('Practice in Patient Assessment'),
                            ),
                          ),
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
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(999), border: Border.all(color: cs.outline.withValues(alpha: 0.12))),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(child: Text(title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
        Text(subtitle, style: context.textStyles.labelSmall?.copyWith(color: cs.onSurfaceVariant), overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _TreatmentTile extends StatelessWidget {
  const _TreatmentTile({required this.id});
  final TreatmentId id;

  @override
  Widget build(BuildContext context) {
    final lesson = TreatmentContent.lessons[id]!;
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: () => context.push('${AppRoutes.treatments}/${id.id}'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        splashFactory: NoSplash.splashFactory,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(gradient: LinearGradient(colors: AppColors.headerGradient.map((c) => c.withValues(alpha: 0.14)).toList()), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
                child: Icon(id.icon, color: AppColors.emsBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(id.title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900))),
                        if (id.isMedication)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                            child: Text('Protocol', style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: Colors.orange.shade800)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(lesson.usedFor, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _DecisionBuilder extends StatelessWidget {
  const _DecisionBuilder({required this.scenario, required this.selected, required this.checked, required this.onToggle, required this.onCheck, required this.onNext});

  final DecisionScenario scenario;
  final Set<TreatmentId> selected;
  final bool checked;
  final ValueChanged<TreatmentId> onToggle;
  final VoidCallback onCheck;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final options = <TreatmentId>{...scenario.bestChoices, ...scenario.avoidChoices}.toList();
    final missed = scenario.bestChoices.where((id) => !selected.contains(id)).toList();
    final unsafe = scenario.avoidChoices.where(selected.contains).toList();
    final correctSelected = selected.where(scenario.bestChoices.contains).length;
    final scoreText = '${correctSelected}/${scenario.bestChoices.length} key choices selected';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(scenario.title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final f in scenario.findings) Chip(label: Text(f), avatar: const Icon(Icons.monitor_heart, size: 16))],
        ),
        const SizedBox(height: 12),
        for (final id in options) ...[
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: selected.contains(id),
            onChanged: (_) => onToggle(id),
            title: Text('Consider ${id.title}', style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
            subtitle: Text(id.isMedication ? 'Medication/protocol dependent' : 'Treatment decision', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const Divider(height: 1),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: FilledButton.icon(onPressed: onCheck, icon: const Icon(Icons.check), label: const Text('Check Decision'))),
            const SizedBox(width: 10),
            IconButton.filledTonal(onPressed: onNext, icon: const Icon(Icons.refresh), tooltip: 'New case'),
          ],
        ),
        if (checked) ...[
          const SizedBox(height: 12),
          EMSResultBox(
            title: unsafe.isEmpty && missed.isEmpty ? 'Good treatment decision' : unsafe.isNotEmpty ? 'Unsafe/protocol concern' : 'Needs more treatment choices',
            message: [
              scoreText,
              scenario.feedback,
              if (missed.isNotEmpty) 'Missed: ${missed.map((e) => e.title).join(', ')}.',
              if (unsafe.isNotEmpty) 'Avoid: ${unsafe.map((e) => e.title).join(', ')}.',
            ].join('\n'),
            kind: unsafe.isNotEmpty ? EMSResultKind.error : missed.isNotEmpty ? EMSResultKind.warning : EMSResultKind.success,
          ),
        ],
      ],
    );
  }
}
