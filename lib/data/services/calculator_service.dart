import 'dart:math' as math;

import 'package:math_expressions/math_expressions.dart';

import 'math_library.dart';
import 'math_expression_engine.dart';

/// Service de calcul scientifique base sur la bibliotheque maths interne.
/// cos(pi), sin(pi/2), ln(e), etc. ne renvoient plus « Erreur ».
class CalculatorService {
  final MathExpressionEngine _engine = MathExpressionEngine();

  String evaluate(String expression) {
    if (expression.trim().isEmpty) return '0';

    // 1) Moteur interne (prioritaire)
    final internal = _evaluateInternal(expression);
    if (internal != null) return MathLibrary.format(internal);

    // 2) Fallback math_expressions avec pi et e lies
    final fallback = _evaluateMathExpressions(expression);
    if (fallback != null) return MathLibrary.format(fallback);

    return 'Expression invalide';
  }

  double? _evaluateInternal(String expression) {
    try {
      // Pour la calculatrice, pas de variable x : on evalue en x=0
      // apres avoir remplace les constantes.
      final normalized = MathLibrary.normalizeExpression(expression);
      // Si l'expression contient encore x libre, on refuse ici
      // (sauf si c'est dans un nom de fonction deja normalise).
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

      // math_expressions utilise souvent log pour ln ; on garde ln/log
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
