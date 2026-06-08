import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:emscode_sim_vitals/treatments/treatment_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TreatmentLessonPage extends StatefulWidget {
  const TreatmentLessonPage({super.key, required this.treatmentId});
  final String treatmentId;

  @override
  State<TreatmentLessonPage> createState() => _TreatmentLessonPageState();
}

class _TreatmentLessonPageState extends State<TreatmentLessonPage> {
  int? _selected;
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final lesson = TreatmentContent.lessonFor(widget.treatmentId);
    if (lesson == null) {
      return EMSVitalsScaffold(title: 'Treatment not found', subtitle: 'Return to the treatments hub.', bodySlivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: FilledButton(onPressed: () => context.go(AppRoutes.treatments), child: const Text('Back to Treatments')),
          ),
        ),
      ]);
    }

    final id = lesson.id;
    final cs = Theme.of(context).colorScheme;
    final correct = _selected == lesson.correctOptionIndex;

    return EMSVitalsScaffold(
      title: id.title,
      subtitle: id.isMedication ? 'Medication decision card — protocol and medical direction may vary.' : 'Treatment decision card — learn when to consider it and what to reassess.',
      onBackPressed: () => context.go(AppRoutes.treatments),
      onInfoPressed: () {
        EMSInfoSheet.show(
          context,
          title: 'Protocol reminder',
          children: const [
            Text('This app teaches EMT decision-making. Always follow your local protocol, instructor guidance, and medical direction.'),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (id.isMedication) const EMSWarningNote(text: 'Use only when allowed by local protocol and medical direction. Check contraindications before medication decisions.'),
                    if (id.isMedication) const SizedBox(height: 12),
                    _HeroCard(lesson: lesson),
                    const SizedBox(height: 12),
                    _LessonBlock(title: 'When to consider it', icon: Icons.help_outline, child: Text(lesson.whenToConsider, style: context.textStyles.bodyMedium?.copyWith(height: 1.35))),
                    const SizedBox(height: 12),
                    _LessonList(title: 'Findings that support it', icon: Icons.monitor_heart, items: lesson.supportingFindings),
                    const SizedBox(height: 12),
                    _LessonList(title: 'Check first', icon: Icons.fact_check, items: lesson.checkFirst),
                    const SizedBox(height: 12),
                    _LessonList(title: 'Contraindications / red flags', icon: Icons.warning_amber, items: lesson.redFlags, warning: true),
                    const SizedBox(height: 12),
                    _LessonList(title: 'Reassess after treatment', icon: Icons.repeat, items: lesson.reassess),
                    const SizedBox(height: 12),
                    EMSResultBox(title: 'Common student mistake', message: lesson.commonMistake, kind: EMSResultKind.info),
                    const SizedBox(height: 12),
                    EMSSectionCard(
                      title: 'Practice decision',
                      subtitle: lesson.practicePrompt,
                      child: Column(
                        children: [
                          for (var i = 0; i < lesson.practiceOptions.length; i++) ...[
                            RadioListTile<int>(
                              value: i,
                              groupValue: _selected,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (v) => setState(() {
                                _selected = v;
                                _checked = false;
                              }),
                              title: Text(lesson.practiceOptions[i]),
                            ),
                            const Divider(height: 1),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _selected == null ? null : () => setState(() => _checked = true),
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Check Answer'),
                            ),
                          ),
                          if (_checked) ...[
                            const SizedBox(height: 12),
                            EMSResultBox(
                              title: correct ? 'Correct' : 'Needs work',
                              message: lesson.practiceFeedback,
                              kind: correct ? EMSResultKind.success : EMSResultKind.warning,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: cs.outline.withValues(alpha: 0.12))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Documentation / report reminder', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Text('Document what you found, what you considered or did per protocol, patient response, and reassessment findings.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.lesson});
  final TreatmentLesson lesson;

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
              width: 52,
              height: 52,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: AppColors.headerGradient), borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: Icon(lesson.id.icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lesson.id.title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(lesson.usedFor, style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                  if (lesson.id.isMedication) ...[
                    const SizedBox(height: 8),
                    Chip(label: const Text('Protocol dependent'), avatar: const Icon(Icons.rule, size: 16), visualDensity: VisualDensity.compact),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonBlock extends StatelessWidget {
  const _LessonBlock({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return EMSSectionCard(
      title: title,
      trailing: Icon(icon, color: AppColors.emsBlue),
      child: child,
    );
  }
}

class _LessonList extends StatelessWidget {
  const _LessonList({required this.title, required this.icon, required this.items, this.warning = false});
  final String title;
  final IconData icon;
  final List<String> items;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning ? Colors.orange : AppColors.emsBlue;
    return EMSSectionCard(
      title: title,
      trailing: Icon(icon, color: color),
      child: Column(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(warning ? Icons.warning_amber : Icons.check_circle, size: 18, color: color),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item, style: context.textStyles.bodyMedium?.copyWith(height: 1.35))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
