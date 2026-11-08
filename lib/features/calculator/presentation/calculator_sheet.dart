import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/calculator.dart';
import '../application/calculator_history.dart';

/// Result of the mini calculator sheet. `used` is true when the owner
/// tapped "Use result" and `value` holds the evaluated decimal literal.
final class CalculatorResult {
  const CalculatorResult({required this.used, required this.value});

  final bool used;
  final String value;
}

/// Bottom-sheet calculator per `files/DESIGN.md` section 7.1 and Step 9.
///
/// Starts with the field's current value; "Use result" writes the value
/// back into the field and closes the sheet.
Future<CalculatorResult?> showCalculatorSheet(
  BuildContext context,
  String initialText, {
  int? quantity,
}) {
  return showModalBottomSheet<CalculatorResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        CalculatorSheet(initialText: initialText, quantity: quantity),
  );
}

final class CalculatorSheet extends ConsumerStatefulWidget {
  const CalculatorSheet({super.key, required this.initialText, this.quantity});

  final String initialText;
  final int? quantity;

  @override
  ConsumerState<CalculatorSheet> createState() => _CalculatorSheetState();
}

final class _CalculatorSheetState extends ConsumerState<CalculatorSheet> {
  late final List<List<String?>> _rows;

  late String _expression;
  String? _error;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    final qty = widget.quantity;
    final qtyKey = (qty != null && qty > 1) ? '$qty×' : null;
    _rows = [
      ['C', '⌫', '%', '÷'],
      ['7', '8', '9', '−'],
      ['4', '5', '6', '+'],
      ['1', '2', '3', '×'],
      ['0', '.', '=', qtyKey],
    ];
    final trimmed = widget.initialText.trim();
    _expression = trimmed.replaceAll('ETB', '').trim();
  }

  void _onKey(String key) {
    setState(() {
      _error = null;
      if (key.endsWith('×') && key != '×') {
        // e.g. "5×" quick multiplier shortcut
        if (_expression.isEmpty) {
          _expression = key;
        } else if (!_expression.contains('×')) {
          _expression = '$key$_expression';
        } else {
          _expression = _expression + key;
        }
        return;
      }
      switch (key) {
        case 'C':
          _expression = '';
        case '⌫':
          if (_expression.isNotEmpty) {
            _expression = _expression.substring(0, _expression.length - 1);
          }
        case '=':
          _evaluateAndLog();
        default:
          _expression = _expression + key;
      }
    });
  }

  void _evaluateAndLog() {
    if (_expression.trim().isEmpty) return;
    try {
      final exprToLog = _expression;
      final value = CalculatorEvaluator.evaluate(_expression);
      _expression = value;
      // Record in history (max 20 entries)
      ref.read(calculatorHistoryProvider.notifier).addEntry(exprToLog, value);
    } on CalculatorException catch (error) {
      _error = error.message;
    }
  }

  Future<void> _copyResult() async {
    if (_expression.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _expression.trim()));
    await HapticFeedback.lightImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Result copied to clipboard!'),
          duration: Duration(milliseconds: 1500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final history = ref.watch(calculatorHistoryProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.bottomSheet),
          ),
          border: Border(top: BorderSide(color: colors.border)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.m,
          AppSpacing.l,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top drag handle & history switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    _showHistory
                        ? Icons.calculate_outlined
                        : Icons.history_rounded,
                    color: colors.primary,
                  ),
                  tooltip: _showHistory ? 'Show Keypad' : 'Show History',
                  onPressed: () => setState(() => _showHistory = !_showHistory),
                ),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  tooltip: 'Copy current result',
                  onPressed: _expression.isNotEmpty ? _copyResult : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),

            if (_showHistory) ...[
              // History view (last 20 calculations)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Calculation History (${history.length}/20)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (history.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        ref.read(calculatorHistoryProvider.notifier).clear();
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              SizedBox(
                height: 260,
                child: history.isEmpty
                    ? Center(
                        child: Text(
                          'No calculations logged yet',
                          style: TextStyle(color: colors.textMuted),
                        ),
                      )
                    : ListView.separated(
                        itemCount: history.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = history[index];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${item.expression} =',
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textMuted,
                              ),
                            ),
                            trailing: Text(
                              item.result,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Sora',
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _expression = item.result;
                                _showHistory = false;
                              });
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: AppSpacing.m),
              OutlinedButton(
                onPressed: () => setState(() => _showHistory = false),
                child: const Text('Back to keypad'),
              ),
            ] else ...[
              // Expression & Result display
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _expression.isEmpty ? '0' : _expression,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colors.loss,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.l),

              // Keypad rows
              for (final row in _rows)
                Row(
                  children: [
                    for (final key in row)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          child: key == null
                              ? const SizedBox.shrink()
                              : _Key(label: key, onTap: () => _onKey(key)),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: AppSpacing.l),

              // Action buttons: Use result & Copy
              Row(
                children: [
                  Expanded(child: _UseResultButton(onPressed: _popWithValue)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _popWithValue() {
    if (_expression.trim().isEmpty) {
      setState(() => _error = 'Nothing to use yet');
      return;
    }
    try {
      final value = CalculatorEvaluator.evaluate(_expression);
      ref.read(calculatorHistoryProvider.notifier).addEntry(_expression, value);
      Navigator.of(context).pop(CalculatorResult(used: true, value: value));
    } on CalculatorException catch (error) {
      setState(() => _error = error.message);
    }
  }
}

final class _UseResultButton extends StatelessWidget {
  const _UseResultButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.primary,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: Center(
            child: Text(
              'Use result',
              style: TextStyle(
                color: colors.onPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isAction = label == 'C' || label == '⌫';
    final isOperator =
        label == '%' ||
        label == '÷' ||
        label == '−' ||
        label == '+' ||
        label == '×';
    final foreground = isOperator ? colors.primary : colors.textPrimary;
    return Semantics(
      button: true,
      child: Material(
        color: isAction || isOperator
            ? colors.surfaceVariant
            : colors.surfaceVariant.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: SizedBox(
            height: 54,
            child: Center(
              child: label == '⌫'
                  ? Icon(Icons.backspace_outlined, color: foreground, size: 22)
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: foreground,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
