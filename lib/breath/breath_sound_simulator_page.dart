import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:emscode_sim_vitals/app/app_state.dart';
import 'package:emscode_sim_vitals/breath/breath_demo_sounds.dart';
import 'package:emscode_sim_vitals/breath/breath_sound_player.dart';
import 'package:emscode_sim_vitals/nav.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

enum BodyView { front, right, back, left }

enum PatientSide { left, right }

enum BreathSound { normalVesicular, wheezing, coarseCrackles, stridor, diminished }

extension _BreathSoundLabels on BreathSound {
  String get label => switch (this) {
    BreathSound.normalVesicular => 'Normal vesicular',
    BreathSound.wheezing => 'Wheezing',
    BreathSound.coarseCrackles => 'Coarse crackles',
    BreathSound.stridor => 'Stridor (neck only)',
    BreathSound.diminished => 'Diminished / absent',
  };
}

extension _BodyViewLabels on BodyView {
  String get label => switch (this) {
    BodyView.front => 'FRONT',
    BodyView.right => 'RIGHT',
    BodyView.back => 'BACK',
    BodyView.left => 'LEFT',
  };
}

class BreathHotspot {
  const BreathHotspot({required this.id, required this.label, required this.patientSide, required this.isNeck, required this.dx, required this.dy});

  final String id;
  final String label;
  final PatientSide patientSide;
  final bool isNeck;

  /// Fractional position inside the body view (0..1)
  final double dx;
  final double dy;
}

class BreathSoundSimulatorPage extends StatefulWidget {
  const BreathSoundSimulatorPage({super.key});

  @override
  State<BreathSoundSimulatorPage> createState() => _BreathSoundSimulatorPageState();
}

