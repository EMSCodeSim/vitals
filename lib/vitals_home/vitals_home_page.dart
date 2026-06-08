import 'package:emscode_sim_vitals/app/app_state.dart';
import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/shared/normal_not_normal.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class VitalsHomePage extends StatelessWidget {
  const VitalsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
            toolbarHeight: 112,
            flexibleSpace: Container(
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
                          const Icon(Icons.medical_services, color: Colors.white),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'EMSCodeSim — Patient Assessment',
                              style: context.textStyles.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _HeaderPill(label: 'Mode: ${mode.label}', icon: Icons.school),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'An EMT instructor in your pocket — learn vitals, learn assessment tools, choose EMT treatments, then run the patient.',
                        style: context.textStyles.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.92), height: 1.35),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => context.push(AppRoutes.settings),
                              borderRadius: BorderRadius.circular(14),
                              splashFactory: NoSplash.splashFactory,
                              child: Container(
                                height: 46,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.22))),
                                child: Row(
                                  children: [
                                    const Icon(Icons.tune, color: Colors.white, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text('Settings', style: context.textStyles.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
                                    const Icon(Icons.chevron_right, color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => context.read<AppState>().setInstructorMode(!instructor),
                              borderRadius: BorderRadius.circular(14),
                              splashFactory: NoSplash.splashFactory,
                              child: Container(
                                height: 46,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.22))),
                                child: Row(
                                  children: [
                                    Icon(instructor ? Icons.visibility : Icons.visibility_off, color: Colors.white, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(instructor ? 'Instructor Mode: ON' : 'Instructor Mode: OFF', style: context.textStyles.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: const PreferredSize(preferredSize: Size.fromHeight(18), child: SizedBox(height: 18)),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
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
                      const NormalNotNormalCard(),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Training mode', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 6),
                              Text('Learn: hints • Practice: coached • Test: scored', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          _HomeSectionSliver(
            title: '1) Vital Walkthroughs + Practice',
            subtitle: 'Recommended first. Learn the vital, decide normal/not normal, then explain why it matters.',
            icon: Icons.monitor_heart,
            buttonText: 'Start with Vitals',
            onTap: () => context.push(AppRoutes.learnVitals),
          ),
          _HomeSectionSliver(
            title: '2) Assessment Tools + Practice',
            subtitle: 'Go here after vitals, or skip ahead if you already know vitals. SAMPLE, OPQRST, primary assessment, stroke, trauma, and reassessment.',
            icon: Icons.fact_check,
            buttonText: 'Skip to Assessment Tools',
            onTap: () => context.push(AppRoutes.assessmentTools),
          ),
          _HomeSectionSliver(
            title: '3) EMT Treatments & Meds',
            subtitle: 'Learn what treatments may fit the findings, what to check first, and what to reassess.',
            icon: Icons.medication,
            buttonText: 'Open Treatments',
            onTap: () {
              context.read<AppState>().markModuleOpened(TrainingModule.treatments);
              context.push(AppRoutes.treatments);
            },
          ),
          _HomeSectionSliver(
            title: '4) Patient Assessment Walkthrough',
            subtitle: 'Guided step-by-step patient assessment. Gather findings, choose treatment, reassess, and report.',
            icon: Icons.route,
            buttonText: 'Start Walkthrough',
            onTap: () {
              context.read<AppState>().markModuleOpened(TrainingModule.walkthrough);
              context.push(AppRoutes.walkthrough);
            },
            accent: true,
          ),
          _HomeSectionSliver(
            title: '5) Patient Assessment Cases',
            subtitle: 'Free walkthrough cases now — with “Coming Soon” locked packs for future add-ons.',
            icon: Icons.collections_bookmark,
            buttonText: 'Browse Cases',
            onTap: () => context.push(AppRoutes.cases),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xxl),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: EMSResultBox(
                    title: 'Existing simulators/tools are still included',
                    message: 'You can access Blood Pressure, Pulse, Stroke, Pupils, Rule of Nines, Breath Sounds, and EMT Treatments from the learning pathway.',
                    kind: EMSResultKind.info,
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

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.22))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: context.textStyles.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
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
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(gradient: LinearGradient(colors: AppColors.headerGradient.map((c) => c.withValues(alpha: 0.18)).toList()), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
                  child: const Icon(Icons.school, color: AppColors.emsBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Learn the finding. Decide normal or not normal. Then treat the patient.', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text('Best path for new EMTs: start with vitals, then assessment tools, then treatments, then full patient assessments. Experienced users can skip ahead anytime.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _PathStep(number: '1', title: 'Vitals first', subtitle: 'BP, pulse, RR, SpO₂, skin, pupils, AVPU, AAOx. Normal? Not normal? Why?'),
            const SizedBox(height: 8),
            _PathStep(number: '2', title: 'Assessment tools', subtitle: 'SAMPLE, OPQRST, primary assessment, DCAP-BTLS, stroke, reassessment.'),
            const SizedBox(height: 8),
            _PathStep(number: '3', title: 'Treatment decisions', subtitle: 'Pick EMT-level treatments, check red flags, reassess, and report.'),
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
                      label: const Text('Start with Vitals', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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
                icon: const Icon(Icons.route),
                label: const Text('Go Straight to Patient Assessment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathStep extends StatelessWidget {
  const _PathStep({required this.number, required this.title, required this.subtitle});

  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.26), borderRadius: BorderRadius.circular(14), border: Border.all(color: cs.outline.withValues(alpha: 0.12))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 14, backgroundColor: AppColors.emsBlue.withValues(alpha: 0.14), child: Text(number, style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w900, color: AppColors.emsBlue))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(subtitle, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSectionSliver extends StatelessWidget {
  const _HomeSectionSliver({required this.title, required this.subtitle, required this.icon, required this.buttonText, required this.onTap, this.accent = false});
  final String title;
  final String subtitle;
  final IconData icon;
  final String buttonText;
  final VoidCallback onTap;
  final bool accent;

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
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: (accent ? AppColors.headerGradient : [cs.secondary, cs.tertiary]).map((c) => c.withValues(alpha: 0.14)).toList()),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
                          ),
                          child: Icon(icon, color: accent ? AppColors.emsBlue : cs.onSurface),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 4),
                              Text(subtitle, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: onTap,
                        style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                        icon: const Icon(Icons.chevron_right, color: Colors.white),
                        label: Text(buttonText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      ),
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
