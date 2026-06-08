import 'package:flutter/material.dart';

enum ToolId {
  sample,
  opqrst,
  avpu,
  aao,
  dcapbtls,
  stroke,
  pupils,
  ruleOfNines,
  breathSounds,
  painScale,
  generalImpression,
  primaryAssessment,
  secondaryAssessment,
}

extension ToolIdX on ToolId {
  String get id => name;

  String get title => switch (this) {
    ToolId.sample => 'SAMPLE History',
    ToolId.opqrst => 'OPQRST',
    ToolId.avpu => 'AVPU',
    ToolId.aao => 'AAOx4',
    ToolId.dcapbtls => 'DCAP-BTLS',
    ToolId.stroke => 'Stroke Assessment',
    ToolId.pupils => 'Pupil Assessment',
    ToolId.ruleOfNines => 'Rule of Nines',
    ToolId.breathSounds => 'Breath Sounds',
    ToolId.painScale => 'Pain Scale',
    ToolId.generalImpression => 'General Impression',
    ToolId.primaryAssessment => 'Primary Assessment',
    ToolId.secondaryAssessment => 'Secondary Assessment',
  };

  IconData get icon => switch (this) {
    ToolId.sample => Icons.assignment,
    ToolId.opqrst => Icons.quiz,
    ToolId.avpu => Icons.psychology,
    ToolId.aao => Icons.person_pin_circle,
    ToolId.dcapbtls => Icons.search,
    ToolId.stroke => Icons.health_and_safety,
    ToolId.pupils => Icons.remove_red_eye,
    ToolId.ruleOfNines => Icons.local_fire_department,
    ToolId.breathSounds => Icons.air,
    ToolId.painScale => Icons.trending_up,
    ToolId.generalImpression => Icons.visibility,
    ToolId.primaryAssessment => Icons.rule,
    ToolId.secondaryAssessment => Icons.list_alt,
  };
}

@immutable
class ToolLesson {
  const ToolLesson({required this.tool, required this.usedFor, required this.whenToUse, required this.whatToAsk, required this.abnormalMeans, required this.practicePrompt});
  final ToolId tool;
  final String usedFor;
  final String whenToUse;
  final List<String> whatToAsk;
  final List<String> abnormalMeans;
  final String practicePrompt;
}

class AssessmentToolsContent {
  static ToolLesson? lessonFor(String toolId) {
    final t = ToolId.values.cast<ToolId?>().firstWhere((x) => x?.id == toolId, orElse: () => null);
    if (t == null) return null;
    return _lessons[t];
  }

