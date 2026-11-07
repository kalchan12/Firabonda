import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Rounded text field used across the app.
final class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.keyboardType,
    this.prefixIcon,
    this.helperText,
    this.validator,
    this.onChanged,
    this.autofillHints,
    this.filled = true,
    this.maxLines = 1,
    this.enabled = true,
  });

  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final String? helperText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final List<String>? autofillHints;
  final bool filled;
  final int maxLines;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      inputFormatters: keyboardType == TextInputType.number
          ? <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ]
          : null,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      autofillHints: autofillHints,
      style: TextStyle(color: colors.textPrimary, fontSize: 15),
      cursorColor: colors.primary,
      decoration: InputDecoration(
        filled: filled,
        fillColor: colors.surfaceVariant.withValues(alpha: 0.6),
        labelText: label,
        labelStyle: TextStyle(color: colors.textMuted, fontSize: 14),
        helperText: helperText,
        helperStyle: TextStyle(color: colors.textMuted, fontSize: 12),
        prefixIcon: prefixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.loss),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.loss, width: 1.5),
        ),
      ),
    );
  }
}
