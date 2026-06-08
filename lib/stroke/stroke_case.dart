import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:emscode_sim_vitals/dev/dev_flags.dart';

enum StrokeBalanceFinding { normal, unsteady, leansLeft, leansRight }

enum StrokeEyesFinding { followsBothWays, followsSlowly, pulledLeft, pulledRight }

enum StrokeFaceFinding { noDroop, leftDroops, rightDroops }

enum StrokeArmsFinding { noDrift, leftDriftsDown, rightDriftsDown }

enum StrokeSpeechFinding { normal, slurred, troubleSpeaking, troubleUnderstanding, noSpeech }

enum StrokeTest { balance, eyes, face, armDrift, speech }

class StrokeCase {
  StrokeCase({
    required this.age,
    required this.sex,
    required this.mainConcern,
    required this.lastKnownWellMinutes,
    required this.bloodSugarMgDl,
    required this.history,
    required this.isLikelyStroke,
    required this.balance,
    required this.eyes,
    required this.face,
    required this.arms,
    required this.speech,
  });

  final int age;
  final String sex;
  final String mainConcern;
  final int lastKnownWellMinutes;
  final int bloodSugarMgDl;
  final String history;
  final bool isLikelyStroke;

  final StrokeBalanceFinding balance;
  final StrokeEyesFinding eyes;
  final StrokeFaceFinding face;
  final StrokeArmsFinding arms;
  final StrokeSpeechFinding speech;

  int get strokeSignsCount {
    int signs = 0;
    if (balance != StrokeBalanceFinding.normal) signs++;
    if (eyes == StrokeEyesFinding.pulledLeft || eyes == StrokeEyesFinding.pulledRight) signs++;
    if (face != StrokeFaceFinding.noDroop) signs++;
    if (arms != StrokeArmsFinding.noDrift) signs++;
    if (speech != StrokeSpeechFinding.normal) signs++;
    return signs;
  }

  static StrokeCase generate(Random rng) {
    const ages = [34, 41, 55, 62, 69, 73, 79, 84];
    const sexes = ['Male', 'Female'];
    const concerns = [
      'sudden weakness',
      'face looks uneven',
      'hard to speak',
      'unsteady walking',
      'blurry vision',
      'headache',
      'numbness',
      'confusion',
    ];
    const lkw = [10, 15, 20, 25, 30, 45, 60, 90, 120, 180];
    const sugars = [58, 72, 88, 101, 110, 126, 140, 182];
    const histories = [
      'high blood pressure',
      'type 2 diabetes',
      'irregular heartbeat',
      'high cholesterol',
      'former smoker',
      'heart disease',
      'no major history',
    ];

    final isLikelyStroke = rng.nextDouble() < 0.70;

    StrokeBalanceFinding balance;
    StrokeEyesFinding eyes;
    StrokeFaceFinding face;
    StrokeArmsFinding arms;
    StrokeSpeechFinding speech;

    if (!isLikelyStroke) {
      balance = StrokeBalanceFinding.normal;
      eyes = StrokeEyesFinding.followsBothWays;
      face = StrokeFaceFinding.noDroop;
      arms = StrokeArmsFinding.noDrift;
      speech = StrokeSpeechFinding.normal;
    } else {
      balance = _pickWeighted(rng, {
        StrokeBalanceFinding.normal: 0.35,
        StrokeBalanceFinding.unsteady: 0.35,
        StrokeBalanceFinding.leansLeft: 0.15,
        StrokeBalanceFinding.leansRight: 0.15,
      });

      eyes = _pickWeighted(rng, {
        StrokeEyesFinding.followsBothWays: 0.40,
        StrokeEyesFinding.followsSlowly: 0.25,
        StrokeEyesFinding.pulledLeft: 0.175,
        StrokeEyesFinding.pulledRight: 0.175,
      });

      face = _pickWeighted(rng, {
        StrokeFaceFinding.noDroop: 0.45,
        StrokeFaceFinding.leftDroops: 0.275,
        StrokeFaceFinding.rightDroops: 0.275,
      });

      arms = _pickWeighted(rng, {
        StrokeArmsFinding.noDrift: 0.45,
        StrokeArmsFinding.leftDriftsDown: 0.275,
        StrokeArmsFinding.rightDriftsDown: 0.275,
      });

      speech = _pickWeighted(rng, {
        StrokeSpeechFinding.normal: 0.35,
        StrokeSpeechFinding.slurred: 0.20,
        StrokeSpeechFinding.troubleSpeaking: 0.20,
        StrokeSpeechFinding.troubleUnderstanding: 0.15,
        StrokeSpeechFinding.noSpeech: 0.10,
      });

      // Ensure a “likely stroke” case almost always has ≥1 sign.
      if (_strokeSignsCount(balance: balance, eyes: eyes, face: face, arms: arms, speech: speech) == 0) {
        face = rng.nextBool() ? StrokeFaceFinding.leftDroops : StrokeFaceFinding.rightDroops;
      }
    }

    final c = StrokeCase(
      age: ages[rng.nextInt(ages.length)],
      sex: sexes[rng.nextInt(sexes.length)],
      mainConcern: concerns[rng.nextInt(concerns.length)],
      lastKnownWellMinutes: lkw[rng.nextInt(lkw.length)],
      bloodSugarMgDl: sugars[rng.nextInt(sugars.length)],
      history: histories[rng.nextInt(histories.length)],
      isLikelyStroke: isLikelyStroke,
      balance: balance,
      eyes: eyes,
      face: face,
      arms: arms,
      speech: speech,
    );

    devLog('Stroke Assessment case generated (hidden): signs=${c.strokeSignsCount}, likelyStroke=${c.isLikelyStroke}');
    return c;
  }
}

T _pickWeighted<T>(Random rng, Map<T, double> weights) {
  final entries = weights.entries.toList(growable: false);
  final total = entries.fold<double>(0, (s, e) => s + e.value);
  double roll = rng.nextDouble() * total;
  for (final e in entries) {
    roll -= e.value;
    if (roll <= 0) return e.key;
  }
  return entries.last.key;
}

int _strokeSignsCount({
  required StrokeBalanceFinding balance,
  required StrokeEyesFinding eyes,
  required StrokeFaceFinding face,
  required StrokeArmsFinding arms,
  required StrokeSpeechFinding speech,
}) {
  int signs = 0;
  if (balance != StrokeBalanceFinding.normal) signs++;
  if (eyes == StrokeEyesFinding.pulledLeft || eyes == StrokeEyesFinding.pulledRight) signs++;
  if (face != StrokeFaceFinding.noDroop) signs++;
  if (arms != StrokeArmsFinding.noDrift) signs++;
  if (speech != StrokeSpeechFinding.normal) signs++;
  return signs;
}
