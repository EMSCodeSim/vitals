import 'package:flutter/material.dart';

enum WalkthroughMode { learn, practice, test }

extension WalkthroughModeX on WalkthroughMode {
  String get label => switch (this) {
    WalkthroughMode.learn => 'Learn',
    WalkthroughMode.practice => 'Practice',
    WalkthroughMode.test => 'Test',
  };
}

enum AssessmentCategory {
  sceneSizeUp,
  generalImpression,
  mentalStatus,
  primaryAssessment,
  vitalSigns,
  history,
  focusedAssessment,
  treatment,
  reassessment,
  handoffReport,
}

extension AssessmentCategoryX on AssessmentCategory {
  String get label => switch (this) {
    AssessmentCategory.sceneSizeUp => 'Scene size-up',
    AssessmentCategory.generalImpression => 'General impression',
    AssessmentCategory.mentalStatus => 'Mental status',
    AssessmentCategory.primaryAssessment => 'Primary assessment',
    AssessmentCategory.vitalSigns => 'Vital signs',
    AssessmentCategory.history => 'SAMPLE/OPQRST',
    AssessmentCategory.focusedAssessment => 'Focused assessment',
    AssessmentCategory.treatment => 'Treatment choices',
    AssessmentCategory.reassessment => 'Reassessment',
    AssessmentCategory.handoffReport => 'Handoff report',
  };
}

enum StepKind { multiChoice, multiSelect, number }

@immutable
class WalkthroughStep {
  const WalkthroughStep({required this.id, required this.title, required this.prompt, required this.category, required this.kind, required this.choices, required this.correctChoiceIndexes, this.numberTarget, this.numberTolerance, this.learnHint, this.whyItMatters, this.critical = false});

  final String id;
  final String title;
  final String prompt;
  final AssessmentCategory category;
  final StepKind kind;
  final List<String> choices;
  final List<int> correctChoiceIndexes;
  final int? numberTarget;
  final int? numberTolerance;
  final String? learnHint;
  final String? whyItMatters;
  final bool critical;
}

@immutable
class AssessmentCase {
  const AssessmentCase({required this.id, required this.title, required this.age, required this.sex, required this.chiefComplaint, required this.presentation, required this.steps, this.locked = false, this.packTitle});

  final String id;
  final String title;
  final int age;
  final String sex;
  final String chiefComplaint;
  final String presentation;
  final List<WalkthroughStep> steps;
  final bool locked;
  final String? packTitle;
}

@immutable
class WalkthroughScore {
  const WalkthroughScore({required this.total, required this.correct, required this.byCategoryCorrect, required this.byCategoryTotal, required this.missedCriticalStepIds});

  final int total;
  final int correct;
  final Map<AssessmentCategory, int> byCategoryCorrect;
  final Map<AssessmentCategory, int> byCategoryTotal;
  final List<String> missedCriticalStepIds;

  int get percent => total == 0 ? 0 : ((correct / total) * 100).round();
}

class WalkthroughCases {
  static AssessmentCase? byId(String id) => all.cast<AssessmentCase?>().firstWhere((c) => c?.id == id, orElse: () => null);

  static const List<AssessmentCase> all = [
    _normalAdult,
    _sob,
    _chestPain,
    _ams,
    _minorTrauma,
    // Locked coming-soon pack teasers
    _lockedMedicalPack,
    _lockedTraumaPack,
  ];

