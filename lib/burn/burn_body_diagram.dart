import 'package:emscode_sim_vitals/burn/burn_models.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';

/// Clean tappable body diagram for quick TBSA practice.
///
/// This intentionally uses simple region hit-boxes sized for touch, rather than a
/// detailed anatomical SVG, so it remains usable on phones.
class BurnBodyDiagram extends StatelessWidget {
  const BurnBodyDiagram({super.key, required this.patientType, required this.viewSide, required this.selected, required this.onToggle});

  final BurnPatientType patientType;
  final BurnViewSide viewSide;
  final Set<BurnRegionId> selected;
  final ValueChanged<BurnRegionId> onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final regions = BurnRegions.byView(viewSide);

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = (w * 1.25).clamp(260.0, 440.0);
        return SizedBox(
          width: w,
          height: h,
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: CustomPaint(
                        painter: _SilhouettePainter(color: cs.onSurfaceVariant.withValues(alpha: 0.10)),
                      ),
                    ),
                  ),
                  ...regions.map((r) {
                    final rr = _regionRelRect(viewSide, r.id);
                    final isSelected = selected.contains(r.id);
                    final pct = r.percentFor(patientType);
                    return Positioned(
                      left: rr.x * w,
                      top: rr.y * h,
                      width: rr.w * w,
                      height: rr.h * h,
                      child: _RegionButton(
                        label: '${r.shortLabel}\n${_fmtPct(pct)}',
                        selected: isSelected,
                        onTap: () => onToggle(r.id),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RegionButton extends StatelessWidget {
  const _RegionButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fill = selected ? Colors.deepOrange.withValues(alpha: 0.26) : AppColors.emsBlue.withValues(alpha: 0.10);
    final stroke = selected ? Colors.deepOrange.withValues(alpha: 0.70) : cs.outline.withValues(alpha: 0.18);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: stroke),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w900, height: 1.15),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ),
        ),
      ),
    );
  }
}

@immutable
class _RelRect {
  const _RelRect(this.x, this.y, this.w, this.h);
  final double x;
  final double y;
  final double w;
  final double h;
}

// Relative hit-box positions for a readable “diagram-like” layout.
_RelRect _regionRelRect(BurnViewSide side, BurnRegionId id) {
  // Coordinates are normalized 0..1 relative to the diagram container.
  // Designed to be symmetric and touch-friendly.
  if (side == BurnViewSide.front) {
    return switch (id) {
      BurnRegionId.headFront => const _RelRect(0.38, 0.05, 0.24, 0.14),
      BurnRegionId.chestUpperAbdomen => const _RelRect(0.35, 0.22, 0.30, 0.16),
      BurnRegionId.lowerAbdomen => const _RelRect(0.35, 0.39, 0.30, 0.16),
      BurnRegionId.rightArmFront => const _RelRect(0.18, 0.24, 0.16, 0.34),
      BurnRegionId.leftArmFront => const _RelRect(0.66, 0.24, 0.16, 0.34),
      BurnRegionId.rightLegFront => const _RelRect(0.36, 0.60, 0.13, 0.34),
      BurnRegionId.leftLegFront => const _RelRect(0.51, 0.60, 0.13, 0.34),
      BurnRegionId.perineum => const _RelRect(0.44, 0.54, 0.12, 0.08),
      _ => const _RelRect(-2, -2, 0, 0),
    };
  }

  // Back view
  return switch (id) {
    BurnRegionId.headBack => const _RelRect(0.38, 0.05, 0.24, 0.14),
    BurnRegionId.upperBack => const _RelRect(0.35, 0.22, 0.30, 0.18),
    BurnRegionId.lowerBack => const _RelRect(0.35, 0.41, 0.30, 0.16),
    BurnRegionId.rightArmBack => const _RelRect(0.18, 0.24, 0.16, 0.34),
    BurnRegionId.leftArmBack => const _RelRect(0.66, 0.24, 0.16, 0.34),
    BurnRegionId.rightLegBack => const _RelRect(0.36, 0.60, 0.13, 0.34),
    BurnRegionId.leftLegBack => const _RelRect(0.51, 0.60, 0.13, 0.34),
    _ => const _RelRect(-2, -2, 0, 0),
  };
}

String _fmtPct(double v) => '${v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2)}%';

class _SilhouettePainter extends CustomPainter {
  const _SilhouettePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final w = size.width;
    final h = size.height;

    final head = Rect.fromCenter(center: Offset(w * 0.5, h * 0.13), width: w * 0.22, height: h * 0.16);
    canvas.drawRRect(RRect.fromRectAndRadius(head, const Radius.circular(44)), p);

    final torso = Rect.fromCenter(center: Offset(w * 0.5, h * 0.43), width: w * 0.38, height: h * 0.46);
    canvas.drawRRect(RRect.fromRectAndRadius(torso, const Radius.circular(28)), p);

    final armL = Rect.fromCenter(center: Offset(w * 0.27, h * 0.44), width: w * 0.14, height: h * 0.50);
    final armR = Rect.fromCenter(center: Offset(w * 0.73, h * 0.44), width: w * 0.14, height: h * 0.50);
    canvas.drawRRect(RRect.fromRectAndRadius(armL, const Radius.circular(28)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(armR, const Radius.circular(28)), p);

    final legL = Rect.fromCenter(center: Offset(w * 0.43, h * 0.83), width: w * 0.18, height: h * 0.44);
    final legR = Rect.fromCenter(center: Offset(w * 0.57, h * 0.83), width: w * 0.18, height: h * 0.44);
    canvas.drawRRect(RRect.fromRectAndRadius(legL, const Radius.circular(28)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(legR, const Radius.circular(28)), p);
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter oldDelegate) => oldDelegate.color != color;
}
