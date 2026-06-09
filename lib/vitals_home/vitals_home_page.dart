import 'package:emscode_sim_vitals/app/app_state.dart';
import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class VitalsHomePage extends StatelessWidget {
  const VitalsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _SimpleHeader()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxl),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StartWithVitalsCard(
                        onStartVitals: () => context.push(AppRoutes.learnVitals),
                        onSkipAhead: () => context.push(AppRoutes.assessmentTools),
                      ),
                      const SizedBox(height: 18),
                      const _SectionLabel(
                        title: 'Start Here',
                        subtitle: 'Vitals are the foundation. Learn the finding, then decide normal or not normal.',
                      ),
                      const SizedBox(height: 10),
                      _HomeTile(
                        icon: Icons.monitor_heart,
                        accent: AppColors.emsBlue,
                        title: 'Vitals',
                        subtitle: 'BP, pulse, respirations, SpO₂, skin, pupils, AVPU, AAOx, pain',
                        helper: 'Walkthroughs + practice inside each vital',
                        onTap: () => context.push(AppRoutes.learnVitals),
                      ),
                      const SizedBox(height: 22),
                      const _SectionLabel(
                        title: 'After Vitals',
                        subtitle: 'Assessment tools come next. Use the patient findings to decide what matters.',
                      ),
                      const SizedBox(height: 10),
                      _HomeTile(
                        icon: Icons.fact_check,
                        accent: const Color(0xFF22C55E),
                        title: 'Assessment Tools',
                        subtitle: 'SAMPLE, OPQRST, primary assessment, trauma, stroke, reassessment, reports',
                        helper: 'Each tool has Learn + Practice',
                        onTap: () => context.push(AppRoutes.assessmentTools),
                      ),
                      const SizedBox(height: 22),
                      const _SectionLabel(
                        title: 'Put It Together',
                        subtitle: 'Treatments and patient cases use vitals + assessment findings together.',
                      ),
                      const SizedBox(height: 10),
                      _HomeTile(
                        icon: Icons.medication,
                        accent: const Color(0xFF8B5CF6),
                        title: 'Treatments & Meds',
                        subtitle: 'When to consider treatment, what to check first, what to reassess',
                        helper: 'Protocol-aware decision practice',
                        onTap: () {
                          context.read<AppState>().markModuleOpened(TrainingModule.treatments);
                          context.push(AppRoutes.treatments);
                        },
                      ),
                      const SizedBox(height: 10),
                      _HomeTile(
                        icon: Icons.person_search,
                        accent: const Color(0xFFFFA51F),
                        title: 'Patient Assessment',
                        subtitle: 'Assess the patient, collect vitals, choose treatment, reassess, give report',
                        helper: 'Full walkthrough cases',
                        onTap: () {
                          context.read<AppState>().markModuleOpened(TrainingModule.walkthrough);
                          context.push(AppRoutes.walkthrough);
                        },
                      ),
                      const SizedBox(height: 18),
                      const _NormalNotNormalCard(),
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

class _SimpleHeader extends StatelessWidget {
  const _SimpleHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, MediaQuery.of(context).padding.top + 18, AppSpacing.md, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF041225), Color(0xFF0A1F3D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: const Icon(Icons.emergency, color: Color(0xFF22D3FF)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(text: 'EMS', style: TextStyle(color: Color(0xFF2281FF), fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
                          TextSpan(text: 'Code', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
                          TextSpan(text: 'Sim', style: TextStyle(color: Color(0xFFFF4B55), fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Patient Assessment Trainer', style: context.textStyles.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('Learn the vital. Decide normal or not normal. Understand why. Then assess and treat the patient.', style: context.textStyles.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.82), height: 1.35)),
              const SizedBox(height: 16),
              const SizedBox(height: 132, child: _HeroPulseGraphic()),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPulseGraphic extends StatelessWidget {
  const _HeroPulseGraphic();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HeroPulsePainter(),
      child: Center(
        child: Icon(Icons.medical_services, size: 94, color: Colors.white.withValues(alpha: 0.10)),
      ),
    );
  }
}

class _HeroPulsePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height * 0.58;
    final grid = Paint()..color = Colors.white.withValues(alpha: 0.025)..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }

    final glow = Paint()
      ..color = const Color(0xFF22D3FF).withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    final blue = Paint()
      ..color = const Color(0xFF22D3FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final amber = Paint()
      ..color = const Color(0xFFFFA51F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final left = Path()
      ..moveTo(0, centerY)
      ..lineTo(size.width * .20, centerY)
      ..lineTo(size.width * .23, centerY - 10)
      ..lineTo(size.width * .26, centerY + 9)
      ..lineTo(size.width * .30, centerY - 50)
      ..lineTo(size.width * .34, centerY + 45)
      ..lineTo(size.width * .38, centerY)
      ..lineTo(size.width * .48, centerY);
    canvas.drawPath(left, glow);
    canvas.drawPath(left, blue);

    canvas.drawLine(
      Offset(size.width * .50, 18),
      Offset(size.width * .50, size.height - 12),
      Paint()..color = const Color(0xFF22D3FF).withValues(alpha: .70)..strokeWidth = 3..strokeCap = StrokeCap.round,
    );

    final right = Path()
      ..moveTo(size.width * .52, centerY)
      ..lineTo(size.width * .60, centerY)
      ..lineTo(size.width * .64, centerY - 24)
      ..lineTo(size.width * .68, centerY + 40)
      ..lineTo(size.width * .73, centerY - 36)
      ..lineTo(size.width * .78, centerY + 18)
      ..lineTo(size.width * .83, centerY - 12)
      ..lineTo(size.width * .88, centerY)
      ..lineTo(size.width, centerY);
    canvas.drawPath(right, Paint()..color = const Color(0xFFFFA51F).withValues(alpha: 0.23)..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    canvas.drawPath(right, amber);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StartWithVitalsCard extends StatelessWidget {
  const _StartWithVitalsCard({required this.onStartVitals, required this.onSkipAhead});
  final VoidCallback onStartVitals;
  final VoidCallback onSkipAhead;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [AppColors.emsBlue.withValues(alpha: .95), const Color(0xFF0EA5E9).withValues(alpha: .72)]),
              ),
              child: const Icon(Icons.favorite_border, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start with Vitals', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('Recommended for new EMTs. You can skip ahead if you already know the basics.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      FilledButton(onPressed: onStartVitals, child: const Text('Start Vitals')),
                      TextButton(onPressed: onSkipAhead, child: const Text('Skip to Assessment')),
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
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(subtitle, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
      ],
    );
  }
}

class _HomeTile extends StatelessWidget {
  const _HomeTile({required this.icon, required this.accent, required this.title, required this.subtitle, required this.helper, required this.onTap});
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final String helper;
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(18), border: Border.all(color: accent.withValues(alpha: 0.25))),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                    const SizedBox(height: 6),
                    Text(helper, style: context.textStyles.labelMedium?.copyWith(color: accent, fontWeight: FontWeight.w900)),
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

class _NormalNotNormalCard extends StatelessWidget {
  const _NormalNotNormalCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: const Color(0xFFFF4B55).withValues(alpha: .10), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.search, color: Color(0xFFFF4B55)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Normal or Not Normal?', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('Every practice screen should ask this first, then ask why it matters.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                  const SizedBox(height: 10),
                  Text('Pulse 110 and irregular → Not normal: fast and not regular.', style: context.textStyles.bodyMedium?.copyWith(color: const Color(0xFFFF4B55), fontWeight: FontWeight.w900, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
