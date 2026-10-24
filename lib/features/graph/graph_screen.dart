import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../solver/solver_screen.dart';

/// Graphique : route fonctionnelle, redirigée vers le solveur en attendant
/// le module de tracé complet.
class GraphScreen extends StatelessWidget {
  const GraphScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SolverScreen();
  }
}
