import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bibliotheque complete de formules mathematiques (hors ligne)
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
    'Algebre',
    'Analyse',
    'Trigonometrie',
    'Geometrie',
    'Probabilites',
    'Suites',
    'Complexes',
    'Matrices',
  ];

  static final formulas = <_Formula>[
    // Algebre
    _Formula('Algebre', 'Identites remarquables',
        '(a+b)² = a² + 2ab + b²\n(a−b)² = a² − 2ab + b²\na² − b² = (a−b)(a+b)'),
    _Formula('Algebre', 'Equation du second degre',
        'ax² + bx + c = 0\nΔ = b² − 4ac\nx = (−b ± √Δ) / (2a)'),
    _Formula('Algebre', 'Somme et produit des racines',
        'Si x₁, x₂ racines de ax²+bx+c=0\nx₁+x₂ = −b/a\nx₁·x₂ = c/a'),
    _Formula('Algebre', 'Factorielle / binome',
        'n! = 1·2·…·n\nC(n,k) = n! / (k!(n−k)!)\n(a+b)ⁿ = Σ C(n,k) aⁿ⁻ᵏ bᵏ'),
    // Analyse
    _Formula('Analyse', 'Derivees usuelles',
        "(xⁿ)' = n xⁿ⁻¹\n(ln x)' = 1/x\n(eˣ)' = eˣ\n(sin x)' = cos x\n(cos x)' = −sin x\n(tan x)' = 1+tan²x = 1/cos²x"),
    _Formula('Analyse', 'Regles de derivation',
        '(u+v)' = u'+v'\n(uv)' = u'v + uv'\n(u/v)' = (u'v − uv')/v²\n(u∘v)' = (u'∘v)·v'"),
    _Formula('Analyse', 'Integrales usuelles',
        '∫ xⁿ dx = xⁿ⁺¹/(n+1) + C (n≠−1)\n∫ 1/x dx = ln|x| + C\n∫ eˣ dx = eˣ + C\n∫ sin x dx = −cos x + C\n∫ cos x dx = sin x + C'),
    _Formula('Analyse', 'Limites classiques',
        'lim_{x→0} sin x / x = 1\nlim_{x→0} (1−cos x)/x² = 1/2\nlim_{x→∞} (1+1/x)ˣ = e\nlim_{x→0} ln(1+x)/x = 1'),
    _Formula('Analyse', 'Asymptotes',
        'Verticale x=a si lim_{x→a} f = ±∞\nHorizontale y=L si lim_{x→±∞} f = L\nOblique y=ax+b si lim (f−ax−b)=0'),
    // Trigonometrie
    _Formula('Trigonometrie', 'Valeurs remarquables',
        'sin(0)=0  cos(0)=1\nsin(π/6)=1/2  cos(π/6)=√3/2\nsin(π/4)=√2/2  cos(π/4)=√2/2\nsin(π/3)=√3/2  cos(π/3)=1/2\nsin(π/2)=1  cos(π/2)=0'),
    _Formula('Trigonometrie', 'Formules d addition',
        'cos(a±b) = cos a cos b ∓ sin a sin b\nsin(a±b) = sin a cos b ± cos a sin b\ntan(a±b) = (tan a ± tan b)/(1 ∓ tan a tan b)'),
    _Formula('Trigonometrie', 'Duplication',
        'cos 2a = cos²a − sin²a = 2cos²a − 1 = 1 − 2sin²a\nsin 2a = 2 sin a cos a\ntan 2a = 2 tan a / (1 − tan² a)'),
    _Formula('Trigonometrie', 'Pythagore trigonometrique',
        'cos²θ + sin²θ = 1\n1 + tan²θ = 1/cos²θ\n1 + cot²θ = 1/sin²θ'),
    // Geometrie
    _Formula('Geometrie', 'Pythagore / Thales',
        'Triangle rectangle : a² + b² = c²\nThales : AD/AB = AE/AC = DE/BC'),
    _Formula('Geometrie', 'Aires',
        'Rectangle : L×l\nTriangle : (b×h)/2\nCercle : π r²\nDisque secteur : (α/360) π r²'),
    _Formula('Geometrie', 'Volumes',
        'Cube : a³\nPave : L×l×h\nSphere : (4/3) π r³\nCylindre : π r² h\nCone : (1/3) π r² h'),
    _Formula('Geometrie', 'Vecteurs',
        'u·v = |u||v| cos θ = xu xv + yu yv + zu zv\n|u×v| = |u||v| sin θ\nu×v = (uy vz − uz vy, uz vx − ux vz, ux vy − uy vx)'),
    // Probabilites
    _Formula('Probabilites', 'Denombrement',
        'Permutations : n!\nArrangements : A(n,k) = n!/(n−k)!\nCombinaisons : C(n,k) = n!/(k!(n−k)!)'),
    _Formula('Probabilites', 'Loi binomiale',
        'X ~ B(n,p)\nP(X=k) = C(n,k) pᵏ (1−p)ⁿ⁻ᵏ\nE(X)=np  V(X)=np(1−p)'),
    _Formula('Probabilites', 'Loi normale',
        'X ~ N(μ,σ²)\nz = (x−μ)/σ\nf(x) = 1/(σ√(2π)) exp(−½ z²)'),
    // Suites
    _Formula('Suites', 'Arithmetique',
        'uₙ = u₀ + n r\nSₙ = (n+1)(u₀+uₙ)/2'),
    _Formula('Suites', 'Geometrique',
        'uₙ = u₀ · qⁿ\nSₙ = u₀ (1−qⁿ⁺¹)/(1−q)  (q≠1)'),
    // Complexes
    _Formula('Complexes', 'Formes',
        'z = a + bi = r (cos θ + i sin θ) = r e^{iθ}\nr = |z| = √(a²+b²)\nθ = arg(z)'),
    _Formula('Complexes', 'Operations',
        '(a+bi)(c+di) = (ac−bd)+(ad+bc)i\n1/z = z̄ / |z|²\nzⁿ = rⁿ (cos nθ + i sin nθ)'),
    // Matrices
    _Formula('Matrices', '2×2',
        'det [[a,b],[c,d]] = ad−bc\nInverse = (1/det) [[d,−b],[−c,a]]'),
    _Formula('Matrices', 'Proprietes',
        'det(AB)=det(A)det(B)\n(AB)⁻¹ = B⁻¹ A⁻¹\ntr(A+B)=tr(A)+tr(B)'),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = formulas.where((f) {
      final catOk = _category == 'Tous' || f.category == _category;
      final q = _query.trim().toLowerCase();
      final qOk = q.isEmpty ||
          f.title.toLowerCase().contains(q) ||
          f.body.toLowerCase().contains(q) ||
          f.category.toLowerCase().contains(q);
      return catOk && qOk;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Bibliotheque mathematiques')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Rechercher une formule…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                  content: Text('Formule copiee')),
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
