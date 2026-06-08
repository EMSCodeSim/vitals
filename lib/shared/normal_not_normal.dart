import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';

class NormalNotNormalCard extends StatelessWidget {
  const NormalNotNormalCard({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return EMSSectionCard(
      title: 'Core thinking: Normal? Not normal? Why?',
      subtitle: 'Every vital and assessment finding should lead to a short interpretation, not just a number.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NormalStep(icon: Icons.check_circle, label: '1. Is it normal?', value: 'Compare to an adult range and the patient picture.'),
          const SizedBox(height: 10),
          _NormalStep(icon: Icons.report_problem, label: '2. If not normal, what is wrong?', value: 'Name the problem: fast, slow, weak, irregular, low, high, labored, altered.'),
          const SizedBox(height: 10),
          _NormalStep(icon: Icons.psychology_alt, label: '3. Why does it matter?', value: 'Connect it to perfusion, oxygenation, shock, pain, neuro status, or treatment priority.'),
          if (!compact) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.34),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
              ),
              child: Text(
                'Example: Pulse 110 and irregular → Not normal: fast and not regular. Why: could be pain, fever, dehydration, anxiety, shock, or cardiac rhythm issue. Recheck, assess perfusion, and correlate with BP, skin signs, complaint, and mental status.',
                style: context.textStyles.bodySmall?.copyWith(height: 1.35, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NormalStep extends StatelessWidget {
  const _NormalStep({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.emsBlue, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: context.textStyles.bodySmall?.copyWith(height: 1.35, color: cs.onSurfaceVariant),
              children: [
                TextSpan(text: '$label ', style: context.textStyles.bodySmall?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurface)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class FindingInterpretationBox extends StatelessWidget {
  const FindingInterpretationBox({super.key, required this.title, required this.findings});

  final String title;
  final List<FindingInterpretation> findings;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return EMSSectionCard(
      title: title,
      subtitle: 'Do not stop at the value. Decide normal/not normal and explain why.',
      child: Column(
        children: [
          for (final finding in findings) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
                color: finding.isNormal ? Colors.green.withValues(alpha: 0.08) : Colors.orange.withValues(alpha: 0.10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(finding.label, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(finding.status, style: context.textStyles.bodySmall?.copyWith(fontWeight: FontWeight.w800, color: finding.isNormal ? Colors.green.shade700 : Colors.orange.shade800)),
                  const SizedBox(height: 4),
                  Text(finding.why, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                ],
              ),
            ),
            if (finding != findings.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class FindingInterpretation {
  const FindingInterpretation({required this.label, required this.status, required this.why, required this.isNormal});

  final String label;
  final String status;
  final String why;
  final bool isNormal;
}
