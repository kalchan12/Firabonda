import 'package:flutter/material.dart';

import '../../features/calculator/presentation/calculator_sheet.dart';
import 'app_text_field.dart';

/// Money input field with a calculator icon that opens the mini
/// calculator bottom sheet, per `files/DESIGN.md` section 7.1.
///
/// Values are ETB amounts; the stored value is cents via [Money.parseCents].
///
/// Passing [controller] is optional; when omitted the field owns one.
final class MoneyField extends StatefulWidget {
  const MoneyField({
    super.key,
    this.controller,
    required this.label,
    this.helperText,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String label;
  final String? helperText;
  final bool enabled;

  @override
  State<MoneyField> createState() => _MoneyFieldState();
}

final class _MoneyFieldState extends State<MoneyField> {
  late final TextEditingController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    final provided = widget.controller;
    if (provided != null) {
      _controller = provided;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _openCalculator() async {
    final result = await showCalculatorSheet(context, _controller.text);
    if (result != null && result.used) {
      _controller.text = result.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      controller: _controller,
      keyboardType: TextInputType.number,
      helperText: widget.helperText,
      enabled: widget.enabled,
      prefixIcon: IconButton(
        icon: const Icon(
          Icons.calculate_outlined,
          semanticLabel: 'Open calculator',
        ),
        onPressed: _openCalculator,
      ),
    );
  }
}
