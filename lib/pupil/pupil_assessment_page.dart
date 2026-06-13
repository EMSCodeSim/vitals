import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum PupilReaction { normal, sluggish, nonReactive }

extension on PupilReaction {
  String get label => switch (this) {
    PupilReaction.normal => 'Normal',
    PupilReaction.sluggish => 'Sluggish',
    PupilReaction.nonReactive => 'Non-reactive',
  };

  bool get isReactive => this != PupilReaction.nonReactive;
}

class _EyeFinding {
  const _EyeFinding({required this.ratioPercent, required this.reaction});

  final double ratioPercent;
  final PupilReaction reaction;
}

class _PupilCase {
  const _PupilCase({required this.left, required this.right});

  final _EyeFinding left;
  final _EyeFinding right;
}

enum TrackingCase {
  normal,
  limitedTowardPatientLeft,
  limitedTowardPatientRight,
  heldToPatientLeft,
  heldToPatientRight,
  nystagmus,
  notTogetherOneLags,
}

extension on TrackingCase {
  String get label => switch (this) {
    TrackingCase.normal => 'Normal tracking',
    TrackingCase.limitedTowardPatientLeft => 'Movement limited toward the patient\'s left',
    TrackingCase.limitedTowardPatientRight => 'Movement limited toward the patient\'s right',
    TrackingCase.heldToPatientLeft => 'Both eyes held to the patient\'s left',
    TrackingCase.heldToPatientRight => 'Both eyes held to the patient\'s right',
    TrackingCase.nystagmus => 'Nystagmus (visible small rapid shaking)',
    TrackingCase.notTogetherOneLags => 'Eyes do not move together / one lags',
  };
}

class PupilAssessmentPage extends StatefulWidget {
  const PupilAssessmentPage({super.key});

  @override
  State<PupilAssessmentPage> createState() => _PupilAssessmentPageState();
}

class _PupilAssessmentPageState extends State<PupilAssessmentPage> with TickerProviderStateMixin {
  static const double _irisDiameterMm = 11.5;

  final _rng = Random();

  late _PupilCase _case;
  late TrackingCase _trackingCase;
  late bool _rightEyeLags;

  // Live tracking slider (patient-direction): -100 = patient LEFT, +100 = patient RIGHT.
  // Note: patient-right is screen-left because the patient is facing us.
  double _trackingTarget = 0;
  double _trackingCurrent = 0;
  double _trackingLagCurrent = 0;
  double _trackingBias = 0;

  late final AnimationController _frame;
  AnimationController? _returnToCenter;

  late final AnimationController _penlightRight;
  late final AnimationController _penlightLeft;

  // Student inputs
  String? _perlPick;
  String? _rightSizePick;
  String? _rightReactionPick;
  String? _rightTrackingPick;
  String? _leftSizePick;
  String? _leftReactionPick;
  String? _leftTrackingPick;

  bool _graded = false;
  List<_GradeRow> _gradeRows = const [];
  String? _teachingText;

  @override
  void initState() {
    super.initState();
    _frame = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..addListener(_onFrame)
      ..repeat();

    _penlightRight = AnimationController(vsync: this);
    _penlightLeft = AnimationController(vsync: this);

    _newCase();
  }

  @override
  void dispose() {
    _frame.removeListener(_onFrame);
    _frame.dispose();
    _returnToCenter?.dispose();
    _penlightRight.dispose();
    _penlightLeft.dispose();
    super.dispose();
  }

  void _onFrame() {
    // Only the "one lags" scenario needs continuous smoothing.
    if (_trackingCase == TrackingCase.notTogetherOneLags) {
      final next = lerpDouble(_trackingLagCurrent, _trackingTarget, 0.10) ?? _trackingTarget;
      if ((next - _trackingLagCurrent).abs() > 0.01) {
        setState(() => _trackingLagCurrent = next);
      }
    }
  }

  static double _ratioToMm(double ratioPercent) => ratioPercent / 100.0 * _irisDiameterMm;

