import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/routes/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = [
      _Module('Calculatrice', 'Scientifique + fractions', Icons.calculate_rounded, const Color(0xFF1565C0), AppRoutes.calculator),
      _Module('Étude de fonction', 'Graphique + analyse + PDF', Icons.show_chart_rounded, const Color(0xFF2E7D32), AppRoutes.graph),
      _Module('Solveur d’équations', 'Polynômes de degré n', Icons.architecture_rounded, const Color(0xFF6A1B9A), AppRoutes.solver),
      _Module('Matrices', '2×2 / 3×3 + det + inverse', Icons.grid_on_rounded, const Color(0xFF0277BD), AppRoutes.matrices),
      _Module('Cercle trigonométrique', 'Interactif cos / sin / tan', Icons.radar_rounded, const Color(0xFF00838F), AppRoutes.unitCircle),
      _Module('Suites numériques', 'Arithmétiques & géométriques', Icons.format_list_numbered_rounded, const Color(0xFF5D4037), AppRoutes.sequences),
      _Module('Géométrie', 'Pythagore, Thalès, aires, volumes', Icons.pentagon_rounded, const Color(0xFF37474F), AppRoutes.geometry),
      _Module('Dérivée & Intégrale', 'Calcul + explications', Icons.functions_rounded, const Color(0xFF4527A0), AppRoutes.derivative),
      _Module('Probabilités', 'Permutations, arrangements, combinaisons', Icons.casino_rounded, const Color(0xFF00695C), AppRoutes.probability),
      _Module('Statistiques', 'Série de données + indicateurs', Icons.bar_chart_rounded, const Color(0xFFEF6C00), AppRoutes.statistics),
      _Module('Nombres complexes', 'Opérations + forme polaire', Icons.blur_on_rounded, const Color(0xFFAD1457), AppRoutes.complex),
      _Module('Convertisseur', 'Devises, longueurs, masses…', Icons.swap_horiz_rounded, const Color(0xFF455A64), AppRoutes.converter),
      _Module('Historique', 'Tes derniers calculs', Icons.history_rounded, const Color(0xFF4E342E), AppRoutes.history),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calc For All'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        children: [
          Text('Choisis un module', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600)).animate().fadeIn(),
          const SizedBox(height: 12),
          ...modules.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            return _ModuleCard(module: m).animate().fadeIn(delay: (40 * i).ms, duration: 280.ms).slideY(begin: 0.08, end: 0);
          }),
        ],
      ),
    );
  }
}

class _Module {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final String route;
  _Module(this.title, this.subtitle, this.icon, this.color, this.route);
}

class _ModuleCard extends StatelessWidget {
  final _Module module;
  const _ModuleCard({required this.module});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, module.route),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: module.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(module.icon, color: module.color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(module.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(module.subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
