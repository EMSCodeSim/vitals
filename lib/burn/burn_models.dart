import 'package:flutter/foundation.dart';

enum BurnPatientType { adult, pediatric }

extension BurnPatientTypeLabel on BurnPatientType {
  String get label => switch (this) {
    BurnPatientType.adult => 'Adult',
    BurnPatientType.pediatric => 'Pediatric / Small Child',
  };
}

enum BurnDepth { superficial, partialThickness, fullThickness, mixed }

extension BurnDepthLabel on BurnDepth {
  String get label => switch (this) {
    BurnDepth.superficial => 'Superficial',
    BurnDepth.partialThickness => 'Partial-thickness',
    BurnDepth.fullThickness => 'Full-thickness',
    BurnDepth.mixed => 'Mixed depth',
  };

  bool get countsTowardTbsa => this != BurnDepth.superficial;
}

enum BurnViewSide { front, back }

extension BurnViewSideLabel on BurnViewSide {
  String get label => switch (this) {
    BurnViewSide.front => 'Front',
    BurnViewSide.back => 'Back',
  };
}

enum BurnRegionId {
  headFront,
  headBack,
  chestUpperAbdomen,
  lowerAbdomen,
  upperBack,
  lowerBack,
  rightArmFront,
  rightArmBack,
  leftArmFront,
  leftArmBack,
  rightLegFront,
  rightLegBack,
  leftLegFront,
  leftLegBack,
  perineum,
}

@immutable
class BurnRegion {
  const BurnRegion({required this.id, required this.view, required this.shortLabel, required this.longLabel, required this.adultPercent, required this.pediatricPercent});

  final BurnRegionId id;
  final BurnViewSide view;
  final String shortLabel;
  final String longLabel;
  final double adultPercent;
  final double pediatricPercent;

  double percentFor(BurnPatientType type) => type == BurnPatientType.adult ? adultPercent : pediatricPercent;
}

class BurnRegions {
  static const List<BurnRegion> all = [
    BurnRegion(
      id: BurnRegionId.headFront,
      view: BurnViewSide.front,
      shortLabel: 'Head (F)',
      longLabel: 'Head/neck front',
      adultPercent: 4.5,
      pediatricPercent: 9,
    ),
    BurnRegion(
      id: BurnRegionId.headBack,
      view: BurnViewSide.back,
      shortLabel: 'Head (B)',
      longLabel: 'Head/neck back',
      adultPercent: 4.5,
      pediatricPercent: 9,
    ),
    BurnRegion(
      id: BurnRegionId.chestUpperAbdomen,
      view: BurnViewSide.front,
      shortLabel: 'Chest',
      longLabel: 'Chest/upper abdomen',
      adultPercent: 9,
      pediatricPercent: 9,
    ),
    BurnRegion(
      id: BurnRegionId.lowerAbdomen,
      view: BurnViewSide.front,
      shortLabel: 'Abd',
      longLabel: 'Lower abdomen',
      adultPercent: 9,
      pediatricPercent: 9,
    ),
    BurnRegion(
      id: BurnRegionId.upperBack,
      view: BurnViewSide.back,
      shortLabel: 'Back+',
      longLabel: 'Upper back',
      adultPercent: 9,
      pediatricPercent: 9,
    ),
    BurnRegion(
      id: BurnRegionId.lowerBack,
      view: BurnViewSide.back,
      shortLabel: 'Back-',
      longLabel: 'Lower back',
      adultPercent: 9,
      pediatricPercent: 9,
    ),
    BurnRegion(
      id: BurnRegionId.rightArmFront,
      view: BurnViewSide.front,
      shortLabel: 'R arm (F)',
      longLabel: 'Right arm front',
      adultPercent: 4.5,
      pediatricPercent: 4.5,
    ),
    BurnRegion(
      id: BurnRegionId.rightArmBack,
      view: BurnViewSide.back,
      shortLabel: 'R arm (B)',
      longLabel: 'Right arm back',
      adultPercent: 4.5,
      pediatricPercent: 4.5,
    ),
    BurnRegion(
      id: BurnRegionId.leftArmFront,
      view: BurnViewSide.front,
      shortLabel: 'L arm (F)',
      longLabel: 'Left arm front',
      adultPercent: 4.5,
      pediatricPercent: 4.5,
    ),
    BurnRegion(
      id: BurnRegionId.leftArmBack,
      view: BurnViewSide.back,
      shortLabel: 'L arm (B)',
      longLabel: 'Left arm back',
      adultPercent: 4.5,
      pediatricPercent: 4.5,
    ),
    BurnRegion(
      id: BurnRegionId.rightLegFront,
      view: BurnViewSide.front,
      shortLabel: 'R leg (F)',
      longLabel: 'Right leg front',
      adultPercent: 9,
      pediatricPercent: 6.75,
    ),
    BurnRegion(
      id: BurnRegionId.rightLegBack,
      view: BurnViewSide.back,
      shortLabel: 'R leg (B)',
      longLabel: 'Right leg back',
      adultPercent: 9,
      pediatricPercent: 6.75,
    ),
    BurnRegion(
      id: BurnRegionId.leftLegFront,
      view: BurnViewSide.front,
      shortLabel: 'L leg (F)',
      longLabel: 'Left leg front',
      adultPercent: 9,
      pediatricPercent: 6.75,
    ),
    BurnRegion(
      id: BurnRegionId.leftLegBack,
      view: BurnViewSide.back,
      shortLabel: 'L leg (B)',
      longLabel: 'Left leg back',
      adultPercent: 9,
      pediatricPercent: 6.75,
    ),
    BurnRegion(
      id: BurnRegionId.perineum,
      view: BurnViewSide.front,
      shortLabel: 'Peri',
      longLabel: 'Perineum/genital area',
      adultPercent: 1,
      pediatricPercent: 1,
    ),
  ];

  static BurnRegion byId(BurnRegionId id) => all.firstWhere((r) => r.id == id);

  static List<BurnRegion> byView(BurnViewSide view) => all.where((r) => r.view == view).toList(growable: false);

  static double totalFor(BurnPatientType type) {
    final sum = all.fold<double>(0, (p, r) => p + r.percentFor(type));
    return double.parse(sum.toStringAsFixed(2));
  }
}
