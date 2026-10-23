import 'dart:math' as math;

import 'package:math_expressions/math_expressions.dart';

import 'math_library.dart';
import 'math_expression_engine.dart';

/// Service de calcul scientifique.
class CalculatorService {
  final MathExpressionEngine _engine = MathExpressionEngine();
  static const String mathError = 'Erreur mathématique';

  String nthRoot(double a, double n) {
    final r = _nthRoot(a, n);
    if (r == null) return mathError;
    return MathLibrary.format(r);
  }

  String evaluate(String expression) {
    if (expression.trim().isEmpty) return '0';

    var expr = expression.replaceAll(' ', '');

    final rootMatch = RegExp(
      r'root\s*\(\s*([^,]+)\s*,\s*([^)]+)\s*\)',
      caseSensitive: false,
    ).firstMatch(expr);
    if (rootMatch != null) {
      final a = _evalScalar(rootMatch.group(1)!);
      final n = _evalScalar(rootMatch.group(2)!);
      if (a != null && n != null) {
        final r = _nthRoot(a, n);
        return r != null ? MathLibrary.format(r) : mathError;
      }
      return mathError;
    }

    final cbrtMatch = RegExp(
      r'(?:cbrt|∛)\s*\(\s*([^)]+)\s*\)',
      caseSensitive: false,
    ).firstMatch(expr);
    if (cbrtMatch != null) {
      final a = _evalScalar(cbrtMatch.group(1)!);
      if (a != null) {
        final r = _nthRoot(a, 3);
        return r != null ? MathLibrary.format(r) : mathError;
      }
      return mathError;
    }

    final powRoot = RegExp(
      r'^([-+]?\d*\.?\d+(?:e[-+]?\d+)?)\^\(1\/([-+]?\d*\.?\d+)\)$',
      caseSensitive: false,
    ).firstMatch(expr);
    if (powRoot != null) {
      final a = _evalScalar(powRoot.group(1)!);
      final n = _evalScalar(powRoot.group(2)!);
      if (a != null && n != null) {
        final r = _nthRoot(a, n);
        return r != null ? MathLibrary.format(r) : mathError;
      }
      return mathError;
    }

    final internal = _evaluateInternal(expression);
    if (internal != null) return MathLibrary.format(internal);

    final fallback = _evaluateMathExpressions(expression);
    if (fallback != null) return MathLibrary.format(fallback);

    return mathError;
  }

  double? _evalScalar(String s) {
    final t = s.trim().replaceAll(',', '.');
    if (t == 'pi' || t == 'π') return math.pi;
    if (t == 'e') return math.e;
    return double.tryParse(t);
  }

  double? _nthRoot(double a, double n) {
    if (n == 0) return null;
    final nInt = n.round();
    final isInt = (n - nInt).abs() < 1e-9;
    if (a < 0) {
      if (isInt && nInt.isOdd) {
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
      if (value == null || value.isNaN || value.isInfinite) return null;
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
      final parsed = parser.parse(expr);
      final result = parsed.evaluate(EvaluationType.REAL, cm);
      if (result is num && result.isFinite) {
        return MathLibrary.clean(result.toDouble());
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