  static const AssessmentCase _normalAdult = AssessmentCase(
    id: 'normal-adult',
    title: 'Normal Adult Assessment',
    age: 28,
    sex: 'Male',
    chiefComplaint: '“Just feels off”',
    presentation: 'You find a 28y/o male sitting upright, speaking clearly. No obvious distress. You still must do a complete assessment in order.',
    steps: [
      WalkthroughStep(
        id: 'bsi',
        title: 'Scene size-up',
        prompt: 'Before contact, what is the FIRST thing you should confirm?',
        category: AssessmentCategory.sceneSizeUp,
        kind: StepKind.multiChoice,
        choices: ['BSI/PPE', 'OPQRST', 'Secondary assessment'],
        correctChoiceIndexes: [0],
        learnHint: 'BSI/PPE is always first — protect yourself.',
        whyItMatters: 'If you become a patient, you can’t help anyone.',
        critical: true,
      ),
      WalkthroughStep(
        id: 'resources',
        title: 'Scene size-up',
        prompt: 'Scene is safe. What should you check next?',
        category: AssessmentCategory.sceneSizeUp,
        kind: StepKind.multiSelect,
        choices: ['Number of patients', 'Need for additional resources', 'Mechanism of injury / nature of illness', 'Patient’s full medication list'],
        correctChoiceIndexes: [0, 1, 2],
        learnHint: 'Early: how many patients and what resources do you need?',
        whyItMatters: 'Calling for help late delays care.',
      ),
      WalkthroughStep(
        id: 'gi',
        title: 'General impression',
        prompt: 'On first glance, this patient appears:',
        category: AssessmentCategory.generalImpression,
        kind: StepKind.multiChoice,
        choices: ['Sick', 'Not sick', 'Unresponsive'],
        correctChoiceIndexes: [1],
        learnHint: 'They are upright, speaking clearly, and not in distress.',
      ),
      WalkthroughStep(
        id: 'avpu',
        title: 'Level of consciousness',
        prompt: 'Patient answers questions appropriately and follows commands. AVPU is:',
        category: AssessmentCategory.mentalStatus,
        kind: StepKind.multiChoice,
        choices: ['A', 'V', 'P', 'U'],
        correctChoiceIndexes: [0],
        critical: true,
      ),
      WalkthroughStep(
        id: 'primary',
        title: 'Primary assessment',
        prompt: 'Which is the BEST primary assessment sequence?',
        category: AssessmentCategory.primaryAssessment,
        kind: StepKind.multiChoice,
        choices: ['Airway → Breathing → Circulation', 'OPQRST → SAMPLE → Vitals', 'Head-to-toe → Vitals → History'],
        correctChoiceIndexes: [0],
        learnHint: 'ABC comes before detailed history.',
        critical: true,
      ),
      WalkthroughStep(
        id: 'rr',
        title: 'Vital signs',
        prompt: 'Respiratory rate is 16/min. Is that:',
        category: AssessmentCategory.vitalSigns,
        kind: StepKind.multiChoice,
        choices: ['Normal adult range', 'Abnormally low', 'Abnormally high'],
        correctChoiceIndexes: [0],
      ),
      WalkthroughStep(
        id: 'pulse',
        title: 'Vital signs',
        prompt: 'Radial pulse is 72 and strong. This suggests:',
        category: AssessmentCategory.vitalSigns,
        kind: StepKind.multiChoice,
        choices: ['Likely adequate perfusion', 'Immediate shock', 'Immediate respiratory failure'],
        correctChoiceIndexes: [0],
      ),
      WalkthroughStep(
        id: 'bp',
        title: 'Vital signs',
        prompt: 'BP is 118/76. This is:',
        category: AssessmentCategory.vitalSigns,
        kind: StepKind.multiChoice,
        choices: ['Normal adult range', 'Severe hypotension', 'Hypertensive emergency'],
        correctChoiceIndexes: [0],
      ),
      WalkthroughStep(
        id: 'sample',
        title: 'History taking',
        prompt: 'Which item belongs in SAMPLE under “A”?',
        category: AssessmentCategory.history,
        kind: StepKind.multiChoice,
        choices: ['Allergies', 'Airway', 'Aspirin use'],
        correctChoiceIndexes: [0],
      ),
      WalkthroughStep(
        id: 'tx',
        title: 'Treatment decision',
        prompt: 'With normal findings and no distress, best EMT action is:',
        category: AssessmentCategory.treatment,
        kind: StepKind.multiChoice,
        choices: ['Continue assessment + reassess vitals', 'Intubate immediately', 'Ignore vitals'],
        correctChoiceIndexes: [0],
      ),
      WalkthroughStep(
        id: 'report',
        title: 'Summary / report',
        prompt: 'Which item belongs in a handoff report?',
        category: AssessmentCategory.handoffReport,
        kind: StepKind.multiSelect,
        choices: ['Age/sex', 'Chief complaint', 'Mental status', 'Key vitals', 'Favorite movie'],
        correctChoiceIndexes: [0, 1, 2, 3],
      ),
    ],
  );

