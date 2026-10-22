import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bibliothèque de formules mathématiques (hors ligne) — enrichie
class MathLibraryScreen extends StatefulWidget {
  const MathLibraryScreen({super.key});

  @override
  State<MathLibraryScreen> createState() => _MathLibraryScreenState();
}

class _MathLibraryScreenState extends State<MathLibraryScreen> {
  String _query = '';
  String _category = 'Tous';

  static const categories = [
    'Tous',
    'Algèbre',
    'Analyse',
    'Trigonométrie',
    'Géométrie',
    'Probabilités',
    'Suites',
    'Complexes',
    'Matrices',
    'Statistiques',
  ];

  static final formulas = <_Formula>[
    // —— Algèbre ——
    _Formula('Algèbre', 'Identités remarquables',
        '(a+b)² = a² + 2ab + b²\n(a−b)² = a² − 2ab + b²\na² − b² = (a−b)(a+b)\n(a+b)³ = a³ + 3a²b + 3ab² + b³'),
    _Formula('Algèbre', 'Équation du second degré',
        'ax² + bx + c = 0\nΔ = b² − 4ac\nSi Δ > 0 : x = (−b ± √Δ)/(2a)\nSi Δ = 0 : x = −b/(2a)\nSi Δ < 0 : racines complexes'),
    _Formula('Algèbre', 'Binôme de Newton',
        '(a+b)^n = Σ C(n,k) a^(n−k) b^k\nC(n,k) = n! / (k!(n−k)!)'),
    _Formula('Algèbre', 'Factorisation',
        'a³ − b³ = (a−b)(a² + ab + b²)\na³ + b³ = (a+b)(a² − ab + b²)'),
    // —— Analyse ——
    _Formula('Analyse', 'Dérivées usuelles',
        '(x^n)\' = n x^(n−1)\n(√x)\' = 1/(2√x)\n(e^x)\' = e^x\n(ln x)\' = 1/x\n(sin x)\' = cos x\n(cos x)\' = −sin x\n(tan x)\' = 1 + tan²x = 1/cos²x'),
    _Formula('Analyse', 'Primitives usuelles',
        '∫ x^n dx = x^(n+1)/(n+1) + C (n ≠ −1)\n∫ 1/x dx = ln|x| + C\n∫ e^x dx = e^x + C\n∫ sin x dx = −cos x + C\n∫ cos x dx = sin x + C'),
    _Formula('Analyse', 'Limites classiques',
        'lim(x→0) sin(x)/x = 1\nlim(x→0) (1−cos x)/x² = 1/2\nlim(x→∞) (1+1/x)^x = e\nlim(x→0) ln(1+x)/x = 1'),
    _Formula('Analyse', 'Règles de dérivation',
        '(u+v)\' = u\' + v\'\n(uv)\' = u\'v + uv\'\n(u/v)\' = (u\'v − uv\')/v²\n(u∘v)\' = (u\'∘v)·v\''),
    // —— Trigonométrie ——
    _Formula('Trigonométrie', 'Identités fondamentales',
        'cos²θ + sin²θ = 1\n1 + tan²θ = 1/cos²θ\nsin(2θ) = 2 sinθ cosθ\ncos(2θ) = cos²θ − sin²θ = 2cos²θ − 1'),
    _Formula('Trigonométrie', 'Valeurs remarquables',
        'sin(0)=0, sin(π/6)=1/2, sin(π/4)=√2/2, sin(π/3)=√3/2, sin(π/2)=1\ncos(0)=1, cos(π/6)=√3/2, cos(π/4)=√2/2, cos(π/3)=1/2, cos(π/2)=0'),
    _Formula('Trigonométrie', 'Formules d\'addition',
        'sin(a±b) = sin a cos b ± cos a sin b\ncos(a±b) = cos a cos b ∓ sin a sin b\ntan(a±b) = (tan a ± tan b)/(1 ∓ tan a tan b)'),
    _Formula('Trigonométrie', 'Équations trigonométriques',
        'sin x = sin α  ⇒  x = α + 2kπ ou x = π − α + 2kπ\ncos x = cos α  ⇒  x = ±α + 2kπ\ntan x = tan α  ⇒  x = α + kπ'),
    // —— Géométrie ——
    _Formula('Géométrie', 'Aires et volumes',
        'Disque : πr²\nCercle (périmètre) : 2πr\nSphère (volume) : (4/3)πr³\nSphère (aire) : 4πr²\nCône : (1/3)πr²h\nCylindre : πr²h'),
    _Formula('Géométrie', 'Théorème de Pythagore',
        'Dans un triangle rectangle : a² + b² = c²\nc hypoténuse'),
    _Formula('Géométrie', 'Théorème de Thalès',
        'Si (DE) ∥ (BC) dans ABC avec D sur (AB), E sur (AC) :\nAD/AB = AE/AC = DE/BC'),
    _Formula('Géométrie', 'Produit scalaire',
        'u·v = ||u|| ||v|| cos θ\nu·v = x1x2 + y1y2 (+ z1z2)\nOrthogonalité : u·v = 0'),
    // —— Probabilités ——
    _Formula('Probabilités', 'Dénombrement',
        'Permutations : n!\nArrangements : A(n,k) = n!/(n−k)!\nCombinaisons : C(n,k) = n!/(k!(n−k)!)'),
    _Formula('Probabilités', 'Loi binomiale',
        'X ~ B(n,p)\nP(X=k) = C(n,k) p^k (1−p)^(n−k)\nE(X)=np, V(X)=np(1−p)'),
    _Formula('Probabilités', 'Loi normale',
        'X ~ N(μ,σ²)\nDensité : (1/(σ√(2π))) exp(−(x−μ)²/(2σ²))\nZ = (X−μ)/σ ~ N(0,1)'),
    // —— Suites ——
    _Formula('Suites', 'Suite arithmétique',
        'un = u1 + (n−1)r\nSn = n(u1+un)/2 = n(2u1+(n−1)r)/2'),
    _Formula('Suites', 'Suite géométrique',
        'un = u1 · q^(n−1)\nSn = u1(1−q^n)/(1−q) si q≠1\nSi |q|<1 : lim Sn = u1/(1−q)'),
    _Formula('Suites', 'Suite récurrente linéaire',
        'u(n+1) = a·un + b\nPoint fixe L = b/(1−a) si a≠1\nConvergence si |a|<1'),
    _Formula('Suites', 'Fibonacci',
        'F1=1, F2=1, Fn = F(n−1)+F(n−2)\nFormule de Binet : Fn ≈ φ^n / √5\nφ = (1+√5)/2'),
    // —— Complexes ——
    _Formula('Complexes', 'Formes',
        'Algébrique : z = a + bi\nModule : |z| = √(a²+b²)\nArgument : arg(z) = atan2(b,a)\nPolaire : z = |z|(cos θ + i sin θ)\nExponentielle : z = |z| e^(iθ)'),
    _Formula('Complexes', 'Opérations',
        '(a+bi)+(c+di) = (a+c)+(b+d)i\n(a+bi)(c+di) = (ac−bd)+(ad+bc)i\nConjugué : z̄ = a − bi\nz·z̄ = |z|²'),
    // —— Matrices ——
    _Formula('Matrices', 'Déterminant 2×2',
        '|a b|\n|c d| = ad − bc'),
    _Formula('Matrices', 'Inverse 2×2',
        'A⁻¹ = (1/det A) · | d −b |\n                    |−c  a |'),
    _Formula('Matrices', 'Trace et transposée',
        'Tr(A) = somme des aᵢᵢ\n(Aᵀ)ᵢⱼ = Aⱼᵢ\nTr(A+B)=Tr(A)+Tr(B)\nTr(AB)=Tr(BA)'),
    // —— Statistiques ——
    _Formula('Statistiques', 'Indicateurs',
        'Moyenne : x̄ = (Σ xi)/n\nVariance : V = (Σ (xi−x̄)²)/n\nÉcart-type : σ = √V\nMédiane : valeur centrale triée'),
    _Formula('Statistiques', 'Quartiles',
        'Q1 : 25e centile\nQ2 = médiane\nQ3 : 75e centile\nÉcart interquartile : Q3 − Q1'),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = formulas.where((f) {
      final okCat = _category == 'Tous' || f.category == _category;
      final q = _query.toLowerCase();
      final okQ = q.isEmpty ||
          f.title.toLowerCase().contains(q) ||
          f.body.toLowerCase().contains(q) ||
          f.category.toLowerCase().contains(q);
      return okCat && okQ;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Bibliothèque mathématiques')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher une formule…',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: categories
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
                    subtitle: Text(f.category,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SelectableText(
                          f.body,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            height: 1.5,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: f.body));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Formule copiée')),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Copier'),
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
  final String category, title, body;
  const _Formula(this.category, this.title, this.body);
}
