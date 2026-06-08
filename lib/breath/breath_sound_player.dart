import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:emscode_sim_vitals/audio/sine_wav.dart';
import 'package:flutter/foundation.dart';

/// Lightweight asset audio player with an iOS/Safari unlock strategy.
///
/// - Call [unlockFromUserGesture] after the first tap.
/// - Use [playAsset] to start/restart an asset from the beginning.
class BreathSoundPlayer {
  BreathSoundPlayer();

  final AudioPlayer _player = AudioPlayer();
  bool _unlocked = false;

  AudioPlayer get player => _player;

  static final Uint8List _silentWav = buildSineWav(
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
      debugPrint('BreathSoundPlayer unlock failed: $e');
    }
  }

  Future<void> playAsset(String assetPath) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('BreathSoundPlayer play failed ($assetPath): $e');
      rethrow;
    }
  }

  Future<void> playBytes(Uint8List wavBytes, {double volume = 1.0}) async {
    try {
      await _player.stop();
      await _player.play(BytesSource(wavBytes), volume: volume);
    } catch (e) {
      debugPrint('BreathSoundPlayer playBytes failed: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('BreathSoundPlayer stop failed: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      debugPrint('BreathSoundPlayer pause failed: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (e) {
      debugPrint('BreathSoundPlayer dispose failed: $e');
    }
  }
}
