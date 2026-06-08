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
      subtitle: 'Step 1: learn each vital, practice individual skills, then complete a full vital set like an EMT assessment.',
      onInfoPressed: () {
        EMSInfoSheet.show(
          context,
          title: 'How this section works',
          children: const [
            Text('Start by learning what each vital means.'),
            SizedBox(height: 12),
            Text('Then practice specific skills like BP, pulse, pupils, and respiratory rate.'),
            SizedBox(height: 12),
            Text('Finish with a full vital set before moving into the patient assessment walkthrough.'),
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
                      title: '1) Learn Each Vital',
                      subtitle: 'Start here if you are new. Each vital uses the same thinking pattern: normal/not normal, what is wrong, and why it matters.',
                      child: Column(
                        children: [
                          for (final v in VitalId.values) ...[
                            _VitalTile(vital: v),
                            if (v != VitalId.values.last) const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: '2) Practice Individual Skills',
                      subtitle: 'Practice hands-on skills before the full vital set. Experienced students can skip straight to practice.',
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
                            title: 'Practice Respiratory Rate',
                            subtitle: 'Open the respiratory rate lesson for the counting drill.',
                            icon: Icons.air,
                            onTap: () => context.push('${AppRoutes.learnVitals}/${VitalId.respiratoryRate.id}'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: '3) Complete a Full Vitals Set',
                      subtitle: 'Put the pieces together: collect vitals, decide normal/not normal, explain why, then document the patient picture.',
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
                    const SizedBox(height: AppSpacing.md),
                    EMSResultBox(
                      title: 'Next step: Assessment Tools',
                      message: 'New EMTs should master vitals first. If you already know vitals, skip ahead to assessment tools and start SAMPLE, OPQRST, primary assessment, and treatment decisions.',
                      kind: EMSResultKind.info,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.assessmentTools),
                        style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                        icon: const Icon(Icons.fast_forward),
                        label: const Text('Skip to Assessment Tools'),
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
