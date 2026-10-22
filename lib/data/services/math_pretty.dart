/// Affichage mathematique naturel (pretty-print) hors-ligne.
/// Transforme 3*(x^2)-3  en  3x² − 3
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

  /// Formate une expression pour l'affichage (pas pour l'evaluation).
  static String format(String raw) {
    if (raw.trim().isEmpty) return raw;
    var s = raw.trim();

    s = s.replaceAll('×', '*').replaceAll('÷', '/');
    s = _powersToSuperscript(s);
    s = _stripMultiplications(s);

    s = s.replaceAllMapped(RegExp(r'\blog\('), (_) => 'ln(');

    s = s.replaceAll('pi', 'π');
    s = s.replaceAll('Pi', 'π');
    s = s.replaceAll('PI', 'π');

    s = s.replaceAllMapped(
      RegExp(r'sqrt\(([^()]+)\)'),
      (m) => '√(${m[1]})',
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

    out = out.replaceAllMapped(
      RegExp(r'\(([^()]+)\)\^(\d+)'),
      (m) => '(${m[1]})${_toSup(m[2]!)}',
    );

    out = out.replaceAllMapped(
      RegExp(r'([a-zA-Z]\w*|\d+(?:\.\d+)?)\^(\d+)'),
      (m) => '${m[1]}${_toSup(m[2]!)}',
    );

    out = out.replaceAllMapped(
      RegExp(r'\^([a-zA-Z])\b'),
      (m) => _sup[m[1]!] ?? ('^${m[1]}'),
    );

    out = out.replaceAllMapped(
      RegExp(r'\^\(([-+]?\d+)\)'),
      (m) => _toSup(m[1]!),
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

  static String _stripMultiplications(String s) {
    var out = s;

    out = out.replaceAllMapped(
      RegExp(r'(\d+(?:\.\d+)?)\s*\*\s*([a-zA-Z(])'),
      (m) => '${m[1]}${m[2]}',
    );

    out = out.replaceAll(RegExp(r'\)\s*\*\s*\('), ')(');

    out = out.replaceAllMapped(
      RegExp(r'\)\s*\*\s*([a-zA-Z])'),
      (m) => ')${m[1]}',
    );

    out = out.replaceAllMapped(
      RegExp(r'\b([a-zA-Z])\s*\*\s*([a-zA-Z])\b'),
      (m) {
        if (m[1]!.length == 1 && m[2]!.length == 1) {
          return '${m[1]}${m[2]}';
        }
        return m[0]!;
      },
    );

    out = out.replaceAllMapped(
      RegExp(r'\b([a-zA-Z])\s*\*\s*\('),
      (m) => '${m[1]}(',
    );

    out = out.replaceAll('*', '·');

    return out;
  }

  static String functionLine(String expr) => 'f(x) = ${format(expr)}';

  static String derivativeLine(String expr) => 'f′(x) = ${format(expr)}';

  static String secondDerivativeLine(String expr) =>
      'f″(x) = ${format(expr)}';
}
