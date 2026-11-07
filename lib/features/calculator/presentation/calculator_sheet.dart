import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/calculator.dart';

/// Result of the mini calculator sheet. `used` is true when the owner
/// tapped "Use result" and `value` holds the evaluated decimal literal.
final class CalculatorResult {
  const CalculatorResult({required this.used, required this.value});

  final bool used;
  final String value;
}

/// Bottom-sheet calculator per `files/DESIGN.md` section 7.1.
///
/// Starts with the field's current value; "Use result" writes the value
/// back into the field and closes the sheet.
Future<CalculatorResult?> showCalculatorSheet(
  BuildContext context,
  String initialText,
) {
  return showModalBottomSheet<CalculatorResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => CalculatorSheet(initialText: initialText),
  );
}

final class CalculatorSheet extends StatefulWidget {
  const CalculatorSheet({super.key, required this.initialText});

  final String initialText;

  @override
  State<CalculatorSheet> createState() => _CalculatorSheetState();
}

final class _CalculatorSheetState extends State<CalculatorSheet> {
  static const _rows = <List<String?>>[
    ['C', '⌫', '%', '÷'],
    ['7', '8', '9', '−'],
    ['4', '5', '6', '+'],
    ['1', '2', '3', '×'],
    ['0', '.', '=', null],
  ];

  late String _expression;
  String? _error;

  @override
  void initState() {
    super.initState();
    final trimmed = widget.initialText.trim();
    _expression = trimmed.replaceAll('ETB', '').trim();
  }

  void _onKey(String key) {
    setState(() {
      _error = null;
      switch (key) {
        case 'C':
          _expression = '';
        case '⌫':
          if (_expression.isNotEmpty) {
            _expression = _expression.substring(0, _expression.length - 1);
          }
        case '=':
          _evaluate();
        default:
          _expression = _expression + key;
      }
    });
  }

  void _evaluate() {
    if (_expression.trim().isEmpty) return;
    try {
      final value = CalculatorEvaluator.evaluate(_expression);
      _expression = value;
    } on CalculatorException catch (error) {
      _error = error.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
          AppSpacing.xl,
          AppSpacing.m,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.l),
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _expression.isEmpty ? '0' : _expression,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
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
            _UseResultButton(onPressed: _popWithValue),
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
            height: 56,
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
