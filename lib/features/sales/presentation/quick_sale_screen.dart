import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';

/// Screen for recording quick sales in 2-3 taps with 100% target profit default (Step 6).
final class QuickSaleScreen extends StatelessWidget {
  const QuickSaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Quick Sale'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.point_of_sale_rounded, size: 56, color: colors.profit),
              const SizedBox(height: AppSpacing.m),
              const Text(
                'Quick Sale',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Select items directly from active inventory and sell in 2-3 taps.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