class _BreathSoundSimulatorPageState extends State<BreathSoundSimulatorPage> with WidgetsBindingObserver {
  // Stop audio when backgrounding.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      unawaited(_audio.stop());
    }
  }

  final BreathSoundPlayer _audio = BreathSoundPlayer();

  BodyView _view = BodyView.front;

  BreathSound _leftSound = BreathSound.normalVesicular;
  BreathSound _rightSound = BreathSound.normalVesicular;

  bool _leftStridorEnabled = false;
  bool _rightStridorEnabled = false;

  String? _note;
  String? _nowPlaying;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<PlayerState>? _stateSub;
  PlayerState _playerState = PlayerState.stopped;

  Set<String>? _assetPaths;

  static const _assetFront = 'images/front.png';
  static const _assetRight = 'images/right.png';
  static const _assetBack = 'images/back.png';
  static const _assetLeft = 'images/left.png';

  static const _audioNormal = 'audio/Lung-NormalVesicular.mp3';
  static const _audioWheeze = 'audio/Lung-Wheezing.mp3';
  static const _audioCrackles = 'audio/Lung-CoarseCrackles.mp3';
  static const _audioStridor = 'audio/Lung-InspiratoryStridor.mp3';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _durSub = _audio.player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
    });
    _posSub = _audio.player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
    _stateSub = _audio.player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _playerState = s);
    });
    unawaited(_loadAssetManifest());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _durSub?.cancel();
    _posSub?.cancel();
    _stateSub?.cancel();
    _audio.dispose();
    super.dispose();
  }

  Future<void> _loadAssetManifest() async {
    try {
      final jsonStr = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest = json.decode(jsonStr) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _assetPaths = manifest.keys.toSet());
    } catch (e) {
      debugPrint('Failed to read AssetManifest.json: $e');
      // Safe fallback: treat as unknown; we will attempt to load and handle errors.
      if (!mounted) return;
      setState(() => _assetPaths = null);
    }
  }

  bool _assetKnownExists(String path) {
    final set = _assetPaths;
    if (set == null) return false;
    return set.contains('assets/$path');
  }

  Future<bool> _assetExists(String path) async {
    if (_assetKnownExists(path)) return true;
    // Manifest not ready or missing: attempt a direct load.
    try {
      await rootBundle.load('assets/$path');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _unlockAudio() => _audio.unlockFromUserGesture();

  void _rotateBody() {
    setState(() {
      _view = switch (_view) {
        BodyView.front => BodyView.right,
        BodyView.right => BodyView.back,
        BodyView.back => BodyView.left,
        BodyView.left => BodyView.front,
      };

      // Leaving a neck point disables stridor per spec.
      _leftStridorEnabled = false;
      _rightStridorEnabled = false;

      if (_leftSound == BreathSound.stridor) {
        _leftSound = BreathSound.normalVesicular;
        _note = 'Stridor is only available when listening to the neck. Reverted to Normal vesicular.';
      }
      if (_rightSound == BreathSound.stridor) {
        _rightSound = BreathSound.normalVesicular;
        _note = 'Stridor is only available when listening to the neck. Reverted to Normal vesicular.';
      }
    });
  }

  List<BreathHotspot> _hotspotsForView(BodyView v) {
    // Positions are intentionally approximate; they’re tuned for a clean phone UI.
    return switch (v) {
      BodyView.front => const [
          BreathHotspot(id: 'RUL', label: 'RUL', patientSide: PatientSide.right, isNeck: false, dx: 0.33, dy: 0.30),
          BreathHotspot(id: 'LUL', label: 'LUL', patientSide: PatientSide.left, isNeck: false, dx: 0.67, dy: 0.30),
          BreathHotspot(id: 'RLL', label: 'RLL', patientSide: PatientSide.right, isNeck: false, dx: 0.36, dy: 0.60),
          BreathHotspot(id: 'LLL', label: 'LLL', patientSide: PatientSide.left, isNeck: false, dx: 0.64, dy: 0.60),
        ],
      BodyView.back => const [
          BreathHotspot(id: 'LUL', label: 'LUL', patientSide: PatientSide.left, isNeck: false, dx: 0.33, dy: 0.28),
          BreathHotspot(id: 'RUL', label: 'RUL', patientSide: PatientSide.right, isNeck: false, dx: 0.67, dy: 0.28),
          BreathHotspot(id: 'LLL', label: 'LLL', patientSide: PatientSide.left, isNeck: false, dx: 0.35, dy: 0.62),
          BreathHotspot(id: 'RLL', label: 'RLL', patientSide: PatientSide.right, isNeck: false, dx: 0.65, dy: 0.62),
        ],
      BodyView.right => const [
          BreathHotspot(id: 'Neck_R', label: 'Neck', patientSide: PatientSide.right, isNeck: true, dx: 0.52, dy: 0.20),
          BreathHotspot(id: 'Midax_R', label: 'Midaxillary', patientSide: PatientSide.right, isNeck: false, dx: 0.56, dy: 0.52),
        ],
      BodyView.left => const [
          BreathHotspot(id: 'Neck_L', label: 'Neck', patientSide: PatientSide.left, isNeck: true, dx: 0.48, dy: 0.20),
          BreathHotspot(id: 'Midax_L', label: 'Midaxillary', patientSide: PatientSide.left, isNeck: false, dx: 0.44, dy: 0.52),
        ],
    };
  }

  BreathSound _soundForSide(PatientSide side) => side == PatientSide.left ? _leftSound : _rightSound;

  bool _stridorEnabledForSide(PatientSide side) => side == PatientSide.left ? _leftStridorEnabled : _rightStridorEnabled;

  void _setStridorEnabled(PatientSide side, bool enabled) {
    if (side == PatientSide.left) {
      _leftStridorEnabled = enabled;
    } else {
      _rightStridorEnabled = enabled;
    }
  }

  void _setSoundForSide(PatientSide side, BreathSound sound) {
    if (side == PatientSide.left) {
      _leftSound = sound;
    } else {
      _rightSound = sound;
    }
  }

  String _assetForSound(BreathSound s) => switch (s) {
    BreathSound.normalVesicular => _audioNormal,
    BreathSound.wheezing => _audioWheeze,
    BreathSound.coarseCrackles => _audioCrackles,
    BreathSound.stridor => _audioStridor,
    BreathSound.diminished => _audioNormal,
  };

  BreathDemoSound _demoForSound(BreathSound s) => switch (s) {
    BreathSound.normalVesicular => BreathDemoSound.normal,
    BreathSound.wheezing => BreathDemoSound.wheeze,
    BreathSound.coarseCrackles => BreathDemoSound.crackles,
    BreathSound.stridor => BreathDemoSound.stridor,
    BreathSound.diminished => BreathDemoSound.diminished,
  };

  Future<void> _onTapHotspot(BreathHotspot hs) async {
    await _unlockAudio();

    setState(() {
      _note = null;
      if (hs.isNeck) {
        _setStridorEnabled(hs.patientSide, true);
      } else {
        // Leaving neck disables stridor for both sides.
        _leftStridorEnabled = false;
        _rightStridorEnabled = false;

        for (final side in PatientSide.values) {
          if (_soundForSide(side) == BreathSound.stridor) {
            _setSoundForSide(side, BreathSound.normalVesicular);
            _note = 'Stridor is only available at the neck. Reverted to Normal vesicular.';
          }
        }
      }
    });

    final selected = _soundForSide(hs.patientSide);
    if (selected == BreathSound.stridor && !hs.isNeck) {
      // Extra safety; should be reverted above.
      setState(() {
        _setSoundForSide(hs.patientSide, BreathSound.normalVesicular);
        _note = 'Stridor is only available when listening to the neck.';
      });
    }

    final effective = _soundForSide(hs.patientSide);
    final asset = _assetForSound(effective);

    final missing = !(await _assetExists(asset));
    final useDemo = context.read<AppState>().useDemoSoundsWhenMissing;
    if (missing && !useDemo) {
      setState(() {
        _nowPlaying = null;
        _note = 'Audio files are missing. Add the lung sound MP3 files to assets/audio.\n\nTip: enable “Use demo sounds when MP3 files are missing” to practice without assets.';
      });
      return;
    }

    try {
      if (missing && useDemo) {
        final wav = buildBreathDemoWav(sound: _demoForSound(effective));
        await _audio.playBytes(wav, volume: effective == BreathSound.diminished ? 0.35 : 1.0);
      } else {
        await _audio.playAsset(asset);
      }
      if (!mounted) return;
      setState(() => _nowPlaying = '${hs.patientSide == PatientSide.left ? 'Left' : 'Right'} • ${effective.label}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _nowPlaying = null;
        _note = 'Audio failed to play. (Is the MP3 uploaded and listed in pubspec?)';
      });
    }
  }

  Widget _bodyImageOrDiagram(BodyView v) {
    final asset = switch (v) {
      BodyView.front => _assetFront,
      BodyView.right => _assetRight,
      BodyView.back => _assetBack,
      BodyView.left => _assetLeft,
    };

    if (_assetKnownExists(asset)) {
      return Image.asset(
        'assets/$asset',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => _BodyDiagram(view: v),
      );
    }

    return _BodyDiagram(view: v);
  }

  void _showInfo() {
    EMSInfoSheet.show(
      context,
      title: 'Breath sounds: what they mean & where to listen',
      children: const [
        _TeachingCard(
          title: 'Normal vesicular',
          chips: ['Normal vesicular', 'Low-pitched', 'Peripheral'],
          bullets: [
            'Soft, rustling; inspiratory longer than expiratory, no pause.',
            'Best heard over peripheral lung fields, upper and lower, front and back.',
            'Use as baseline for side-to-side comparison.',
          ],
        ),
        SizedBox(height: AppSpacing.md),
        _TeachingCard(
          title: 'Wheezing',
          chips: ['Wheezing', 'High-pitched musical', 'Expiratory ± inspiratory'],
          bullets: [
            'Narrowed airways create polyphonic musical tones.',
            'Common causes: asthma, COPD, anaphylaxis, CHF exacerbation/cardiac asthma.',
            'May be heard without a stethoscope if severe.',
          ],
        ),
        SizedBox(height: AppSpacing.md),
        _TeachingCard(
          title: 'Coarse crackles',
          chips: ['Coarse crackles', 'Bubbling/popping', 'Inspiratory'],
          bullets: [
            'Air moving through fluid or secretions; coarse popping/bubbling.',
            'Common causes: pneumonia, CHF/pulmonary edema.',
            'Best heard at posterior bases and lower lobes.',
          ],
        ),
        SizedBox(height: AppSpacing.md),
        _TeachingCard(
          title: 'Stridor',
          chips: ['Stridor', 'Inspiratory, harsh', 'Upper airway'],
          bullets: [
            'Loud upper-airway sound best heard over neck/trachea.',
            'Red flag: voice change, drooling, severe work of breathing.',
          ],
        ),
        SizedBox(height: AppSpacing.md),
        _TeachingCard(
          title: 'Diminished / absent',
          chips: ['Diminished', 'Quiet'],
          bullets: [
            'Reduced air movement can suggest obstruction, effusion, or pneumothorax.',
            'Compare side-to-side at the same level.',
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hotspots = _hotspotsForView(_view);

    return EMSVitalsScaffold(
      title: 'Breath Sound Simulator',
      subtitle: 'Tap a region • Choose left/right sounds • Rotate the body',
      onInfoPressed: _showInfo,
      onBackPressed: () {
        unawaited(_audio.stop());
        context.go(AppRoutes.home);
      },
      bodySlivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Body view', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                              ),
                              FilledButton.tonal(
                                onPressed: _rotateBody,
                                style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
                                child: const Text('Rotate Body'),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.rotate_90_degrees_ccw, color: cs.onSurfaceVariant, size: 18),
                                const SizedBox(width: 8),
                                Text('View: ${_view.label}', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AspectRatio(
                            aspectRatio: 0.82,
                            child: LayoutBuilder(
                              builder: (context, c) {
                                return Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                                            border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
                                            borderRadius: BorderRadius.circular(18),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(AppSpacing.md),
                                            child: _bodyImageOrDiagram(_view),
                                          ),
                                        ),
                                      ),
                                    ),
                                    for (final hs in hotspots)
                                      Positioned(
                                        left: (c.maxWidth * hs.dx) - 56,
                                        top: (c.maxHeight * hs.dy) - 18,
                                        width: 112,
                                        height: 44,
                                        child: _HotspotButton(
                                          label: hs.label,
                                          onPressed: () => _onTapHotspot(hs),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                          if (_view == BodyView.front) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Front view is mirrored to patient: screen-left = patient’s RIGHT.',
                              style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sound selectors', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: AppSpacing.md),
                          Consumer<AppState>(
                            builder: (context, s, _) {
                              return SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                value: s.useDemoSoundsWhenMissing,
                                onChanged: (v) => s.setUseDemoSoundsWhenMissing(v),
                                title: const Text('Use demo sounds when MP3 files are missing'),
                                subtitle: Text('Recommended for web preview and early training builds.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _SoundDropdown(
                            label: 'Left sound',
                            value: _leftSound,
                            stridorEnabled: _leftStridorEnabled,
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() {
                                if (v == BreathSound.stridor && !_leftStridorEnabled) {
                                  _note = 'Stridor is only available when listening to the neck.';
                                  _leftSound = BreathSound.normalVesicular;
                                } else {
                                  _leftSound = v;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _SoundDropdown(
                            label: 'Right sound',
                            value: _rightSound,
                            stridorEnabled: _rightStridorEnabled,
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() {
                                if (v == BreathSound.stridor && !_rightStridorEnabled) {
                                  _note = 'Stridor is only available when listening to the neck.';
                                  _rightSound = BreathSound.normalVesicular;
                                } else {
                                  _rightSound = v;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('Audio', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                            FilledButton.tonalIcon(
                              onPressed: () => _audio.pause(),
                              style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
                              icon: const Icon(Icons.pause, size: 18),
                              label: const Text('Pause'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if ((_note ?? '').isNotEmpty)
                          EMSResultBox(title: 'Audio note', message: _note!, kind: EMSResultKind.info),
                        if ((_note ?? '').isNotEmpty) const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Icon(Icons.graphic_eq, color: cs.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _nowPlaying == null ? 'Tap a listening point to play the selected sound.' : 'Now playing: $_nowPlaying',
                                style: context.textStyles.bodyMedium?.copyWith(height: 1.4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _AudioProgressBar(
                          duration: _duration,
                          position: _position,
                          isPlaying: _playerState == PlayerState.playing,
                          onSeek: (d) async {
                            try {
                              await _audio.player.seek(d);
                            } catch (e) {
                              debugPrint('Seek failed: $e');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HotspotButton extends StatelessWidget {
  const _HotspotButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: ButtonStyle(
        splashFactory: NoSplash.splashFactory,
        backgroundColor: const WidgetStatePropertyAll(AppColors.emsBlue),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
        textStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
      ),
      child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
    );
  }
}

class _SoundDropdown extends StatelessWidget {
  const _SoundDropdown({required this.label, required this.value, required this.stridorEnabled, required this.onChanged});

  final String label;
  final BreathSound value;
  final bool stridorEnabled;
  final ValueChanged<BreathSound?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = BreathSound.values.map((s) {
      final enabled = s != BreathSound.stridor || stridorEnabled;
      return DropdownMenuItem<BreathSound>(
        value: s,
        enabled: enabled,
        child: Row(
          children: [
            Icon(
              s == BreathSound.normalVesicular
                  ? Icons.spa
                  : s == BreathSound.wheezing
                      ? Icons.multitrack_audio
                      : s == BreathSound.coarseCrackles
                          ? Icons.bubble_chart
                          : Icons.warning_amber,
              size: 18,
              color: enabled ? cs.onSurfaceVariant : cs.onSurfaceVariant.withValues(alpha: 0.35),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                s.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: enabled ? cs.onSurface : cs.onSurface.withValues(alpha: 0.38)),
              ),
            ),
          ],
        ),
      );
    }).toList();

    return DropdownButtonFormField<BreathSound>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.25),
      ),
    );
  }
}

class _AudioProgressBar extends StatelessWidget {
  const _AudioProgressBar({required this.duration, required this.position, required this.isPlaying, required this.onSeek});

  final Duration duration;
  final Duration position;
  final bool isPlaying;
  final ValueChanged<Duration> onSeek;

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxMs = duration.inMilliseconds;
    final posMs = position.inMilliseconds.clamp(0, maxMs == 0 ? 0 : maxMs);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            overlayShape: SliderComponentShape.noOverlay,
            activeTrackColor: AppColors.emsBlue,
            thumbColor: AppColors.emsCyan,
            inactiveTrackColor: cs.outline.withValues(alpha: 0.22),
          ),
          child: Slider(
            value: maxMs == 0 ? 0 : posMs.toDouble(),
            min: 0,
            max: maxMs == 0 ? 1 : maxMs.toDouble(),
            onChanged: (v) {
              if (maxMs == 0) return;
              onSeek(Duration(milliseconds: v.round()));
            },
          ),
        ),
        Row(
          children: [
            Text(_fmt(position), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            const Spacer(),
            Text(_fmt(duration), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
        if (!isPlaying && duration != Duration.zero)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Paused', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          ),
      ],
    );
  }
}

class _TeachingCard extends StatelessWidget {
  const _TeachingCard({required this.title, required this.chips, required this.bullets});

  final String title;
  final List<String> chips;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in chips)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: AppColors.headerGradient.map((x) => x.withValues(alpha: 0.16)).toList()),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
                  ),
                  child: Text(c, style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final b in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(Icons.circle, size: 6, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(b, style: context.textStyles.bodyMedium?.copyWith(height: 1.45))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BodyDiagram extends StatelessWidget {
  const _BodyDiagram({required this.view});

  final BodyView view;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _BodyDiagramPainter(view: view, outline: cs.outline.withValues(alpha: 0.30), fill: cs.surface, accent: AppColors.emsCyan.withValues(alpha: 0.22)),
      child: const SizedBox.expand(),
    );
  }
}

class _BodyDiagramPainter extends CustomPainter {
  _BodyDiagramPainter({required this.view, required this.outline, required this.fill, required this.accent});

  final BodyView view;
  final Color outline;
  final Color fill;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final pFill = Paint()..color = fill;
    final pOutline = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final pAccent = Paint()..color = accent;

    // Head
    final headR = w * 0.10;
    final headC = Offset(cx, h * 0.18);
    canvas.drawCircle(headC, headR, pAccent);
    canvas.drawCircle(headC, headR, pOutline);

    // Torso silhouette (simple, clean)
    final torsoTop = h * 0.28;
    final torsoBottom = h * 0.86;
    final shoulderY = h * 0.32;
    final hipY = h * 0.72;
    final shoulderHalf = w * 0.24;
    final chestHalf = w * 0.20;
    final waistHalf = w * 0.16;
    final hipHalf = w * 0.18;

    final path = Path()
      ..moveTo(cx - shoulderHalf, shoulderY)
      ..quadraticBezierTo(cx - chestHalf, torsoTop, cx, torsoTop)
      ..quadraticBezierTo(cx + chestHalf, torsoTop, cx + shoulderHalf, shoulderY)
      ..quadraticBezierTo(cx + chestHalf, hipY, cx + hipHalf, torsoBottom)
      ..quadraticBezierTo(cx, h * 0.92, cx - hipHalf, torsoBottom)
      ..quadraticBezierTo(cx - chestHalf, hipY, cx - shoulderHalf, shoulderY)
      ..close();

    canvas.drawPath(path, pAccent);
    canvas.drawPath(path, pOutline);

    // Subtle view indicator lines.
    final linePaint = Paint()
      ..color = outline.withValues(alpha: 0.40)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    if (view == BodyView.front || view == BodyView.back) {
      canvas.drawLine(Offset(cx, torsoTop + 8), Offset(cx, torsoBottom - 12), linePaint);
      canvas.drawLine(Offset(cx - waistHalf, hipY), Offset(cx + waistHalf, hipY), linePaint);
    } else {
      // Side profile rib line
      final sgn = view == BodyView.right ? 1.0 : -1.0;
      canvas.drawLine(Offset(cx + sgn * w * 0.06, torsoTop + 18), Offset(cx + sgn * w * 0.12, hipY + 12), linePaint);
      canvas.drawCircle(Offset(cx + sgn * w * 0.10, h * 0.46), w * 0.04, Paint()..color = outline.withValues(alpha: 0.22));
    }
  }

  @override
  bool shouldRepaint(covariant _BodyDiagramPainter oldDelegate) => oldDelegate.view != view || oldDelegate.outline != outline || oldDelegate.fill != fill || oldDelegate.accent != accent;
}
