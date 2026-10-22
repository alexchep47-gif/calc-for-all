import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/l10n/locale_provider.dart';
import '../../data/storage/local_storage.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final _modules = [
    _Module('Calculatrice', 'Scientifique · fractions · ⁿ√',
        Icons.calculate_rounded, const Color(0xFF1565C0), AppRoutes.calculator),
    _Module('Graphique', 'Courbes · étude · points critiques',
        Icons.show_chart_rounded, const Color(0xFF2E7D32), AppRoutes.graph),
    _Module('Bibliothèque', 'Formules et identités',
        Icons.menu_book_rounded, const Color(0xFF283593), AppRoutes.library),
    _Module('Solveur d’équations', 'Polynômes de degré n',
        Icons.architecture_rounded, const Color(0xFF6A1B9A), AppRoutes.solver),
    _Module('Systèmes & Inéquations', 'Systèmes linéaires + inéquations',
        Icons.account_tree_rounded, const Color(0xFF5C6BC0), AppRoutes.systems),
    _Module('Matrices', 'Ordre libre · fractions · FE / FER', Icons.grid_on_rounded,
        const Color(0xFF0277BD), AppRoutes.matrices),
    _Module('Cercle trigo', 'Angles en fractions de π',
        Icons.radar_rounded, const Color(0xFF00838F), AppRoutes.unitCircle),
    _Module('Suites', 'Arithmétiques / géométriques',
        Icons.timeline_rounded, const Color(0xFF558B2F), AppRoutes.sequences),
    _Module('Géométrie', 'Aires, volumes, vecteurs',
        Icons.pentagon_rounded, const Color(0xFF37474F), AppRoutes.geometry),
    _Module('Exercices', 'Entraînement guidé',
        Icons.school_rounded, const Color(0xFFC62828), AppRoutes.exercises),
    _Module('Dérivées & Intégrales', 'Calcul symbolique',
        Icons.functions_rounded, const Color(0xFF4527A0), AppRoutes.derivative),
    _Module('Probabilités', 'Lois et combinatoire',
        Icons.casino_rounded, const Color(0xFF00695C), AppRoutes.probability),
    _Module('Statistiques', 'Moyenne, variance…',
        Icons.bar_chart_rounded, const Color(0xFFEF6C00), AppRoutes.statistics),
    _Module('Complexes', 'Module, argument, plan',
        Icons.blur_on_rounded, const Color(0xFFAD1457), AppRoutes.complex),
    _Module('Convertisseur', 'Unités et devises',
        Icons.swap_horiz_rounded, const Color(0xFF455A64), AppRoutes.converter),
    _Module('Historique', 'Calculs récents',
        Icons.history_rounded, const Color(0xFF4E342E), AppRoutes.history),
  ];

  @override
  Widget build(BuildContext context) {
    final isFr = context.watch<LocaleProvider?>()?.isFrench ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calc For All'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
        ),
        itemCount: _modules.length,
        itemBuilder: (context, i) {
          final m = _modules[i];
          return _ModuleCard(module: m)
              .animate(delay: (40 * i).ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.08, end: 0);
        },
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
  const _Module(this.title, this.subtitle, this.icon, this.color, this.route);
}

class _ModuleCard extends StatelessWidget {
  final _Module module;
  const _ModuleCard({required this.module});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: module.color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.pushNamed(context, module.route),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: module.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(module.icon, color: module.color, size: 26),
              ),
              const Spacer(),
              Text(
                module.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                module.subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
