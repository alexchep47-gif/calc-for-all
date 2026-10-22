import '../models/complex_number.dart';
import 'math_library.dart';

/// Service pour les opérations sur nombres complexes
class ComplexService {
  /// Parse une chaîne du type "3+4i" ou "-2.5-1.2i"
  ComplexNumber? parse(String input) {
    try {
      input = input.replaceAll(' ', '').toLowerCase();
      if (input.isEmpty) return null;

      // Cas purement réel
      if (!input.contains('i')) {
        return ComplexNumber.real(double.parse(input));
      }

      // Cas purement imaginaire : 5i, -3i, i, -i
      if (RegExp(r'^[+-]?(\d*\.?\d*)?i$').hasMatch(input)) {
        String numPart = input.replaceAll('i', '');
        if (numPart.isEmpty || numPart == '+') return const ComplexNumber(0, 1);
        if (numPart == '-') return const ComplexNumber(0, -1);
        return ComplexNumber(0, double.parse(numPart));
      }

      // Forme a+bi ou a-bi
      final match =
          RegExp(r'^([+-]?\d*\.?\d+)([+-]\d*\.?\d*)i$').firstMatch(input);
      if (match != null) {
        double real = double.parse(match.group(1)!);
        String imagStr = match.group(2)!;
        if (imagStr == '+' || imagStr == '-') imagStr += '1';
        double imag = double.parse(imagStr);
        return ComplexNumber(real, imag);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  ComplexNumber add(ComplexNumber a, ComplexNumber b) => a + b;
  ComplexNumber subtract(ComplexNumber a, ComplexNumber b) => a - b;
  ComplexNumber multiply(ComplexNumber a, ComplexNumber b) => a * b;
  ComplexNumber divide(ComplexNumber a, ComplexNumber b) => a / b;

  String modulus(ComplexNumber c) => MathLibrary.format(c.modulus);
  String argument(ComplexNumber c) =>
      MathLibrary.format(c.argument * 180 / 3.1415926535) + '°';
  ComplexNumber conjugate(ComplexNumber c) => c.conjugate;
}
