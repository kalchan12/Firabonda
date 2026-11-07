/// Decimal-aware evaluator for the mini calculator expressions.
///
/// Grammar (postfix percent, standard precedence):
///   expression := term (('+' | '-') term)*
///   term       := factor (('x' | '/') factor)*
///   factor     := number '%'? | '-' factor | '+' factor
///
/// The calculator evaluates with decimal-safe logic and returns a plain
/// decimal string that can be written back into a money field.
library;

final class CalculatorException implements Exception {
  const CalculatorException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class CalculatorEvaluator {
  const CalculatorEvaluator._();

  static final RegExp _tokenizer = RegExp(r'\d+(?:\.\d+)?|[-+x/%]');

  /// Evaluates `input` and returns the result as a decimal literal
  /// string, safe to put back into a money field.
  ///
  /// Throws [CalculatorException] for invalid input (never crashes).
  static String evaluate(String input) {
    final cleaned = input
        .replaceAll('ETB', '')
        .replaceAll(RegExp(r'[\s\u00a0]'), '')
        .replaceAll(',', '.')
        .replaceAll('×', 'x')
        .replaceAll('÷', '/');
    if (cleaned.isEmpty) {
      throw const CalculatorException('Nothing to calculate');
    }
    if (!RegExp(r'^[\d.+\-x/%]+$').hasMatch(cleaned)) {
      throw const CalculatorException('Invalid expression');
    }
    final tokens = _tokenizer.allMatches(cleaned).map((m) => m[0]!).toList();
    if (tokens.isEmpty) {
      throw const CalculatorException('Nothing to calculate');
    }
    final parser = _Parser(tokens);
    final result = parser.expression();
    if (!parser.isAtEnd) {
      throw const CalculatorException('Invalid expression');
    }
    return _formatResult(result);
  }

  static String _formatResult(double value) {
    if (value.isInfinite || value.isNaN) {
      throw const CalculatorException('Invalid expression');
    }
    final rounded = (value * 100).roundToDouble() / 100;
    var text = rounded.toStringAsFixed(2);
    if (text.endsWith('.00')) {
      text = text.substring(0, text.length - 3);
    } else if (text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }
}

/// Recursive-descent parser over the token list.
final class _Parser {
  _Parser(this._tokens);

  final List<String> _tokens;
  int _pos = 0;

  bool get isAtEnd => _pos == _tokens.length;

  double expression() {
    var value = term();
    while (_isNewOperator('+', '-')) {
      final op = _tokens[_pos++];
      final rhs = term();
      value = op == '+' ? value + rhs : value - rhs;
    }
    return value;
  }

  double term() {
    var value = factor();
    while (_isNewOperator('x', '/')) {
      final op = _tokens[_pos++];
      final rhs = factor();
      if (op == '/') {
        if (rhs == 0) {
          throw const CalculatorException('Cannot divide by zero');
        }
        value = value / rhs;
      } else {
        value = value * rhs;
      }
    }
    return value;
  }

  double factor() {
    if (_pos >= _tokens.length) {
      throw const CalculatorException('Invalid expression');
    }
    var negative = false;
    if (_tokens[_pos] == '-' || _tokens[_pos] == '+') {
      negative = _tokens[_pos] == '-';
      _pos++;
      if (_pos >= _tokens.length || double.tryParse(_tokens[_pos]) == null) {
        throw const CalculatorException('Invalid expression');
      }
    }
    final number = double.tryParse(_tokens[_pos]);
    if (number == null) {
      throw const CalculatorException('Invalid expression');
    }
    _pos++;
    var value = number;
    if (negative) value = -value;
    while (_pos < _tokens.length && _tokens[_pos] == '%') {
      _pos++;
      value = value / 100;
    }
    return value;
  }

  bool _isNewOperator(String first, String second) {
    if (_pos >= _tokens.length) return false;
    final token = _tokens[_pos];
    return token == first || token == second;
  }
}
