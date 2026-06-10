import 'dart:async';

import 'package:emscode_sim_vitals/app/app_state.dart';
import 'package:emscode_sim_vitals/blood_pressure/bp_gauge.dart';
import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class BpLearnWalkthroughPage extends StatefulWidget {
  const BpLearnWalkthroughPage({super.key});

  @override
  State<BpLearnWalkthroughPage> createState() => _BpLearnWalkthroughPageState();
}

class _BpLearnWalkthroughPageState extends State<BpLearnWalkthroughPage> {
  static const int _sys = 118;
  static const int _dia = 76;
  static const double _targetInflation = 170;
  static const String _placementAsset = 'assets/images/bp_cuff_stethoscope_placement.png';

  Timer? _timer;
  Timer? _autoAdvanceTimer;
  double _pressure = 0;
  _VideoStage _stage = _VideoStage.ready;
  bool _showPlacementPhoto = true;
  int _questionIndex = 0;
  final List<int?> _answers = [null, null];

  bool get _isPlaying => _timer?.isActive == true || _autoAdvanceTimer?.isActive == true;

  bool get _showBeats =>
      _stage == _VideoStage.systolicPopup ||
      _stage == _VideoStage.releaseToDia ||
      (_stage == _VideoStage.releaseToSys && _pressure <= _sys && _pressure > _dia);

  bool get _highlightTarget => _stage == _VideoStage.targetPopup || _stage == _VideoStage.inflate;
  bool get _highlightSys => _stage == _VideoStage.systolicPopup;
  bool get _highlightDia => _stage == _VideoStage.diastolicPopup;

  _PopUpData get _popUpData => switch (_stage) {
        _VideoStage.ready => const _PopUpData(
            icon: Icons.play_circle_outline,
            title: 'Ready',
            message: 'The demo will show one full BP reading.',
            color: AppColors.emsBlue,
          ),
        _VideoStage.inflate => const _PopUpData(
            icon: Icons.arrow_upward,
            title: 'Pump up',
            message: 'Inflate cuff to raise pressure.',
            color: AppColors.emsBlue,
          ),
        _VideoStage.targetPopup => const _PopUpData(
            icon: Icons.flag,
            title: 'Stop around 170',
            message: 'Above the example systolic pressure.',
            color: Colors.orange,
          ),
        _VideoStage.releaseToSys => const _PopUpData(
            icon: Icons.south,
            title: 'Release slowly',
            message: 'Let the needle fall while listening.',
            color: AppColors.emsBlue,
          ),
        _VideoStage.systolicPopup => const _PopUpData(
            icon: Icons.graphic_eq,
            title: 'First sound = 118',
            message: 'Record this as systolic, the top number.',
            color: Colors.green,
          ),
        _VideoStage.releaseToDia => const _PopUpData(
            icon: Icons.south,
            title: 'Keep releasing',
            message: 'Sounds continue while pressure drops.',
            color: AppColors.emsBlue,
          ),
        _VideoStage.diastolicPopup => const _PopUpData(
            icon: Icons.volume_off,
            title: 'Sounds stop = 76',
            message: 'Record this as diastolic, the bottom number.',
            color: AppColors.emsBlue,
          ),
        _VideoStage.finalReading => const _PopUpData(
            icon: Icons.check_circle,
            title: 'BP 118/76',
            message: 'Normal adult BP for this training example.',
            color: Colors.green,
          ),
        _VideoStage.quickCheck => const _PopUpData(
            icon: Icons.quiz_outlined,
            title: 'Quick check',
            message: 'Two questions, then practice it yourself.',
            color: AppColors.emsBlue,
          ),
      };

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  void _cancelTimers() {
    _timer?.cancel();
    _autoAdvanceTimer?.cancel();
    _timer = null;
    _autoAdvanceTimer = null;
  }

  void _startVideo() {
    _cancelTimers();
    setState(() {
      _showPlacementPhoto = false;
      _pressure = 0;
      _stage = _VideoStage.inflate;
      _questionIndex = 0;
      _answers[0] = null;
      _answers[1] = null;
    });
    _beginInflation(resetPressure: true);
  }

  void _beginInflation({bool resetPressure = false}) {
    if (!mounted) return;
    _cancelTimers();
    setState(() {
      _stage = _VideoStage.inflate;
      if (resetPressure) _pressure = 0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 45), (_) {
      if (!mounted) return;
      final next = (_pressure + 2.8).clamp(0.0, _targetInflation);
      setState(() => _pressure = next);
      if (_pressure >= _targetInflation) {
        _cancelTimers();
        setState(() {
          _pressure = _targetInflation;
          _stage = _VideoStage.targetPopup;
        });
        _scheduleNext(const Duration(seconds: 2), () => _beginReleaseToSys());
      }
    });
  }

