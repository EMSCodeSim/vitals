import 'dart:math';
import 'dart:typed_data';

Uint8List buildBreathDemoWav({required BreathDemoSound sound, int sampleRate = 44100}) {
  final seconds = switch (sound) {
    BreathDemoSound.normal => 2.4,
    BreathDemoSound.wheeze => 2.0,
    BreathDemoSound.crackles => 2.2,
    BreathDemoSound.stridor => 1.8,
    BreathDemoSound.diminished => 2.2,
  };
  final totalSamples = max(1, (seconds * sampleRate).round());
  final pcm = Int16List(totalSamples);
  final rnd = Random(sound.index + 7);

  double env(double t) {
    // Soft attack/decay to avoid clicks.
    final a = 0.08;
    final d = 0.10;
    if (t < a) return t / a;
    if (t > seconds - d) return max(0.0, (seconds - t) / d);
    return 1.0;
  }

  for (int i = 0; i < totalSamples; i++) {
    final t = i / sampleRate;
    final e = env(t);
    double x = 0;

    switch (sound) {
      case BreathDemoSound.normal:
        // Low, gentle breath-like: a couple of low sines + subtle noise.
        x = 0.18 * sin(2 * pi * 180 * t) + 0.08 * sin(2 * pi * 90 * t);
        x += (rnd.nextDouble() - 0.5) * 0.05;
      case BreathDemoSound.wheeze:
        // Higher steady tone with tiny pitch wobble.
        final wobble = 12 * sin(2 * pi * 1.5 * t);
        final f = 780 + wobble;
        x = 0.30 * sin(2 * pi * f * t);
      case BreathDemoSound.crackles:
        // Baseline breath + random pop bursts.
        x = 0.12 * sin(2 * pi * 160 * t) + (rnd.nextDouble() - 0.5) * 0.04;
        if (rnd.nextDouble() < 0.0035) {
          // pop burst ~12ms
          final burstLen = (0.012 * sampleRate).round();
          for (int k = 0; k < burstLen && i + k < totalSamples; k++) {
            final tt = (i + k) / sampleRate;
            final win = sin(pi * (k / burstLen));
            pcm[i + k] = (pcm[i + k] + (sin(2 * pi * 2200 * tt) * 0.55 * win * 32767)).clamp(-32767, 32767).round();
          }
        }
      case BreathDemoSound.stridor:
        // Harsh inspiratory: square-ish via harmonics.
        final f = 520.0;
        x = 0.22 * sin(2 * pi * f * t) + 0.18 * sin(2 * pi * (2 * f) * t) + 0.10 * sin(2 * pi * (3 * f) * t);
      case BreathDemoSound.diminished:
        // Very quiet baseline.
        x = 0.05 * sin(2 * pi * 140 * t) + (rnd.nextDouble() - 0.5) * 0.01;
    }

    final v = (x * e * 32767).clamp(-32767.0, 32767.0).round();
    pcm[i] = (pcm[i] + v).clamp(-32767, 32767);
  }

  return _wrapAsWav(pcm, sampleRate: sampleRate);
}

enum BreathDemoSound { normal, wheeze, crackles, stridor, diminished }

Uint8List _wrapAsWav(Int16List pcm, {required int sampleRate}) {
  const bytesPerSample = 2;
  final dataSize = pcm.length * bytesPerSample;
  final fileSize = 44 + dataSize;
  final buffer = BytesBuilder();

  void writeAscii(String s) => buffer.add(Uint8List.fromList(s.codeUnits));
  void writeUint32LE(int v) => buffer.add(Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.little));
  void writeUint16LE(int v) => buffer.add(Uint8List(2)..buffer.asByteData().setUint16(0, v, Endian.little));

  writeAscii('RIFF');
  writeUint32LE(fileSize - 8);
  writeAscii('WAVE');
  writeAscii('fmt ');
  writeUint32LE(16);
  writeUint16LE(1);
  writeUint16LE(1);
  writeUint32LE(sampleRate);
  writeUint32LE(sampleRate * bytesPerSample);
  writeUint16LE(bytesPerSample);
  writeUint16LE(16);
  writeAscii('data');
  writeUint32LE(dataSize);
  buffer.add(pcm.buffer.asUint8List());
  return buffer.toBytes();
}
