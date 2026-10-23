import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/locale_provider.dart';

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
        loc.t('Nombres', 'Numbers'),
      ];

  List<_Formula> _formulas(LocaleProvider loc) => [
        // Algèbre
        _Formula('Algèbre', 'Algebra', loc.t('Identités remarquables', 'Remarkable identities'),
            '(a+b)² = a² + 2ab + b²\n(a−b)² = a² − 2ab + b²\na² − b² = (a−b)(a+b)\n(a+b)³ = a³ + 3a²b + 3ab² + b³\n(a−b)³ = a³ − 3a²b + 3ab² − b³\na³ ± b³ = (a ± b)(a² ∓ ab + b²)'),
        _Formula('Algèbre', 'Algebra', loc.t('Équation du second degré', 'Quadratic equation'),
            'ax² + bx + c = 0\nΔ = b² − 4ac\nΔ > 0 : deux racines réelles\nΔ = 0 : racine double\nΔ < 0 : racines complexes\nx = (−b ± √Δ) / (2a)'),
        _Formula('Algèbre', 'Algebra', loc.t('Factorisation', 'Factoring'),
            'x² + sx + p = (x−r₁)(x−r₂)\nSomme des racines = −b/a\nProduit = c/a'),
        _Formula('Algèbre', 'Algebra', loc.t('Valeur absolue', 'Absolute value'),
            '|x| = x si x ≥ 0, −x si x < 0\n|a·b| = |a|·|b|\n|a+b| ≤ |a|+|b|'),
        // Analyse
        _Formula('Analyse', 'Analysis', loc.t('Dérivées usuelles', 'Common derivatives'),
            '(xⁿ)′ = n xⁿ⁻¹\n(sin x)′ = cos x\n(cos x)′ = −sin x\n(tan x)′ = 1/cos²x\n(eˣ)′ = eˣ\n(ln x)′ = 1/x\n(√x)′ = 1/(2√x)\n(u∘v)′ = (u′∘v)·v′  (chaîne)'),
        _Formula('Analyse', 'Analysis', loc.t('Primitives usuelles', 'Common antiderivatives'),
            '∫ xⁿ dx = xⁿ⁺¹/(n+1) + C (n≠−1)\n∫ 1/x dx = ln|x| + C\n∫ sin x dx = −cos x + C\n∫ cos x dx = sin x + C\n∫ eˣ dx = eˣ + C'),
        _Formula('Analyse', 'Analysis', loc.t('Intégration par parties', 'Integration by parts'),
            '∫ u dv = uv − ∫ v du'),
        _Formula('Analyse', 'Analysis', loc.t('Changement de variable', 'Substitution'),
            'u = g(x), du = g′(x) dx'),
        _Formula('Analyse', 'Analysis', loc.t('Limites usuelles', 'Common limits'),
            'lim_{x→0} sin x / x = 1\nlim_{x→0} (1−cos x)/x² = 1/2\nlim_{x→∞} (1+1/x)ˣ = e'),
        // Trigo
        _Formula('Trigonométrie', 'Trigonometry', loc.t('Identités', 'Identities'),
            'cos²θ + sin²θ = 1\n1 + tan²θ = 1/cos²θ\nsin(2θ) = 2 sinθ cosθ\ncos(2θ) = cos²θ − sin²θ\nsin(a±b) = sin a cos b ± cos a sin b\ncos(a±b) = cos a cos b ∓ sin a sin b'),
        _Formula('Trigonométrie', 'Trigonometry', loc.t('Valeurs remarquables', 'Key values'),
            'sin 0 = 0, cos 0 = 1\nsin(π/6)=1/2, cos(π/6)=√3/2\nsin(π/4)=√2/2, cos(π/4)=√2/2\nsin(π/3)=√3/2, cos(π/3)=1/2\nsin(π/2)=1, cos(π/2)=0'),
        // Géométrie
        _Formula('Géométrie', 'Geometry', 'Pythagore / Pythagoras', 'a² + b² = c²'),
        _Formula('Géométrie', 'Geometry', loc.t('Aires', 'Areas'),
            'Triangle : (b·h)/2\nRectangle : L·l\nCercle : π r²\nDisque secteur : (α/2π)·π r²'),
        _Formula('Géométrie', 'Geometry', loc.t('Volumes', 'Volumes'),
            'Cube : a³\nPavé : L·l·h\nSphère : (4/3)π r³\nCylindre : π r² h\nCône : (1/3)π r² h'),
        // Proba
        _Formula('Probabilités', 'Probability', loc.t('Combinatoire', 'Combinatorics'),
            'P(n,k) = n!/(n−k)!\nC(n,k) = n!/(k!(n−k)!)\nn! = 1·2·…·n'),
        _Formula('Probabilités', 'Probability', loc.t('Lois', 'Distributions'),
            'Bernoulli, binomiale B(n,p)\nP(X=k) = C(n,k) pᵏ (1−p)ⁿ⁻ᵏ\nEspérance binomiale : np'),
        // Suites
        _Formula('Suites', 'Sequences', loc.t('Arithmétique', 'Arithmetic'),
            'uₙ = u₁ + (n−1)r\nSₙ = n(u₁+uₙ)/2'),
        _Formula('Suites', 'Sequences', loc.t('Géométrique', 'Geometric'),
            'uₙ = u₁ · qⁿ⁻¹\nSₙ = u₁ (qⁿ−1)/(q−1) (q≠1)'),
        // Complexes
        _Formula('Complexes', 'Complex', loc.t('Formes', 'Forms'),
            'z = a+bi = |z|(cosθ + i sinθ) = |z| e^{iθ}\n|z| = √(a²+b²)\narg(z) en fractions de π'),
        _Formula('Complexes', 'Complex', loc.t('Opérations', 'Operations'),
            '(a+bi)+(c+di) = (a+c)+(b+d)i\n(a+bi)(c+di) = …\n1/z = z̄ / |z|²'),
        // Matrices
        _Formula('Matrices', 'Matrices', 'det 2×2', '|a b; c d| = ad − bc'),
        _Formula('Matrices', 'Matrices', loc.t('Opérations', 'Operations'),
            'Trace = somme diagonale\nᵗA transposition\nA⁻¹ si det≠0'),
        // Stats
        _Formula('Statistiques', 'Statistics', loc.t('Régression linéaire', 'Linear regression'),
            'y = a + bx\nb = cov(x,y)/var(x)\nr = cov/(σₓ σᵧ)'),
        _Formula('Statistiques', 'Statistics', loc.t('Méthode de Mayer', 'Mayer method'),
            'Deux groupes de moyennes (x̄₁,ȳ₁), (x̄₂,ȳ₂)\nb = (ȳ₂−ȳ₁)/(x̄₂−x̄₁)'),
        _Formula('Statistiques', 'Statistics', loc.t('Séries groupées', 'Grouped series'),
            'Classe [aᵢ ; bᵢ[\ncᵢ = (aᵢ+bᵢ)/2\nx̄ = Σ nᵢcᵢ / N\nMédiane, mode, ECC, FEC…'),
        // Nombres
        _Formula('Nombres', 'Numbers', loc.t('Bases', 'Bases'),
            'Décimal ↔ binaire ↔ hexadécimal\nEx. 13 = 1101₂ = D₁₆'),
        _Formula('Nombres', 'Numbers', loc.t('Fractions', 'Fractions'),
            'Simplifier : 2/2 = 1\na/b + c/d = (ad+bc)/(bd)'),
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
      appBar: AppBar(title: Text(loc.t('Formules', 'Formulas'))),
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
