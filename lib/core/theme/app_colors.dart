import 'package:flutter/material.dart';

/// Semantic color tokens per `files/DESIGN.md` section 3.
/// Base colors are defined once; widgets must never hardcode colors.
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.primary,
    required this.onPrimary,
    required this.textPrimary,
    required this.textMuted,
    required this.profit,
    required this.loss,
    required this.warning,
    required this.border,
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color primary;
  final Color onPrimary;
  final Color textPrimary;
  final Color textMuted;
  final Color profit;
  final Color loss;
  final Color warning;
  final Color border;

  static const dark = AppColorsExtension(
    background: Color(0xFF0B1020),
    surface: Color(0xFF121A33),
    surfaceVariant: Color(0xFF1A2547),
    primary: Color(0xFF3D6BFF),
    onPrimary: Color(0xFFFFFFFF),
    textPrimary: Color(0xFFF2F5FF),
    textMuted: Color(0xFF8A96B8),
    profit: Color(0xFF2ECC8F),
    loss: Color(0xFFFF5C7A),
    warning: Color(0xFFFFB84D),
    border: Color(0xFF232F55),
  );

  static const light = AppColorsExtension(
    background: Color(0xFFF6F8FC),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFEAEFFA),
    primary: Color(0xFF2F5BFF),
    onPrimary: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF0B1020),
    textMuted: Color(0xFF5B6788),
    profit: Color(0xFF14A56E),
    loss: Color(0xFFE0405E),
    warning: Color(0xFFE59A1F),
    border: Color(0xFFD9E0F2),
  );

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? primary,
    Color? onPrimary,
    Color? textPrimary,
    Color? textMuted,
    Color? profit,
    Color? loss,
    Color? warning,
    Color? border,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      profit: profit ?? this.profit,
      loss: loss ?? this.loss,
      warning: warning ?? this.warning,
      border: border ?? this.border,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      profit: Color.lerp(profit, other.profit, t)!,
      loss: Color.lerp(loss, other.loss, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

/// Convenience accessor: `context.appColors.background`.
extension AppColorsContext on BuildContext {
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>()!;
}