  static String _classifySize(double ratioPercent) {
    final mm = _ratioToMm(ratioPercent);
    if (mm < 2.5) return 'Pinpoint';
    if (mm < 5.5) return 'Normal';
    return 'Dilated';
  }

  void _newCase() {
    final pupilCases = <_PupilCase>[
      const _PupilCase(
        left: _EyeFinding(ratioPercent: 30, reaction: PupilReaction.normal),
        right: _EyeFinding(ratioPercent: 30, reaction: PupilReaction.normal),
      ),
      const _PupilCase(
        left: _EyeFinding(ratioPercent: 10, reaction: PupilReaction.normal),
        right: _EyeFinding(ratioPercent: 10, reaction: PupilReaction.normal),
      ),
      const _PupilCase(
        left: _EyeFinding(ratioPercent: 55, reaction: PupilReaction.sluggish),
        right: _EyeFinding(ratioPercent: 55, reaction: PupilReaction.sluggish),
      ),
      const _PupilCase(
        left: _EyeFinding(ratioPercent: 25, reaction: PupilReaction.normal),
        right: _EyeFinding(ratioPercent: 80, reaction: PupilReaction.nonReactive),
      ),
      const _PupilCase(
        left: _EyeFinding(ratioPercent: 20, reaction: PupilReaction.normal),
        right: _EyeFinding(ratioPercent: 45, reaction: PupilReaction.normal),
      ),
    ];

    setState(() {
      _case = pupilCases[_rng.nextInt(pupilCases.length)];
      _trackingCase = TrackingCase.values[_rng.nextInt(TrackingCase.values.length)];
      _rightEyeLags = _rng.nextBool();

      _trackingTarget = 0;
      _trackingCurrent = 0;
      _trackingLagCurrent = 0;
      _trackingBias = switch (_trackingCase) {
        TrackingCase.heldToPatientLeft => -55,
        TrackingCase.heldToPatientRight => 55,
        _ => 0,
      };

      _perlPick = null;
      _rightSizePick = null;
      _rightReactionPick = null;
      _rightTrackingPick = null;
      _leftSizePick = null;
      _leftReactionPick = null;
      _leftTrackingPick = null;

      _graded = false;
      _gradeRows = const [];
      _teachingText = null;
    });
  }

