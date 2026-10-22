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
    _Formula('Algebre', 'Identites remarquables',
        '(a+b)^2 = a^2 + 2ab + b^2\n(a-b)^2 = a^2 - 2ab + b^2\na^2 - b^2 = (a-b)(a+b)'),
    _Formula('Algebre', 'Equation du second degre',
        'ax^2 + bx + c = 0\nDelta = b^2 - 4ac\nx = (-b +/- sqrt(Delta)) / (2a)'),
    _Formula('Algebre', 'Somme et produit des racines',
        'Si x1, x2 racines de ax^2+bx+c=0\nx1+x2 = -b/a\nx1*x2 = c/a'),
    _Formula('Algebre', 'Factorielle / binome',
        'n! = 1*2*...*n\nC(n,k) = n! / (k!(n-k)!)\n(a+b)^n = somme C(n,k) a^(n-k) b^k'),
    _Formula('Analyse', 'Derivees usuelles',
        "(x^n)' = n x^(n-1)\n(ln x)' = 1/x\n(e^x)' = e^x\n(sin x)' = cos x\n(cos x)' = -sin x\n(tan x)' = 1/cos^2(x)"),
    _Formula('Analyse', 'Regles de derivation',
        "(u+v)' = u'+v'\n(uv)' = u'v + uv'\n(u/v)' = (u'v - uv')/v^2\n(u o v)' = (u' o v) * v'"),
    _Formula('Analyse', 'Integrales usuelles',
        'int x^n dx = x^(n+1)/(n+1) + C (n != -1)\nint 1/x dx = ln|x| + C\nint e^x dx = e^x + C\nint sin x dx = -cos x + C\nint cos x dx = sin x + C'),
    _Formula('Analyse', 'Limites classiques',
        'lim x->0 sin(x)/x = 1\nlim x->0 (1-cos x)/x^2 = 1/2\nlim x->inf (1+1/x)^x = e\nlim x->0 ln(1+x)/x = 1'),
    _Formula('Analyse', 'Asymptotes',
        'Verticale x=a si lim x->a f = +/-inf\nHorizontale y=L si lim x->+/-inf f = L\nOblique y=ax+b si lim (f-ax-b)=0'),
    _Formula('Trigonometrie', 'Valeurs remarquables',
        'sin(0)=0  cos(0)=1\nsin(pi/6)=1/2  cos(pi/6)=sqrt(3)/2\nsin(pi/4)=sqrt(2)/2  cos(pi/4)=sqrt(2)/2\nsin(pi/3)=sqrt(3)/2  cos(pi/3)=1/2\nsin(pi/2)=1  cos(pi/2)=0'),
    _Formula('Trigonometrie', 'Formules d addition',
        'cos(a+/-b) = cos a cos b -/+ sin a sin b\nsin(a+/-b) = sin a cos b +/- cos a sin b\ntan(a+/-b) = (tan a +/- tan b)/(1 -/+ tan a tan b)'),
    _Formula('Trigonometrie', 'Duplication',
        'cos 2a = cos^2 a - sin^2 a = 2cos^2 a - 1\nsin 2a = 2 sin a cos a\ntan 2a = 2 tan a / (1 - tan^2 a)'),
    _Formula('Trigonometrie', 'Pythagore trigonometrique',
        'cos^2 + sin^2 = 1\n1 + tan^2 = 1/cos^2\n1 + cot^2 = 1/sin^2'),
    _Formula('Geometrie', 'Pythagore / Thales',
        'Triangle rectangle : a^2 + b^2 = c^2\nThales : AD/AB = AE/AC = DE/BC'),
    _Formula('Geometrie', 'Aires',
        'Rectangle : L*l\nTriangle : (b*h)/2\nCercle : pi r^2'),
    _Formula('Geometrie', 'Volumes',
        'Cube : a^3\nSphere : (4/3) pi r^3\nCylindre : pi r^2 h\nCone : (1/3) pi r^2 h'),
    _Formula('Geometrie', 'Vecteurs',
        'u.v = |u||v| cos theta = ux*vx + uy*vy + uz*vz\n|u x v| = |u||v| sin theta'),
    _Formula('Probabilites', 'Denombrement',
        'Permutations : n!\nArrangements A(n,k) = n!/(n-k)!\nCombinaisons C(n,k) = n!/(k!(n-k)!)'),
    _Formula('Probabilites', 'Loi binomiale',
        'X ~ B(n,p)\nP(X=k) = C(n,k) p^k (1-p)^(n-k)\nE(X)=np  V(X)=np(1-p)'),
    _Formula('Probabilites', 'Loi normale',
        'X ~ N(mu, sigma^2)\nz = (x-mu)/sigma\nf(x) = 1/(sigma sqrt(2pi)) exp(-1/2 z^2)'),
    _Formula('Suites', 'Arithmetique',
        'u_n = u_0 + n r\nS_n = (n+1)(u_0+u_n)/2'),
    _Formula('Suites', 'Geometrique',
        'u_n = u_0 * q^n\nS_n = u_0 (1-q^(n+1))/(1-q)  (q != 1)'),
    _Formula('Complexes', 'Formes',
        'z = a + bi = r (cos theta + i sin theta) = r e^(i theta)\nr = |z| = sqrt(a^2+b^2)'),
    _Formula('Complexes', 'Operations',
        '(a+bi)(c+di) = (ac-bd)+(ad+bc)i\n1/z = conjugate(z) / |z|^2'),
    _Formula('Matrices', '2x2',
        'det [[a,b],[c,d]] = ad-bc\nInverse = (1/det) [[d,-b],[-c,a]]'),
    _Formula('Matrices', 'Proprietes',
        'det(AB)=det(A)det(B)\n(AB)^-1 = B^-1 A^-1'),
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
