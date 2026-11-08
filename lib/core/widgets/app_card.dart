import 'package:flutter/material.dart';

import '../constants/app_dimensions.dart';
import '../theme/app_colors.dart';

/// Rounded card used everywhere per `files/DESIGN.md` and Fix Plan V2.1 Task 2.
/// Always applies the token border and radius, with [Clip.antiAlias]
/// so inner backgrounds, gradients, and ink effects never leak sharp edges.
final class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.gradient,
    this.borderRadius,
    this.clipBehavior = Clip.antiAlias,
    this.hero = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final Clip clipBehavior;
  final bool hero;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius =
        borderRadius ??
        BorderRadius.circular(
          hero ? AppRadius.radiusHero : AppRadius.radiusCard,
        );

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: clipBehavior,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: colors.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              color: gradient == null ? (color ?? colors.surface) : null,
              gradient: gradient,
              borderRadius: radius,
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
