import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:emscode_sim_vitals/walkthrough/walkthrough_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PatientAssessmentCasesPage extends StatelessWidget {
  const PatientAssessmentCasesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final free = WalkthroughCases.all.where((c) => !c.locked).toList();
    final locked = WalkthroughCases.all.where((c) => c.locked).toList();

    return EMSVitalsScaffold(
      title: 'Cases',
      subtitle: 'Free cases included. Future add-on packs appear as locked cards (“Coming Soon”).',
      onInfoPressed: () {
        EMSInfoSheet.show(
          context,
          title: 'About case packs',
          children: const [
            Text('This app is local-only today (no backend).'),
            SizedBox(height: 12),
            Text('Locked packs are placeholders for future paid add-ons. Nothing is charged or purchased in this build.'),
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
                    EMSSectionCard(
                      title: 'Free cases',
                      child: Column(
                        children: [
                          for (final c in free) ...[
                            _CaseTile(
                              title: c.title,
                              subtitle: '${c.age}y/o ${c.sex} • CC: ${c.chiefComplaint}',
                              body: c.presentation,
                              locked: false,
                              onTap: () => context.push('${AppRoutes.walkthrough}/run/${c.id}?mode=practice'),
                            ),
                            if (c != free.last) const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: 'Coming Soon — Advanced Assessment Packs',
                      subtitle: 'Locked placeholders (no payments in this project yet).',
                      child: Column(
                        children: [
                          for (final c in locked) ...[
                            _CaseTile(
                              title: c.title,
                              subtitle: 'Coming Soon — ${c.packTitle ?? 'Advanced Pack'}',
                              body: 'Locked case pack placeholder. Structure is ready for future add-ons.',
                              locked: true,
                              onTap: null,
                            ),
                            if (c != locked.last) const SizedBox(height: 12),
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

class _CaseTile extends StatelessWidget {
  const _CaseTile({required this.title, required this.subtitle, required this.body, required this.locked, required this.onTap});
  final String title;
  final String subtitle;
  final String body;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Card(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            splashFactory: NoSplash.splashFactory,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                      if (locked)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(999), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.lock, size: 16, color: cs.onSurfaceVariant), const SizedBox(width: 8), Text('Locked', style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w900))]),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                  const SizedBox(height: 10),
                  Text(body, style: context.textStyles.bodySmall?.copyWith(height: 1.35)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: locked ? null : onTap,
                      style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
                      icon: Icon(locked ? Icons.lock : Icons.play_arrow, color: Colors.white),
                      label: Text(locked ? 'Coming Soon' : 'Start', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (locked)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(color: cs.surface.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
            ),
          ),
      ],
    );
  }
}
