import 'package:flutter/material.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/calculator/calculator_screen.dart';
import '../../features/graph/graph_screen.dart';
import '../../features/complex/complex_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/probability/probability_screen.dart';
import '../../features/converter/converter_screen.dart';
import '../../features/statistics/statistics_screen.dart';
import '../../features/derivative/derivative_screen.dart';
import '../../features/solver/solver_screen.dart';
import '../../features/matrices/matrices_screen.dart';
import '../../features/trigonometry/unit_circle_screen.dart';
import '../../features/sequences/sequences_screen.dart';
import '../../features/geometry/geometry_screen.dart';

class AppRoutes {
  static const String onboarding = '/';
  static const String home = '/home';
  static const String calculator = '/calculator';
  static const String graph = '/graph';
  static const String complex = '/complex';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String probability = '/probability';
  static const String converter = '/converter';
  static const String statistics = '/statistics';
  static const String derivative = '/derivative';
  static const String solver = '/solver';
  static const String matrices = '/matrices';
  static const String unitCircle = '/unit-circle';
  static const String sequences = '/sequences';
  static const String geometry = '/geometry';

  static Map<String, WidgetBuilder> get routes => {
        onboarding: (context) => const OnboardingScreen(),
        home: (context) => const HomeScreen(),
        calculator: (context) => const CalculatorScreen(),
        graph: (context) => const GraphScreen(),
        complex: (context) => const ComplexScreen(),
        history: (context) => const HistoryScreen(),
        settings: (context) => const SettingsScreen(),
        probability: (context) => const ProbabilityScreen(),
        converter: (context) => const ConverterScreen(),
        statistics: (context) => const StatisticsScreen(),
        derivative: (context) => const DerivativeScreen(),
        solver: (context) => const SolverScreen(),
        matrices: (context) => const MatricesScreen(),
        unitCircle: (context) => const UnitCircleScreen(),
        sequences: (context) => const SequencesScreen(),
        geometry: (context) => const GeometryScreen(),
      };
}
