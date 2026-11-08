import 'package:flutter_riverpod/flutter_riverpod.dart';

final class CalculationHistoryItem {
  const CalculationHistoryItem({
    required this.expression,
    required this.result,
    required this.timestamp,
  });

  final String expression;
  final String result;
  final DateTime timestamp;
}

final class CalculatorHistoryNotifier
    extends Notifier<List<CalculationHistoryItem>> {
  @override
  List<CalculationHistoryItem> build() => const [];

  void addEntry(String expression, String result) {
    if (expression.trim().isEmpty || result.trim().isEmpty) return;
    final item = CalculationHistoryItem(
      expression: expression.trim(),
      result: result.trim(),
      timestamp: DateTime.now(),
    );
    // Keep max 20 entries, newest first
    state = [item, ...state.take(19)];
  }

  void clear() {
    state = const [];
  }
}

final calculatorHistoryProvider =
    NotifierProvider<CalculatorHistoryNotifier, List<CalculationHistoryItem>>(
      CalculatorHistoryNotifier.new,
    );
