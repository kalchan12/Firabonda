import 'package:flutter_test/flutter_test.dart';

import 'package:firabonda/core/utils/calculator.dart';

void main() {
  group('CalculatorEvaluator', () {
    test('evaluates plain numbers', () {
      expect(CalculatorEvaluator.evaluate('1250'), '1250');
      expect(CalculatorEvaluator.evaluate('12.5'), '12.5');
    });

    test('respects operator precedence', () {
      expect(CalculatorEvaluator.evaluate('2+3x4'), '14');
      expect(CalculatorEvaluator.evaluate('10-2x3'), '4');
      expect(CalculatorEvaluator.evaluate('100/5+5'), '25');
    });

    test('handles percent', () {
      expect(CalculatorEvaluator.evaluate('50%'), '0.5');
      expect(CalculatorEvaluator.evaluate('200x10%'), '20');
    });

    test('handles signed operands', () {
      expect(CalculatorEvaluator.evaluate('5-+3'), '2');
      expect(CalculatorEvaluator.evaluate('-3+8'), '5');
    });

    test('rounds thirds to cents', () {
      expect(CalculatorEvaluator.evaluate('10/3'), '3.33');
      expect(CalculatorEvaluator.evaluate('10/6'), '1.67');
    });

    test('rejects division by zero with a gentle message', () {
      expect(
        () => CalculatorEvaluator.evaluate('10/0'),
        throwsA(
          isA<CalculatorException>().having(
            (e) => e.message,
            'message',
            'Cannot divide by zero',
          ),
        ),
      );
    });

    test('rejects empty input', () {
      expect(
        () => CalculatorEvaluator.evaluate(''),
        throwsA(
          isA<CalculatorException>().having(
            (e) => e.message,
            'message',
            'Nothing to calculate',
          ),
        ),
      );
    });

    test('rejects malformed expressions without crashing', () {
      expect(
        () => CalculatorEvaluator.evaluate('12.+'),
        throwsA(isA<CalculatorException>()),
      );
      expect(
        () => CalculatorEvaluator.evaluate('5+'),
        throwsA(isA<CalculatorException>()),
      );
    });

    test('accepts common separators', () {
      expect(CalculatorEvaluator.evaluate('1,5x2'), '3');
      expect(CalculatorEvaluator.evaluate('ETB 100+50'), '150');
    });
  });
}