  static const Map<ToolId, ToolLesson> _lessons = {
    ToolId.sample: ToolLesson(
      tool: ToolId.sample,
      usedFor: 'A structured history to avoid missing key info.',
      whenToUse: 'After life threats are managed — usually during history taking.',
      whatToAsk: [
        'S — Signs/Symptoms',
        'A — Allergies',
        'M — Medications',
        'P — Past medical history',
        'L — Last oral intake',
        'E — Events leading to illness/injury',
      ],
      abnormalMeans: ['Missing meds/allergies can change treatment decisions', 'Events can reveal poisoning, trauma mechanism, or onset timing'],
      practicePrompt: 'Match each item to the correct SAMPLE letter.',
    ),
    ToolId.opqrst: ToolLesson(
      tool: ToolId.opqrst,
      usedFor: 'A quick way to characterize pain or a symptom.',
      whenToUse: 'When the complaint is pain or a symptom you need to clarify (chest pain, abdominal pain, SOB, headache, etc).',
      whatToAsk: ['O — Onset', 'P — Provocation/Palliation', 'Q — Quality', 'R — Region/Radiation', 'S — Severity (0–10)', 'T — Time'],
      abnormalMeans: ['Sudden onset severe pain can be high risk', 'Radiation + associated symptoms can be cardiac red flags'],
      practicePrompt: 'Which OPQRST letter asks about “severity 0–10”?',
    ),
    ToolId.dcapbtls: ToolLesson(
      tool: ToolId.dcapbtls,
      usedFor: 'A head-to-toe trauma assessment mnemonic.',
      whenToUse: 'Trauma calls, or when you suspect injury.',
      whatToAsk: ['Deformities', 'Contusions', 'Abrasions', 'Punctures/Penetrations', 'Burns', 'Tenderness', 'Lacerations', 'Swelling'],
      abnormalMeans: ['Findings may indicate internal bleeding, fractures, spinal injury, or need for rapid transport'],
      practicePrompt: 'Select all items that belong in DCAP-BTLS.',
    ),
    ToolId.avpu: ToolLesson(
      tool: ToolId.avpu,
      usedFor: 'A fast initial mental status check.',
      whenToUse: 'Early in general impression / primary assessment, and whenever status changes.',
      whatToAsk: ['Alert?', 'Responds to verbal?', 'Responds to pain?', 'Unresponsive?'],
      abnormalMeans: ['V/P/U can indicate hypoxia, shock, head injury, intoxication, hypoglycemia'],
      practicePrompt: 'Patient only responds to painful stimulus — what is AVPU?',
    ),
    ToolId.aao: ToolLesson(
      tool: ToolId.aao,
      usedFor: 'A clear description of orientation and confusion.',
      whenToUse: 'After AVPU, during neuro checks and reassessments.',
      whatToAsk: ['Person: name?', 'Place: where are we?', 'Time: date/day?', 'Event: what happened?'],
      abnormalMeans: ['Disorientation may signal hypoxia, shock, stroke, head injury, sepsis, intoxication'],
      practicePrompt: 'Knows person+place only — what AAOx is that?',
    ),
    ToolId.painScale: ToolLesson(
      tool: ToolId.painScale,
      usedFor: 'A fast pain trend: baseline → after treatment → reassess.',
      whenToUse: 'Any pain complaint; repeat after interventions.',
      whatToAsk: ['“On a scale of 0–10…”', '“Is it better or worse with movement/breathing?”'],
      abnormalMeans: ['Severe pain can indicate serious pathology or poor control; trends matter more than a single number'],
      practicePrompt: 'Pick the best pain score for “worst pain imaginable”.',
    ),
    ToolId.generalImpression: ToolLesson(
      tool: ToolId.generalImpression,
      usedFor: 'Your first 10 seconds: sick/not sick + obvious life threats.',
      whenToUse: 'Immediately after scene size-up, before detailed history.',
      whatToAsk: ['Position found', 'Work of breathing', 'Skin signs', 'Obvious distress', 'Immediate life threats'],
      abnormalMeans: ['“Sick” appearance pushes higher transport priority and more aggressive assessment'],
      practicePrompt: 'Which finding is most “sick”?',
    ),
    ToolId.primaryAssessment: ToolLesson(
      tool: ToolId.primaryAssessment,
      usedFor: 'Find and treat immediate life threats (ABC).',
      whenToUse: 'Right after general impression; repeat as needed.',
      whatToAsk: ['Airway', 'Breathing', 'Circulation', 'Life threats', 'Transport priority'],
      abnormalMeans: ['Life threats override detailed history — treat first'],
      practicePrompt: 'In primary assessment, what comes first?',
    ),
    ToolId.secondaryAssessment: ToolLesson(
      tool: ToolId.secondaryAssessment,
      usedFor: 'Detailed exam after life threats are controlled.',
      whenToUse: 'Stable patients, or en route after primary actions.',
      whatToAsk: ['Focused exam (by complaint) or head-to-toe', 'Reassess vitals', 'Document changes'],
      abnormalMeans: ['New findings may change transport priority and treatment'],
      practicePrompt: 'Secondary assessment happens:',
    ),
    ToolId.stroke: ToolLesson(
      tool: ToolId.stroke,
      usedFor: 'Rapid recognition of possible stroke and time-sensitive history.',
      whenToUse: 'Any neuro deficit, speech change, facial droop, arm drift, confusion.',
      whatToAsk: ['Face: droop?', 'Arms: drift?', 'Speech: slurred/aphasia?', 'Time: last known well?'],
      abnormalMeans: ['Abnormal findings = time-sensitive transport + stroke alert (per protocol)'],
      practicePrompt: 'Practice the stroke screen and document last known well.',
    ),
    ToolId.pupils: ToolLesson(
      tool: ToolId.pupils,
      usedFor: 'Neuro and tox clues; document patient-left vs patient-right.',
      whenToUse: 'Head injury, altered mental status, tox, stroke suspicion.',
      whatToAsk: ['Size (mm)', 'Reactivity (brisk/sluggish/fixed)', 'Equal?', 'Track?'],
      abnormalMeans: ['Unequal/sluggish can be head injury/neuro emergency; pinpoint suggests opioids'],
      practicePrompt: 'Practice documenting pupils clearly.',
    ),
    ToolId.ruleOfNines: ToolLesson(
      tool: ToolId.ruleOfNines,
      usedFor: 'Estimate burn TBSA to guide severity and destination decisions.',
      whenToUse: 'Moderate/severe burns; consider burn-center criteria.',
      whatToAsk: ['Adult vs pediatric percentages', 'Depth and circumferential burns', 'Inhalation injury concerns'],
      abnormalMeans: ['Large TBSA burns can cause shock; airway burns are urgent'],
      practicePrompt: 'Estimate TBSA and identify when to consider a burn center.',
    ),
    ToolId.breathSounds: ToolLesson(
      tool: ToolId.breathSounds,
      usedFor: 'Auscultation helps narrow respiratory causes (wheeze, crackles, absent sounds).',
      whenToUse: 'SOB, asthma/COPD, trauma, any breathing concern.',
      whatToAsk: ['Compare sides', 'Upper/mid/lower regions', 'Listen through full inspiration/expiration'],
      abnormalMeans: ['Absent/unilateral sounds can indicate pneumothorax; stridor is upper airway'],
      practicePrompt: 'Listen by region and identify the best match.',
    ),
  };
}
