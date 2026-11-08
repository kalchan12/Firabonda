import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_dimensions.dart';
import '../theme/app_colors.dart';
import '../../features/calculator/presentation/calculator_sheet.dart';
import 'floating_nav_bar.dart';

/// Shell that hosts the branch body plus the floating bottom bar and quick calculator FAB.
/// Scrollables add their own bottom padding to clear the floating bar.
final class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: navigationShell),

            // Quick Calculator floating button (Step 9)
            Positioned(
              right: AppSpacing.screenPadding,
              bottom: 94,
              child: Semantics(
                button: true,
                label: 'Quick Calculator',
                child: Material(
                  color: colors.surfaceVariant,
                  shape: const CircleBorder(),
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.25),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () async {
                      final result = await showCalculatorSheet(context, '');
                      if (result != null && result.used) {
                        await Clipboard.setData(
                          ClipboardData(text: result.value),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Result ${result.value} copied to clipboard!',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.border),
                      ),
                      child: Icon(
                        Icons.calculate_outlined,
                        size: 22,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Floating Navigation Bar
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: FloatingNavBar(
                  currentIndex: navigationShell.currentIndex,
                  onDestinationTap: _goBranch,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

/// Extra bottom padding for scrollable content under the floating bar.
double get floatingBarClearance => 96;
