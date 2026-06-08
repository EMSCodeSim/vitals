import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TrainingMode { learn, practice, test }

extension TrainingModeLabels on TrainingMode {
  String get label => switch (this) {
    TrainingMode.learn => 'Learn',
    TrainingMode.practice => 'Practice',
    TrainingMode.test => 'Test',
  };
}

enum TrainingModule { bloodPressure, pulse, stroke, pupil, burn, breath, walkthrough }

extension TrainingModuleLabels on TrainingModule {
  String get label => switch (this) {
    TrainingModule.bloodPressure => 'Blood Pressure',
    TrainingModule.pulse => 'Pulse Test',
    TrainingModule.stroke => 'Stroke Assessment',
    TrainingModule.pupil => 'Pupil Assessment',
    TrainingModule.burn => 'Rule of Nines',
    TrainingModule.breath => 'Breath Sounds',
    TrainingModule.walkthrough => 'Patient Assessment Walkthrough',
  };
}

@immutable
class ModuleProgress {
  const ModuleProgress({required this.attempts, required this.lastScore, required this.bestScore, required this.lastOpenedEpochMs});

  final int attempts;
  final int? lastScore;
  final int? bestScore;
  final int? lastOpenedEpochMs;

  ModuleProgress copyWith({int? attempts, int? lastScore, int? bestScore, int? lastOpenedEpochMs}) => ModuleProgress(
    attempts: attempts ?? this.attempts,
    lastScore: lastScore ?? this.lastScore,
    bestScore: bestScore ?? this.bestScore,
    lastOpenedEpochMs: lastOpenedEpochMs ?? this.lastOpenedEpochMs,
  );

  Map<String, dynamic> toJson() => {
    'attempts': attempts,
    'lastScore': lastScore,
    'bestScore': bestScore,
    'lastOpenedEpochMs': lastOpenedEpochMs,
  };

  static ModuleProgress fromJson(Map<String, dynamic> json) => ModuleProgress(
    attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    lastScore: (json['lastScore'] as num?)?.toInt(),
    bestScore: (json['bestScore'] as num?)?.toInt(),
    lastOpenedEpochMs: (json['lastOpenedEpochMs'] as num?)?.toInt(),
  );
}

class AppState extends ChangeNotifier {
  static const _prefsKey = 'emsvitals.app_state.v1';

  TrainingMode _mode = TrainingMode.practice;
  TrainingModule? _lastModule;
  final Map<TrainingModule, ModuleProgress> _progress = {};

  bool _useDemoSoundsWhenMissing = true;

  bool _instructorMode = false;

  bool _ready = false;
  bool get isReady => _ready;

  TrainingMode get mode => _mode;
  TrainingModule? get lastModule => _lastModule;
  bool get useDemoSoundsWhenMissing => _useDemoSoundsWhenMissing;
  bool get instructorMode => _instructorMode;
  ModuleProgress progressFor(TrainingModule module) => _progress[module] ?? const ModuleProgress(attempts: 0, lastScore: null, bestScore: null, lastOpenedEpochMs: null);

  Future<void> init() async {
    if (_ready) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) {
        _ready = true;
        notifyListeners();
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) throw StateError('Invalid stored app state');

      final modeStr = decoded['mode'] as String?;
      _mode = TrainingMode.values.firstWhere((m) => m.name == modeStr, orElse: () => TrainingMode.practice);

      final lastStr = decoded['lastModule'] as String?;
      _lastModule = lastStr == null ? null : TrainingModule.values.cast<TrainingModule?>().firstWhere((m) => m?.name == lastStr, orElse: () => null);

      final prog = decoded['progress'];
      if (prog is Map<String, dynamic>) {
        _progress.clear();
        for (final entry in prog.entries) {
          final key = TrainingModule.values.firstWhere((m) => m.name == entry.key, orElse: () => TrainingModule.bloodPressure);
          final value = entry.value;
          if (value is Map<String, dynamic>) _progress[key] = ModuleProgress.fromJson(value);
        }
      }

      _useDemoSoundsWhenMissing = decoded['useDemoSoundsWhenMissing'] as bool? ?? true;
      _instructorMode = decoded['instructorMode'] as bool? ?? false;
    } catch (e) {
      debugPrint('AppState init failed, using defaults: $e');
    } finally {
      _ready = true;
      notifyListeners();
    }
  }

  Future<void> setMode(TrainingMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await _persist();
  }

  Future<void> markModuleOpened(TrainingModule module) async {
    _lastModule = module;
    final current = progressFor(module);
    _progress[module] = current.copyWith(lastOpenedEpochMs: DateTime.now().millisecondsSinceEpoch);
    notifyListeners();
    await _persist();
  }

  Future<void> recordAttempt({required TrainingModule module, required int scorePercent}) async {
    final current = progressFor(module);
    final best = current.bestScore == null ? scorePercent : (scorePercent > current.bestScore! ? scorePercent : current.bestScore);
    _progress[module] = current.copyWith(attempts: current.attempts + 1, lastScore: scorePercent, bestScore: best);
    notifyListeners();
    await _persist();
  }

  Future<void> setUseDemoSoundsWhenMissing(bool v) async {
    if (_useDemoSoundsWhenMissing == v) return;
    _useDemoSoundsWhenMissing = v;
    notifyListeners();
    await _persist();
  }

  Future<void> setInstructorMode(bool v) async {
    if (_instructorMode == v) return;
    _instructorMode = v;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = {
        'mode': _mode.name,
        'lastModule': _lastModule?.name,
        'progress': {for (final e in _progress.entries) e.key.name: e.value.toJson()},
        'useDemoSoundsWhenMissing': _useDemoSoundsWhenMissing,
        'instructorMode': _instructorMode,
      };
      await prefs.setString(_prefsKey, jsonEncode(json));
    } catch (e) {
      debugPrint('AppState persist failed: $e');
    }
  }
}
