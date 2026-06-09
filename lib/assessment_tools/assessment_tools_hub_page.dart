import 'package:emscode_sim_vitals/assessment_tools/assessment_tools_models.dart';
import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AssessmentToolsHubPage extends StatelessWidget {
  const AssessmentToolsHubPage({super.key});

  static const List<ToolId> _assessmentOnlyTools = [
    ToolId.sample,
    ToolId.opqrst,
    ToolId.generalImpression,
    ToolId.primaryAssessment,
    ToolId.secondaryAssessment,
    ToolId.dcapbtls,
    ToolId.stroke,
    ToolId.breathSounds,
    ToolId.ruleOfNines,
    ToolId.painScale,
  ];

  @override
  Widget build(BuildContext context) {
    return EMSVitalsScaffold(
      title: 'Assessment Tools',
      subtitle: 'Assessment-only skills after vitals: history, primary assessment, focused exams, reassessment, and reports.',
      onInfoPressed: () {
        EMSInfoSheet.show(
          context,
          title: 'How to use tools',
          children: const [
            Text('These are fast “field-friendly” reminders.'),
            SizedBox(height: 12),
            Text('Vitals are intentionally kept in the Vitals section. This page focuses on assessment tools and decision flow.'),
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
                    for (final t in _assessmentOnlyTools) ...[
                      _ToolTile(tool: t),
                      if (t != _assessmentOnlyTools.last) const SizedBox(height: 12),
                    ],
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
