import 'dart:math';

import 'package:emscode_sim_vitals/app/app_state.dart';
import 'package:emscode_sim_vitals/shared/ems_vitals_shell.dart';
import 'package:emscode_sim_vitals/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum InstructorDifficulty { easy, standard, hard }

extension on InstructorDifficulty {
  String get label => switch (this) {
    InstructorDifficulty.easy => 'Easy',
    InstructorDifficulty.standard => 'Standard',
    InstructorDifficulty.hard => 'Hard',
  };
}

/// Local-only Instructor Mode.
///
/// Version 1 goal: let an instructor quickly generate a hidden scenario + reveal an answer key
/// for a subset of modules (BP + Pulse). This avoids backend needs and keeps the app fast.
class InstructorModePage extends StatefulWidget {
  const InstructorModePage({super.key});

  @override
  State<InstructorModePage> createState() => _InstructorModePageState();
}

class _InstructorModePageState extends State<InstructorModePage> {
  final _rng = Random();
  TrainingModule _module = TrainingModule.bloodPressure;
  InstructorDifficulty _difficulty = InstructorDifficulty.standard;

  String? _caseText;
  String? _answerKey;
  bool _revealed = false;

  void _generateCase() {
    final (caseText, key) = switch (_module) {
      TrainingModule.bloodPressure => _generateBp(),
      TrainingModule.pulse => _generatePulse(),
      _ => ('This module is not yet supported in Instructor Mode (v1).', 'No answer key available.'),
    };

    setState(() {
      _caseText = caseText;
      _answerKey = key;
      _revealed = false;
    });
  }

  (String, String) _generateBp() {
    final (sysMin, sysMax, diaMin, diaMax) = switch (_difficulty) {
      InstructorDifficulty.easy => (110, 140, 70, 90),
      InstructorDifficulty.standard => (90, 180, 50, 110),
      InstructorDifficulty.hard => (70, 220, 40, 130),
    };
    int even(int min, int maxVal) {
      final start = min.isEven ? min : min + 1;
      final end = maxVal.isEven ? maxVal : maxVal - 1;
      final count = ((end - start) ~/ 2) + 1;
      return start + 2 * _rng.nextInt(max(1, count));
    }

    final sys = even(sysMin, sysMax);
    var dia = even(diaMin, min(diaMax, sys - 10));
    if (dia >= sys) dia = sys - 10;

    final pulse = switch (_difficulty) {
      InstructorDifficulty.easy => 72 + _rng.nextInt(18),
      InstructorDifficulty.standard => 60 + _rng.nextInt(61),
      InstructorDifficulty.hard => 40 + _rng.nextInt(121),
    };

    final caseText = 'Adult patient • Pulse ${pulse} • Auscultated BP reading';
    final key = 'Answer key: $sys/$dia mmHg (pulse $pulse)';
    return (caseText, key);
  }

  (String, String) _generatePulse() {
    final bpm = switch (_difficulty) {
      InstructorDifficulty.easy => 60 + _rng.nextInt(41),
      InstructorDifficulty.standard => 50 + _rng.nextInt(101),
      InstructorDifficulty.hard => 40 + _rng.nextInt(151),
    };
    final caseText = 'Pulse counting scenario • Rate is hidden • Use 15s or 30s count';
    final key = 'Answer key: $bpm BPM';
    return (caseText, key);
  }

  @override
  Widget build(BuildContext context) {
    return EMSVitalsScaffold(
      title: 'Instructor Mode',
      subtitle: 'Local-only case generator & answer key • Training use only',
      onInfoPressed: () {
        EMSInfoSheet.show(
          context,
          title: 'Instructor Mode (v1)',
          children: const [
            Text('Generate a quick scenario and reveal the answer key for teaching or skills lab checkoffs.'),
            SizedBox(height: 12),
            EMSWarningNote(text: 'This feature is local-only. It does not save student identities or transmit data.'),
          ],
        );
      },
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
                      title: 'Setup',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<TrainingModule>(
                                  value: _module,
                                  decoration: const InputDecoration(labelText: 'Module'),
                                  items: [
                                    for (final m in TrainingModule.values) DropdownMenuItem(value: m, child: Text(m.label)),
                                  ],
                                  onChanged: (v) => setState(() => _module = v ?? _module),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<InstructorDifficulty>(
                                  value: _difficulty,
                                  decoration: const InputDecoration(labelText: 'Difficulty'),
                                  items: [
                                    for (final d in InstructorDifficulty.values) DropdownMenuItem(value: d, child: Text(d.label)),
                                  ],
                                  onChanged: (v) => setState(() => _difficulty = v ?? _difficulty),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton.icon(
                              onPressed: _generateCase,
                              style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                              icon: const Icon(Icons.shuffle, color: Colors.white),
                              label: const Text('Generate random case', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_caseText != null)
                      EMSSectionCard(
                        title: 'Case',
                        subtitle: 'Share this with the student. Use Reveal to show the answer key.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_caseText!, style: context.textStyles.bodyMedium?.copyWith(height: 1.5)),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 50,
                                    child: OutlinedButton.icon(
                                      onPressed: () => setState(() => _revealed = !_revealed),
                                      style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                                      icon: Icon(_revealed ? Icons.visibility_off : Icons.visibility),
                                      label: Text(_revealed ? 'Hide answer key' : 'Reveal answer key'),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 50,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _caseText = null;
                                          _answerKey = null;
                                          _revealed = false;
                                        });
                                      },
                                      style: ButtonStyle(splashFactory: NoSplash.splashFactory, shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                                      icon: const Icon(Icons.restart_alt),
                                      label: const Text('Reset'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_revealed && _answerKey != null) ...[
                              const SizedBox(height: 12),
                              EMSResultBox(title: 'Answer key', message: _answerKey!, kind: EMSResultKind.info),
                            ],
                          ],
                        ),
                      )
                    else
                      EMSSectionCard(
                        title: 'Ready when you are',
                        subtitle: 'Generate a case to begin. (BP + Pulse supported in v1.)',
                        child: Text('Tip: Set student app mode to Test for a more realistic attempt.', style: context.textStyles.bodySmall?.copyWith(height: 1.4)),
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
