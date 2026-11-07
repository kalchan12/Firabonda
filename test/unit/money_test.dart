import 'package:flutter_test/flutter_test.dart';

import 'package:firabonda/core/utils/money.dart';

void main() {
  group('Money.etb', () {
    test('formats zero', () {
      expect(Money.etb(0), 'ETB 0.00');
    });

    test('formats large numbers with grouping', () {
      expect(Money.etb(125000), 'ETB 1,250.00');
      expect(Money.etb(125000999), 'ETB 1,250,009.99');
    });

    test('formats small fractional values', () {
      expect(Money.etb(5), 'ETB 0.05');
    });
  });

  group('Money.parseCents', () {
    test('parses plain integers', () {
      expect(Money.parseCents('1250'), 125000);
    });

    test('parses decimals', () {
      expect(Money.parseCents('1250.5'), 125050);
      expect(Money.parseCents('1250.75'), 125075);
    });

    test('parses formatted values', () {
      expect(Money.parseCents('ETB 1,250.00'), 125000);
      expect(Money.parseCents('1 250,50'), 125050);
    });

    test('rounds thirds to nearest cent without float error', () {
      expect(Money.parseCents('0.1'), 10);
      expect(Money.parseCents('10.003'), 1000);
      expect(Money.parseCents('10.005'), 1001);
      expect(Money.parseCents('10.006'), 1000 + 1);
    });

    test('rejects empty and malformed input', () {
      expect(() => Money.parseCents(''), throwsFormatException);
      expect(() => Money.parseCents('12.34.56'), throwsFormatException);
      expect(() => Money.parseCents('abc'), throwsFormatException);
    });
  });

  group('Money.amount', () {
    test('formats without currency symbol', () {
      expect(Money.amount(125000), '1,250.00');
    });
  });
}
