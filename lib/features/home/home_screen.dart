import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../data/storage/local_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  static final modules = [
    _Module('Calculatrice', 'Scientifique + fractions', Icons.calculate_rounded,
        const Color(0xFF1565C0), AppRoutes.calculator),
    _Module('Étude de fonction', 'Graphique + analyse + PDF',
        Icons.show_chart_rounded, const Color(0xFF2E7D32), AppRoutes.graph),
    _Module('Solveur d’équations', 'Polynômes de degré n',
        Icons.architecture_rounded, const Color(0xFF6A1B9A), AppRoutes.solver),
    _Module('Matrices', '2×2 / 3×3 + det + inverse', Icons.grid_on_rounded,
        const Color(0xFF0277BD), AppRoutes.matrices),
    _Module('Cercle trigonométrique', 'Interactif cos / sin / tan',
        Icons.radar_rounded, const Color(0xFF00838F), AppRoutes.unitCircle),
    _Module(
        'Suites numériques',
        'Arithmétiques & géométriques',
        Icons.format_list_numbered_rounded,
        const Color(0xFF5D4037),
        AppRoutes.sequences),
    _Module('Géométrie', 'Pythagore, Thalès, aires, volumes',
        Icons.pentagon_rounded, const Color(0xFF37474F), AppRoutes.geometry),
    _Module('Exercices', 'Quiz avec correction détaillée', Icons.quiz_rounded,
        const Color(0xFFC62828), AppRoutes.exercises),
    _Module('Dérivée & Intégrale', 'Calcul + explications',
        Icons.functions_rounded, const Color(0xFF4527A0), AppRoutes.derivative),
    _Module('Probabilités', 'Permutations, arrangements, combinaisons',
        Icons.casino_rounded, const Color(0xFF00695C), AppRoutes.probability),
    _Module('Statistiques', 'Série de données + indicateurs',
        Icons.bar_chart_rounded, const Color(0xFFEF6C00), AppRoutes.statistics),
    _Module('Nombres complexes', 'Opérations + forme polaire',
        Icons.blur_on_rounded, const Color(0xFFAD1457), AppRoutes.complex),
    _Module('Convertisseur', 'Devises, longueurs, masses…',
        Icons.swap_horiz_rounded, const Color(0xFF455A64), AppRoutes.converter),
    _Module('Historique', 'Tes derniers calculs', Icons.history_rounded,
        const Color(0xFF4E342E), AppRoutes.history),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<LocalStorage>();
    final favorites = storage.favoriteModules;
    final filtered = modules.where((m) {
      final q = _query.trim().toLowerCase();
      return q.isEmpty || '${m.title} ${m.subtitle}'.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => (favorites.contains(b.route) ? 0 : 1)
          .compareTo(favorites.contains(a.route) ? 0 : 1));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calc For All'),
        actions: [
          IconButton(
              icon: const Icon(Icons.settings_rounded),
              tooltip: 'Réglages',
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.settings)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Rechercher un outil…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      }),
            ),
          ),
          const SizedBox(height: 16),
          if (_query.isEmpty) ...[
            Text('Exemples rapides',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _ExampleChip(
                  label: 'Étudier ln(2x+1)',
                  icon: Icons.show_chart,
                  route: AppRoutes.graph),
              _ExampleChip(
                  label: 'Résoudre x²−3x+2',
                  icon: Icons.functions,
                  route: AppRoutes.solver),
              _ExampleChip(
                  label: 'Statistiques',
                  icon: Icons.bar_chart,
                  route: AppRoutes.statistics),
            ]),
            const SizedBox(height: 20),
          ],
          Text(_query.isEmpty ? 'Modules' : 'Résultats',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Aucun module trouvé.')))
          else
            ...filtered.asMap().entries.map((entry) => _ModuleCard(
                    module: entry.value,
                    isFavorite: favorites.contains(entry.value.route))
                .animate()
                .fadeIn(delay: (25 * entry.key).ms, duration: 240.ms)
                .slideY(begin: 0.05, end: 0)),
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
  const _Module(this.title, this.subtitle, this.icon, this.color, this.route);
}

class _ExampleChip extends StatelessWidget {
  final String label, route;
  final IconData icon;
  const _ExampleChip(
      {required this.label, required this.icon, required this.route});

  @override
  Widget build(BuildContext context) => ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => Navigator.pushNamed(context, route));
}

class _ModuleCard extends StatelessWidget {
  final _Module module;
  final bool isFavorite;
  const _ModuleCard({required this.module, required this.isFavorite});

  @override
  Widget build(BuildContext context) {
    final storage = context.read<LocalStorage>();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, module.route),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: module.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(module.icon, color: module.color, size: 26)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(module.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(module.subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color))
                ])),
            IconButton(
                icon: Icon(
                    isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isFavorite ? Colors.amber : null),
                tooltip: isFavorite ? 'Retirer des favoris' : 'Épingler',
                onPressed: () => storage.toggleFavorite(module.route)),
            const Icon(Icons.chevron_right_rounded),
          ]),
        ),
      ),
    );
  }
}
