import 'package:flutter/material.dart';

enum VitalId { bloodPressure, pulseRate, respiratoryRate, skinSigns, pupils, spo2, avpu, aao }

extension VitalIdX on VitalId {
  String get id => name;

  String get title => switch (this) {
    VitalId.bloodPressure => 'Blood Pressure',
    VitalId.pulseRate => 'Pulse Rate',
    VitalId.respiratoryRate => 'Respiratory Rate',
    VitalId.skinSigns => 'Skin Signs',
    VitalId.pupils => 'Pupils',
    VitalId.spo2 => 'SpO₂',
    VitalId.avpu => 'Level of Consciousness (AVPU)',
    VitalId.aao => 'AAOx Status',
  };

  IconData get icon => switch (this) {
    VitalId.bloodPressure => Icons.speed,
    VitalId.pulseRate => Icons.favorite,
    VitalId.respiratoryRate => Icons.air,
    VitalId.skinSigns => Icons.palette,
    VitalId.pupils => Icons.remove_red_eye,
    VitalId.spo2 => Icons.bloodtype,
    VitalId.avpu => Icons.psychology,
    VitalId.aao => Icons.person_pin_circle,
  };
}

@immutable
class VitalLesson {
  const VitalLesson({
    required this.vital,
    required this.whatItMeans,
    required this.normalRange,
    required this.abnormalMaySuggest,
    required this.whatToDocument,
    required this.commonStudentMistake,
    required this.quickQuizPrompt,
    required this.quickQuizChoices,
    required this.quickQuizCorrectIndex,
    this.practiceHint,
  });

  final VitalId vital;
  final String whatItMeans;
  final String normalRange;
  final List<String> abnormalMaySuggest;
  final String whatToDocument;
  final String commonStudentMistake;
  final String quickQuizPrompt;
  final List<String> quickQuizChoices;
  final int quickQuizCorrectIndex;
  final String? practiceHint;
}

class LearnVitalsContent {
  static VitalLesson? lessonFor(String vitalId) {
    final v = VitalId.values.cast<VitalId?>().firstWhere((x) => x?.id == vitalId, orElse: () => null);
    if (v == null) return null;
    return _lessons[v];
  }

