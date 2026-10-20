import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/routes/app_routes.dart';

/// Écran d'accueil avec accès à tous les modules
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = [
      _Module(
        title: 'Calculatrice',
        subtitle: 'Scientifique + fractions',
        icon: Icons.calculate_rounded,
        color: const Color(0xFF1565C0),
        route: AppRoutes.calculator,
      ),
      _Module(
        title: 'Étude de fonction',
        subtitle: 'Les 8 étapes + graphique + PDF',
        icon: Icons.show_chart_rounded,
        color: const Color(0xFF2E7D32),
        route: AppRoutes.graph,
      ),
      _Module(
        title: 'Dérivée & Intégrale',
        subtitle: 'Calcul + explications',
        icon: Icons.functions_rounded,
        color: const Color(0xFF6A1B9A),
        route: AppRoutes.derivative,
      ),
      _Module(
        title: 'Probabilités',
        subtitle: 'Permutations, arrangements, combinaisons',
        icon: Icons.casino_rounded,
        color: const Color(0xFF00838F),
        route: AppRoutes.probability,
      ),
      _Module(
        title: 'Statistiques',
        subtitle: 'Tableau de données + indicateurs',
        icon: Icons.bar_chart_rounded,
        color: const Color(0xFFEF6C00),
        route: AppRoutes.statistics,
      ),
      _Module(
        title: 'Nombres complexes',
        subtitle: 'Opérations + forme polaire',
        icon: Icons.blur_on_rounded,
        color: const Color(0xFFAD1457),
        route: AppRoutes.complex,
      ),
      _Module(
        title: 'Convertisseur',
        subtitle: 'Devises, longueurs, masses…',
        icon: Icons.swap_horiz_rounded,
        color: const Color(0xFF455A64),
        route: AppRoutes.converter,
      ),
      _Module(
        title: 'Historique',
        subtitle: 'Tes derniers calculs',
        icon: Icons.history_rounded,
        color: const Color(0xFF5D4037),
        route: AppRoutes.history,
      ),
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
          Text(
            'Choisis un module',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ).animate().fadeIn(),
          const SizedBox(height: 12),
          ...modules.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            return _ModuleCard(module: m)
                .animate()
                .fadeIn(delay: (80 * i).ms, duration: 350.ms)
                .slideY(begin: 0.15, end: 0);
          }),
        ],
      ),
    );
  }
}

class _Module {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  _Module({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class _ModuleCard extends StatelessWidget {
  final _Module module;

  const _ModuleCard({required this.module});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.pushNamed(context, module.route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: module.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(module.icon, color: module.color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      module.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
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
