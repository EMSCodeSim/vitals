import 'dart:math' as math;

import 'package:emscode_sim_vitals/stroke/stroke_case.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';

class StrokePatientFigure extends StatelessWidget {
  const StrokePatientFigure({
    super.key,
    required this.activeTest,
    required this.strokeCase,
    required this.balancePhase,
    required this.eyePhase,
    required this.armTimerValue,
  });

  final StrokeTest? activeTest;
  final StrokeCase strokeCase;

  /// 0..1 repeating phase for “unsteady” sway.
  final double balancePhase;

  /// 0..1 repeating phase for eye tracking.
  final double eyePhase;

  /// 0..1 progress for the 10s arm drift timer.
  final double armTimerValue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final double baseLean = switch (activeTest) {
      StrokeTest.balance => _balanceLeanAmount(strokeCase.balance, balancePhase),
      _ => 0,
    };

    // Patient’s right appears on the LEFT side of the screen.
    // Our convention: negative lean = patient’s left, positive = patient’s right.
    // For display, invert X because patient-right is screen-left.
    final double displayLean = -baseLean;

    final bool showArmsUp = activeTest == StrokeTest.armDrift;
    final _ArmsPose armsPose = showArmsUp ? _armsPoseForDrift(strokeCase.arms, armTimerValue) : const _ArmsPose.neutral();

    final _EyesPose eyesPose = activeTest == StrokeTest.eyes ? _eyesPose(strokeCase.eyes, eyePhase) : const _EyesPose.neutral();
    final _FacePose facePose = activeTest == StrokeTest.face ? _facePose(strokeCase.face) : const _FacePose.neutral();

    return AspectRatio(
      aspectRatio: 0.86,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: CustomPaint(
            painter: _StrokeFigurePainter(
              colorScheme: cs,
              displayLean: displayLean,
              eyes: eyesPose,
              face: facePose,
              arms: armsPose,
              showSpeechStrip: activeTest == StrokeTest.speech,
            ),
          ),
        ),
      ),
    );
  }
}

double _balanceLeanAmount(StrokeBalanceFinding finding, double phase01) {
  switch (finding) {
    case StrokeBalanceFinding.normal:
      return 0;
    case StrokeBalanceFinding.unsteady:
      final t = phase01 * 2 * math.pi;
      return 0.10 * math.sin(t);
    case StrokeBalanceFinding.leansLeft:
      return -0.22;
    case StrokeBalanceFinding.leansRight:
      return 0.22;
  }
}

_EyesPose _eyesPose(StrokeEyesFinding finding, double phase01) {
  switch (finding) {
    case StrokeEyesFinding.followsBothWays:
      final t = (phase01 * 2 * math.pi);
      return _EyesPose(dx: 0.55 * math.sin(t), dy: 0);
    case StrokeEyesFinding.followsSlowly:
      final t = (phase01 * 2 * math.pi);
      return _EyesPose(dx: 0.55 * math.sin(t * 0.6), dy: 0);
    case StrokeEyesFinding.pulledLeft:
      return const _EyesPose(dx: -0.65, dy: 0);
    case StrokeEyesFinding.pulledRight:
      return const _EyesPose(dx: 0.65, dy: 0);
  }
}

_FacePose _facePose(StrokeFaceFinding finding) {
  switch (finding) {
    case StrokeFaceFinding.noDroop:
      return const _FacePose.neutral();
    case StrokeFaceFinding.leftDroops:
      return const _FacePose(droopLeft: true);
    case StrokeFaceFinding.rightDroops:
      return const _FacePose(droopRight: true);
  }
}

_ArmsPose _armsPoseForDrift(StrokeArmsFinding finding, double timer01) {
  if (finding == StrokeArmsFinding.noDrift) return const _ArmsPose(raise: true);
  final driftStart = 0.30; // ~3 seconds into 10 sec
  final t = ((timer01 - driftStart) / (1 - driftStart)).clamp(0.0, 1.0);
  final eased = Curves.easeInOutCubic.transform(t);
  if (finding == StrokeArmsFinding.leftDriftsDown) return _ArmsPose(raise: true, leftDrop: eased);
  return _ArmsPose(raise: true, rightDrop: eased);
}

class _EyesPose {
  const _EyesPose({required this.dx, required this.dy});
  const _EyesPose.neutral() : dx = 0, dy = 0;
  final double dx;
  final double dy;
}

