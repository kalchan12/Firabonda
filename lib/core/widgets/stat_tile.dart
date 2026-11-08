import 'package:flutter/material.dart';

import '../constants/app_dimensions.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';

/// Tone for a [StatTile] value, mapping to token colors.
enum StatTone { primary, profit, loss }

/// Stat tile with large bold money number and animated counter,
/// per `files/DESIGN.md` sections 7 and 8.
final class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.tone = StatTone.primary,
    this.hero = false,
  });

  final String label;
  final String value;
  final StatTone tone;

  /// Full-width emphasized tile with a soft gradient.
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final valueColor = switch (tone) {
      StatTone.primary => colors.primary,
      StatTone.profit => colors.profit,
      StatTone.loss => colors.loss,
    };

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.textMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _CountUpText(value: value, color: valueColor, large: hero),
      ],
    );

    final tile = AppCard(
      hero: hero,
      gradient: hero
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.surfaceVariant.withValues(alpha: 0.9),
                colors.primary.withValues(alpha: 0.12),
              ],
            )
          : null,
      padding: EdgeInsets.all(hero ? AppSpacing.xxl : AppSpacing.l),
      child: content,
    );

    return tile;
  }
}

/// Animates the text change by fading/sliding the digits in.
final class _CountUpText extends StatelessWidget {
  const _CountUpText({
    required this.value,
    required this.color,
    required this.large,
  });

  final String value;
  final Color color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, 6 * (1 - t.clamp(0, 1).toDouble())),
            child: child,
          ),
        );
      },
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: AppTypography.moneyStyle(
            fontSize: large ? 32 : 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}