  void _beginReleaseToSys() {
    if (!mounted) return;
    _cancelTimers();
    setState(() => _stage = _VideoStage.releaseToSys);
    _timer = Timer.periodic(const Duration(milliseconds: 55), (_) {
      if (!mounted) return;
      final next = (_pressure - 0.75).clamp(0.0, _targetInflation);
      setState(() => _pressure = next);
      if (_pressure <= _sys) {
        _cancelTimers();
        setState(() {
          _pressure = _sys.toDouble();
          _stage = _VideoStage.systolicPopup;
        });
        _scheduleNext(const Duration(seconds: 3), () => _beginReleaseToDia());
      }
    });
  }

  void _beginReleaseToDia() {
    if (!mounted) return;
    _cancelTimers();
    setState(() => _stage = _VideoStage.releaseToDia);
    _timer = Timer.periodic(const Duration(milliseconds: 55), (_) {
      if (!mounted) return;
      final next = (_pressure - 0.65).clamp(0.0, _targetInflation);
      setState(() => _pressure = next);
      if (_pressure <= _dia) {
        _cancelTimers();
        setState(() {
          _pressure = _dia.toDouble();
          _stage = _VideoStage.diastolicPopup;
        });
        _scheduleNext(const Duration(seconds: 3), () {
          if (!mounted) return;
          _cancelTimers();
          setState(() => _stage = _VideoStage.finalReading);
        });
      }
    });
  }

  void _scheduleNext(Duration delay, VoidCallback action) {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(delay, action);
  }

  void _pauseResume() {
    if (_stage == _VideoStage.ready || _stage == _VideoStage.quickCheck) return;
    if (_timer?.isActive == true || _autoAdvanceTimer?.isActive == true) {
      _cancelTimers();
      setState(() {});
      return;
    }

    switch (_stage) {
      case _VideoStage.inflate:
        _beginInflation();
        break;
      case _VideoStage.targetPopup:
        _scheduleNext(const Duration(milliseconds: 800), () => _beginReleaseToSys());
        break;
      case _VideoStage.releaseToSys:
        _beginReleaseToSys();
        break;
      case _VideoStage.systolicPopup:
        _scheduleNext(const Duration(milliseconds: 800), () => _beginReleaseToDia());
        break;
      case _VideoStage.releaseToDia:
        _beginReleaseToDia();
        break;
      case _VideoStage.diastolicPopup:
        _scheduleNext(const Duration(milliseconds: 800), () {
          if (mounted) setState(() => _stage = _VideoStage.finalReading);
        });
        break;
      case _VideoStage.finalReading:
      case _VideoStage.ready:
      case _VideoStage.quickCheck:
        break;
    }
    setState(() {});
  }

  void _goToQuickCheck() {
    _cancelTimers();
    setState(() {
      _showPlacementPhoto = false;
      _pressure = _dia.toDouble();
      _stage = _VideoStage.quickCheck;
      _questionIndex = 0;
      _answers[0] = null;
      _answers[1] = null;
    });
  }

  void _replay() {
    _startVideo();
  }

  void _selectAnswer(int answerIndex) => setState(() => _answers[_questionIndex] = answerIndex);

  void _nextQuestionOrFinish() {
    if (_questionIndex == 0) {
      setState(() => _questionIndex = 1);
    } else {
      context.read<AppState>().setMode(TrainingMode.practice);
      context.go('${AppRoutes.bloodPressure}?flow=practice');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showPlacementPhoto) return _buildPlacementPhotoPage(context);
    return _buildVideoDemoPage(context);
  }

