import 'package:emscode_sim_vitals/app/app_state.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appState = context.watch<AppState>();

    return EMSVitalsScaffold(
      title: 'Settings & Progress',
      subtitle: 'Local-only progress (no account) • Educational use only, not medical advice',
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
                      title: 'Audio',
                      subtitle: 'Breath Sound Simulator can fall back to generated demo audio when MP3 files are not present.',
                      child: Row(
                        children: [
                          Expanded(child: Text('Use demo sounds when MP3 files are missing', style: context.textStyles.bodyMedium?.copyWith(height: 1.4))),
                          Switch(
                            value: appState.useDemoSoundsWhenMissing,
                            onChanged: (v) => context.read<AppState>().setUseDemoSoundsWhenMissing(v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    EMSSectionCard(
                      title: 'Progress',
                      subtitle: 'Best score is stored per module (Test mode only).',
                      child: Column(
                        children: [
                          for (final m in TrainingModule.values) ...[
                            _ProgressRow(module: m),
                            const SizedBox(height: 10),
                          ],
                          Container(height: 1, color: cs.outline.withValues(alpha: 0.12)),
                          const SizedBox(height: 12),
                          Text('Tip: Scores are saved locally on this device/browser.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4)),
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

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.module});
  final TrainingModule module;

  @override
  Widget build(BuildContext context) {
    final p = context.select<AppState, ModuleProgress>((s) => s.progressFor(module));
    final cs = Theme.of(context).colorScheme;
    final best = p.bestScore;
    final last = p.lastScore;
    return Row(
      children: [
        Expanded(child: Text(module.label, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900))),
        Text('${p.attempts} tries', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(999), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
          child: Text(
            best == null ? 'Best: —' : 'Best: $best%',
            style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 8),
        if (last != null)
          Text('Last $last%', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant))
        else
          Text('Last —', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}
