import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VitalsHomePage extends StatelessWidget {
  const VitalsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return EMSVitalsScaffold(
      title: 'EMSCodeSim Vitals',
      subtitle: 'Pick a track: master the vitals, or practice the assessment flow and focused exams.',
      showModePill: false,
      showBackButton: false,
      bodySlivers: [
        SliverToBoxAdapter(
          child: EMSCentered(
            maxWidth: 820,
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HomeActionCard(
                  icon: Icons.monitor_heart,
                  accent: cs.primary,
                  title: 'Vitals',
                  subtitle: 'Practice vital signs step-by-step (BP, pulse, respirations, pupils) and complete a full set.',
                  chips: const ['BP', 'Pulse', 'Respirations', 'Pupils', 'Full set'],
                  buttonText: 'Open Vitals',
                  onTap: () => context.push(AppRoutes.learnVitals),
                ),
                const SizedBox(height: 14),
                _HomeActionCard(
                  icon: Icons.fact_check,
                  accent: Colors.green,
                  title: 'Assessment',
                  subtitle: 'Practice the EMT assessment flow (primary, history, focused exams) and run patient scenarios.',
                  chips: const ['Primary', 'SAMPLE', 'OPQRST', 'Stroke', 'Burns'],
                  buttonText: 'Open Assessment',
                  onTap: () => context.push(AppRoutes.assessmentTools),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.chips,
    required this.buttonText,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final List<String> chips;
  final String buttonText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: accent, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: context.textStyles.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final chip in chips)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: cs.outline.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Text(
                        chip,
                        style: context.textStyles.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(buttonText),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FixedNavBar extends StatelessWidget {
  const _FixedNavBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.16),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.learnVitals),
                icon: const Icon(Icons.monitor_heart),
                label: const Text('Vitals'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => context.push(AppRoutes.assessmentTools),
                icon: const Icon(Icons.fact_check),
                label: const Text('Assessment'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