  static const AssessmentCase _sob = AssessmentCase(
    id: 'sob',
    title: 'Shortness of Breath',
    age: 64,
    sex: 'Female',
    chiefComplaint: 'Shortness of breath',
    presentation: '64y/o female sitting forward, speaking in short phrases. Audible wheeze. Increased work of breathing.',
    steps: [
      WalkthroughStep(
        id: 'bsi2',
        title: 'Scene size-up',
        prompt: 'First action before patient contact:',
        category: AssessmentCategory.sceneSizeUp,
        kind: StepKind.multiChoice,
        choices: ['BSI/PPE', 'DCAP-BTLS', 'OPQRST'],
        correctChoiceIndexes: [0],
        critical: true,
      ),
      WalkthroughStep(
        id: 'gi2',
        title: 'General impression',
        prompt: 'Tripoding + short phrases suggests:',
        category: AssessmentCategory.generalImpression,
        kind: StepKind.multiChoice,
        choices: ['Low work of breathing', 'Increased work of breathing', 'Normal breathing'],
        correctChoiceIndexes: [1],
        critical: true,
      ),
      WalkthroughStep(
        id: 'primary2',
        title: 'Primary assessment',
        prompt: 'Which is MOST urgent to assess?',
        category: AssessmentCategory.primaryAssessment,
        kind: StepKind.multiChoice,
        choices: ['Airway/Breathing', 'Past medical history', 'Last oral intake'],
        correctChoiceIndexes: [0],
        critical: true,
      ),
      WalkthroughStep(
        id: 'spo2',
        title: 'Vital signs',
        prompt: 'SpO₂ is 88% on room air. This is:',
        category: AssessmentCategory.vitalSigns,
        kind: StepKind.multiChoice,
        choices: ['Normal', 'Mildly low', 'Urgently low'],
        correctChoiceIndexes: [2],
        critical: true,
      ),
      WalkthroughStep(
        id: 'focused2',
        title: 'Focused assessment',
        prompt: 'Best focused assessment actions for SOB:',
        category: AssessmentCategory.focusedAssessment,
        kind: StepKind.multiSelect,
        choices: ['Auscultate multiple lung regions', 'Ask asthma/COPD history', 'Compare left vs right', 'Ask about shoe size'],
        correctChoiceIndexes: [0, 1, 2],
      ),
      WalkthroughStep(
        id: 'tx2',
        title: 'Treatment decision',
        prompt: 'Appropriate EMT-level treatment choices include:',
        category: AssessmentCategory.treatment,
        kind: StepKind.multiSelect,
        choices: ['Oxygen per protocol', 'Position of comfort', 'Request ALS if severe', 'Ignore work of breathing'],
        correctChoiceIndexes: [0, 1, 2],
      ),
      WalkthroughStep(
        id: 'reassess2',
        title: 'Reassessment',
        prompt: 'After oxygen, what should you reassess soon?',
        category: AssessmentCategory.reassessment,
        kind: StepKind.multiSelect,
        choices: ['Work of breathing', 'SpO₂ trend', 'Mental status', 'Favorite color'],
        correctChoiceIndexes: [0, 1, 2],
      ),
      WalkthroughStep(
        id: 'report2',
        title: 'Summary / report',
        prompt: 'Key report item for SOB:',
        category: AssessmentCategory.handoffReport,
        kind: StepKind.multiChoice,
        choices: ['SpO₂ + treatment response', 'Only name and age', 'No vitals needed'],
        correctChoiceIndexes: [0],
      ),
    ],
  );

  static const AssessmentCase _chestPain = AssessmentCase(
    id: 'chest-pain',
    title: 'Chest Pain',
    age: 58,
    sex: 'Male',
    chiefComplaint: 'Chest pressure',
    presentation: '58y/o male clutching chest, anxious, pale and diaphoretic. Says “pressure” started 20 minutes ago.',
    steps: [
      WalkthroughStep(
        id: 'gi3',
        title: 'General impression',
        prompt: 'Pale/diaphoretic + chest pressure suggests:',
        category: AssessmentCategory.generalImpression,
        kind: StepKind.multiChoice,
        choices: ['Likely benign', 'Possible cardiac emergency', 'Normal finding'],
        correctChoiceIndexes: [1],
        critical: true,
      ),
      WalkthroughStep(
        id: 'opqrst3',
        title: 'History taking',
        prompt: 'OPQRST “S” stands for:',
        category: AssessmentCategory.history,
        kind: StepKind.multiChoice,
        choices: ['Severity', 'Skin signs', 'Scene safety'],
        correctChoiceIndexes: [0],
      ),
      WalkthroughStep(
        id: 'tx3',
        title: 'Treatment decision',
        prompt: 'Appropriate EMT-level actions may include:',
        category: AssessmentCategory.treatment,
        kind: StepKind.multiSelect,
        choices: ['Oxygen per protocol if needed', 'Position of comfort', 'Request ALS', 'Rapid transport'],
        correctChoiceIndexes: [0, 1, 2, 3],
        critical: true,
      ),
      WalkthroughStep(
        id: 'report3',
        title: 'Summary / report',
        prompt: 'Most important time-sensitive history for suspected ACS is:',
        category: AssessmentCategory.handoffReport,
        kind: StepKind.multiChoice,
        choices: ['Last known well', 'Onset time + OPQRST', 'Favorite foods'],
        correctChoiceIndexes: [1],
      ),
    ],
  );

