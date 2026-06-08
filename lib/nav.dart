import 'package:emscode_sim_vitals/blood_pressure/blood_pressure_simulator_page.dart';
import 'package:emscode_sim_vitals/breath/breath_sound_simulator_page.dart';
import 'package:emscode_sim_vitals/burn/rule_of_nines_page.dart';
import 'package:emscode_sim_vitals/pupil/pupil_assessment_page.dart';
import 'package:emscode_sim_vitals/pulse/pulse_test_page.dart';
import 'package:emscode_sim_vitals/stroke/stroke_assessment_page.dart';
import 'package:emscode_sim_vitals/shared/training_summary_page.dart';
import 'package:emscode_sim_vitals/case_flow/random_patient_case_page.dart';
import 'package:emscode_sim_vitals/instructor/instructor_mode_page.dart';
import 'package:emscode_sim_vitals/settings/settings_page.dart';
import 'package:emscode_sim_vitals/vitals_home/vitals_home_page.dart';
import 'package:emscode_sim_vitals/learn_vitals/learn_vitals_hub_page.dart';
import 'package:emscode_sim_vitals/learn_vitals/vital_lesson_page.dart';
import 'package:emscode_sim_vitals/assessment_tools/assessment_tools_hub_page.dart';
import 'package:emscode_sim_vitals/assessment_tools/tool_lesson_page.dart';
import 'package:emscode_sim_vitals/walkthrough/walkthrough_home_page.dart';
import 'package:emscode_sim_vitals/walkthrough/walkthrough_run_page.dart';
import 'package:emscode_sim_vitals/cases/patient_assessment_cases_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// GoRouter configuration for app navigation
///
/// This uses go_router for declarative routing, which provides:
/// - Type-safe navigation
/// - Deep linking support (web URLs, app links)
/// - Easy route parameters
/// - Navigation guards and redirects
///
/// To add a new route:
/// 1. Add a route constant to AppRoutes below
/// 2. Add a GoRoute to the routes list
/// 3. Navigate using context.go() or context.push()
/// 4. Use context.pop() to go back.
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    errorBuilder: (context, state) {
      // go_router can end up on a blank page on web if the initial location
      // doesn't match a route (e.g. hash/strategy mismatch). Make this explicit.
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Navigation error', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Location: ${state.uri}'),
                const SizedBox(height: 8),
                Text('Error: ${state.error}'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text('Go to Home'),
                ),
              ],
            ),
          ),
        ),
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => NoTransitionPage(
          child: const VitalsHomePage(),
        ),
      ),

      // Main learning pathway hubs
      GoRoute(
        path: AppRoutes.learnVitals,
        name: 'learnVitals',
        pageBuilder: (context, state) => const MaterialPage(child: LearnVitalsHubPage()),
      ),
      GoRoute(
        path: '${AppRoutes.learnVitals}/:id',
        name: 'vitalLesson',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return MaterialPage(child: VitalLessonPage(vitalId: id));
        },
      ),
      GoRoute(
        path: AppRoutes.assessmentTools,
        name: 'assessmentTools',
        pageBuilder: (context, state) => const MaterialPage(child: AssessmentToolsHubPage()),
      ),
      GoRoute(
        path: '${AppRoutes.assessmentTools}/:id',
        name: 'toolLesson',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return MaterialPage(child: ToolLessonPage(toolId: id));
        },
      ),
      GoRoute(
        path: AppRoutes.walkthrough,
        name: 'walkthrough',
        pageBuilder: (context, state) => const MaterialPage(child: WalkthroughHomePage()),
      ),
      GoRoute(
        path: '${AppRoutes.walkthrough}/run/:caseId',
        name: 'walkthroughRun',
        pageBuilder: (context, state) {
          final caseId = state.pathParameters['caseId'] ?? '';
          final modeStr = state.uri.queryParameters['mode'];
          return MaterialPage(child: WalkthroughRunPage(caseId: caseId, modeOverride: modeStr));
        },
      ),
      GoRoute(
        path: AppRoutes.cases,
        name: 'cases',
        pageBuilder: (context, state) => const MaterialPage(child: PatientAssessmentCasesPage()),
      ),

      GoRoute(
        path: AppRoutes.randomCase,
        name: 'randomCase',
        pageBuilder: (context, state) => const MaterialPage(child: RandomPatientCasePage()),
      ),
      GoRoute(
        path: AppRoutes.instructor,
        name: 'instructor',
        pageBuilder: (context, state) => const MaterialPage(child: InstructorModePage()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) => const MaterialPage(child: SettingsPage()),
      ),
      GoRoute(
        path: AppRoutes.bloodPressure,
        name: 'bloodPressure',
        pageBuilder: (context, state) => const MaterialPage(child: BloodPressureSimulatorPage()),
      ),
      GoRoute(
        path: AppRoutes.pulseTest,
        name: 'pulseTest',
        pageBuilder: (context, state) => const MaterialPage(child: PulseTestPage()),
      ),
      GoRoute(
        path: AppRoutes.strokeAssessment,
        name: 'strokeAssessment',
        pageBuilder: (context, state) => const MaterialPage(child: StrokeAssessmentPage()),
      ),
      GoRoute(
        path: AppRoutes.pupilAssessment,
        name: 'pupilAssessment',
        pageBuilder: (context, state) => const MaterialPage(child: PupilAssessmentPage()),
      ),
      GoRoute(
        path: AppRoutes.ruleOfNines,
        name: 'ruleOfNines',
        pageBuilder: (context, state) => const MaterialPage(child: RuleOfNinesPage()),
      ),
      GoRoute(
        path: AppRoutes.breathSound,
        name: 'breathSound',
        pageBuilder: (context, state) => const MaterialPage(child: BreathSoundSimulatorPage()),
      ),
      GoRoute(
        path: AppRoutes.summary,
        name: 'summary',
        pageBuilder: (context, state) {
          final extra = state.extra;
          if (extra is! TrainingSummaryArgs) {
            return const MaterialPage(child: Scaffold(body: Center(child: Text('Missing summary data'))));
          }
          return MaterialPage(child: TrainingSummaryPage(args: extra));
        },
      ),
    ],
  );
}

/// Route path constants
/// Use these instead of hard-coding route strings
class AppRoutes {
  static const String home = '/';
  static const String learnVitals = '/learn-vitals';
  static const String assessmentTools = '/assessment-tools';
  static const String walkthrough = '/walkthrough';
  static const String cases = '/cases';
  static const String randomCase = '/random-case';
  static const String instructor = '/instructor';
  static const String settings = '/settings';
  static const String bloodPressure = '/blood-pressure';
  static const String pulseTest = '/pulse-test';
  static const String strokeAssessment = '/stroke-assessment';
  static const String pupilAssessment = '/pupil-assessment';
  static const String ruleOfNines = '/rule-of-nines';
  static const String breathSound = '/breath-sound';
  static const String summary = '/summary';
}
