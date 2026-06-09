import 'package:emscode_sim_vitals/app/app_state.dart';
import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class VitalsHomePage extends StatelessWidget {
  const VitalsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.select<AppState, TrainingMode>((s) => s.mode);
    final instructor = context.select<AppState, bool>((s) => s.instructorMode);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            toolbarHeight: 132,
            flexibleSpace: _HomeHeader(mode: mode, instructor: instructor),
            bottom: const PreferredSize(preferredSize: Size.fromHeight(14), child: SizedBox(height: 14)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PrimaryHeroCard(
                        onStartVitals: () => context.push(AppRoutes.learnVitals),
                        onSkipToAssessment: () => context.push(AppRoutes.assessmentTools),
                        onStartPatient: () {
                          context.read<AppState>().markModuleOpened(TrainingModule.walkthrough);
                          context.push(AppRoutes.walkthrough);
                        },
                      ),
                      const SizedBox(height: 12),
                      _NormalNotNormalHero(),
                      const SizedBox(height: 12),
                      _ModeCard(mode: mode),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _PathwaySliver(
            step: '1',
            title: 'Vitals Walkthroughs + Practice',
            subtitle: 'Recommended first for new EMTs. Learn BP, pulse, respirations, SpO₂, skin, pupils, AVPU, AAOx, and pain before patient assessment.',
            badge: 'Start here',
            icon: Icons.monitor_heart,
            buttonText: 'Start Vitals',
            onTap: () => context.push(AppRoutes.learnVitals),
            primary: true,
          ),
          _PathwaySliver(
            step: '2',
            title: 'Assessment Tools + Practice',
            subtitle: 'Skip ahead if you already know vitals. Learn SAMPLE, OPQRST, primary assessment, stroke checks, trauma checks, reassessment, and reports.',
            badge: 'Skip allowed',
            icon: Icons.fact_check,
            buttonText: 'Open Assessment Tools',
            onTap: () => context.push(AppRoutes.assessmentTools),
          ),
          _PathwaySliver(
            step: '3',
            title: 'EMT Treatments & Meds',
            subtitle: 'Connect abnormal findings to EMT-level actions. Learn what to consider, what to check first, protocol cautions, and what to reassess.',
            badge: 'Decision layer',
            icon: Icons.medication,
            buttonText: 'Open Treatments & Meds',
            onTap: () {
              context.read<AppState>().markModuleOpened(TrainingModule.treatments);
              context.push(AppRoutes.treatments);
            },
          ),
          _PathwaySliver(
            step: '4',
            title: 'Patient Assessment Walkthrough',
            subtitle: 'Run the patient step by step. Determine mental status, collect vitals, use SAMPLE/OPQRST, choose treatment, reassess, and give report.',
            badge: 'Main skill',
            icon: Icons.route,
            buttonText: 'Start Walkthrough',
            onTap: () {
              context.read<AppState>().markModuleOpened(TrainingModule.walkthrough);
              context.push(AppRoutes.walkthrough);
            },
            primary: true,
          ),
          _PathwaySliver(
            step: '5',
            title: 'Patient Assessment Cases',
            subtitle: 'Practice free cases now. Future packs can add medical, trauma, respiratory, cardiac, pediatric, and AI patient interview simulations.',
            badge: 'Case library',
            icon: Icons.collections_bookmark,
            buttonText: 'Browse Cases',
            onTap: () => context.push(AppRoutes.cases),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxl),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Column(
                    children: [
                      _QuickToolsCard(),
                      const SizedBox(height: 12),
                      EMSResultBox(
                        title: 'Core learning rule',
                        message: 'Every major skill should ask: Is this normal? If not normal, why? What does it change in the assessment or treatment plan?',
                        kind: EMSResultKind.info,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.mode, required this.instructor});
  final TrainingMode mode;
  final bool instructor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: AppColors.headerGradient, begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.22))),
                    child: const Icon(Icons.medical_services, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('EMSCodeSim', style: context.textStyles.labelLarge?.copyWith(color: Colors.white.withValues(alpha: 0.84), fontWeight: FontWeight.w800)),
                        Text('Patient Assessment Trainer', style: context.textStyles.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  _HeaderPill(label: mode.label, icon: Icons.school),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Learn vitals first, then assessment tools, then treatments, then run the patient.',
                style: context.textStyles.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.94), height: 1.3, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _HeaderButton(icon: Icons.tune, label: 'Settings', onTap: () => context.push(AppRoutes.settings)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeaderButton(
                      icon: instructor ? Icons.visibility : Icons.visibility_off,
                      label: instructor ? 'Instructor ON' : 'Instructor OFF',
                      onTap: () => context.read<AppState>().setInstructorMode(!instructor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      splashFactory: NoSplash.splashFactory,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.22))),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: context.textStyles.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.22))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 7),
          Text(label, style: context.textStyles.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _PrimaryHeroCard extends StatelessWidget {
  const _PrimaryHeroCard({required this.onStartVitals, required this.onSkipToAssessment, required this.onStartPatient});
  final VoidCallback onStartVitals;
  final VoidCallback onSkipToAssessment;
  final VoidCallback onStartPatient;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(gradient: LinearGradient(colors: AppColors.headerGradient.map((c) => c.withValues(alpha: 0.18)).toList()), borderRadius: BorderRadius.circular(18), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
                  child: const Icon(Icons.route, color: AppColors.emsBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Build the patient assessment step by step.', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text('New EMTs should start with vitals. Students who already know vitals can skip ahead and use the app as a practice lab.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _MiniPathRow(label: 'Vitals', detail: 'Normal / not normal / why'),
            const SizedBox(height: 8),
            _MiniPathRow(label: 'Assessment', detail: 'SAMPLE, OPQRST, primary, focused'),
            const SizedBox(height: 8),
            _MiniPathRow(label: 'Treatment', detail: 'Consider action, check red flags, reassess'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: onStartVitals,
                      style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                      icon: const Icon(Icons.monitor_heart, color: Colors.white),
                      label: const Text('Start with Vitals', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: onSkipToAssessment,
                      style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                      icon: const Icon(Icons.fast_forward),
                      label: const Text('Skip Ahead'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: onStartPatient,
                style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                icon: const Icon(Icons.play_circle),
                label: const Text('Go Straight to Patient Assessment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPathRow extends StatelessWidget {
  const _MiniPathRow({required this.label, required this.detail});
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(14), border: Border.all(color: cs.outline.withValues(alpha: 0.11))),
      child: Row(
        children: [
          Text(label, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          Expanded(child: Text(detail, textAlign: TextAlign.right, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _NormalNotNormalHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_alt, color: AppColors.emsBlue),
                const SizedBox(width: 8),
                Expanded(child: Text('The app-wide thinking pattern', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900))),
              ],
            ),
            const SizedBox(height: 10),
            Text('Every finding should lead to a decision:', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 10),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ThinkingChip(label: 'Normal?'),
                _ThinkingChip(label: 'Not normal?'),
                _ThinkingChip(label: 'Why?'),
                _ThinkingChip(label: 'What next?'),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.emsBlue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.emsBlue.withValues(alpha: 0.16))),
              child: Text('Example: Pulse 110 and irregular → Not normal: fast and not regular. Why it matters: check perfusion, BP, skin signs, pain, chest complaint, and reassess.', style: context.textStyles.bodySmall?.copyWith(height: 1.35, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThinkingChip extends StatelessWidget {
  const _ThinkingChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label, style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w900)), avatar: const Icon(Icons.check_circle, size: 18), visualDensity: VisualDensity.compact);
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode});
  final TrainingMode mode;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Training mode', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Learn gives walkthroughs. Practice gives coaching. Test scores at the end.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
            const SizedBox(height: 10),
            SegmentedButton<TrainingMode>(
              showSelectedIcon: false,
              segments: [
                for (final m in TrainingMode.values)
                  ButtonSegment(value: m, label: Text(m.label), icon: Icon(m == TrainingMode.learn ? Icons.school : m == TrainingMode.practice ? Icons.fitness_center : Icons.timer)),
              ],
              selected: {mode},
              onSelectionChanged: (s) => context.read<AppState>().setMode(s.first),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathwaySliver extends StatelessWidget {
  const _PathwaySliver({required this.step, required this.title, required this.subtitle, required this.badge, required this.icon, required this.buttonText, required this.onTap, this.primary = false});
  final String step;
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final String buttonText;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: (primary ? AppColors.headerGradient : [cs.secondary, cs.tertiary]).map((c) => c.withValues(alpha: 0.16)).toList()),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
                          ),
                          child: Icon(icon, color: primary ? AppColors.emsBlue : cs.onSurface),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(radius: 12, backgroundColor: AppColors.emsBlue.withValues(alpha: 0.12), child: Text(step, style: context.textStyles.labelSmall?.copyWith(color: AppColors.emsBlue, fontWeight: FontWeight.w900))),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(subtitle, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.46), borderRadius: BorderRadius.circular(999), border: Border.all(color: cs.outline.withValues(alpha: 0.12))),
                          child: Text(badge, style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurfaceVariant)),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: onTap,
                          style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
                          icon: const Icon(Icons.chevron_right, color: Colors.white),
                          label: Text(buttonText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickToolsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick practice tools', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Use these anytime without following the full pathway.', style: context.textStyles.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickToolButton(label: 'BP', route: AppRoutes.bloodPressure, module: TrainingModule.bloodPressure),
                _QuickToolButton(label: 'Pulse', route: AppRoutes.pulseTest, module: TrainingModule.pulse),
                _QuickToolButton(label: 'Pupils', route: AppRoutes.pupilAssessment, module: TrainingModule.pupil),
                _QuickToolButton(label: 'Stroke', route: AppRoutes.strokeAssessment, module: TrainingModule.stroke),
                _QuickToolButton(label: 'Breath Sounds', route: AppRoutes.breathSound, module: TrainingModule.breath),
                _QuickToolButton(label: 'Rule of Nines', route: AppRoutes.ruleOfNines, module: TrainingModule.burn),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickToolButton extends StatelessWidget {
  const _QuickToolButton({required this.label, required this.route, required this.module});
  final String label;
  final String route;
  final TrainingModule module;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w900)),
      avatar: const Icon(Icons.play_arrow, size: 18),
      onPressed: () {
        context.read<AppState>().markModuleOpened(module);
        context.push(route);
      },
    );
  }
}
