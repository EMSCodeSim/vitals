import 'package:emscode_sim_vitals/app/app_state.dart';
import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/shared/visual_training_widgets.dart';
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
      subtitle: 'Video-style patient assessment: one scene, one decision, one feedback card.',
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
                    EMSVisualHero(
                      title: 'Choose a patient scene',
                      subtitle: 'The run screen now works like a guided animation: watch the cue, tap the action, get feedback.',
                      icon: Icons.personal_injury_rounded,
                      accent: const Color(0xFF22C55E),
                      steps: const ['Scene cue', 'Student choice', 'Feedback'],
                    ),
                    const SizedBox(height: 12),
                    EMSStoryboard(
                      title: 'Walkthrough rhythm',
                      items: const [
                        EMSStoryboardItem(icon: Icons.visibility_rounded, label: 'Observe', caption: 'Read the visual cue', accent: Color(0xFF22C55E)),
                        EMSStoryboardItem(icon: Icons.touch_app_rounded, label: 'Tap', caption: 'Choose action/finding', accent: AppColors.emsBlue),
                        EMSStoryboardItem(icon: Icons.check_circle_rounded, label: 'Correct', caption: 'See why it matters', accent: Color(0xFFF97316)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: 'Mode',
                      subtitle: 'Pick coaching level.',
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
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SegmentedButton<WalkthroughMode>(
                                showSelectedIcon: false,
                                segments: [
                                  for (final m in WalkthroughMode.values)
                                    ButtonSegment(value: m, label: Text(m.label), icon: Icon(m == WalkthroughMode.learn ? Icons.school : m == WalkthroughMode.practice ? Icons.fitness_center : Icons.timer)),
                                ],
                                selected: {_mode},
                                onSelectionChanged: (s) => setState(() => _mode = s.first),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: () => context.read<AppState>().setInstructorMode(!instructor),
                              style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                              icon: Icon(instructor ? Icons.visibility_off : Icons.visibility),
                              label: Text(instructor ? 'Instructor OFF' : 'Instructor ON'),
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
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onStart,
        splashFactory: NoSplash.splashFactory,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 112,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accentFor(c).withValues(alpha: 0.92), AppColors.emsCyan.withValues(alpha: 0.68)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(right: -20, top: -28, child: Icon(Icons.person_rounded, size: 140, color: Colors.white.withValues(alpha: 0.16))),
                  Positioned(left: 16, top: 16, child: Icon(_iconFor(c), color: Colors.white, size: 34)),
                  Positioned(
                    right: 16,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.22))),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 4),
                          Text('${c.steps.length} steps', style: context.textStyles.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(c.title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                      Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('${c.age}y/o ${c.sex} • CC: ${c.chiefComplaint}', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _MiniPill(icon: Icons.visibility_rounded, label: 'Scene'),
                      _MiniPill(icon: Icons.touch_app_rounded, label: 'Choices'),
                      _MiniPill(icon: Icons.feedback_rounded, label: 'Feedback'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(AssessmentCase c) {
    final text = '${c.title} ${c.chiefComplaint}'.toLowerCase();
    if (text.contains('chest')) return Icons.monitor_heart_rounded;
    if (text.contains('sob') || text.contains('breath')) return Icons.air_rounded;
    if (text.contains('trauma')) return Icons.healing_rounded;
    if (text.contains('ams') || text.contains('altered')) return Icons.psychology_rounded;
    return Icons.personal_injury_rounded;
  }

  Color _accentFor(AssessmentCase c) {
    final text = '${c.title} ${c.chiefComplaint}'.toLowerCase();
    if (text.contains('chest')) return AppColors.danger;
    if (text.contains('sob') || text.contains('breath')) return const Color(0xFF0EA5E9);
    if (text.contains('trauma')) return const Color(0xFFF97316);
    if (text.contains('ams') || text.contains('altered')) return const Color(0xFF7C3AED);
    return const Color(0xFF22C55E);
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.48), borderRadius: BorderRadius.circular(999), border: Border.all(color: cs.outline.withValues(alpha: 0.12))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.emsBlue),
          const SizedBox(width: 5),
          Text(label, style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
