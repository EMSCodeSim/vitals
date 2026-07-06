import 'package:emscode_sim_vitals/assessment_tools/assessment_tools_models.dart';
import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/shared/visual_training_widgets.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AssessmentToolsHubPage extends StatelessWidget {
  const AssessmentToolsHubPage({super.key});

  static const List<ToolId> _coreTools = [
    ToolId.primaryAssessment,
    ToolId.generalImpression,
    ToolId.sample,
    ToolId.opqrst,
    ToolId.secondaryAssessment,
    ToolId.dcapbtls,
  ];

  static const List<ToolId> _focusedExamTools = [
    ToolId.stroke,
    ToolId.ruleOfNines,
    ToolId.painScale,
    ToolId.breathSounds,
  ];

  @override
  Widget build(BuildContext context) {
    return EMSVitalsScaffold(
      title: 'Assessment Tools',
      subtitle: 'Graphic assessment flow with scene cards, prompts, and quick decision checks.',
      onInfoPressed: () {
        EMSInfoSheet.show(
          context,
          title: 'How to use tools',
          children: const [
            Text('Start with scenarios when you want a full assessment flow.'),
            SizedBox(height: 12),
            Text('Use tools when you want quick reps: SAMPLE, OPQRST, primary, secondary, and focused exams.'),
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
                    EMSVisualHero(
                      title: 'Assessment Walkthrough',
                      subtitle: 'Looks more like a mini training video: scene cue → student decision → feedback.',
                      icon: Icons.route_rounded,
                      accent: const Color(0xFF22C55E),
                      steps: const ['Scene', 'Decision', 'Feedback'],
                      actionLabel: 'Start Walkthrough',
                      onAction: () => context.push(AppRoutes.walkthrough),
                    ),
                    const SizedBox(height: 12),
                    EMSStoryboard(
                      title: 'Primary flow',
                      items: const [
                        EMSStoryboardItem(icon: Icons.shield_rounded, label: 'Scene', caption: 'Safe, PPE, resources', accent: Color(0xFF22C55E)),
                        EMSStoryboardItem(icon: Icons.visibility_rounded, label: 'General', caption: 'Sick or not sick?', accent: Color(0xFF14B8A6)),
                        EMSStoryboardItem(icon: Icons.air_rounded, label: 'ABC', caption: 'Airway, breathing, circulation', accent: AppColors.emsBlue),
                        EMSStoryboardItem(icon: Icons.history_edu_rounded, label: 'History', caption: 'SAMPLE / OPQRST', accent: Color(0xFFF97316)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: 'Scenario buttons',
                      subtitle: 'Start a visual case instead of reading a long lesson.',
                      child: Column(
                        children: [
                          _QuickActionTile(
                            title: 'Scene Size-Up Simulator',
                            subtitle: 'Scene safe/not safe, resources, PPE, NOI/MOI, patient count, and C-spine.',
                            icon: Icons.shield_rounded,
                            onTap: () => context.push(AppRoutes.sceneSizeUp),
                          ),
                          const SizedBox(height: 10),
                          _QuickActionTile(
                            title: 'ABC Assessment Simulator',
                            subtitle: 'Tap airway, breathing, circulation and score the first actions.',
                            icon: Icons.health_and_safety_rounded,
                            onTap: () => context.push(AppRoutes.abcAssessment),
                          ),
                          const SizedBox(height: 10),
                          _QuickActionTile(
                            title: 'Patient Assessment Walkthrough',
                            subtitle: 'One step on screen at a time.',
                            icon: Icons.route,
                            onTap: () => context.push(AppRoutes.walkthrough),
                          ),
                          const SizedBox(height: 10),
                          _QuickActionTile(
                            title: 'Patient Assessment Cases',
                            subtitle: 'Pick a patient and make decisions.',
                            icon: Icons.assignment,
                            onTap: () => context.push(AppRoutes.cases),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: 'Core Flow Tools',
                      subtitle: 'Short visual tool cards.',
                      child: Column(
                        children: [
                          for (final t in _coreTools) ...[
                            _ToolTile(tool: t),
                            if (t != _coreTools.last) const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: 'Focused Exams (optional)',
                      subtitle: 'Fast refreshers and drills. Breath sounds also lives in Vitals for practice.',
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(top: 12),
                          title: Text('Show focused exams', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                          subtitle: Text('Stroke, Rule of Nines, pain scale, breath sounds…', style: context.textStyles.bodySmall?.copyWith(height: 1.35, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          children: [
                            for (final t in _focusedExamTools) ...[
                              _ToolTile(tool: t),
                              if (t != _focusedExamTools.last) const SizedBox(height: 10),
                            ],
                          ],
                        ),
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

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.title, required this.subtitle, required this.icon, required this.onTap});
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashFactory: NoSplash.splashFactory,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.outline.withValues(alpha: 0.16)), color: cs.surfaceContainerHighest.withValues(alpha: 0.24)),
        child: Row(
          children: [
            Icon(icon, color: AppColors.emsBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.3)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.tool});
  final ToolId tool;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lesson = AssessmentToolsContent.lessonFor(tool.id);
    final subtitle = lesson?.usedFor ?? 'Tap to learn and practice.';

    return Card(
      child: InkWell(
        onTap: () => context.push('${AppRoutes.assessmentTools}/${tool.id}'),
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
                child: Icon(tool.icon, color: AppColors.emsBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tool.title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
