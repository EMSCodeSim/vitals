import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:emscode_sim_vitals/audio/sine_wav.dart';
import 'package:flutter/foundation.dart';

/// Plays a short Korotkoff-style tone in a loop.
///
/// Uses an in-memory WAV so it works without bundling audio assets.
/// The first play should be initiated after a user gesture on iOS/Safari.
class BpBeepPlayer {
  BpBeepPlayer();

  final AudioPlayer _player = AudioPlayer();
  Timer? _loopTimer;
  bool _unlocked = false;

  static final Uint8List _beepWav = _buildSineWav(
    frequencyHz: 1000,
    durationSeconds: 0.18,
    sampleRate: 44100,
    volume: 0.65,
  );

  static final Uint8List _silentWav = _buildSineWav(
    frequencyHz: 1000,
    durationSeconds: 0.02,
    sampleRate: 44100,
    volume: 0.0,
  );

  Future<void> unlockFromUserGesture() async {
    if (_unlocked) return;
    try {
      // A tiny silent play primes audio on iOS/Safari after a user interaction.
      await _player.play(BytesSource(_silentWav), volume: 0.0);
      await _player.stop();
      _unlocked = true;
    } catch (e) {
      debugPrint('BpBeepPlayer unlock failed: $e');
    }
  }

  Future<void> startLoop({Duration interval = const Duration(milliseconds: 666)}) async {
    if (_loopTimer != null) return;
    await _playOnce();
    _loopTimer = Timer.periodic(interval, (_) => _playOnce());
  }

  Future<void> stopLoop() async {
    _loopTimer?.cancel();
    _loopTimer = null;
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('BpBeepPlayer stop failed: $e');
    }
  }

  Future<void> dispose() async {
    _loopTimer?.cancel();
    _loopTimer = null;
    try {
      await _player.dispose();
    } catch (e) {
      debugPrint('BpBeepPlayer dispose failed: $e');
    }
  }

  Future<void> _playOnce() async {
    try {
      // We re-trigger each time; WAV is short.
      await _player.play(BytesSource(_beepWav));
    } catch (e) {
      debugPrint('BpBeepPlayer play failed: $e');
    }
  }

  static Uint8List _buildSineWav({
    required int frequencyHz,
    required double durationSeconds,
    required int sampleRate,
    required double volume,
  }) => buildSineWav(
    frequencyHz: frequencyHz,
    durationSeconds: durationSeconds,
    sampleRate: sampleRate,
    volume: volume,
  );
}
