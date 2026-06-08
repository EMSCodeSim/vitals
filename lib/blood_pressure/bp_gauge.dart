import 'dart:math';

import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';

class BpGauge extends StatelessWidget {
  const BpGauge({super.key, required this.pressure});
  final double pressure;

  @override
  Widget build(BuildContext context) {
    final clamped = pressure.clamp(0.0, 280.0);
    // Needle is drawn pointing straight up at 0°.
    // We want 0 mmHg at the bottom (pointing down) and values to increase clockwise.
    // In Flutter's Transform.rotate: positive angles rotate clockwise.
    final targetAngleDeg = 180.0 + (clamped / 280.0) * 360.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  size: Size.square(size),
                  painter: _DialPainter(colorScheme: Theme.of(context).colorScheme),
                ),
              ),
              TweenAnimationBuilder<double>(
                // Let the builder animate from the previous value for smooth motion.
                tween: Tween<double>(end: targetAngleDeg),
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return Transform.rotate(
                    angle: value * pi / 180.0,
                    child: const _Needle(),
                  );
                },
              ),
              const _CenterHub(),
            ],
          ),
        );
      },
    );
  }
}

class _Needle extends StatelessWidget {
  const _Needle();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: 10,
        height: double.infinity,
        child: CustomPaint(
          painter: _NeedlePainter(),
        ),
      ),
    );
  }
}

class _NeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final needleLength = size.height * 0.38;
    final base = center;
    final tip = Offset(center.dx, center.dy - needleLength);

    final paint = Paint()
      ..color = AppColors.gaugeNeedle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(base, tip, paint);

    final tipPaint = Paint()..color = AppColors.gaugeNeedle;
    canvas.drawCircle(tip, 4, tipPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CenterHub extends StatelessWidget {
  const _CenterHub();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [AppColors.gaugeMetalLight, AppColors.gaugeMetalDark],
          stops: [0.0, 1.0],
        ),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 1),
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.18),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final facePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          colorScheme.surface,
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        ],
        stops: const [0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, facePaint);

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.06
      ..shader = const LinearGradient(
        colors: [AppColors.gaugeMetalLight, AppColors.gaugeMetalDark, AppColors.gaugeMetalLight],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius * 0.95, rimPaint);

    final tickPaintMajor = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.65)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final tickPaintMinor = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.35)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // 0..280 in steps of 10, with majors at 20.
    for (int p = 0; p <= 280; p += 10) {
      // Canvas polar angle: 0° points to the right, positive rotates clockwise.
      // We want 0 at the bottom (90°) and values to increase clockwise.
      final deg = 90.0 + (p / 280.0) * 360.0;
      final a = deg * pi / 180.0;
      final isMajor = p % 20 == 0;

      final outerR = radius * 0.82;
      final innerR = isMajor ? radius * 0.72 : radius * 0.76;
      final p1 = center + Offset(cos(a), sin(a)) * innerR;
      final p2 = center + Offset(cos(a), sin(a)) * outerR;
      canvas.drawLine(p1, p2, isMajor ? tickPaintMajor : tickPaintMinor);

      if (isMajor) {
        final labelR = radius * 0.60;
        final labelPos = center + Offset(cos(a), sin(a)) * labelR;
        textPainter.text = TextSpan(
          text: '$p',
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.78),
            fontSize: radius * 0.085,
            fontWeight: FontWeight.w600,
          ),
        );
        textPainter.layout();
        final offset = labelPos - Offset(textPainter.width / 2, textPainter.height / 2);
        textPainter.paint(canvas, offset);
      }
    }

    // Subtle inner ring.
    final innerRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = colorScheme.onSurface.withValues(alpha: 0.08);
    canvas.drawCircle(center, radius * 0.70, innerRing);
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) => oldDelegate.colorScheme != colorScheme;
}
