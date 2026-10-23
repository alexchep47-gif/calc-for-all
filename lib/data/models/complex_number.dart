import 'dart:math' as math;
import '../services/math_library.dart';

/// Représentation d'un nombre complexe (a + bi)
class ComplexNumber {
  final double real;
  final double imag;

  const ComplexNumber(this.real, this.imag);

  factory ComplexNumber.real(double value) => ComplexNumber(value, 0);
  factory ComplexNumber.imaginary(double value) => ComplexNumber(0, value);
  static const zero = ComplexNumber(0, 0);

  double get modulus => math.sqrt(real * real + imag * imag);
  double get argument => math.atan2(imag, real);
  ComplexNumber get conjugate => ComplexNumber(real, -imag);

  ComplexNumber operator +(ComplexNumber other) =>
      ComplexNumber(real + other.real, imag + other.imag);
  ComplexNumber operator -(ComplexNumber other) =>
      ComplexNumber(real - other.real, imag - other.imag);
  ComplexNumber operator *(ComplexNumber other) => ComplexNumber(
        real * other.real - imag * other.imag,
        real * other.imag + imag * other.real,
      );
  ComplexNumber operator /(ComplexNumber other) {
    final denom = other.real * other.real + other.imag * other.imag;
    if (denom == 0) throw ArgumentError('Division par zéro complexe');
    return ComplexNumber(
      (real * other.real + imag * other.imag) / denom,
      (imag * other.real - real * other.imag) / denom,
    );
  }

  ComplexNumber pow(int n) {
    if (n == 0) return const ComplexNumber(1, 0);
    ComplexNumber result = this;
    for (int i = 1; i < n.abs(); i++) {
      result = result * this;
    }
    if (n < 0) return const ComplexNumber(1, 0) / result;
    return result;
  }

  @override
  String toString() {
    if (imag == 0) return _format(real);
    if (real == 0) {
      if (imag == 1) return 'i';
      if (imag == -1) return '-i';
      return '${_format(imag)}i';
    }
    final sign = imag > 0 ? '+' : '-';
    final absImag = imag.abs();
    final imagStr = absImag == 1 ? 'i' : '${_format(absImag)}i';
    return '${_format(real)} $sign $imagStr';
  }

  String _format(double v) => MathLibrary.format(v);

  /// Forme polaire : module et argument en fraction de π (ex. 3π/2)
  String toPolarString() {
    final mod = modulus;
    final arg = MathLibrary.formatArgAsPi(argument);
    return '${_format(mod)} (cos($arg) + i sin($arg))';
  }
}
