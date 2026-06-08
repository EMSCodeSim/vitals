import 'package:emscode_sim_vitals/app/app_state.dart';
import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class TrainingSummaryArgs {
  const TrainingSummaryArgs({required this.module, required this.scorePercent, required this.correct, required this.total, required this.timeSpent, required this.recommendedReview, this.missedTeachingPoints = const []});

  final TrainingModule module;
  final int scorePercent;
  final int correct;
  final int total;
  final Duration timeSpent;
  final String recommendedReview;
  final List<String> missedTeachingPoints;
}

class TrainingSummaryPage extends StatelessWidget {
  const TrainingSummaryPage({super.key, required this.args});
  final TrainingSummaryArgs args;

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return EMSVitalsScaffold(
      title: 'Test Summary',
      subtitle: '${args.module.label} • Mode: Test',
      onInfoPressed: null,
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
                      title: 'Score',
                      subtitle: 'Time spent: ${_fmt(args.timeSpent)}',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: AppColors.headerGradient.map((c) => c.withValues(alpha: 0.12)).toList()),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
                                ),
                                child: Text('${args.scorePercent}%', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text('${args.correct}/${args.total} correct', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: args.total == 0 ? 0 : (args.correct / args.total),
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(999),
                            backgroundColor: cs.outline.withValues(alpha: 0.16),
                            color: AppColors.emsBlue,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    EMSSectionCard(
                      title: 'Recommended review',
                      child: Text(args.recommendedReview, style: context.textStyles.bodyMedium?.copyWith(height: 1.5)),
                    ),
                    if (args.missedTeachingPoints.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      EMSSectionCard(
                        title: 'Missed teaching points',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final p in args.missedTeachingPoints)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.circle, size: 8, color: cs.onSurfaceVariant),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(p, style: context.textStyles.bodyMedium?.copyWith(height: 1.45))),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: OutlinedButton.icon(
                              onPressed: () => context.go(AppRoutes.home),
                              style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                              icon: const Icon(Icons.home),
                              label: const Text('Back to Home'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: FilledButton.icon(
                              onPressed: () {
                                // "Try again" = just return to home; modules provide Start.
                                context.go(AppRoutes.home);
                              },
                              style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
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
        ),
      ],
      bottomPadding: true,
    );
  }

  static Future<void> recordAndShow(BuildContext context, {required TrainingSummaryArgs args}) async {
    await context.read<AppState>().recordAttempt(module: args.module, scorePercent: args.scorePercent);
    if (!context.mounted) return;
    context.push(AppRoutes.summary, extra: args);
  }
}
