import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VitalsHomePage extends StatelessWidget {
  const VitalsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const _FixedNormalBar(),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _HomeHeader()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                110,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _FreeVersionBadge(),
                      const SizedBox(height: 16),

                      _HomeActionCard(
                        icon: Icons.monitor_heart,
                        accent: AppColors.emsBlue,
                        title: 'Basic Vitals',
                        subtitle:
                            'Blood pressure, pulse, respiratory rate, skin, pupils, AVPU, and AAOx4.',
                        chips: const [
                          'BP',
                          'Pulse',
                          'Respirations',
                          'Skin',
                          'Pupils',
                          'AVPU',
                          'AAOx4',
                        ],
                        buttonText: 'Start Vitals',
                        onTap: () => context.push(AppRoutes.learnVitals),
                      ),

                      const SizedBox(height: 14),

                      _HomeActionCard(
                        icon: Icons.fact_check,
                        accent: const Color(0xFF22C55E),
                        title: 'Assessment Flow',
                        subtitle:
                            'Practice Primary Assessment, SAMPLE, OPQRST, Secondary Assessment, and Reassessment.',
                        chips: const [
                          'Primary',
                          'SAMPLE',
                          'OPQRST',
                          'Secondary',
                          'Reassessment',
                        ],
                        buttonText: 'Start Assessment',
                        onTap: () => context.push(AppRoutes.assessmentTools),
                      ),

                      const SizedBox(height: 14),

                      _HomeActionCard(
                        icon: Icons.health_and_safety,
                        accent: const Color(0xFFFFA51F),
                        title: 'EMT Skill Tools',
                        subtitle:
                            'Quick practice tools for stroke assessment and Rule of Nines burn estimates.',
                        chips: const [
                          'Stroke',
                          'Rule of Nines',
                          'Normal / Not Normal',
                        ],
                        buttonText: 'Start Tools',
                        onTap: () => _showSkillToolsSheet(context),
                      ),

                      const SizedBox(height: 14),

                      _HomeActionCard(
                        icon: Icons.assignment_turned_in,
                        accent: const Color(0xFF8B5CF6),
                        title: 'Full Vitals Practice',
                        subtitle:
                            'Complete an adult vital set, decide what is abnormal, and explain why it matters.',
                        chips: const [
                          'Adult patient',
                          'Full set',
                          'Decision practice',
                        ],
                        buttonText: 'Start Practice',
                        onTap: () => context.push(AppRoutes.fullVitalsSet),
                      ),

                      const SizedBox(height: 14),

                      _HomeActionCard(
                        icon: Icons.show_chart,
                        accent: const Color(0xFF0EA5E9),
                        title: 'Progress',
                        subtitle:
                            'Review practice attempts, recent activity, and your training settings.',
                        chips: const [
                          'Scores',
                          'Attempts',
                          'Settings',
                        ],
                        buttonText: 'View Progress',
                        onTap: () => context.push(AppRoutes.settings),
                      ),

                      const SizedBox(height: 20),

                      const _ProPreviewCard(),
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

  static void _showSkillToolsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'EMT Skill Tools',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 12),
              _SheetButton(
                icon: Icons.psychology_alt,
                title: 'Stroke Assessment',
                subtitle: 'Facial droop, arm drift, speech, and last known well.',
                onTap: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.strokeAssessment);
                },
              ),
              const SizedBox(height: 10),
              _SheetButton(
                icon: Icons.local_fire_department,
                title: 'Rule of Nines',
                subtitle: 'Estimate adult burn percentage using body regions.',
                onTap: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.ruleOfNines);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        MediaQuery.of(context).padding.top + 20,
        AppSpacing.md,
        24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF061A33),
            Color(0xFF0A2E55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Icon(
                      Icons.emergency,
                      color: Color(0xFF22D3FF),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'EMS',
                            style: TextStyle(
                              color: Color(0xFF22D3FF),
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          TextSpan(
                            text: 'Code',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          TextSpan(
                            text: 'Sim',
                            style: TextStyle(
                              color: Color(0xFFFF4B55),
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Vitals & Assessment',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Practice adult vitals, basic assessment flow, and normal vs not normal decision-making.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.84),
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 18),
              const _HeroStatsRow(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroStatsRow extends StatelessWidget {
  const _HeroStatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _HeroStat(
            label: 'Free',
            value: 'Adult',
            icon: Icons.person,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _HeroStat(
            label: 'Focus',
            value: 'Normal?',
            icon: Icons.check_circle,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _HeroStat(
            label: 'Level',
            value: 'EMT',
            icon: Icons.school,
          ),
        ),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _FreeVersionBadge extends StatelessWidget {
  const _FreeVersionBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_open, color: Color(0xFF15803D)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Free version: adult vitals and basic EMT assessment tools.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF14532D),
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
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

class _ProPreviewCard extends StatelessWidget {
  const _ProPreviewCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.workspace_premium, color: Color(0xFFFFA51F)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EMSCodeSim Pro',
                  style: context.textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pediatric normal values, full patient simulations, breath sounds, treatment decisions, and instructor tools can be added later.',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA51F).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Coming Soon',
              style: context.textStyles.labelSmall?.copyWith(
                color: const Color(0xFFB45309),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FixedNormalBar extends StatelessWidget {
  const _FixedNormalBar();

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
                onPressed: () => _showNormalValues(context),
                icon: const Icon(Icons.check_circle),
                label: const Text('Normal'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.assessmentTools),
                icon: const Icon(Icons.fact_check),
                label: const Text('Assess'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showNormalValues(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
              children: const [
                _NormalHeader(),
                SizedBox(height: 14),
                _NormalValueTile(
                  title: 'Blood Pressure',
                  normal: 'About 90–120 systolic / 60–80 diastolic',
                  abnormal: 'Low BP, very high BP, or signs of poor perfusion.',
                  icon: Icons.speed,
                ),
                _NormalValueTile(
                  title: 'Pulse',
                  normal: '60–100 bpm, strong and regular',
                  abnormal: 'Under 60, over 100, weak, irregular, or absent radial.',
                  icon: Icons.favorite,
                ),
                _NormalValueTile(
                  title: 'Respiratory Rate',
                  normal: '12–20/min with normal effort',
                  abnormal: 'Under 12, over 20, shallow, labored, or irregular.',
                  icon: Icons.air,
                ),
                _NormalValueTile(
                  title: 'Skin',
                  normal: 'Pink, warm, and dry',
                  abnormal: 'Pale, cool, clammy, cyanotic, flushed, or hot.',
                  icon: Icons.back_hand,
                ),
                _NormalValueTile(
                  title: 'Pupils',
                  normal: 'PERRL: equal, round, reactive to light',
                  abnormal: 'Unequal, fixed, dilated, pinpoint, or sluggish.',
                  icon: Icons.visibility,
                ),
                _NormalValueTile(
                  title: 'AVPU',
                  normal: 'Alert',
                  abnormal: 'Responds only to verbal, pain, or is unresponsive.',
                  icon: Icons.record_voice_over,
                ),
                _NormalValueTile(
                  title: 'AAOx4',
                  normal: 'Person, place, time, and event',
                  abnormal: 'Confusion or unable to answer orientation questions.',
                  icon: Icons.psychology,
                ),
                _NormalValueTile(
                  title: 'SpO₂',
                  normal: 'Usually 94–100%',
                  abnormal: 'Low oxygen saturation or signs of respiratory distress.',
                  icon: Icons.bloodtype,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _NormalHeader extends StatelessWidget {
  const _NormalHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adult Normal Findings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Quick reference for the free version. Pediatric ranges can be added to the paid version later.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
        ),
      ],
    );
  }
}

class _NormalValueTile extends StatelessWidget {
  const _NormalValueTile({
    required this.title,
    required this.normal,
    required this.abnormal,
    required this.icon,
  });

  final String title;
  final String normal;
  final String abnormal;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF16A34A)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textStyles.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Normal: $normal',
                    style: context.textStyles.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Watch for: $abnormal',
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
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.emsBlue),
        title: Text(
          title,
          style: context.textStyles.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: context.textStyles.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }
}
