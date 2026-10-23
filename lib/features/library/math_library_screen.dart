import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/locale_provider.dart';

/// Formules mathématiques hors ligne (pas de mention technique interne)
class MathLibraryScreen extends StatefulWidget {
  const MathLibraryScreen({super.key});

  @override
  State<MathLibraryScreen> createState() => _MathLibraryScreenState();
}

class _MathLibraryScreenState extends State<MathLibraryScreen> {
  String _query = '';
  String _category = '';

  List<String> _categories(LocaleProvider loc) => [
        loc.t('Tous', 'All'),
        loc.t('Algèbre', 'Algebra'),
        loc.t('Analyse', 'Analysis'),
        loc.t('Trigonométrie', 'Trigonometry'),
        loc.t('Géométrie', 'Geometry'),
        loc.t('Probabilités', 'Probability'),
        loc.t('Suites', 'Sequences'),
        loc.t('Complexes', 'Complex'),
        loc.t('Matrices', 'Matrices'),
        loc.t('Statistiques', 'Statistics'),
      ];

  List<_Formula> _formulas(LocaleProvider loc) => [
        _Formula('Algèbre', 'Algebra', loc.t('Identités remarquables', 'Remarkable identities'),
            '(a+b)² = a² + 2ab + b²\n(a−b)² = a² − 2ab + b²\na² − b² = (a−b)(a+b)'),
        _Formula('Algèbre', 'Algebra', loc.t('Équation du second degré', 'Quadratic equation'),
            'ax² + bx + c = 0\nΔ = b² − 4ac'),
        _Formula('Analyse', 'Analysis', loc.t('Dérivées usuelles', 'Common derivatives'),
            '(xⁿ)′ = n xⁿ⁻¹\n(sin x)′ = cos x\n(eˣ)′ = eˣ\n(ln x)′ = 1/x'),
        _Formula('Analyse', 'Analysis', loc.t('Primitives usuelles', 'Common antiderivatives'),
            '∫ xⁿ dx = xⁿ⁺¹/(n+1) + C\n∫ 1/x dx = ln|x| + C'),
        _Formula('Trigonométrie', 'Trigonometry', loc.t('Identités', 'Identities'),
            'cos²θ + sin²θ = 1\nsin(2θ) = 2 sinθ cosθ'),
        _Formula('Trigonométrie', 'Trigonometry', loc.t('Angles moitiés', 'Half-angle formulas'),
            'sin²(θ/2) = (1 − cosθ)/2\ncos²(θ/2) = (1 + cosθ)/2\ntan²(θ/2) = (1 − cosθ)/(1 + cosθ)\nsin(θ/2) = ±√((1 − cosθ)/2)\ncos(θ/2) = ±√((1 + cosθ)/2)\ntan(θ/2) = sinθ/(1 + cosθ) = (1 − cosθ)/sinθ'),
        _Formula('Complexes', 'Complex', loc.t('Angles moitiés complexes', 'Complex half-angle factorization'),
            'e^{iθ} = cosθ + i sinθ\ncos(θ/2) = ±√((1 + cosθ)/2)\nsin(θ/2) = ±√((1 − cosθ)/2)\ne^{iθ/2} = ±(√((1 + cosθ)/2) + i√((1 − cosθ)/2))\ncosθ = (e^{iθ}+e^{-iθ})/2\nsinθ = (e^{iθ}−e^{-iθ})/(2i)'),
        _Formula('Statistiques', 'Statistics', loc.t('Régression linéaire', 'Linear regression'),
            'y = a + bx\nb = cov(x,y)/var(x)\nr = cov/(σₓ σᵧ)'),
        _Formula('Statistiques', 'Statistics', loc.t('Méthode de Mayer', 'Mayer method'),
            'Deux groupes de moyennes (x̄₁,ȳ₁), (x̄₂,ȳ₂)\nb = (ȳ₂−ȳ₁)/(x̄₂−x̄₁)'),
        _Formula('Complexes', 'Complex', loc.t('Formes', 'Forms'),
            'z = a+bi = |z|(cosθ + i sinθ)'),
        _Formula('Matrices', 'Matrices', 'det 2×2', '|a b; c d| = ad − bc'),
        _Formula('Suites', 'Sequences', loc.t('Arithmétique', 'Arithmetic'),
            'uₙ = u₁ + (n−1)r\nSₙ = n(u₁+uₙ)/2'),
        _Formula('Probabilités', 'Probability', loc.t('Combinaisons', 'Combinations'),
            'C(n,k) = n! / (k!(n−k)!)'),
        _Formula('Géométrie', 'Geometry', 'Pythagore / Pythagoras',
            'a² + b² = c²'),
      ];

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final cats = _categories(loc);
    if (_category.isEmpty || !cats.contains(_category)) {
      _category = cats.first;
    }
    final all = _formulas(loc);
    final filtered = all.where((f) {
      final catKey = loc.isFrench ? f.catFr : f.catEn;
      final okCat = _category == cats.first || catKey == _category;
      final q = _query.toLowerCase();
      final okQ = q.isEmpty ||
          f.title.toLowerCase().contains(q) ||
          f.body.toLowerCase().contains(q);
      return okCat && okQ;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('Formules', 'Formulas')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: loc.t('Rechercher…', 'Search…'),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: cats
                  .map((c) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(c),
                          selected: _category == c,
                          onSelected: (_) => setState(() => _category = c),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final f = filtered[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text(f.title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(loc.isFrench ? f.catFr : f.catEn),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SelectableText(
                          f.body,
                          style: const TextStyle(
                              fontFamily: 'monospace', height: 1.5),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: f.body));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      loc.t('Formule copiée', 'Copied'))),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 18),
                          label: Text(loc.t('Copier', 'Copy')),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Formula {
  final String catFr, catEn, title, body;
  const _Formula(this.catFr, this.catEn, this.title, this.body);
}
