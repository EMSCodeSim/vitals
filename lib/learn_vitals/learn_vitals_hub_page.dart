import 'package:emscode_sim_vitals/learn_vitals/learn_vitals_models.dart';
import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/shared/normal_not_normal.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LearnVitalsHubPage extends StatelessWidget {
  const LearnVitalsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EMSVitalsScaffold(
      title: 'Learn Vitals',
      subtitle: 'Practice vital signs in a clean, step-by-step flow: quick drills first, then a full set.',
      onInfoPressed: () {
        EMSInfoSheet.show(
          context,
          title: 'How this section works',
          children: const [
            Text('Start with quick practice drills (BP, pulse, pupils, breath sounds).'),
            SizedBox(height: 12),
            Text('Use “Learn Topics” when you want the deeper explanation and normal ranges.'),
            SizedBox(height: 12),
            Text('Finish with a full vital set practice, then move into the Assessment track.'),
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
                    const _StepHeroCard(),
                    const SizedBox(height: 12),
                    const NormalNotNormalCard(compact: true),
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: 'Quick Practice',
                      subtitle: 'Short drills that feel like real EMT muscle-memory practice.',
                      child: Column(
                        children: [
                          _PracticeLinkTile(
                            title: 'Practice Blood Pressure',
                            subtitle: 'Pump, release, listen, and estimate systolic/diastolic.',
                            icon: Icons.speed,
                            onTap: () => context.push(AppRoutes.bloodPressure),
                          ),
                          const SizedBox(height: 10),
                          _PracticeLinkTile(
                            title: 'Practice Pulse Count',
                            subtitle: 'Estimate rate and connect pulse quality to perfusion.',
                            icon: Icons.favorite,
                            onTap: () => context.push(AppRoutes.pulseTest),
                          ),
                          const SizedBox(height: 10),
                          _PracticeLinkTile(
                            title: 'Practice Pupils',
                            subtitle: 'Document size, equality, reactivity, and patient-left/right.',
                            icon: Icons.remove_red_eye,
                            onTap: () => context.push(AppRoutes.pupilAssessment),
                          ),
                          const SizedBox(height: 10),
                          _PracticeLinkTile(
                            title: 'Practice Breath Sounds',
                            subtitle: 'Listen and identify breath sounds by lung field.',
                            icon: Icons.spatial_audio_off,
                            onTap: () => context.push(AppRoutes.breathSound),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: 'Full Vitals Set',
                      subtitle: 'Put it together: collect vitals, decide normal/not normal, and document a patient picture.',
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: () => context.push(AppRoutes.fullVitalsSet),
                          style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                          icon: const Icon(Icons.assignment_turned_in, color: Colors.white),
                          label: const Text('Start Full Vitals Set Practice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: 'Learn Topics (optional)',
                      subtitle: 'Tap a topic for normal ranges, what it means, and how to document it.',
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(top: 12),
                          title: Text('Show vital lessons', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                          subtitle: Text('Blood pressure, pulse, respirations, skin, SpO₂, AVPU, AAOx4…', style: context.textStyles.bodySmall?.copyWith(height: 1.35, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          children: [
                            for (final v in VitalId.values) ...[
                              _VitalTile(vital: v),
                              if (v != VitalId.values.last) const SizedBox(height: 10),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.assessmentTools),
                        style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Go to Assessment'),
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

class _StepHeroCard extends StatelessWidget {
  const _StepHeroCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: AppColors.headerGradient.map((c) => c.withValues(alpha: 0.13)).toList(), begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.70), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.monitor_heart, color: AppColors.emsBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Step 1 — Master the Vitals', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('Learn what each vital means, decide normal vs not normal, explain why it matters, then complete a full set like you would on a real patient.', style: context.textStyles.bodyMedium?.copyWith(height: 1.4, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VitalTile extends StatelessWidget {
  const _VitalTile({required this.vital});
  final VitalId vital;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lesson = LearnVitalsContent.lessonFor(vital.id)!;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push('${AppRoutes.learnVitals}/${vital.id}'),
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
                child: Icon(vital.icon, color: AppColors.emsBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vital.title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(lesson.normalRange, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
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

class _PracticeLinkTile extends StatelessWidget {
  const _PracticeLinkTile({required this.title, required this.subtitle, required this.icon, required this.onTap});
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
