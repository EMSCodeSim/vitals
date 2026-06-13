import 'package:emscode_sim_vitals/app/app_state.dart';
import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class EMSVitalsScaffold extends StatelessWidget {
  const EMSVitalsScaffold({super.key, required this.title, this.subtitle, this.onInfoPressed, this.onBackPressed, required this.bodySlivers, this.bottomPadding = true, this.showModePill = true});

  final String title;
  final String? subtitle;
  final VoidCallback? onInfoPressed;
  final VoidCallback? onBackPressed;
  final List<Widget> bodySlivers;
  final bool bottomPadding;
  final bool showModePill;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const EMSBottomNav(),
      body: CustomScrollView(
        slivers: [
          EMSVitalsHeader(title: title, onInfoPressed: onInfoPressed, onBackPressed: onBackPressed, showModePill: showModePill),
          if (subtitle != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Text(subtitle!, style: context.textStyles.bodyMedium?.copyWith(height: 1.45, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
                ),
              ),
            ),
          ...bodySlivers,
          if (bottomPadding) const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }
}

class EMSBottomNav extends StatelessWidget {
  const EMSBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final location = GoRouterState.of(context).uri.path;

    Widget navButton({required IconData icon, required String label, required String route, bool filled = false}) {
      final selected = location == route || (route != AppRoutes.home && location.startsWith(route));
      final onPressed = selected ? null : () => context.go(route);
      final child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      );

      if (filled) {
        return FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: selected ? cs.primary.withValues(alpha: 0.68) : cs.primary,
            foregroundColor: cs.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: child,
        );
      }

      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: selected ? cs.primary : cs.onSurface,
          side: BorderSide(color: selected ? cs.primary : cs.outline.withValues(alpha: 0.28)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: child,
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.outline.withValues(alpha: 0.16))),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, -6))],
        ),
        child: Row(
          children: [
            Expanded(child: navButton(icon: Icons.monitor_heart, label: 'Vitals', route: AppRoutes.learnVitals)),
            const SizedBox(width: 8),
            Expanded(child: navButton(icon: Icons.check_circle, label: 'Normal', route: AppRoutes.fullVitalsSet, filled: true)),
            const SizedBox(width: 8),
            Expanded(child: navButton(icon: Icons.fact_check, label: 'Assess', route: AppRoutes.assessmentTools)),
          ],
        ),
      ),
    );
  }
}

class EMSVitalsHeader extends StatelessWidget {
  const EMSVitalsHeader({super.key, required this.title, this.onInfoPressed, this.onBackPressed, this.showModePill = true});

  final String title;
  final VoidCallback? onInfoPressed;
  final VoidCallback? onBackPressed;
  final bool showModePill;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      toolbarHeight: 76,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: AppColors.headerGradient, begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBackPressed ?? () => context.go(AppRoutes.home),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back to Home',
                  style: const ButtonStyle(splashFactory: NoSplash.splashFactory, foregroundColor: WidgetStatePropertyAll(Colors.white)),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                ),
                if (onInfoPressed != null)
                  EMSTrainingButton(
                    onPressed: onInfoPressed,
                    icon: Icons.info_outline,
                    label: 'Info',
                    foreground: Colors.white,
                    background: Colors.white.withValues(alpha: 0.16),
                    borderColor: Colors.white.withValues(alpha: 0.22),
                  )
                else
                  const SizedBox(width: 44),
              ],
            ),
          ),
        ),
      ),
      bottom: showModePill
          ? PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: EMSModePill(
                      background: Colors.white.withValues(alpha: 0.16),
                      borderColor: Colors.white.withValues(alpha: 0.22),
                      foreground: Colors.white,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class EMSModePill extends StatelessWidget {
  const EMSModePill({super.key, required this.background, required this.borderColor, required this.foreground});

  final Color background;
  final Color borderColor;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final mode = context.select<AppState, TrainingMode>((s) => s.mode);
    return Row(
      children: [
        Icon(Icons.school, color: foreground, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text('Mode', style: context.textStyles.labelLarge?.copyWith(color: foreground, fontWeight: FontWeight.w800))),
        DropdownButtonHideUnderline(
          child: DropdownButton<TrainingMode>(
            value: mode,
            dropdownColor: Theme.of(context).colorScheme.surface,
            iconEnabledColor: foreground,
            style: context.textStyles.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w800),
            items: [
              for (final m in TrainingMode.values)
                DropdownMenuItem(
                  value: m,
                  child: Text(m.label),
                ),
            ],
            onChanged: (m) {
              if (m == null) return;
              context.read<AppState>().setMode(m);
            },
          ),
        ),
      ],
    );
  }
}

class EMSSectionCard extends StatelessWidget {
  const EMSSectionCard({super.key, required this.title, this.subtitle, this.child, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? child;
  final Widget? trailing;

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
                Expanded(child: Text(title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                if (trailing != null) trailing!,
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
            ],
            if (child != null) ...[
              const SizedBox(height: AppSpacing.md),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

class EMSResultBox extends StatelessWidget {
  const EMSResultBox({super.key, required this.title, required this.message, required this.kind});

  final String title;
  final String message;
  final EMSResultKind kind;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, icon, iconColor, border) = switch (kind) {
      EMSResultKind.success => (Colors.green.withValues(alpha: 0.10), Icons.check_circle, Colors.green, Colors.green.withValues(alpha: 0.28)),
      EMSResultKind.warning => (Colors.orange.withValues(alpha: 0.12), Icons.warning_amber_rounded, Colors.orange, Colors.orange.withValues(alpha: 0.30)),
      EMSResultKind.error => (AppColors.danger.withValues(alpha: 0.10), Icons.cancel, AppColors.danger, AppColors.danger.withValues(alpha: 0.28)),
      EMSResultKind.info => (cs.surfaceContainerHighest.withValues(alpha: 0.40), Icons.info, cs.onSurfaceVariant, cs.outline.withValues(alpha: 0.16)),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: border)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(message, style: context.textStyles.bodySmall?.copyWith(height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum EMSResultKind { success, warning, error, info }

class EMSWarningNote extends StatelessWidget {
  const EMSWarningNote({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => EMSResultBox(title: 'Note', message: text, kind: EMSResultKind.warning);
}

class EMSTrainingButton extends StatelessWidget {
  const EMSTrainingButton({super.key, required this.onPressed, required this.icon, required this.label, this.foreground, this.background, this.borderColor});

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color? foreground;
  final Color? background;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = foreground ?? cs.onSurface;
    final bg = background;
    return TextButton.icon(
      onPressed: onPressed,
      style: ButtonStyle(
        splashFactory: NoSplash.splashFactory,
        foregroundColor: WidgetStatePropertyAll(fg),
        backgroundColor: bg == null ? null : WidgetStatePropertyAll(bg),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: BorderSide(color: borderColor ?? Colors.transparent))),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
        textStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
      ),
      icon: Icon(icon, size: 18, color: fg),
      label: Text(label),
    );
  }
}

class EMSInfoSheet extends StatelessWidget {
  const EMSInfoSheet({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  static Future<void> show(BuildContext context, {required String title, required List<Widget> children}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EMSInfoSheet(title: title, children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.pop(),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {},
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 720, maxHeight: MediaQuery.sizeOf(context).height * 0.90),
            child: Material(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(title, style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.close),
                            style: ButtonStyle(splashFactory: NoSplash.splashFactory, foregroundColor: WidgetStatePropertyAll(cs.onSurface)),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ...children,
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: () => context.pop(),
                          style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
                          child: const Text('Got it'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
