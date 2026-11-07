import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_dimensions.dart';
import '../theme/app_colors.dart';

/// Floating bottom bar with 4 destinations and a prominent center
/// "+ Add purchase" button, per `files/DESIGN.md` section 6.
///
/// `onAddPurchase` pushes the add-purchase screen; destinations switch
/// go_router branches.
final class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationTap,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationTap;

  static const _destinations = <_NavDestination>[
    _NavDestination(
      location: '/dashboard',
      icon: Icons.home_outlined,
      label: 'Home',
    ),
    _NavDestination(
      location: '/purchases',
      icon: Icons.shopping_bag_outlined,
      label: 'Purchases',
    ),
    _NavDestination(
      location: '/sales',
      icon: Icons.receipt_long_outlined,
      label: 'Sales',
    ),
    _NavDestination(location: '/more', icon: Icons.menu, label: 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.l,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceVariant.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: colors.border),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.s,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _destination(context, 0),
                      _destination(context, 1),
                      const SizedBox(width: 84),
                      _destination(context, 2),
                      _destination(context, 3),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: IntrinsicWidth(
                      child: _AddPurchaseButton(
                        onPressed: () => context.push('/add-purchase'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _destination(BuildContext context, int index) {
    final destination = _destinations[index];
    final selected = index == currentIndex;
    final colors = context.appColors;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          onTap: () => onDestinationTap(index),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  destination.icon,
                  size: 22,
                  color: selected ? colors.primary : colors.textMuted,
                ),
                Text(
                  destination.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected ? colors.primary : colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _NavDestination {
  const _NavDestination({
    required this.location,
    required this.icon,
    required this.label,
  });

  final String location;
  final IconData icon;
  final String label;
}

final class _AddPurchaseButton extends StatelessWidget {
  const _AddPurchaseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      label: 'Add purchase',
      child: Material(
        color: colors.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        elevation: 0,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: Colors.transparent),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: colors.onPrimary, size: 20),
                const SizedBox(width: AppSpacing.s),
                Text(
                  'Add purchase',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
