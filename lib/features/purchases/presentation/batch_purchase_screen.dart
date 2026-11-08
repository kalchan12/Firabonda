import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';

/// Screen for entering batch purchases with automatic cost splitting (Step 7).
final class BatchPurchaseScreen extends StatelessWidget {
  const BatchPurchaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Batch Purchase'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_rounded, size: 56, color: colors.primary),
              const SizedBox(height: AppSpacing.m),
              const Text(
                'Batch Purchase',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Enter entire bundle lots and automatically split costs across items.',
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
