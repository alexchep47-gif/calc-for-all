import 'package:flutter/material.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/calculator/calculator_screen.dart';
import '../../features/graph/graph_screen.dart';
import '../../features/complex/complex_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/settings/settings_screen.dart';

/// Routes de l'application
class AppRoutes {
  static const String onboarding = '/';
  static const String calculator = '/calculator';
  static const String graph = '/graph';
  static const String complex = '/complex';
  static const String history = '/history';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
        onboarding: (context) => const OnboardingScreen(),
        calculator: (context) => const CalculatorScreen(),
        graph: (context) => const GraphScreen(),
        complex: (context) => const ComplexScreen(),
        history: (context) => const HistoryScreen(),
        settings: (context) => const SettingsScreen(),
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => const CalculatorScreen(),
      settings: settings,
    );
  }
}