  void _showInfo() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About Pupil Assessment', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoBullet(
                    text:
                        'Right side and Left side are from the patient\'s point of view. The patient\'s right side appears on the left of your screen.',
                  ),
                  _InfoBullet(
                    text:
                        'The chart and the live pupils use the same scale so the displayed mm size matches the reference chart as closely as possible.',
                  ),
                  _InfoBullet(text: 'Use the penlight buttons to test reactivity.'),
                  _InfoBullet(text: 'Use the tracking slider to check whether the eyes move together.'),
                  _InfoBullet(text: 'The slider recenters when released, like returning your finger to the middle.'),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ButtonStyle(
                        splashFactory: NoSplash.splashFactory,
                        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _runPenlight({required bool isRightSide}) async {
    final eye = isRightSide ? _case.right : _case.left;
    final controller = isRightSide ? _penlightRight : _penlightLeft;

    if (eye.reaction == PupilReaction.nonReactive) return;

    try {
      controller.stop();
      controller.reset();

      final (constrictMs, constrictFactor) = switch (eye.reaction) {
        PupilReaction.normal => (800, 0.62),
        PupilReaction.sluggish => (1100, 0.78),
        PupilReaction.nonReactive => (800, 1.0),
      };

      controller.duration = Duration(milliseconds: constrictMs);
      // We can't reassign late final animations, so instead we read controller.value via helper.
      await controller.forward();
    } catch (e) {
      debugPrint('Penlight animation failed: $e');
    }
  }

  double _lightFactorFor(bool isRightSide) {
    final eye = isRightSide ? _case.right : _case.left;
    final c = isRightSide ? _penlightRight : _penlightLeft;
    if (eye.reaction == PupilReaction.nonReactive) return 1.0;

    final constrictFactor = eye.reaction == PupilReaction.normal ? 0.62 : 0.78;
    final t = c.value;
    if (t <= 0.5) {
      final tt = Curves.easeInOutCubic.transform(t / 0.5);
      return lerpDouble(1.0, constrictFactor, tt) ?? 1.0;
    }
    final tt = Curves.easeInOutCubic.transform((t - 0.5) / 0.5);
    return lerpDouble(constrictFactor, 1.0, tt) ?? 1.0;
  }

  void _onTrackingChanged(double v) {
    setState(() {
      _trackingTarget = v;
      if (_trackingCase != TrackingCase.notTogetherOneLags) {
        _trackingCurrent = v;
        _trackingLagCurrent = v;
      }
    });
  }

  void _onTrackingEnd(double v) {
    _returnToCenter?.dispose();
    _returnToCenter = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    final start = _trackingTarget;
    final anim = CurvedAnimation(parent: _returnToCenter!, curve: Curves.easeOutCubic);
    _returnToCenter!
      ..addListener(() {
        final next = lerpDouble(start, 0, anim.value) ?? 0;
        setState(() {
          _trackingTarget = next;
          if (_trackingCase != TrackingCase.notTogetherOneLags) {
            _trackingCurrent = next;
            _trackingLagCurrent = next;
          }
        });
      })
      ..forward();
  }

  double _trackingForEye({required bool isRightSide}) {
    final base = _trackingCase == TrackingCase.notTogetherOneLags
        ? (isRightSide == _rightEyeLags ? _trackingLagCurrent : _trackingTarget)
        : _trackingTarget;

    final biased = _trackingBias + base * switch (_trackingCase) {
      TrackingCase.heldToPatientLeft || TrackingCase.heldToPatientRight => 0.35,
      _ => 1.0,
    };

    final limited = switch (_trackingCase) {
      TrackingCase.limitedTowardPatientLeft => biased < 0 ? biased * 0.35 : biased,
      TrackingCase.limitedTowardPatientRight => biased > 0 ? biased * 0.35 : biased,
      _ => biased,
    };

    return limited.clamp(-100, 100);
  }

  double _nystagmusOffset() {
    if (_trackingCase != TrackingCase.nystagmus) return 0;
    final t = _frame.value * 2 * pi;
    // Small, rapid shake (kept subtle)
    return sin(t * 9) * 6;
  }

  void _grade() {
    try {
      final expectedRightSize = _classifySize(_case.right.ratioPercent);
      final expectedLeftSize = _classifySize(_case.left.ratioPercent);
      final expectedRightReaction = _case.right.reaction.label;
      final expectedLeftReaction = _case.left.reaction.label;
      final expectedTracking = _trackingCase.label;

      final mmR = _ratioToMm(_case.right.ratioPercent);
      final mmL = _ratioToMm(_case.left.ratioPercent);
      final perlExpected = (mmR - mmL).abs() < 1.0 && _case.right.reaction.isReactive && _case.left.reaction.isReactive ? 'Yes' : 'No';

      final rows = <_GradeRow>[
        _GradeRow.section(section: 'Left side — actual', detail: 'size $expectedLeftSize (${mmL.toStringAsFixed(1)} mm), reaction $expectedLeftReaction, tracking $expectedTracking.'),
        _GradeRow.pick(label: 'Size', pick: _leftSizePick, expected: expectedLeftSize),
        _GradeRow.pick(label: 'Reaction', pick: _leftReactionPick, expected: expectedLeftReaction),
        _GradeRow.pick(label: 'Tracking', pick: _leftTrackingPick, expected: expectedTracking),
        _GradeRow.spacer(),
        _GradeRow.section(section: 'Right side — actual', detail: 'size $expectedRightSize (${mmR.toStringAsFixed(1)} mm), reaction $expectedRightReaction, tracking $expectedTracking.'),
        _GradeRow.pick(label: 'Size', pick: _rightSizePick, expected: expectedRightSize),
        _GradeRow.pick(label: 'Reaction', pick: _rightReactionPick, expected: expectedRightReaction),
        _GradeRow.pick(label: 'Tracking', pick: _rightTrackingPick, expected: expectedTracking),
        _GradeRow.spacer(),
        _GradeRow.perl(pick: _perlPick, expected: perlExpected),
      ];

      final teaching = _buildTeachingText(
        leftSize: expectedLeftSize,
        rightSize: expectedRightSize,
        leftReaction: _case.left.reaction,
        rightReaction: _case.right.reaction,
        tracking: _trackingCase,
      );

      setState(() {
        _graded = true;
        _gradeRows = rows;
        _teachingText = teaching;
      });
    } catch (e) {
      debugPrint('Failed to grade findings: $e');
    }
  }

  String? _buildTeachingText({
    required String leftSize,
    required String rightSize,
    required PupilReaction leftReaction,
    required PupilReaction rightReaction,
    required TrackingCase tracking,
  }) {
    final parts = <String>[];
    final sizeSet = {leftSize, rightSize};
    if (sizeSet.contains('Pinpoint')) {
      parts.add('Pinpoint pupils may be seen with opioid effect, injury to the pons, or cholinergic/organophosphate exposure.');
    }
    if (sizeSet.contains('Dilated')) {
      parts.add(
        'Dilated pupils may be seen with stimulant or anticholinergic effect, low oxygen or no oxygen, after a seizure, or increased pressure inside the skull.',
      );
    }
    if (leftReaction == PupilReaction.sluggish || rightReaction == PupilReaction.sluggish) {
      parts.add('Sluggish reaction may be seen with low oxygen, low body temperature, sedative or opioid medicines, or early increased pressure inside the skull.');
    }
    if (leftReaction == PupilReaction.nonReactive || rightReaction == PupilReaction.nonReactive) {
      parts.add('Non-reactive pupils may be seen with brain herniation, severe head injury, third nerve palsy, recent eye surgery, or eye trauma.');
    }
    switch (tracking) {
      case TrackingCase.limitedTowardPatientLeft:
        parts.add('Movement limited toward the patient\'s left may suggest left gaze palsy or a sixth nerve/eye muscle problem.');
        break;
      case TrackingCase.limitedTowardPatientRight:
        parts.add('Movement limited toward the patient\'s right may suggest right gaze palsy or a sixth nerve/eye muscle problem.');
        break;
      case TrackingCase.heldToPatientLeft:
      case TrackingCase.heldToPatientRight:
        parts.add('Eyes held to one side may be seen with an acute brain lesion with gaze preference, seizure, or post-seizure state.');
        break;
      case TrackingCase.nystagmus:
        parts.add('Nystagmus may be seen with an inner ear or vestibular problem, intoxication, or cerebellar/brainstem involvement.');
        break;
      case TrackingCase.notTogetherOneLags:
        parts.add('Eyes not moving together may suggest internuclear ophthalmoplegia, cranial nerve palsy, orbital trauma, or muscle entrapment.');
        break;
      case TrackingCase.normal:
        break;
    }
    if (parts.isEmpty) return null;
    return parts.join('\n\n');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxContentWidth = 860.0;

    final rightRatio = _case.right.ratioPercent * _lightFactorFor(true);
    final leftRatio = _case.left.ratioPercent * _lightFactorFor(false);
    final rightMm = _ratioToMm(rightRatio);
    final leftMm = _ratioToMm(leftRatio);

    return Scaffold(
      bottomNavigationBar: const EMSBottomNav(),
      body: CustomScrollView(
        slivers: [
          EMSVitalsHeader(title: 'Pupil Assessment', onInfoPressed: _showInfo),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Penlight Pupil Size Chart', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Pinpoint ≈ 1–2 mm • Normal (room light) ≈ 3–4 mm • Dilated ≥ 6 mm',
                                style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const _PupilSizeChart(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Eyes Simulator', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Record findings (sides are the patient\'s). The patient\'s right side appears on the left of your screen.',
                                style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _EyePanel(
                                      sideLabel: 'Right side',
                                      mm: rightMm,
                                      ratioPercent: rightRatio,
                                      trackingValue: _trackingForEye(isRightSide: true),
                                      nystagmusOffsetPx: _nystagmusOffset(),
                                      onPenlight: () => _runPenlight(isRightSide: true),
                                      buttonText: '💡 Penlight — Right side',
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: _EyePanel(
                                      sideLabel: 'Left side',
                                      mm: leftMm,
                                      ratioPercent: leftRatio,
                                      trackingValue: _trackingForEye(isRightSide: false),
                                      nystagmusOffsetPx: _nystagmusOffset(),
                                      onPenlight: () => _runPenlight(isRightSide: false),
                                      buttonText: '💡 Penlight — Left side',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tracking (follow examiner\'s finger): Left ⇄ Right', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Move the slider to test whether both eyes track together. When released, it returns to center.',
                                style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Slider(
                                value: _trackingTarget,
                                min: -100,
                                max: 100,
                                divisions: 200,
                                label: _trackingTarget.toStringAsFixed(0),
                                onChanged: _onTrackingChanged,
                                onChangeEnd: _onTrackingEnd,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Record Findings', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: AppSpacing.sm),
                              Text('Record findings (sides are the patient\'s)', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                              const SizedBox(height: AppSpacing.md),
                              _DropdownString(
                                label: 'PERL',
                                value: _perlPick,
                                items: const ['— choose —', 'Yes', 'No'],
                                onChanged: (v) => setState(() => _perlPick = v),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text('Right side findings', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: AppSpacing.sm),
                              _DropdownString(
                                label: 'Right side — Size',
                                value: _rightSizePick,
                                items: const ['— choose —', 'Pinpoint', 'Normal', 'Dilated'],
                                onChanged: (v) => setState(() => _rightSizePick = v),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _DropdownString(
                                label: 'Right side — Reaction',
                                value: _rightReactionPick,
                                items: const ['— choose —', 'Normal', 'Sluggish', 'Non-reactive'],
                                onChanged: (v) => setState(() => _rightReactionPick = v),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _DropdownString(
                                label: 'Right side — Tracking',
                                value: _rightTrackingPick,
                                items: _DropdownString.trackingItems,
                                onChanged: (v) => setState(() => _rightTrackingPick = v),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text('Left side findings', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: AppSpacing.sm),
                              _DropdownString(
                                label: 'Left side — Size',
                                value: _leftSizePick,
                                items: const ['— choose —', 'Pinpoint', 'Normal', 'Dilated'],
                                onChanged: (v) => setState(() => _leftSizePick = v),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _DropdownString(
                                label: 'Left side — Reaction',
                                value: _leftReactionPick,
                                items: const ['— choose —', 'Normal', 'Sluggish', 'Non-reactive'],
                                onChanged: (v) => setState(() => _leftReactionPick = v),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _DropdownString(
                                label: 'Left side — Tracking',
                                value: _leftTrackingPick,
                                items: _DropdownString.trackingItems,
                                onChanged: (v) => setState(() => _leftTrackingPick = v),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 54,
                                      child: FilledButton(
                                        onPressed: _grade,
                                        style: ButtonStyle(
                                          splashFactory: NoSplash.splashFactory,
                                          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                        ),
                                        child: const Text('Grade Findings'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: SizedBox(
                                      height: 54,
                                      child: OutlinedButton(
                                        onPressed: _newCase,
                                        style: ButtonStyle(
                                          splashFactory: NoSplash.splashFactory,
                                          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                        ),
                                        child: const Text('New Random Case'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_graded) ...[
                        const SizedBox(height: AppSpacing.md),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Grade Findings', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                                const SizedBox(height: AppSpacing.sm),
                                for (final r in _gradeRows) _GradeRowWidget(row: r),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (_teachingText != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.school, color: cs.primary),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text('Why abnormal?', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(_teachingText!, style: context.textStyles.bodyMedium?.copyWith(height: 1.5, color: cs.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ),
                      ],
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

class _PupilSizeChart extends StatelessWidget {
  const _PupilSizeChart();

  // Keep this aligned with the eye painter so mm feels consistent.
  static const double irisDiameterPx = 160;
  static const double irisMm = 11.5;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const mms = [1, 2, 3, 4, 5, 6, 7];
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final mm in mms)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: (mm / irisMm) * irisDiameterPx,
                height: (mm / irisMm) * irisDiameterPx,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.10), blurRadius: 14, offset: const Offset(0, 6))],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('$mm mm', style: context.textStyles.labelMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
            ],
          ),
      ],
    );
  }
}

class _EyePanel extends StatelessWidget {
  const _EyePanel({
    required this.sideLabel,
    required this.mm,
    required this.ratioPercent,
    required this.trackingValue,
    required this.nystagmusOffsetPx,
    required this.onPenlight,
    required this.buttonText,
  });

  final String sideLabel;
  final double mm;
  final double ratioPercent;
  final double trackingValue;
  final double nystagmusOffsetPx;
  final VoidCallback onPenlight;
  final String buttonText;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Keep both eye displays vertically aligned by giving the header
          // a consistent height (prevents wrap differences from shifting the eye).
          SizedBox(
            height: 44,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$sideLabel Pupil: ${mm.toStringAsFixed(1)} mm (ratio ${ratioPercent.toStringAsFixed(0)}%)',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AspectRatio(
            aspectRatio: 1.5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.surfaceContainerHighest.withValues(alpha: 0.65),
                      cs.surfaceContainerHighest.withValues(alpha: 0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CustomPaint(
                  painter: _EyePainter(
                    ratioPercent: ratioPercent,
                    trackingValue: trackingValue,
                    nystagmusOffsetPx: nystagmusOffsetPx,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onPenlight,
              style: ButtonStyle(
                splashFactory: NoSplash.splashFactory,
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
              child: Text(
                buttonText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EyePainter extends CustomPainter {
  const _EyePainter({required this.ratioPercent, required this.trackingValue, required this.nystagmusOffsetPx});

  final double ratioPercent;
  final double trackingValue;
  final double nystagmusOffsetPx;

  static const double irisDiameterPx = _PupilSizeChart.irisDiameterPx;
  static const double irisMm = _PupilSizeChart.irisMm;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final eyeW = size.width * 0.92;
    final eyeH = size.height * 0.72;
    final eyeRect = Rect.fromCenter(center: center, width: eyeW, height: eyeH);
    final eyeRRect = RRect.fromRectAndRadius(eyeRect, Radius.circular(eyeH / 2));

    final scleraPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFF3F6FB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(eyeRect);
    canvas.drawRRect(eyeRRect, scleraPaint);

    final outline = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(eyeRRect, outline);

    // Iris & pupil
    final irisR = min(irisDiameterPx / 2, min(size.width, size.height) * 0.30);
    final pupilR = (ratioPercent / 100) * (irisDiameterPx / 2);

    // Tracking mapping:
    // trackingValue is in patient-direction: -100=patient-left, +100=patient-right.
    // patient-right should move on-screen LEFT.
    final maxDx = irisR * 0.65;
    final dx = (-trackingValue / 100) * maxDx + nystagmusOffsetPx;
    final irisCenter = Offset(center.dx + dx, center.dy);

    final irisPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF2C7A7B), Color(0xFF0F4C5C)],
        stops: [0.2, 1.0],
      ).createShader(Rect.fromCircle(center: irisCenter, radius: irisR));
    canvas.drawCircle(irisCenter, irisR, irisPaint);

    final irisRing = Paint()
      ..color = const Color(0xFF0B2C3A).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(irisCenter, irisR, irisRing);

    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawCircle(irisCenter, pupilR.clamp(0.0, irisR * 0.92), pupilPaint);

    // Highlight reflection
    final highlight = Paint()..color = Colors.white.withValues(alpha: 0.78);
    canvas.drawCircle(irisCenter + Offset(-irisR * 0.32, -irisR * 0.22), irisR * 0.18, highlight);
    final highlight2 = Paint()..color = Colors.white.withValues(alpha: 0.65);
    canvas.drawCircle(irisCenter + Offset(-irisR * 0.18, -irisR * 0.10), irisR * 0.06, highlight2);

    // Soft eyelid overlay
    final lidPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF0F172A).withValues(alpha: 0.10),
          const Color(0xFF0F172A).withValues(alpha: 0.0),
          const Color(0xFF0F172A).withValues(alpha: 0.08),
        ],
        stops: const [0.0, 0.55, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(eyeRect);
    canvas.save();
    canvas.clipRRect(eyeRRect);
    canvas.drawRect(eyeRect, lidPaint);
    canvas.restore();

    // Note: we keep the pupil within iris & eye by clamping radii + modest dx.
    // The chart scale uses the same iris reference (11.5 mm).
    // ignore: unused_local_variable
    const _ = irisMm;
  }

  @override
  bool shouldRepaint(covariant _EyePainter oldDelegate) {
    return oldDelegate.ratioPercent != ratioPercent || oldDelegate.trackingValue != trackingValue || oldDelegate.nystagmusOffsetPx != nystagmusOffsetPx;
  }
}

class _DropdownString extends StatelessWidget {
  const _DropdownString({required this.label, required this.value, required this.items, required this.onChanged});

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  static const List<String> trackingItems = [
    '— choose —',
    'Normal tracking',
    'Movement limited toward the patient\'s left',
    'Movement limited toward the patient\'s right',
    'Both eyes held to the patient\'s left',
    'Both eyes held to the patient\'s right',
    'Nystagmus (visible small rapid shaking)',
    'Eyes do not move together / one lags',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.22))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          icon: Icon(Icons.expand_more, color: cs.onSurfaceVariant),
          items: [
            for (final item in items)
              DropdownMenuItem(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) {
            if (v == null) return;
            if (v == '— choose —') {
              onChanged(null);
            } else {
              onChanged(v);
            }
          },
        ),
      ),
    );
  }
}

class _GradeRow {
  const _GradeRow._({this.section, this.detail, this.label, this.pick, this.expected, this.isSpacer = false, this.isPerl = false});

  final String? section;
  final String? detail;
  final String? label;
  final String? pick;
  final String? expected;
  final bool isSpacer;
  final bool isPerl;

  factory _GradeRow.spacer() => const _GradeRow._(isSpacer: true);

  factory _GradeRow.pick({required String label, required String? pick, required String expected}) => _GradeRow._(label: label, pick: pick, expected: expected);

  factory _GradeRow.section({required String section, required String detail}) => _GradeRow._(section: section, detail: detail);

  factory _GradeRow.perl({required String? pick, required String expected}) => _GradeRow._(isPerl: true, pick: pick, expected: expected);
}

class _GradeRowWidget extends StatelessWidget {
  const _GradeRowWidget({required this.row});

  final _GradeRow row;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (row.isSpacer) return const SizedBox(height: AppSpacing.sm);

    if (row.section != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(row.section!, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(row.detail ?? '', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
          ],
        ),
      );
    }

    if (row.isPerl) {
      final pick = row.pick;
      final expected = row.expected!;
      final ok = pick != null && pick == expected;
      final missing = pick == null;
      final icon = missing ? Icons.help_outline : (ok ? Icons.check_circle : Icons.cancel);
      final color = missing ? cs.onSurfaceVariant : (ok ? Colors.green : cs.error);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                missing
                    ? 'PERL: no selection was made.'
                    : (ok ? 'PERL: You chose $pick. ✅ Correct.' : 'PERL: You chose $pick. ❌ Expected: $expected.'),
                style: context.textStyles.bodyMedium?.copyWith(height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    final pick = row.pick;
    final expected = row.expected!;
    final missing = pick == null;
    final ok = pick == expected;
    final icon = missing ? Icons.help_outline : (ok ? Icons.check_circle : Icons.cancel);
    final color = missing ? cs.onSurfaceVariant : (ok ? Colors.green : cs.error);
    final text = missing
        ? '${row.label}: no selection was made.'
        : (ok ? '${row.label}: correct.' : '${row.label}: Expected $expected.');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: context.textStyles.bodyMedium?.copyWith(height: 1.4))),
        ],
      ),
    );
  }
}

class _InfoBullet extends StatelessWidget {
  const _InfoBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5))),
        ],
      ),
    );
  }
}
