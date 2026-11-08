import 'package:firabonda/features/calculator/application/calculator_history.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Step 9: Calculator History tests', () {
    test('logs calculation expressions and results up to 20 entries newest first', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(calculatorHistoryProvider.notifier);

      expect(container.read(calculatorHistoryProvider), isEmpty);

      // Add 25 calculations
      for (var i = 1; i <= 25; i++) {
        notifier.addEntry('$i + 10', '${i + 10}');
      }

      final history = container.read(calculatorHistoryProvider);
      expect(history.length, 20); // capped at 20

      // Newest calculation first (25 + 10 = 35)
      expect(history.first.expression, '25 + 10');
      expect(history.first.result, '35');

      // Oldest retained is 6 + 10 = 16
      expect(history.last.expression, '6 + 10');
      expect(history.last.result, '16');

      // Clear history
      notifier.clear();
      expect(container.read(calculatorHistoryProvider), isEmpty);
    });
  });
}
