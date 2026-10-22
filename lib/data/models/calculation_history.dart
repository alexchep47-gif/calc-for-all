/// Modèle pour l'historique des calculs (toutes rubriques)
class CalculationHistory {
  final String expression;
  final String result;
  final DateTime timestamp;
  /// Module d'origine : Calculatrice, Graphique, Matrices, Complexes, Suites…
  final String module;

  CalculationHistory({
    required this.expression,
    required this.result,
    required this.timestamp,
    this.module = 'Calculatrice',
  });

  Map<String, dynamic> toJson() => {
        'expression': expression,
        'result': result,
        'timestamp': timestamp.toIso8601String(),
        'module': module,
      };

  factory CalculationHistory.fromJson(Map<String, dynamic> json) {
    return CalculationHistory(
      expression: json['expression'] as String,
      result: json['result'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      module: (json['module'] as String?) ?? 'Calculatrice',
    );
  }
}