  static const AssessmentCase _ams = AssessmentCase(
    id: 'ams',
    title: 'Altered Mental Status',
    age: 44,
    sex: 'Female',
    chiefComplaint: 'Confusion',
    presentation: '44y/o female confused, answers slowly. Family says “not acting right.”',
    steps: [
      WalkthroughStep(
        id: 'avpu4',
        title: 'Level of consciousness',
        prompt: 'Patient is awake and answers but confused. AVPU is:',
        category: AssessmentCategory.mentalStatus,
        kind: StepKind.multiChoice,
        choices: ['A', 'V', 'P', 'U'],
        correctChoiceIndexes: [0],
      ),
      WalkthroughStep(
        id: 'aao4',
        title: 'Level of consciousness',
        prompt: 'Best next question for AAOx:',
        category: AssessmentCategory.mentalStatus,
        kind: StepKind.multiSelect,
        choices: ['What is your name?', 'Where are we right now?', 'What day is it?', 'What happened today?'],
        correctChoiceIndexes: [0, 1, 2, 3],
      ),
      WalkthroughStep(
        id: 'primary4',
        title: 'Primary assessment',
        prompt: 'Altered mental status must prompt you to check for:',
        category: AssessmentCategory.primaryAssessment,
        kind: StepKind.multiSelect,
        choices: ['Hypoxia', 'Poor perfusion', 'Possible stroke', 'All of the above'],
        correctChoiceIndexes: [3],
        critical: true,
      ),
      WalkthroughStep(
        id: 'tx4',
        title: 'Treatment decision',
        prompt: 'Appropriate actions include:',
        category: AssessmentCategory.treatment,
        kind: StepKind.multiSelect,
        choices: ['Support airway/breathing', 'Request ALS if needed', 'Reassess mental status', 'Ignore confusion'],
        correctChoiceIndexes: [0, 1, 2],
      ),
    ],
  );

  static const AssessmentCase _minorTrauma = AssessmentCase(
    id: 'minor-trauma',
    title: 'Minor Trauma',
    age: 19,
    sex: 'Male',
    chiefComplaint: 'Arm pain after fall',
    presentation: '19y/o male fell off a skateboard. Obvious abrasion and pain to forearm. Awake and stable.',
    steps: [
      WalkthroughStep(
        id: 'mois',
        title: 'Scene size-up',
        prompt: 'Mechanism of injury (MOI) helps you predict:',
        category: AssessmentCategory.sceneSizeUp,
        kind: StepKind.multiChoice,
        choices: ['Potential injuries', 'Favorite sport', 'Meal plan'],
        correctChoiceIndexes: [0],
      ),
      WalkthroughStep(
        id: 'dcap',
        title: 'Focused assessment',
        prompt: 'Select all items in DCAP-BTLS:',
        category: AssessmentCategory.focusedAssessment,
        kind: StepKind.multiSelect,
        choices: ['Deformities', 'Burns', 'Tenderness', 'Swelling', 'OPQRST'],
        correctChoiceIndexes: [0, 1, 2, 3],
      ),
      WalkthroughStep(
        id: 'pms',
        title: 'Focused assessment',
        prompt: 'For an injured extremity, you should assess:',
        category: AssessmentCategory.focusedAssessment,
        kind: StepKind.multiSelect,
        choices: ['Pulse', 'Motor', 'Sensation', 'Sleep schedule'],
        correctChoiceIndexes: [0, 1, 2],
        critical: true,
      ),
      WalkthroughStep(
        id: 'tx5',
        title: 'Treatment decision',
        prompt: 'Appropriate EMT care includes:',
        category: AssessmentCategory.treatment,
        kind: StepKind.multiSelect,
        choices: ['Bleeding control', 'Splint as indicated', 'Reassess PMS', 'Ignore pain'],
        correctChoiceIndexes: [0, 1, 2],
      ),
    ],
  );

  static const AssessmentCase _lockedMedicalPack = AssessmentCase(
    id: 'locked-medical-pack',
    title: 'Coming Soon — Medical Assessment Pack',
    age: 0,
    sex: '',
    chiefComplaint: '',
    presentation: 'Locked case pack placeholder.',
    locked: true,
    packTitle: 'Medical Assessment Pack',
    steps: [],
  );

  static const AssessmentCase _lockedTraumaPack = AssessmentCase(
    id: 'locked-trauma-pack',
    title: 'Coming Soon — Trauma Assessment Pack',
    age: 0,
    sex: '',
    chiefComplaint: '',
    presentation: 'Locked case pack placeholder.',
    locked: true,
    packTitle: 'Trauma Assessment Pack',
    steps: [],
  );
}
