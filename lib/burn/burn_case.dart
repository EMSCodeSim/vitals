import 'dart:math';

import 'package:emscode_sim_vitals/burn/burn_models.dart';

class BurnPracticeCase {
  const BurnPracticeCase({required this.patientType, required this.ageYears, required this.weightKg, required this.mechanism, required this.depth, required this.regions, required this.specialConcerns});

  final BurnPatientType patientType;
  final int ageYears;
  final int weightKg;
  final String mechanism;
  final BurnDepth depth;
  final Set<BurnRegionId> regions;
  final List<String> specialConcerns;

  double correctTbsa() {
    if (!depth.countsTowardTbsa) return 0;
    final sum = regions.fold<double>(0, (p, id) => p + BurnRegions.byId(id).percentFor(patientType));
    return double.parse(sum.toStringAsFixed(2));
  }

  String describe() {
    final pt = patientType == BurnPatientType.adult ? 'adult' : 'pediatric';
    final depthText = depth.label;
    final regionText = regions.map((r) => BurnRegions.byId(r).longLabel).toList()..sort();
    final regionSentence = regions.isEmpty ? 'No significant burns.' : 'Burn areas: ${regionText.join(', ')}.';
    final concerns = specialConcerns.isEmpty ? '' : ' Special concerns: ${specialConcerns.join(', ')}.';
    return '$ageYears-year-old $pt patient, $weightKg kg. Mechanism: $mechanism. Depth: $depthText. $regionSentence$concerns';
  }

  static BurnPracticeCase generate(Random rng) {
    final patientType = rng.nextBool() ? BurnPatientType.adult : BurnPatientType.pediatric;
    final ageYears = patientType == BurnPatientType.adult ? 18 + rng.nextInt(70) : 1 + rng.nextInt(12);
    final weightKg = patientType == BurnPatientType.adult ? 55 + rng.nextInt(60) : 10 + rng.nextInt(30);

    const mechanisms = [
      'Scald burn (hot liquid)',
      'Structure fire',
      'Grill flash burn',
      'Grease fire',
      'Electrical contact',
      'Chemical exposure',
      'Vehicle fire',
      'Campfire burn',
    ];

    final mechanism = mechanisms[rng.nextInt(mechanisms.length)];

    final depthPool = [BurnDepth.partialThickness, BurnDepth.fullThickness, BurnDepth.mixed, BurnDepth.superficial];
    final depth = depthPool[rng.nextInt(depthPool.length)];

    // Region bundles favoring common patterns.
    final bundles = <Set<BurnRegionId>>[
      {BurnRegionId.chestUpperAbdomen},
      {BurnRegionId.chestUpperAbdomen, BurnRegionId.lowerAbdomen}, // anterior torso
      {BurnRegionId.upperBack, BurnRegionId.lowerBack}, // posterior torso
      {BurnRegionId.rightArmFront, BurnRegionId.rightArmBack},
      {BurnRegionId.leftArmFront, BurnRegionId.leftArmBack},
      {BurnRegionId.rightLegFront},
      {BurnRegionId.leftLegFront},
      {BurnRegionId.rightLegFront, BurnRegionId.leftLegFront},
      {BurnRegionId.headFront},
      {BurnRegionId.headBack},
      {BurnRegionId.perineum},
      {BurnRegionId.chestUpperAbdomen, BurnRegionId.rightArmFront},
      {BurnRegionId.chestUpperAbdomen, BurnRegionId.lowerAbdomen, BurnRegionId.rightArmFront},
    ];

    Set<BurnRegionId> regions = Set<BurnRegionId>.from(bundles[rng.nextInt(bundles.length)]);
    // Add some variability.
    if (rng.nextDouble() < 0.25) regions.add(BurnRegionId.leftArmFront);
    if (rng.nextDouble() < 0.18) regions.add(BurnRegionId.rightLegFront);
    if (rng.nextDouble() < 0.12) regions.add(BurnRegionId.headFront);

    // Superficial distractor: allow regions but should count 0.
    if (depth == BurnDepth.superficial && rng.nextDouble() < 0.35) {
      regions = {BurnRegionId.chestUpperAbdomen};
    }

    final concernsPool = <String>[
      'Possible inhalation concern',
      'Circumferential pattern',
      'Major joint involved',
      'Hands involved',
      'Feet involved',
      'Face involved',
      'Genitalia/perineum involved',
    ];
    final specialConcerns = <String>[];
    for (final c in concernsPool) {
      if (rng.nextDouble() < 0.14) specialConcerns.add(c);
    }

    // Ensure perineum concern matches region sometimes.
    if (regions.contains(BurnRegionId.perineum) && !specialConcerns.contains('Genitalia/perineum involved')) {
      specialConcerns.add('Genitalia/perineum involved');
    }

    return BurnPracticeCase(
      patientType: patientType,
      ageYears: ageYears,
      weightKg: weightKg,
      mechanism: mechanism,
      depth: depth,
      regions: regions,
      specialConcerns: specialConcerns,
    );
  }
}
