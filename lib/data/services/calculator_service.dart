import 'dart:math' as math;

import 'package:math_expressions/math_expressions.dart';

import 'math_library.dart';
import 'math_expression_engine.dart';

/// Service de calcul scientifique base sur la bibliotheque maths interne.
class CalculatorService {
  final MathExpressionEngine _engine = MathExpressionEngine();

  String evaluate(String expression) {
    if (expression.trim().isEmpty) return '0';

    // Racine n-ieme : root(a,n) ou ⁿ√(a,n)
    final rootMatch = RegExp(
      r'root\s*\(\s*([^,]+)\s*,\s*([^)]+)\s*\)',
      caseSensitive: false,
    ).firstMatch(expression.replaceAll(' ', ''));
    if (rootMatch != null) {
      final a = _evalScalar(rootMatch.group(1)!);
      final n = _evalScalar(rootMatch.group(2)!);
      if (a != null && n != null && n != 0) {
        final r = _nthRoot(a, n);
        if (r != null) return MathLibrary.format(r);
        return 'Indéfini';
      }
    }

    final internal = _evaluateInternal(expression);
    if (internal != null) return MathLibrary.format(internal);

    final fallback = _evaluateMathExpressions(expression);
    if (fallback != null) return MathLibrary.format(fallback);

    return 'Expression invalide';
  }

  double? _evalScalar(String s) {
    final t = s.trim();
    if (t == 'pi' || t == 'π') return math.pi;
    if (t == 'e') return math.e;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  /// Racine n-ième réelle : a^(1/n)
  double? _nthRoot(double a, double n) {
    if (n == 0) return null;
    // n entier impair : racine de négatif OK
    final nInt = n.round();
    final isInt = (n - nInt).abs() < 1e-9;
    if (a < 0) {
      if (isInt && nInt % 2 == 1) {
        return -math.pow(-a, 1 / n).toDouble();
      }
      return null;
    }
    if (a == 0) return 0;
    return math.pow(a, 1 / n).toDouble();
  }

  double? _evaluateInternal(String expression) {
    try {
      final normalized = MathLibrary.normalizeExpression(expression);
      final value = _engine.evaluate(normalized, 0);
      if (value == null || value.isNaN) return null;
      return MathLibrary.clean(value);
    } catch (_) {
      return null;
    }
  }

  double? _evaluateMathExpressions(String expression) {
    try {
      var expr = MathLibrary.normalizeExpression(expression);
      final parser = Parser();
      final cm = ContextModel();
      cm.bindVariable(Variable('pi'), Number(math.pi));
      cm.bindVariable(Variable('e'), Number(math.e));
      cm.bindVariable(Variable('tau'), Number(2 * math.pi));
      final exp = parser.parse(expr);
      final result = exp.evaluate(EvaluationType.REAL, cm) as double;
      if (result.isNaN) return null;
      return MathLibrary.clean(result);
    } catch (_) {
      return null;
    }
  }
}
