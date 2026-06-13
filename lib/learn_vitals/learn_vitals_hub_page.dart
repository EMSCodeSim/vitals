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
                      subtitle: 'Choose a topic.',
                      child: Column(
                        children: [
                          _TopicTile(
                            title: 'Blood Pressure',
                            subtitle: 'Pump, deflate, listen, chart.',
                            icon: Icons.speed,
                            onTap: () => context.push(AppRoutes.bloodPressure),
                          ),
                          const SizedBox(height: 10),
                          _TopicTile(
                            title: 'Pulse',
                            subtitle: 'Count and identify rhythm.',
                            icon: Icons.favorite,
                            onTap: () => context.push(AppRoutes.pulseTest),
                          ),
                          const SizedBox(height: 10),
                          _TopicTile(
                            title: 'Respirations',
                            subtitle: 'Watch chest rise and count.',
                            icon: Icons.air,
                            onTap: () => context.push(AppRoutes.respirationsTest),
                          ),
                          const SizedBox(height: 10),
                          _TopicTile(
                            title: 'Pupils',
                            subtitle: 'PEARL + size/reactivity check.',
                            icon: Icons.remove_red_eye,
                            onTap: () => context.push(AppRoutes.pupilAssessment),
                          ),
                          const SizedBox(height: 10),
                          _TopicTile(
                            title: 'Breath Sounds',
                            subtitle: 'Auscultate and identify sounds.',
                            icon: Icons.spatial_audio_off,
                            onTap: () => context.push(AppRoutes.breathSound),
                          ),
                          const SizedBox(height: 10),
                          _TopicTile(
                            title: 'Full Vitals Set',
                            subtitle: 'Run a full set practice flow.',
                            icon: Icons.assignment_turned_in,
                            onTap: () => context.push(AppRoutes.fullVitalsSet),
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

class _TopicTile extends StatelessWidget {
  const _TopicTile({required this.title, required this.subtitle, required this.icon, required this.onTap});

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        splashFactory: NoSplash.splashFactory,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: AppColors.headerGradient.map((c) => c.withValues(alpha: 0.14)).toList()),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
                ),
                child: Icon(icon, color: AppColors.emsBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
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
