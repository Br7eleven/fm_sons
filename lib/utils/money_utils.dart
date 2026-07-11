/// Normalizes a money value to avoid the "-0.00" display bug.
/// IEEE 754 subtraction can produce -0.0 when two equal values are subtracted.
/// Returns 0.0 when the value rounds to zero at the given precision.
double normalizeMoney(num value, {int precision = 2}) {
  if (value == 0) return 0.0; // catches exact 0 and -0.0
  // Also catch values that round to 0 at the given precision
  // e.g. 0.00001 with precision=2 → 0.0
  final threshold = 1.0 / (10 * precision);
  if (value.abs() < threshold) return 0.0;
  return value.toDouble();
}