import 'package:emscode_sim_vitals/learn_vitals/learn_vitals_models.dart';
import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LearnVitalsHubPage extends StatelessWidget {
  const LearnVitalsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EMSVitalsScaffold(
      title: 'Learn Vitals',
      subtitle: 'Pick a vital to practice.',
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
                    EMSSectionCard(
                      title: 'Vitals',
                      subtitle: 'Choose one to practice right now.',
                      child: Column(
                        children: [
                          _PracticeLinkTile(
                            title: 'Blood Pressure',
                            subtitle: 'Pump, release, listen, and estimate systolic/diastolic.',
                            icon: Icons.speed,
                            onTap: () => context.push(AppRoutes.bloodPressure),
                          ),
                          const SizedBox(height: 10),
                          _PracticeLinkTile(
                            title: 'Pulse',
                            subtitle: 'Estimate rate and connect pulse quality to perfusion.',
                            icon: Icons.favorite,
                            onTap: () => context.push(AppRoutes.pulseTest),
                          ),
                          const SizedBox(height: 10),
                          _PracticeLinkTile(
                            title: 'Skin Signs',
                            subtitle: 'Compare baseline skin to pale, flushed, wet, dry, cyanotic, and mottled findings.',
                            icon: Icons.palette,
                            onTap: () => context.push(AppRoutes.skinVital),
                          ),
                          const SizedBox(height: 10),
                          _PracticeLinkTile(
                            title: 'Pupils',
                            subtitle: 'Document size, equality, reactivity, and patient-left/right.',
                            icon: Icons.remove_red_eye,
                            onTap: () => context.push(AppRoutes.pupilAssessment),
                          ),
                          const SizedBox(height: 10),
                          _PracticeLinkTile(
                            title: 'Breath Sounds',
                            subtitle: 'Listen and identify breath sounds by lung field.',
                            icon: Icons.spatial_audio_off,
                            onTap: () => context.push(AppRoutes.breathSound),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: 'Optional',
                      subtitle: 'If you want to run a full set like a real call.',
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: () => context.push(AppRoutes.fullVitalsSet),
                          style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                          icon: const Icon(Icons.assignment_turned_in, color: Colors.white),
                          label: const Text('Full Vitals Set Practice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: 'Learn (reference)',
                      subtitle: 'Normal ranges and documentation notes.',
                      child: Column(
                        children: [
                          for (final v in VitalId.values) ...[
                            _VitalTile(vital: v),
                            if (v != VitalId.values.last) const SizedBox(height: 10),
                          ],
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