class _FacePose {
  const _FacePose({this.droopLeft = false, this.droopRight = false});
  const _FacePose.neutral() : droopLeft = false, droopRight = false;
  final bool droopLeft;
  final bool droopRight;
}

class _ArmsPose {
  const _ArmsPose({this.raise = false, this.leftDrop = 0, this.rightDrop = 0});
  const _ArmsPose.neutral() : raise = false, leftDrop = 0, rightDrop = 0;
  final bool raise;
  final double leftDrop;
  final double rightDrop;
}

class _StrokeFigurePainter extends CustomPainter {
  _StrokeFigurePainter({
    required this.colorScheme,
    required this.displayLean,
    required this.eyes,
    required this.face,
    required this.arms,
    required this.showSpeechStrip,
  });

  final ColorScheme colorScheme;
  final double displayLean;
  final _EyesPose eyes;
  final _FacePose face;
  final _ArmsPose arms;
  final bool showSpeechStrip;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.52);

    // Subtle ground shadow
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.06);
    final shadowRect = Rect.fromCenter(center: Offset(size.width / 2, size.height * 0.90), width: size.width * 0.42, height: size.height * 0.06);
    canvas.drawRRect(RRect.fromRectAndRadius(shadowRect, const Radius.circular(999)), shadowPaint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(displayLean * 0.35);
    canvas.translate(-center.dx, -center.dy);

    _drawBody(canvas, size);

    if (showSpeechStrip) {
      final stripPaint = Paint()..color = AppColors.emsCyan.withValues(alpha: 0.14);
      final stripRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.12, size.height * 0.09, size.width * 0.76, size.height * 0.09),
        const Radius.circular(999),
      );
      canvas.drawRRect(stripRect, stripPaint);
      final border = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = colorScheme.outline.withValues(alpha: 0.12);
      canvas.drawRRect(stripRect, border);
    }

    canvas.restore();
  }

  void _drawBody(Canvas canvas, Size size) {
    final fill = Paint()..color = colorScheme.surfaceContainerHighest.withValues(alpha: 0.55);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = colorScheme.outline.withValues(alpha: 0.20);

    final skin = Paint()..color = colorScheme.surfaceContainerHighest.withValues(alpha: 0.75);

    // Head
    final headCenter = Offset(size.width * 0.50, size.height * 0.22);
    final headR = size.width * 0.125;
    canvas.drawCircle(headCenter, headR, skin);
    canvas.drawCircle(headCenter, headR, outline);

    // Eyes (pupils)
    final eyeY = headCenter.dy - headR * 0.12;
    final eyeDX = headR * 0.55;
    final eyeWhite = Paint()..color = Colors.white.withValues(alpha: 0.90);
    final pupil = Paint()..color = colorScheme.onSurface.withValues(alpha: 0.70);
    final pupilR = headR * 0.13;
    final scleraR = headR * 0.20;

    final leftEyeCenter = Offset(headCenter.dx - eyeDX, eyeY);
    final rightEyeCenter = Offset(headCenter.dx + eyeDX, eyeY);
    canvas.drawCircle(leftEyeCenter, scleraR, eyeWhite);
    canvas.drawCircle(rightEyeCenter, scleraR, eyeWhite);
    canvas.drawCircle(leftEyeCenter, scleraR, outline);
    canvas.drawCircle(rightEyeCenter, scleraR, outline);

    // Eyes pose uses patient perspective. Patient’s left appears on screen-right.
    // For pupils, we want the direction to look correct visually, so we invert X.
    final pupilOffset = Offset(-eyes.dx * pupilR * 1.6, eyes.dy * pupilR * 1.2);
    canvas.drawCircle(leftEyeCenter + pupilOffset, pupilR, pupil);
    canvas.drawCircle(rightEyeCenter + pupilOffset, pupilR, pupil);

    // Eyebrows
    final browPaint = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.55)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final browLift = headR * 0.12;
    final leftBrowY = eyeY - browLift + (face.droopLeft ? headR * 0.10 : 0);
    final rightBrowY = eyeY - browLift + (face.droopRight ? headR * 0.10 : 0);
    canvas.drawLine(Offset(leftEyeCenter.dx - headR * 0.20, leftBrowY), Offset(leftEyeCenter.dx + headR * 0.20, leftBrowY), browPaint);
    canvas.drawLine(Offset(rightEyeCenter.dx - headR * 0.20, rightBrowY), Offset(rightEyeCenter.dx + headR * 0.20, rightBrowY), browPaint);

    // Mouth
    final mouthY = headCenter.dy + headR * 0.45;
    final mouthW = headR * 1.05;
    final mouthLeft = headCenter.dx - mouthW / 2;
    final mouthRight = headCenter.dx + mouthW / 2;
    final neutralSmile = headR * 0.12;
    final droopDelta = headR * 0.18;
    final leftMouthY = mouthY + (face.droopLeft ? droopDelta : 0) - (face.droopRight ? droopDelta * 0.10 : 0);
    final rightMouthY = mouthY + (face.droopRight ? droopDelta : 0) - (face.droopLeft ? droopDelta * 0.10 : 0);
    final mouthPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = colorScheme.onSurface.withValues(alpha: 0.70);
    final mouthPath = Path()
      ..moveTo(mouthLeft, leftMouthY)
      ..quadraticBezierTo(headCenter.dx, mouthY - neutralSmile, mouthRight, rightMouthY);
    canvas.drawPath(mouthPath, mouthPaint);

    // Torso
    final torsoRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width * 0.50, size.height * 0.50), width: size.width * 0.28, height: size.height * 0.30),
      Radius.circular(size.width * 0.10),
    );
    canvas.drawRRect(torsoRect, fill);
    canvas.drawRRect(torsoRect, outline);

    // Arms
    final shoulderY = size.height * 0.42;
    final shoulderDX = size.width * 0.18;
    final leftShoulder = Offset(size.width * 0.50 - shoulderDX, shoulderY);
    final rightShoulder = Offset(size.width * 0.50 + shoulderDX, shoulderY);

    final armPaint = Paint()
      ..color = fill.color
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round;

    if (!arms.raise) {
      // Arms down
      canvas.drawLine(leftShoulder, Offset(leftShoulder.dx - size.width * 0.08, size.height * 0.63), armPaint);
      canvas.drawLine(rightShoulder, Offset(rightShoulder.dx + size.width * 0.08, size.height * 0.63), armPaint);
    } else {
      // Arms up (palms up)
      final upY = size.height * 0.30;
      final leftTarget = Offset(leftShoulder.dx - size.width * 0.14, upY + arms.leftDrop * size.height * 0.24);
      final rightTarget = Offset(rightShoulder.dx + size.width * 0.14, upY + arms.rightDrop * size.height * 0.24);
      canvas.drawLine(leftShoulder, leftTarget, armPaint);
      canvas.drawLine(rightShoulder, rightTarget, armPaint);

      // Simple palm marker
      final palmPaint = Paint()..color = Colors.white.withValues(alpha: 0.92);
      canvas.drawCircle(leftTarget, size.width * 0.028, palmPaint);
      canvas.drawCircle(rightTarget, size.width * 0.028, palmPaint);
      canvas.drawCircle(leftTarget, size.width * 0.028, outline);
      canvas.drawCircle(rightTarget, size.width * 0.028, outline);
    }

    // Legs
    final hipY = size.height * 0.64;
    final hipDX = size.width * 0.07;
    final leftHip = Offset(size.width * 0.50 - hipDX, hipY);
    final rightHip = Offset(size.width * 0.50 + hipDX, hipY);
    final legPaint = Paint()
      ..color = fill.color
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(leftHip, Offset(leftHip.dx - size.width * 0.05, size.height * 0.86), legPaint);
    canvas.drawLine(rightHip, Offset(rightHip.dx + size.width * 0.05, size.height * 0.86), legPaint);

    // Feet
    final footPaint = Paint()..color = colorScheme.onSurface.withValues(alpha: 0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(size.width * 0.44, size.height * 0.88), width: size.width * 0.12, height: size.height * 0.03), const Radius.circular(999)),
      footPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(size.width * 0.56, size.height * 0.88), width: size.width * 0.12, height: size.height * 0.03), const Radius.circular(999)),
      footPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _StrokeFigurePainter oldDelegate) {
    return oldDelegate.displayLean != displayLean ||
        oldDelegate.eyes.dx != eyes.dx ||
        oldDelegate.eyes.dy != eyes.dy ||
        oldDelegate.face.droopLeft != face.droopLeft ||
        oldDelegate.face.droopRight != face.droopRight ||
        oldDelegate.arms.raise != arms.raise ||
        oldDelegate.arms.leftDrop != arms.leftDrop ||
        oldDelegate.arms.rightDrop != arms.rightDrop ||
        oldDelegate.showSpeechStrip != showSpeechStrip ||
        oldDelegate.colorScheme != colorScheme;
  }
}
