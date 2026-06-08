import 'package:audioplayers/audioplayers.dart';
import 'package:emscode_sim_vitals/audio/sine_wav.dart';
import 'package:flutter/foundation.dart';

/// Plays a short pulse "click" sound.
///
/// Uses the same unlock strategy as the BP simulator for iOS/Safari:
/// call [unlockFromUserGesture] only after a tap.
class PulseBeepPlayer {
  PulseBeepPlayer();

  final AudioPlayer _player = AudioPlayer();
  bool _unlocked = false;

  static final _clickWav = buildSineWav(
    frequencyHz: 660,
    durationSeconds: 0.085,
    sampleRate: 44100,
    volume: 0.70,
  );

  static final _silentWav = buildSineWav(
    frequencyHz: 660,
    durationSeconds: 0.02,
    sampleRate: 44100,
    volume: 0.0,
  );

  Future<void> unlockFromUserGesture() async {
    if (_unlocked) return;
    try {
      await _player.play(BytesSource(_silentWav), volume: 0.0);
      await _player.stop();
      _unlocked = true;
    } catch (e) {
      debugPrint('PulseBeepPlayer unlock failed: $e');
    }
  }

  Future<void> playOnce({double volume = 1.0}) async {
    try {
      await _player.play(BytesSource(_clickWav), volume: volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('PulseBeepPlayer play failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('PulseBeepPlayer stop failed: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (e) {
      debugPrint('PulseBeepPlayer dispose failed: $e');
    }
  }
}