  Widget _buildPlacementPhotoPage(BuildContext context) {
    return EMSVitalsScaffold(
      title: 'BP Tutorial',
      subtitle: 'Start with placement, then watch the demo.',
      showModePill: false,
      onBackPressed: () => context.go(AppRoutes.bloodPressure),
      onInfoPressed: _showTeachingSheet,
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
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              child: Image.asset(
                                _placementAsset,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 54,
                              child: FilledButton.icon(
                                onPressed: _startVideo,
                                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                                label: const Text(
                                  'Next: Play Demo',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showTeachingSheet,
                            icon: const Icon(Icons.info_outline),
                            label: const Text('More Info'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _goToQuickCheck,
                            icon: const Icon(Icons.quiz_outlined),
                            label: const Text('Quiz'),
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
    );
  }

  Widget _buildVideoDemoPage(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return EMSVitalsScaffold(
      title: 'BP Tutorial Demo',
      subtitle: 'Video-style simulator with pop-up checkpoints.',
      showModePill: false,
      onBackPressed: () => setState(() {
        _cancelTimers();
        _showPlacementPhoto = true;
        _stage = _VideoStage.ready;
        _pressure = 0;
      }),
      onInfoPressed: _showTeachingSheet,
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
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _VideoProgress(stage: _stage),
                            const SizedBox(height: 12),
                            _BpSimulatorVideo(
                              pressure: _pressure,
                              showBeats: _showBeats,
                              highlightTarget: _highlightTarget,
                              highlightSys: _highlightSys,
                              highlightDia: _highlightDia,
                              popUp: _popUpData,
                            ),
                            const SizedBox(height: 12),
                            _SoundStrip(active: _showBeats, stage: _stage),
                            if (_stage == _VideoStage.finalReading) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  border: Border.all(color: Colors.green.withValues(alpha: 0.32)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Final reading', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.green.shade800)),
                                          const SizedBox(height: 4),
                                          Text('118 / 76', style: context.textStyles.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurface)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(999)),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.check, color: Colors.white),
                                          SizedBox(width: 6),
                                          Text('Normal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (_stage == _VideoStage.quickCheck) ...[
                              const SizedBox(height: 12),
                              _QuickCheckCard(
                                questionIndex: _questionIndex,
                                selectedAnswer: _answers[_questionIndex],
                                onSelect: _selectAnswer,
                                onContinue: _answers[_questionIndex] == null ? null : _nextQuestionOrFinish,
                              ),
                            ],
                            const SizedBox(height: 14),
                            _VideoControls(
                              stage: _stage,
                              isPlaying: _isPlaying,
                              onPlay: _stage == _VideoStage.ready ? _startVideo : _pauseResume,
                              onQuiz: _goToQuickCheck,
                              onReplay: _replay,
                              onPractice: () {
                                context.read<AppState>().setMode(TrainingMode.practice);
                                context.go('${AppRoutes.bloodPressure}?flow=practice');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showTeachingSheet,
                            icon: const Icon(Icons.info_outline),
                            label: const Text('More Info'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _goToQuickCheck,
                            icon: const Icon(Icons.quiz_outlined),
                            label: const Text('Quiz'),
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
    );
  }

  void _showTeachingSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 560, maxHeight: MediaQuery.sizeOf(context).height * 0.88),
            child: Material(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('Quick reminders', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                          IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _MiniTeachingPoint(icon: Icons.check_circle_outline, text: 'Place cuff about 1 inch above the elbow crease.'),
                      const _MiniTeachingPoint(icon: Icons.straighten, text: 'Confirm the cuff size marker is in range.'),
                      const _MiniTeachingPoint(icon: Icons.hearing, text: 'Place the stethoscope over the brachial artery.'),
                      const _MiniTeachingPoint(icon: Icons.arrow_upward, text: 'Pump above the expected systolic pressure.'),
                      const _MiniTeachingPoint(icon: Icons.south, text: 'Release slowly while listening.'),
                      const _MiniTeachingPoint(icon: Icons.graphic_eq, text: 'First sound = systolic. Last sound = diastolic.'),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(onPressed: () => context.pop(), child: const Text('Got it')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _VideoStage { ready, inflate, targetPopup, releaseToSys, systolicPopup, releaseToDia, diastolicPopup, finalReading, quickCheck }

class _PopUpData {
  const _PopUpData({required this.icon, required this.title, required this.message, required this.color});
  final IconData icon;
  final String title;
  final String message;
  final Color color;
}

class _VideoProgress extends StatelessWidget {
  const _VideoProgress({required this.stage});
  final _VideoStage stage;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final step = switch (stage) {
      _VideoStage.ready => 0,
      _VideoStage.inflate => 1,
      _VideoStage.targetPopup => 2,
      _VideoStage.releaseToSys => 3,
      _VideoStage.systolicPopup => 4,
      _VideoStage.releaseToDia => 5,
      _VideoStage.diastolicPopup => 6,
      _VideoStage.finalReading => 7,
      _VideoStage.quickCheck => 7,
    };
    return Row(
      children: [
        for (var i = 1; i <= 7; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 8,
              decoration: BoxDecoration(
                color: i <= step ? AppColors.emsBlue : cs.outline.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          if (i != 7) const SizedBox(width: 5),
        ],
      ],
    );
  }
}

class _BpSimulatorVideo extends StatelessWidget {
  const _BpSimulatorVideo({
    required this.pressure,
    required this.showBeats,
    required this.highlightTarget,
    required this.highlightSys,
    required this.highlightDia,
    required this.popUp,
  });

  final double pressure;
  final bool showBeats;
  final bool highlightTarget;
  final bool highlightSys;
  final bool highlightDia;
  final _PopUpData popUp;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF0E253B), const Color(0xFF143B5C), cs.surface],
              stops: const [0, 0.56, 1],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
          ),
          child: compact
              ? Column(
                  children: [
                    _SimGaugePanel(
                      pressure: pressure,
                      showBeats: showBeats,
                      highlightTarget: highlightTarget,
                      highlightSys: highlightSys,
                      highlightDia: highlightDia,
                    ),
                    const SizedBox(height: 12),
                    _DemoToolStrip(active: showBeats, pressure: pressure),
                    const SizedBox(height: 12),
                    _CheckpointPopup(popUp: popUp),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: _SimGaugePanel(
                        pressure: pressure,
                        showBeats: showBeats,
                        highlightTarget: highlightTarget,
                        highlightSys: highlightSys,
                        highlightDia: highlightDia,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          _DemoToolStrip(active: showBeats, pressure: pressure),
                          const SizedBox(height: 12),
                          _CheckpointPopup(popUp: popUp),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _DemoToolStrip extends StatelessWidget {
  const _DemoToolStrip({required this.active, required this.pressure});
  final bool active;
  final double pressure;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DemoToolIcon(
                  icon: Icons.air,
                  label: 'Pump',
                  sublabel: 'Inflate cuff',
                  color: AppColors.emsBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DemoToolIcon(
                  icon: Icons.south,
                  label: 'Release',
                  sublabel: 'Deflate slowly',
                  color: pressure > 0 ? Colors.green : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: active ? Colors.green.withValues(alpha: 0.12) : AppColors.emsBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(active ? Icons.graphic_eq : Icons.hearing, color: active ? Colors.green : AppColors.emsBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    active ? 'Korotkoff sounds playing' : 'Listen for Korotkoff sounds',
                    style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoToolIcon extends StatelessWidget {
  const _DemoToolIcon({required this.icon, required this.label, required this.sublabel, required this.color});
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 6),
          Text(label, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
          Text(sublabel, textAlign: TextAlign.center, style: context.textStyles.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _SimGaugePanel extends StatelessWidget {
  const _SimGaugePanel({required this.pressure, required this.showBeats, required this.highlightTarget, required this.highlightSys, required this.highlightDia});
  final double pressure;
  final bool showBeats;
  final bool highlightTarget;
  final bool highlightSys;
  final bool highlightDia;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                BpGauge(pressure: pressure),
                if (highlightTarget) const _GaugeBadge(label: '170', sublabel: 'target', alignment: Alignment.topRight, color: Colors.orange),
                if (highlightSys) const _GaugeBadge(label: '118', sublabel: 'SYS', alignment: Alignment.centerRight, color: Colors.green),
                if (highlightDia) const _GaugeBadge(label: '76', sublabel: 'DIA', alignment: Alignment.bottomRight, color: AppColors.emsBlue),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(showBeats ? Icons.graphic_eq : Icons.volume_off, color: showBeats ? Colors.green : cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Text('${pressure.round()} mmHg', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ],
    );
  }
}

class _GaugeBadge extends StatelessWidget {
  const _GaugeBadge({required this.label, required this.sublabel, required this.alignment, required this.color});
  final String label;
  final String sublabel;
  final Alignment alignment;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedAlign(
          alignment: alignment,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.72), width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: context.textStyles.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w900)),
                Text(sublabel, style: context.textStyles.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckpointPopup extends StatelessWidget {
  const _CheckpointPopup({required this.popUp});
  final _PopUpData popUp;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(animation), child: child),
      ),
      child: Container(
        key: ValueKey(popUp.title),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: popUp.color.withValues(alpha: 0.34), width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: popUp.color, borderRadius: BorderRadius.circular(16)),
              child: Icon(popUp.icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(popUp.title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(popUp.message, style: context.textStyles.bodySmall?.copyWith(height: 1.25)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundStrip extends StatelessWidget {
  const _SoundStrip({required this.active, required this.stage});
  final bool active;
  final _VideoStage stage;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = switch (stage) {
      _VideoStage.systolicPopup => 'lub… lub… first sound',
      _VideoStage.releaseToDia => 'lub… lub… lub…',
      _VideoStage.diastolicPopup => 'silence — sounds stopped',
      _VideoStage.finalReading => 'reading complete',
      _ => active ? 'lub… lub… lub…' : 'listening…',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: active ? Colors.green.withValues(alpha: 0.10) : cs.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: active ? Colors.green.withValues(alpha: 0.28) : cs.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(active ? Icons.graphic_eq : Icons.volume_off, color: active ? Colors.green : cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: active ? Colors.green : cs.onSurfaceVariant))),
        ],
      ),
    );
  }
}

class _VideoControls extends StatelessWidget {
  const _VideoControls({required this.stage, required this.isPlaying, required this.onPlay, required this.onQuiz, required this.onReplay, required this.onPractice});
  final _VideoStage stage;
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onQuiz;
  final VoidCallback onReplay;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    final isReady = stage == _VideoStage.ready;
    final isDone = stage == _VideoStage.finalReading;
    final isQuiz = stage == _VideoStage.quickCheck;
    if (isQuiz) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: isDone ? onPractice : onPlay,
                  icon: Icon(isDone ? Icons.fitness_center : (isReady ? Icons.play_arrow : (isPlaying ? Icons.pause : Icons.play_arrow)), color: Colors.white),
                  label: Text(isDone ? 'Go to Practice' : (isReady ? 'Play Demo' : (isPlaying ? 'Pause' : 'Resume')), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
            if (!isReady) ...[
              const SizedBox(width: 10),
              SizedBox(
                height: 54,
                child: OutlinedButton.icon(onPressed: onReplay, icon: const Icon(Icons.replay), label: const Text('Replay')),
              ),
            ],
          ],
        ),
        if (isDone) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(onPressed: onQuiz, icon: const Icon(Icons.quiz_outlined), label: const Text('Quiz')),
          ),
        ],
      ],
    );
  }
}

class _QuickCheckCard extends StatelessWidget {
  const _QuickCheckCard({required this.questionIndex, required this.selectedAnswer, required this.onSelect, required this.onContinue});
  final int questionIndex;
  final int? selectedAnswer;
  final ValueChanged<int> onSelect;
  final VoidCallback? onContinue;

  static const _questions = [
    _QuizQuestion(
      text: 'First sound heard?',
      options: ['Systolic / top number', 'Diastolic / bottom number', 'Respiratory rate'],
      correctIndex: 0,
      explanation: 'First clear Korotkoff sound = systolic.',
    ),
    _QuizQuestion(
      text: 'Sounds disappear?',
      options: ['Systolic', 'Diastolic / bottom number', 'Pulse rate'],
      correctIndex: 1,
      explanation: 'When the sounds disappear, record diastolic.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final q = _questions[questionIndex];
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.16)),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Question ${questionIndex + 1} of 2', style: context.textStyles.labelMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(q.text, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          for (var i = 0; i < q.options.length; i++) ...[
            _AnswerTile(
              text: q.options[i],
              selected: selectedAnswer == i,
              correct: selectedAnswer == null ? null : i == q.correctIndex,
              onTap: () => onSelect(i),
            ),
            if (i != q.options.length - 1) const SizedBox(height: 8),
          ],
          if (selectedAnswer != null) ...[
            const SizedBox(height: 10),
            EMSResultBox(
              title: selectedAnswer == q.correctIndex ? 'Correct' : 'Review',
              message: q.explanation,
              kind: selectedAnswer == q.correctIndex ? EMSResultKind.success : EMSResultKind.warning,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: onContinue,
                child: Text(questionIndex == 0 ? 'Next' : 'Practice'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({required this.text, required this.selected, required this.correct, required this.onTap});
  final String text;
  final bool selected;
  final bool? correct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = correct == true ? Colors.green : (selected ? AppColors.emsBlue : cs.outline);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.10) : cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color.withValues(alpha: 0.42) : cs.outline.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? color : cs.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w800))),
          ],
        ),
      ),
    );
  }
}

class _MiniTeachingPoint extends StatelessWidget {
  const _MiniTeachingPoint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.emsBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: context.textStyles.bodyMedium?.copyWith(height: 1.35))),
        ],
      ),
    );
  }
}

class _QuizQuestion {
  const _QuizQuestion({required this.text, required this.options, required this.correctIndex, required this.explanation});
  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}
