import 'package:emscode_sim_vitals/app/app_state.dart';
import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:emscode_sim_vitals/walkthrough/walkthrough_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class WalkthroughHomePage extends StatefulWidget {
  const WalkthroughHomePage({super.key});

  @override
  State<WalkthroughHomePage> createState() => _WalkthroughHomePageState();
}

class _WalkthroughHomePageState extends State<WalkthroughHomePage> {
  WalkthroughMode _mode = WalkthroughMode.practice;

  @override
  void initState() {
    super.initState();
    // Default to global mode.
    final global = context.read<AppState>().mode;
    _mode = switch (global) {
      TrainingMode.learn => WalkthroughMode.learn,
      TrainingMode.practice => WalkthroughMode.practice,
      TrainingMode.test => WalkthroughMode.test,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final instructor = context.select<AppState, bool>((s) => s.instructorMode);
    final freeCases = WalkthroughCases.all.where((c) => !c.locked).toList();

    return EMSVitalsScaffold(
      title: 'Walkthrough',
      subtitle: 'Guided patient assessment — one step at a time. You’ll make choices and get instructor-style feedback.',
      onInfoPressed: () {
        EMSInfoSheet.show(
          context,
          title: 'Walkthrough modes',
          children: const [
            Text('Learn: hints + “why this matters” after each step.'),
            SizedBox(height: 8),
            Text('Practice: shorter feedback, fewer hints.'),
            SizedBox(height: 8),
            Text('Test: no feedback until the end — then you get a score + study areas.'),
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
                      title: 'Mode',
                      subtitle: 'Pick how coached you want this run to be.',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(instructor ? Icons.visibility : Icons.visibility_off, size: 18, color: cs.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Text(instructor ? 'Instructor: ON' : 'Instructor: OFF', style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurfaceVariant)),
                        ],
                      ),
                      child: Column(
                        children: [
                          SegmentedButton<WalkthroughMode>(
                            showSelectedIcon: false,
                            segments: [
                              for (final m in WalkthroughMode.values)
                                ButtonSegment(value: m, label: Text(m.label), icon: Icon(m == WalkthroughMode.learn ? Icons.school : m == WalkthroughMode.practice ? Icons.fitness_center : Icons.timer)),
                            ],
                            selected: {_mode},
                            onSelectionChanged: (s) => setState(() => _mode = s.first),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: () => context.read<AppState>().setInstructorMode(!instructor),
                              style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                              icon: Icon(instructor ? Icons.visibility_off : Icons.visibility),
                              label: Text(instructor ? 'Turn Instructor Mode OFF' : 'Turn Instructor Mode ON'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: 'Free walkthrough cases',
                      subtitle: 'Start here. More case packs can be added later.',
                      child: Column(
                        children: [
                          for (final c in freeCases) ...[
                            _CaseCard(
                              c: c,
                              onStart: () {
                                final modeStr = _mode.name;
                                context.push('${AppRoutes.walkthrough}/run/${c.id}?mode=$modeStr');
                              },
                            ),
                            if (c != freeCases.last) const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: 'More cases',
                      subtitle: 'Preview locked packs in the Cases section.',
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: () => context.push(AppRoutes.cases),
                          style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                          icon: const Icon(Icons.collections_bookmark, color: Colors.white),
                          label: const Text('Browse all cases', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.c, required this.onStart});
  final AssessmentCase c;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('${c.age}y/o ${c.sex} • CC: ${c.chiefComplaint}', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
          const SizedBox(height: 8),
          Text(c.presentation, style: context.textStyles.bodySmall?.copyWith(height: 1.35)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: onStart,
              style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text('Start', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
