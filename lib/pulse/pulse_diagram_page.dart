import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PulseDiagramPage extends StatelessWidget {
  const PulseDiagramPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return EMSVitalsScaffold(
      title: 'Pulse point diagram',
      subtitle: 'Locate a pulse point first, then practice counting + quality.',
      bodySlivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                          border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Image.asset('assets/images/pulse_points_diagram.png', fit: BoxFit.contain),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.32),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.pan_tool_alt_outlined, color: cs.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Use 2 fingers. Do not use your thumb. Primary focus: radial pulse (wrist).\nBrachial is commonly used in infants.',
                              style: context.textStyles.bodyMedium?.copyWith(height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: () => context.push(AppRoutes.pulseTest),
                        style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)))),
                        icon: const Icon(Icons.arrow_forward, color: Colors.white),
                        label: const Text('Next: Practice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
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
