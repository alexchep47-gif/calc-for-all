/// Affichage mathématique naturel — sans * ni ^
/// Ex. 3*(x^2)-3  →  3x² − 3
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

  /// Formate pour l'affichage uniquement (pas pour l'évaluation).
  static String format(String raw) {
    if (raw.trim().isEmpty) return raw;
    var s = raw.trim();

    s = s.replaceAll('×', '*').replaceAll('÷', '/');

    // Puissances → exposants Unicode
    s = _powersToSuperscript(s);

    // Multiplications explicites → implicites (aucun * restant)
    s = _stripMultiplications(s);

    // Nettoyage final : plus aucun * ni ^
    s = s.replaceAll('*', '');
    s = s.replaceAll('^', '');

    s = s.replaceAllMapped(RegExp(r'\blog\('), (_) => 'ln(');
    s = s.replaceAll('pi', 'π');
    s = s.replaceAll('Pi', 'π');
    s = s.replaceAll('PI', 'π');

    s = s.replaceAllMapped(
      RegExp(r'sqrt\(([^()]+)\)'),
      (m) => '√(${m[1]})',
    );
    s = s.replaceAllMapped(
      RegExp(r'cbrt\(([^()]+)\)'),
      (m) => '∛(${m[1]})',
    );

    s = s.replaceAll('-', '−');
    s = s.replaceAllMapped(RegExp(r'\s*\+\s*'), (_) => ' + ');
    s = s.replaceAllMapped(RegExp(r'\s*−\s*'), (_) => ' − ');
    s = s.replaceAll('( − ', '(−');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    s = s.replaceAll(' + − ', ' − ');

    return s;
  }

  static String _powersToSuperscript(String s) {
    var out = s;

    // (expr)^(n) ou (expr)^n
    out = out.replaceAllMapped(
      RegExp(r'\(([^()]+)\)\^\(([^()]+)\)'),
      (m) => '(${m[1]})${_toSupSafe(m[2]!)}',
    );
    out = out.replaceAllMapped(
      RegExp(r'\(([^()]+)\)\^(\d+)'),
      (m) => '(${m[1]})${_toSup(m[2]!)}',
    );

    // x^2, sin(x)^2, 10^3
    out = out.replaceAllMapped(
      RegExp(r'([a-zA-Z]\w*|\d+(?:\.\d+)?)\^(\d+)'),
      (m) => '${m[1]}${_toSup(m[2]!)}',
    );

    // x^(2), a^(-1)
    out = out.replaceAllMapped(
      RegExp(r'([a-zA-Z]\w*|\d+(?:\.\d+)?)\^\(([-+]?\d+)\)'),
      (m) => '${m[1]}${_toSup(m[2]!)}',
    );

    // x^n, x^y
    out = out.replaceAllMapped(
      RegExp(r'\^([a-zA-Z])\b'),
      (m) => _sup[m[1]!] ?? m[1]!,
    );

    // ^(1/2) etc. → ⁽¹ᐟ²⁾ approximation
    out = out.replaceAllMapped(
      RegExp(r'\^\(([^()]+)\)'),
      (m) => '⁽${_toSupSafe(m[1]!)}⁾',
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

  static String _toSupSafe(String s) {
    final buf = StringBuffer();
    for (final c in s.split('')) {
      if (_sup.containsKey(c)) {
        buf.write(_sup[c]);
      } else if (c == '/') {
        buf.write('ᐟ');
      } else {
        buf.write(c);
      }
    }
    return buf.toString();
  }

  static String _stripMultiplications(String s) {
    var out = s;

    // 3*x → 3x, 2*( → 2(
    out = out.replaceAllMapped(
      RegExp(r'(\d+(?:\.\d+)?)\s*\*\s*([a-zA-Z(])'),
      (m) => '${m[1]}${m[2]}',
    );

    // )*(
    out = out.replaceAll(RegExp(r'\)\s*\*\s*\('), ')(');

    // )*x
    out = out.replaceAllMapped(
      RegExp(r'\)\s*\*\s*([a-zA-Z])'),
      (m) => ')${m[1]}',
    );

    // x*y (variables simples)
    out = out.replaceAllMapped(
      RegExp(r'\b([a-zA-Z])\s*\*\s*([a-zA-Z])\b'),
      (m) => '${m[1]}${m[2]}',
    );

    // x*(
    out = out.replaceAllMapped(
      RegExp(r'\b([a-zA-Z])\s*\*\s*\('),
      (m) => '${m[1]}(',
    );

    // 2*3 reste 2×3 pour lisibilité numérique
    out = out.replaceAllMapped(
      RegExp(r'(\d+(?:\.\d+)?)\s*\*\s*(\d+(?:\.\d+)?)'),
      (m) => '${m[1]}×${m[2]}',
    );

    return out;
  }

  static String functionLine(String expr) => 'f(x) = ${format(expr)}';

  static String derivativeLine(String expr) => 'f′(x) = ${format(expr)}';

  static String secondDerivativeLine(String expr) =>
      'f″(x) = ${format(expr)}';
}
