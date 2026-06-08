import 'dart:math';
import 'dart:typed_data';

/// Build a mono 16‑bit PCM WAV containing a sine wave.
///
/// Useful for tiny training sounds without bundling audio assets.
Uint8List buildSineWav({
  required int frequencyHz,
  required double durationSeconds,
  required int sampleRate,
  required double volume,
}) {
  final totalSamples = max(1, (durationSeconds * sampleRate).round());
  const bytesPerSample = 2; // 16-bit
  final dataSize = totalSamples * bytesPerSample;
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

  final amplitude = (volume.clamp(0.0, 1.0) * 32767).round();
  final twoPiF = 2 * pi * frequencyHz;
  final pcm = Int16List(totalSamples);
  for (int i = 0; i < totalSamples; i++) {
    final t = i / sampleRate;
    pcm[i] = (sin(twoPiF * t) * amplitude).round();
  }
  buffer.add(pcm.buffer.asUint8List());
  return buffer.toBytes();
}
