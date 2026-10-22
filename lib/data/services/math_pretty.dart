/// Affichage mathématique "naturel" (pretty-print) hors-ligne.
/// Transforme 3*(x^2)-3  →  3x² − 3
class MathPretty {
  MathPretty._();

  static const _sup = {
    '0': '⁰',
    '1': '¹',
    '2': '²',
    '3': '³',
    '4': '⁴',
    '5': '⁵',
    '6': '⁶',
    '7': '⁷',
    '8': '⁸',
    '9': '⁹',
    '+': '⁺',
    '-': '⁻',
    'n': 'ⁿ',
    'x': 'ˣ',
    'y': 'ʸ',
    'i': 'ⁱ',
  };

  /// Formate une expression pour l'affichage (pas pour l'évaluation).
  static String format(String raw) {
    if (raw.trim().isEmpty) return raw;
    var s = raw.trim();

    // Normaliser opérateurs unicode éventuels
    s = s.replaceAll('×', '*').replaceAll('÷', '/');

    // Espaces autour des + - (pas unary)
    // D'abord gérer les puissances a^b → aᵇ
    s = _powersToSuperscript(s);

    // Supprimer multiplications explicites inutiles
    s = _stripMultiplications(s);

    // Fonctions usuelles en italique-like (on garde le nom)
    s = s.replaceAll('log(', 'ln('); // affichage fr
    // Ne pas toucher si déjà ln

    // Opérateurs jolis
    s = s.replaceAll('-', '−'); // minus typographique
    s = s.replaceAll('+', ' + ');
    s = s.replaceAll('−', ' − ');
    // Nettoyer doubles espaces et unary
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    s = s.replaceAll('( − ', '(−');
    s = s.replaceAll(' + − ', ' − ');

    // pi, e
    s = s.replaceAll('pi', 'π');
    s = s.replaceAll('Pi', 'π');
    s = s.replaceAll('PI', 'π');

    // sqrt(...)
    s = s.replaceAllMapped(
      RegExp(r'sqrt\(([^()]+)\)'),
      (m) => '√(${m[1]})',
    );

    return s;
  }

  /// Convertit ^ en exposants Unicode quand c'est simple.
  static String _powersToSuperscript(String s) {
    // x^2, x^10, (x+1)^2, 2^n
    // Pattern: base^exposant où exposant est nombre ou variable courte
    var out = s;

    // (expr)^n
    out = out.replaceAllMapped(
      RegExp(r'\(([^()]+)\)\^(\d+)'),
      (m) => '(${m[1]})${_toSup(m[2]!)}',
    );

    // ident^n  (x^2, sin(x) already handled separately)
    out = out.replaceAllMapped(
      RegExp(r'([a-zA-Z]\w*|\d+(?:\.\d+)?)\^(\d+)'),
      (m) => '${m[1]}${_toSup(m[2]!)}',
    );

    // reste: a^b avec b symbolique court → aᵇ si possible
    out = out.replaceAllMapped(
      RegExp(r'\^([a-zA-Z])\b'),
      (m) => _sup[m[1]!] ?? '^(${m[1]})',
    );

    // Nettoyer ^ restants simples
    out = out.replaceAllMapped(
      RegExp(r'\^\(([^()]+)\)'),
      (m) {
        final inner = m[1]!;
        if (RegExp(r'^[\d+-]+\$').hasMatch(inner)) {
          return _toSup(inner);
        }
        return '^(${inner})';
      },
    );

    return out;
  }

  static String _toSup(String digits) {
    final buf = StringBuffer();
    for (final c in digits.split('')) {
      buf.write(_sup[c] ?? c);
    }
    return buf.toString();
  }

  /// 3*x → 3x, 2*(x+1) → 2(x+1), x*y → xy
  static String _stripMultiplications(String s) {
    var out = s;

    // chiffre * variable/fonction/parenthèse
    out = out.replaceAllMapped(
      RegExp(r'(\d+(?:\.\d+)?)\s*\*\s*([a-zA-Z(])'),
      (m) => '${m[1]}${m[2]}',
    );

    // ) * (
    out = out.replaceAllMapped(
      RegExp(r'\)\s*\*\s*\('),
      (_) => ')(',
    );

    // ) * variable
    out = out.replaceAllMapped(
      RegExp(r'\)\s*\*\s*([a-zA-Z])'),
      (m) => ')${m[1]}',
    );

    // variable * variable (pas fonction: sin*x est rare)
    out = out.replaceAllMapped(
      RegExp(r'\b([a-zA-Z])\s*\*\s*([a-zA-Z])\b'),
      (m) {
        // Eviter de coller des noms de fonctions
        const funcs = {
          'sin',
          'cos',
          'tan',
          'ln',
          'log',
          'exp',
          'abs',
          'sqrt'
        };
        // simple single letter only
        if (m[1]!.length == 1 && m[2]!.length == 1) {
          return '${m[1]}${m[2]}';
        }
        return m[0]!;
      },
    );

    // variable * (
    out = out.replaceAllMapped(
      RegExp(r'\b([a-zA-Z])\s*\*\s*\('),
      (m) => '${m[1]}(',
    );

    // * restants → espace fin (cas ambigus)
    out = out.replaceAll('*', '·');

    return out;
  }

  /// Pour titres : f(x) = …
  static String functionLine(String expr) => 'f(x) = ${format(expr)}';

  /// Dérivée : f′(x) = …
  static String derivativeLine(String expr) => "f′(x) = ${format(expr)}";

  /// Seconde dérivée
  static String secondDerivativeLine(String expr) =>
      "f″(x) = ${format(expr)}";
}
