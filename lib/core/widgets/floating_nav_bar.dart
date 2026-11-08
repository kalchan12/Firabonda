import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_dimensions.dart';
import '../theme/app_colors.dart';
import 'speed_dial_sheet.dart';

/// Floating navigation bar with 4 destinations and a prominent 68-72dp
/// raised circular center speed-dial button with subtle blue glow.
final class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationTap,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationTap;

  /// Configuration: If true, tap opens speed-dial. If false, tap navigates directly
  /// to single purchase and long-press opens speed-dial.
  static const bool speedDialOnTap = true;

  static const _destinations = <_NavDestination>[
    _NavDestination(
      location: '/dashboard',
      outlineIcon: Icons.home_outlined,
      filledIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavDestination(
      location: '/purchases',
      outlineIcon: Icons.shopping_bag_outlined,
      filledIcon: Icons.shopping_bag_rounded,
      label: 'Purchases',
    ),
    _NavDestination(
      location: '/sales',
      outlineIcon: Icons.receipt_long_outlined,
      filledIcon: Icons.receipt_long_rounded,
      label: 'Sales',
    ),
    _NavDestination(
      location: '/more',
      outlineIcon: Icons.grid_view_outlined,
      filledIcon: Icons.grid_view_rounded,
      label: 'More',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        0,
        AppSpacing.m,
        AppSpacing.s,
      ),
      child: SizedBox(
        height: 84,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Floating bar dock
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: colors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        _destination(context, 0),
                        _destination(context, 1),
                        const SizedBox(width: 76), // clearance for 70dp center button
                        _destination(context, 2),
                        _destination(context, 3),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Center circular button (68-72dp, raised 22dp with subtle glow and cutout notch)
            Positioned(
              top: 0,
              child: _CenterSpeedDialButton(
                onTap: () {
                  if (speedDialOnTap) {
                    showSpeedDialSheet(context);
                  } else {
                    HapticFeedback.lightImpact();
                    context.push('/add-purchase');
                  }
                },
                onLongPress: () {
                  if (!speedDialOnTap) {
                    showSpeedDialSheet(context);
                  } else {
                    HapticFeedback.lightImpact();
                    context.push('/add-purchase');
                  }
                },
              ),
            ),
          ],
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
        label: destination.label,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onDestinationTap(index);
          },
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? destination.filledIcon : destination.outlineIcon,
                size: 22,
                color: selected ? colors.primary : colors.textMuted,
              ),
              const SizedBox(height: 2),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? colors.primary : colors.textMuted,
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

final class _NavDestination {
  const _NavDestination({
    required this.location,
    required this.outlineIcon,
    required this.filledIcon,
    required this.label,
  });

  final String location;
  final IconData outlineIcon;
  final IconData filledIcon;
  final String label;
}

/// Raised circular center button (70dp) with blue accent glow and cutout ring.
final class _CenterSpeedDialButton extends StatelessWidget {
  const _CenterSpeedDialButton({
    required this.onTap,
    this.onLongPress,
  });

  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Semantics(
      button: true,
      label: 'Add',
      tooltip: 'Add',
      child: Tooltip(
        message: 'Add',
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.background, // Cutout ring effect
          ),
          alignment: Alignment.center,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primary,
                  Color.lerp(colors.primary, Colors.blue.shade900, 0.25)!,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.38),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                onLongPress: onLongPress,
                child: const Center(
                  child: Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
