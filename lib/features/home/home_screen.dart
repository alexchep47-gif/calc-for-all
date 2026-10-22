import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/l10n/locale_provider.dart';
import '../../data/storage/local_storage.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static List<_Module> _modules(LocaleProvider loc) => [
        _Module(
            loc.t('Calculatrice', 'Calculator'),
            loc.t('Scientifique · fractions · ⁿ√', 'Scientific · fractions · ⁿ√'),
            Icons.calculate_rounded,
            const Color(0xFF1565C0),
            AppRoutes.calculator),
        _Module(
            loc.t('Graphique', 'Graph'),
            loc.t('Courbes · étude · points critiques',
                'Curves · study · critical points'),
            Icons.show_chart_rounded,
            const Color(0xFF2E7D32),
            AppRoutes.graph),
        _Module(
            loc.t('Formules', 'Formulas'),
            loc.t('Identités et formules', 'Identities and formulas'),
            Icons.menu_book_rounded,
            const Color(0xFF283593),
            AppRoutes.library),
        _Module(
            loc.t('Solveur d’équations', 'Equation solver'),
            loc.t('Polynômes de degré n', 'Degree-n polynomials'),
            Icons.architecture_rounded,
            const Color(0xFF6A1B9A),
            AppRoutes.solver),
        _Module(
            loc.t('Systèmes & Inéquations', 'Systems & Inequalities'),
            loc.t('Systèmes linéaires + inéquations',
                'Linear systems + inequalities'),
            Icons.account_tree_rounded,
            const Color(0xFF5C6BC0),
            AppRoutes.systems),
        _Module(
            loc.t('Matrices', 'Matrices'),
            loc.t('Ordre libre · fractions · FE / FER',
                'Free order · fractions · REF / RREF'),
            Icons.grid_on_rounded,
            const Color(0xFF0277BD),
            AppRoutes.matrices),
        _Module(
            loc.t('Cercle trigo', 'Unit circle'),
            loc.t('Angles en fractions de π', 'Angles as π fractions'),
            Icons.radar_rounded,
            const Color(0xFF00838F),
            AppRoutes.unitCircle),
        _Module(
            loc.t('Suites', 'Sequences'),
            loc.t('Arithmétiques / géométriques', 'Arithmetic / geometric'),
            Icons.timeline_rounded,
            const Color(0xFF558B2F),
            AppRoutes.sequences),
        _Module(
            loc.t('Géométrie', 'Geometry'),
            loc.t('Aires, volumes, vecteurs', 'Areas, volumes, vectors'),
            Icons.pentagon_rounded,
            const Color(0xFF37474F),
            AppRoutes.geometry),
        _Module(
            loc.t('Exercices', 'Exercises'),
            loc.t('Entraînement guidé', 'Guided practice'),
            Icons.school_rounded,
            const Color(0xFFC62828),
            AppRoutes.exercises),
        _Module(
            loc.t('Dérivées & Intégrales', 'Derivatives & Integrals'),
            loc.t('Calcul symbolique', 'Symbolic calculus'),
            Icons.functions_rounded,
            const Color(0xFF4527A0),
            AppRoutes.derivative),
        _Module(
            loc.t('Probabilités', 'Probability'),
            loc.t('Lois et combinatoire', 'Laws and combinatorics'),
            Icons.casino_rounded,
            const Color(0xFF00695C),
            AppRoutes.probability),
        _Module(
            loc.t('Statistiques', 'Statistics'),
            loc.t('Régressions · corrélation · Mayer',
                'Regression · correlation · Mayer'),
            Icons.bar_chart_rounded,
            const Color(0xFFEF6C00),
            AppRoutes.statistics),
        _Module(
            loc.t('Complexes', 'Complex numbers'),
            loc.t('Module, argument, plan', 'Modulus, argument, plane'),
            Icons.blur_on_rounded,
            const Color(0xFFAD1457),
            AppRoutes.complex),
        _Module(
            loc.t('Convertisseur', 'Converter'),
            loc.t('Unités et devises', 'Units and currencies'),
            Icons.swap_horiz_rounded,
            const Color(0xFF455A64),
            AppRoutes.converter),
        _Module(
            loc.t('Historique', 'History'),
            loc.t('Calculs récents', 'Recent calculations'),
            Icons.history_rounded,
            const Color(0xFF546E7A),
            AppRoutes.history),
        _Module(
            loc.t('Paramètres', 'Settings'),
            loc.t('Thème, langue, affichage', 'Theme, language, display'),
            Icons.settings_rounded,
            const Color(0xFF607D8B),
            AppRoutes.settings),
      ];

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final storage = context.watch<LocalStorage>();
    final modules = _modules(loc);
    final favorites = storage.favoriteModules;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('Calc For All', 'Calc For All')),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.history),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                loc.t('Modules', 'Modules'),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (favorites.isNotEmpty)
            ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    loc.t('Favoris', 'Favorites'),
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600),
                  ),
                ),
              ),
            ],
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.15,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final m = modules[i];
                  return _ModuleCard(module: m)
                      .animate()
                      .fadeIn(delay: (40 * i).ms)
                      .slideY(begin: 0.08, end: 0);
                },
                childCount: modules.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Module {
  final String title, subtitle, route;
  final IconData icon;
  final Color color;
  const _Module(this.title, this.subtitle, this.icon, this.color, this.route);
}

class _ModuleCard extends StatelessWidget {
  final _Module module;
  const _ModuleCard({required this.module});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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
