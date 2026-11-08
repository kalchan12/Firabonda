import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_dimensions.dart';
import '../theme/app_colors.dart';

/// Shows the Speed Dial action sheet with smooth animation and large touch targets.
Future<void> showSpeedDialSheet(BuildContext context) {
  HapticFeedback.mediumImpact();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    isScrollControlled: true,
    builder: (ctx) => const _SpeedDialContent(),
  );
}

final class _SpeedDialContent extends StatelessWidget {
  const _SpeedDialContent();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            0,
            AppSpacing.screenPadding,
            AppSpacing.l,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Speed Dial Card container
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? colors.surface.withValues(alpha: 0.95)
                      : colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.bottomSheet),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.m,
                  horizontal: AppSpacing.m,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sheet Header indicator
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.m),
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    _SpeedDialOption(
                      icon: Icons.shopping_bag_rounded,
                      iconColor: colors.primary,
                      title: 'Purchase',
                      subtitle: 'Single item restock or inventory add',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/add-purchase');
                      },
                    ),
                    const SizedBox(height: AppSpacing.s),
                    _SpeedDialOption(
                      icon: Icons.inventory_2_rounded,
                      iconColor: const Color(0xFF8B5CF6), // Purple accent
                      title: 'Batch purchase',
                      subtitle: 'Multi-item lot with automatic cost split',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/batch-purchase');
                      },
                    ),
                    const SizedBox(height: AppSpacing.s),
                    _SpeedDialOption(
                      icon: Icons.point_of_sale_rounded,
                      iconColor: colors.profit,
                      title: 'Quick sale',
                      subtitle: 'Fast 2-tap sale from current stock',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/quick-sale');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              // Close circle button
              Semantics(
                button: true,
                label: 'Close add menu',
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.surfaceVariant,
                      border: Border.all(color: colors.border),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: colors.textPrimary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _SpeedDialOption extends StatelessWidget {
  const _SpeedDialOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
