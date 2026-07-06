enum BpTutorialMethod { auscultation, palpation }

extension BpTutorialMethodLabel on BpTutorialMethod {
  String get label => switch (this) {
    BpTutorialMethod.auscultation => 'Auscultation',
    BpTutorialMethod.palpation => 'Palpation',
  };
}