  static const Map<VitalId, VitalLesson> _lessons = {
    VitalId.bloodPressure: VitalLesson(
      vital: VitalId.bloodPressure,
      whatItMeans: 'Blood pressure is the force of blood against arterial walls. In EMS, it helps you judge perfusion and shock risk.',
      normalRange: 'Typical adult: ~90–120 systolic / 60–80 diastolic (context matters).',
      abnormalMaySuggest: ['Shock / dehydration (low BP)', 'Pain/stress (high BP)', 'Sepsis, bleeding, cardiac issues — correlate with skin + mentation'],
      whatToDocument: 'Document systolic/diastolic, patient position if relevant, arm if needed, and whether it was manual or automatic.',
      commonStudentMistake: 'Treating the BP as a standalone number instead of comparing it with pulse, skin signs, mental status, and complaint.',
      quickQuizPrompt: 'Which finding is most concerning for shock (adult)?',
      quickQuizChoices: ['BP 118/76 with warm/dry skin', 'BP 92/60 with cool/clammy skin', 'BP 146/92 with anxiety'],
      quickQuizCorrectIndex: 1,
      practiceHint: 'Practice pumping/deflating and listening for Korotkoff beats.',
    ),
    VitalId.pulseRate: VitalLesson(
      vital: VitalId.pulseRate,
      whatItMeans: 'Pulse rate reflects how fast the heart is beating. Also assess rhythm and quality (strong/weak).',
      normalRange: 'Adult resting: ~60–100 BPM.',
      abnormalMaySuggest: ['Tachycardia: pain, fever, dehydration, anxiety, shock', 'Bradycardia: athlete, medications, hypoxia, heart block'],
      whatToDocument: 'Document rate, rhythm, location, and quality: for example, pulse 124 weak and regular at the radial artery.',
      commonStudentMistake: 'Only documenting the number and forgetting quality. A weak rapid pulse changes the patient picture.',
      quickQuizPrompt: 'A weak rapid pulse with cool clammy skin suggests:',
      quickQuizChoices: ['Good perfusion', 'Possible shock / poor perfusion', 'Normal finding'],
      quickQuizCorrectIndex: 1,
      practiceHint: 'Estimate BPM from rhythm like you would counting a radial pulse.',
    ),
    VitalId.respiratoryRate: VitalLesson(
      vital: VitalId.respiratoryRate,
      whatItMeans: 'Respiratory rate is breaths per minute. Watch work of breathing and ability to speak.',
      normalRange: 'Adult: ~12–20 breaths/min.',
      abnormalMaySuggest: ['Tachypnea: distress, pain, fever, anxiety, hypoxia', 'Bradypnea: CNS depression, opioid overdose, fatigue'],
      whatToDocument: 'Document rate, effort, rhythm, depth, lung sounds when assessed, and ability to speak full sentences.',
      commonStudentMistake: 'Counting the number but missing increased work of breathing, shallow respirations, or fatigue.',
      quickQuizPrompt: 'Which rate is abnormal for a typical adult?',
      quickQuizChoices: ['16/min', '12/min', '28/min'],
      quickQuizCorrectIndex: 2,
      practiceHint: 'Try a quick counting drill — you’ll estimate a hidden RR.',
    ),
    VitalId.skinSigns: VitalLesson(
      vital: VitalId.skinSigns,
      whatItMeans: 'Skin signs are a fast perfusion check: color, temperature, and moisture.',
      normalRange: 'Adult: warm, pink, dry (varies by baseline).',
      abnormalMaySuggest: ['Cool/clammy: shock or sympathetic response', 'Hot/flushed: fever, sepsis, heat illness', 'Cyanosis: severe hypoxia — treat first'],
      whatToDocument: 'Document color, temperature, and moisture together: warm/pink/dry, pale/cool/clammy, hot/flushed/dry, cyanotic, or mottled.',
      commonStudentMistake: 'Writing “skin normal” without describing color, temperature, and moisture.',
      quickQuizPrompt: 'Cool, pale, diaphoretic skin most strongly suggests:',
      quickQuizChoices: ['Good perfusion', 'Possible shock / poor perfusion', 'Normal finding'],
      quickQuizCorrectIndex: 1,
    ),
    VitalId.pupils: VitalLesson(
      vital: VitalId.pupils,
      whatItMeans: 'Pupils can give clues about neurologic status, drugs/tox, and head injury. Document patient-left vs patient-right.',
      normalRange: 'PERRL: equal, round, reactive to light.',
      abnormalMaySuggest: ['Pinpoint: opioids', 'Dilated: stimulants/hypoxia', 'Unequal/sluggish: head injury or neuro emergency'],
      whatToDocument: 'Document size in mm, equality, shape, and reactivity. Use patient-left and patient-right if unequal.',
      commonStudentMistake: 'Saying “right pupil” without clarifying if it is the patient’s right or provider’s right.',
      quickQuizPrompt: 'Best documentation practice is:',
      quickQuizChoices: ['“Right pupil bigger”', '“Patient-right pupil 6 mm, sluggish; patient-left 3 mm, brisk”', '“Pupils abnormal”'],
      quickQuizCorrectIndex: 1,
    ),
    VitalId.spo2: VitalLesson(
      vital: VitalId.spo2,
      whatItMeans: 'SpO₂ is a non-invasive estimate of oxygen saturation. Treat the patient, not just the number.',
      normalRange: 'Typical adult: ~95–100%.',
      abnormalMaySuggest: ['90–94%: mild hypoxemia (evaluate + consider O₂ per protocol)', '<90%: significant hypoxemia — act quickly'],
      whatToDocument: 'Document the percentage, room air or oxygen delivery, device/flow if on oxygen, and patient response after treatment.',
      commonStudentMistake: 'Ignoring work of breathing because the SpO₂ number still looks acceptable.',
      quickQuizPrompt: 'Which SpO₂ is most urgent to address?',
      quickQuizChoices: ['97%', '93%', '84%'],
      quickQuizCorrectIndex: 2,
    ),
    VitalId.avpu: VitalLesson(
      vital: VitalId.avpu,
      whatItMeans: 'AVPU is a quick mental status check: Alert, responds to Verbal, responds to Pain, Unresponsive.',
      normalRange: 'Adult: typically Alert (A).',
      abnormalMaySuggest: ['V/P/U can indicate hypoxia, shock, head injury, stroke, intoxication, hypoglycemia'],
      whatToDocument: 'Document A, V, P, or U and what stimulus caused the response if not alert.',
      commonStudentMistake: 'Calling someone “alert” when they only respond after being spoken to or stimulated.',
      quickQuizPrompt: 'Patient opens eyes only to a sternal rub. AVPU is:',
      quickQuizChoices: ['A', 'V', 'P', 'U'],
      quickQuizCorrectIndex: 2,
    ),
    VitalId.aao: VitalLesson(
      vital: VitalId.aao,
      whatItMeans: 'AAOx (person, place, time, event) helps you describe orientation clearly.',
      normalRange: 'AAOx4 = oriented to person/place/time/event.',
      abnormalMaySuggest: ['Confusion can be hypoxia, shock, stroke, head injury, sepsis, intoxication, hypoglycemia'],
      whatToDocument: 'Document exactly what they know: person, place, time, and event. Example: AAOx2 to person and place only.',
      commonStudentMistake: 'Writing “confused” without stating which orientation questions the patient missed.',
      quickQuizPrompt: 'Patient knows name and place, but not date or what happened. That is:',
      quickQuizChoices: ['AAOx4', 'AAOx3', 'AAOx2', 'AAOx1'],
      quickQuizCorrectIndex: 2,
    ),
  };
}
