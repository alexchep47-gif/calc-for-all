import 'dart:math' as math;

import '../models/complex_number.dart';
import 'math_library.dart';

/// Service for complex numbers.
class ComplexService {
  ComplexNumber? parse(String input) {
    try {
      input = input.replaceAll(' ', '').replaceAll(',', '.').toLowerCase();
      if (input.isEmpty) return null;

      if (!input.contains('i')) {
        return ComplexNumber.real(double.parse(input));
      }

      if (RegExp(r'^[+-]?((\d*\.?\d+)|\.)?i$').hasMatch(input)) {
        String numPart = input.replaceAll('i', '');
        if (numPart.isEmpty || numPart == '+') return const ComplexNumber(0, 1);
        if (numPart == '-') return const ComplexNumber(0, -1);
        return ComplexNumber(0, double.parse(numPart));
      }

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

  List<ComplexNumber> nthRoots(ComplexNumber z, int n) {
    if (n <= 0) {
      throw ArgumentError('n must be a positive integer.');
    }

    if (z.real == 0 && z.imag == 0) {
      return List.generate(n, (_) => const ComplexNumber(0, 0));
    }

    final r = z.modulus;
    final theta = z.argument;
    final radius = math.pow(r, 1 / n).toDouble();
    final roots = <ComplexNumber>[];

    for (var k = 0; k < n; k++) {
      final angle = (theta + 2 * math.pi * k) / n;
      final real = radius * math.cos(angle);
      final imag = radius * math.sin(angle);
      roots.add(ComplexNumber(real, imag));
    }

    return roots;
  }

  String modulus(ComplexNumber c) => MathLibrary.format(c.modulus);
  String argument(ComplexNumber c) =>
      MathLibrary.format(c.argument * 180 / math.pi) + '°';
  ComplexNumber conjugate(ComplexNumber c) => c.conjugate;
}

