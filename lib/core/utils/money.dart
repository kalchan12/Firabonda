import 'package:intl/intl.dart';

/// Money is always stored as `int` cents (1 ETB = 100 cents).
/// This helper must be used for every money value in the app.
/// Never do floating point arithmetic on money.
final class Money {
  const Money._();

  static final NumberFormat _amountFormat = NumberFormat('#,##0.00', 'en_US');

  /// Formats cents as `ETB 1,250.00`.
  static String etb(int cents) => 'ETB ${_amountFormat.format(cents / 100)}';

  /// Formats cents as a plain localized number `1,250.00` (no currency).
  static String amount(int cents) => _amountFormat.format(cents / 100);

  /// Parses an amount like `1250`, `1 250.5`, `ETB 1,250.00` into cents.
  ///
  /// Throws [FormatException] when the input is not a valid non-negative
  /// number. Rounds to the nearest cent using decimal-safe parsing, never
  /// binary floating point. Formats like `1,250` (comma followed by exactly
  /// three digits) are treated as thousands separators, as in `ETB 1,250.00`.
  static int parseCents(String input) {
    final cleaned = input
        .replaceAll('ETB', '')
        .replaceAll(RegExp(r'[\s\u00a0]'), '')
        .replaceAll(RegExp(r'^-'), '');
    if (cleaned.isEmpty) {
      throw const FormatException('Empty money value');
    }

    var decimal = cleaned;
    if (cleaned.contains(',') && cleaned.contains('.')) {
      decimal = cleaned.replaceAll(',', '');
    } else if (cleaned.contains(',')) {
      final parts = cleaned.split(',');
      final afterComma = parts.last;
      final commaIsThousands =
          parts.length > 2 || (afterComma.length == 3 && parts.length == 2);
      decimal = commaIsThousands
          ? cleaned.replaceAll(',', '')
          : cleaned.replaceFirst(',', '.');
    }

    final match = RegExp(r'^(\d*)(?:\.(\d+))?$').firstMatch(decimal);
    if (match == null ||
        (decimal.isEmpty) ||
        (match.group(1) == null && match.group(2) == null) ||
        (match.group(2) == null && decimal == '')) {
      throw const FormatException('Not a valid money value');
    }
    final whole = (match.group(1) ?? '').padLeft(1, '0');
    var fraction = match.group(2) ?? '';
    if (fraction.length < 2) fraction = fraction.padRight(2, '0');
    final cents =
        int.parse(whole) * 100 +
        int.parse(fraction.substring(0, 2)) +
        _roundLastFractionDigit(fraction.substring(2));
    return cents;
  }

  static int _roundLastFractionDigit(String rest) {
    if (rest.isEmpty) return 0;
    return int.parse(rest[0]) >= 5 ? 1 : 0;
  }
}
