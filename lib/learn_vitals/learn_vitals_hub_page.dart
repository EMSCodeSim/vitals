import 'package:emscode_sim_vitals/learn_vitals/learn_vitals_models.dart';
import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/shared/visual_training_widgets.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LearnVitalsHubPage extends StatelessWidget {
  const LearnVitalsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EMSVitalsScaffold(
      title: 'Learn Vitals',
      subtitle: 'Pick a visual demo, then practice the skill.',
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
                      title: 'Vitals Lab',
                      subtitle: 'Start with a picture or animated drill, then answer normal/not normal.',
                      icon: Icons.monitor_heart_rounded,
                      accent: AppColors.emsBlue,
                      imageAsset: 'assets/images/bp_cuff_stethoscope_placement.png',
                      steps: const ['Position', 'Measure', 'Document'],
                      actionLabel: 'Open BP demo',
                      onAction: () => context.push(AppRoutes.bloodPressure),
                    ),
                    const SizedBox(height: 12),
                    EMSStoryboard(
                      title: 'Video-style practice loop',
                      items: const [
                        EMSStoryboardItem(icon: Icons.image_rounded, label: 'Photo cue', caption: 'Show placement or patient finding'),
                        EMSStoryboardItem(icon: Icons.play_arrow_rounded, label: 'Demo', caption: 'Animated countdown or sound'),
                        EMSStoryboardItem(icon: Icons.edit_note_rounded, label: 'Chart', caption: 'Rate, quality, normal?'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _VisualPracticeGrid(
                      children: [
                        _PracticeLinkTile(
                          title: 'Blood Pressure',
                          subtitle: 'Cuff + stethoscope visual demo.',
                          icon: Icons.speed,
                          imageAsset: 'assets/images/bp_cuff_stethoscope_placement.png',
                          onTap: () => context.push(AppRoutes.bloodPressure),
                        ),
                        _PracticeLinkTile(
                          title: 'Pulse',
                          subtitle: 'Pulse points + rate drill.',
                          icon: Icons.favorite,
                          imageAsset: 'assets/images/pulse_points_diagram.png',
                          onTap: () => context.push(AppRoutes.pulseTest),
                        ),
                        _PracticeLinkTile(
                          title: 'Respirations',
                          subtitle: 'Watch chest rise countdown.',
                          icon: Icons.air,
                          imageAsset: 'assets/images/respirations_tutorial.png',
                          onTap: () => context.push('${AppRoutes.learnVitals}/${VitalId.respiratoryRate.id}'),
                        ),
                        _PracticeLinkTile(
                          title: 'Pupils',
                          subtitle: 'Patient-left/right visual check.',
                          icon: Icons.remove_red_eye,
                          onTap: () => context.push(AppRoutes.pupilAssessment),
                        ),
                        _PracticeLinkTile(
                          title: 'Breath Sounds',
                          subtitle: 'Tap lung fields and identify sounds.',
                          icon: Icons.spatial_audio_off,
                          onTap: () => context.push(AppRoutes.breathSound),
                        ),
                        _PracticeLinkTile(
                          title: 'Full Set',
                          subtitle: 'Run BP, pulse, RR, skin, pupils.',
                          icon: Icons.assignment_turned_in,
                          onTap: () => context.push(AppRoutes.fullVitalsSet),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: 'Quick reference',
                      subtitle: 'Short range cards only — tap for the full practice screen.',
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


class _VisualPracticeGrid extends StatelessWidget {
  const _VisualPracticeGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCols = constraints.maxWidth >= 620;
        final tileWidth = twoCols ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final child in children) SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}

class _PracticeLinkTile extends StatelessWidget {
  const _PracticeLinkTile({required this.title, required this.subtitle, required this.icon, required this.onTap, this.imageAsset});
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 104,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageAsset != null)
                    Image.asset(
                      imageAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppColors.emsBlue.withValues(alpha: 0.10)),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.emsBlue.withValues(alpha: 0.16), AppColors.emsCyan.withValues(alpha: 0.12)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.black.withValues(alpha: 0.38)], begin: Alignment.topCenter, end: Alignment.bottomCenter)))),
                  Positioned(
                    left: 12,
                    bottom: 10,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Icon(icon, color: AppColors.emsBlue),
                    ),
                  ),
                  const Positioned(
                    right: 12,
                    bottom: 14,
                    child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 30),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.3)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
