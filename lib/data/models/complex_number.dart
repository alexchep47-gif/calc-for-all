import 'dart:math' as math;
import '../services/math_library.dart';

/// Représentation d'un nombre complexe (a + bi)
class ComplexNumber {
  final double real;
  final double imag;

  const ComplexNumber(this.real, this.imag);

  /// Nombre réel pur
  factory ComplexNumber.real(double value) => ComplexNumber(value, 0);

  /// Nombre imaginaire pur
  factory ComplexNumber.imaginary(double value) => ComplexNumber(0, value);

  /// Zéro
  static const zero = ComplexNumber(0, 0);

  /// Module (valeur absolue)
  double get modulus => math.sqrt(real * real + imag * imag);

  /// Argument (phase) en radians
  double get argument => math.atan2(imag, real);

  /// Conjugué
  ComplexNumber get conjugate => ComplexNumber(real, -imag);

  /// Addition
  ComplexNumber operator +(ComplexNumber other) =>
      ComplexNumber(real + other.real, imag + other.imag);

  /// Soustraction
  ComplexNumber operator -(ComplexNumber other) =>
      ComplexNumber(real - other.real, imag - other.imag);

  /// Multiplication
  ComplexNumber operator *(ComplexNumber other) {
    return ComplexNumber(
      real * other.real - imag * other.imag,
      real * other.imag + imag * other.real,
    );
  }

  /// Division
  ComplexNumber operator /(ComplexNumber other) {
    final denom = other.real * other.real + other.imag * other.imag;
    if (denom == 0) throw ArgumentError('Division par zéro complexe');
    return ComplexNumber(
      (real * other.real + imag * other.imag) / denom,
      (imag * other.real - real * other.imag) / denom,
    );
  }

  /// Puissance entière simple
  ComplexNumber pow(int n) {
    if (n == 0) return const ComplexNumber(1, 0);
    ComplexNumber result = this;
    for (int i = 1; i < n.abs(); i++) {
      result = result * this;
    }
    if (n < 0) {
      return const ComplexNumber(1, 0) / result;
    }
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

  String _format(double v) {
    return MathLibrary.format(v);
  }

  /// Forme polaire : (module, argument en degrés)
  String toPolarString() {
    final mod = modulus;
    final argDeg = argument * 180 / math.pi;
    return '${_format(mod)} ∠ ${_format(argDeg)}°';
  }
}
