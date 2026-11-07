import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/database/app_database.dart';
import '../../../data/models/shop_models.dart';
import '../../../data/repositories/providers.dart';

final class SupplierSummary {
  const SupplierSummary({
    required this.supplier,
    required this.totalSpentCents,
    required this.purchaseCount,
  });

  final SupplierRow supplier;
  final int totalSpentCents;
  final int purchaseCount;
}

final supplierSummariesProvider =
    StreamProvider<List<SupplierSummary>>((ref) {
  final suppliersStream = ref.watch(supplierRepositoryProvider).watchAll();
  final purchasesStream = ref.watch(purchaseRepositoryProvider).watchOverviews();

  return suppliersStream.asyncMap((suppliers) async {
    final purchases = await purchasesStream.first;
    return suppliers.map((supplier) {
      final supplierPurchases = purchases.where((p) => p.supplierId == supplier.id);
      final totalSpent = supplierPurchases.fold<int>(
        0,
        (sum, p) => sum + p.totalCostCents,
      );
      return SupplierSummary(
        supplier: supplier,
        totalSpentCents: totalSpent,
        purchaseCount: supplierPurchases.length,
      );
    }).toList();
  });
});

final class SuppliersScreen extends ConsumerWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final suppliersAsync = ref.watch(supplierSummariesProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Suppliers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Supplier',
            onPressed: () => _showAddEditSupplierDialog(context, ref),
          ),
        ],
      ),
      body: suppliersAsync.when(
        data: (summaries) {
          if (summaries.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.local_shipping_outlined,
                message: 'No suppliers yet. Add suppliers to track purchase history and totals.',
                actionLabel: 'Add supplier',
                onAction: () => _showAddEditSupplierDialog(context, ref),
              ),
            );
          }

          final totalSpentAll = summaries.fold<int>(
            0,
            (sum, s) => sum + s.totalSpentCents,
          );

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              AppCard(
                color: colors.surface,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total spent with suppliers',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Money.etb(totalSpentAll),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              for (final summary in summaries) ...[
                _SupplierCard(
                  summary: summary,
                  onEdit: () => _showAddEditSupplierDialog(
                    context,
                    ref,
                    supplier: summary.supplier,
                  ),
                  onDelete: () => _confirmDeleteSupplier(
                    context,
                    ref,
                    summary.supplier,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            for (var i = 0; i < 4; i++) ...[
              SkeletonLoader(
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s),
            ],
          ],
        ),
        error: (err, _) => Center(
          child: Text(
            'Error loading suppliers: $err',
            style: TextStyle(color: colors.loss),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditSupplierDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEditSupplierDialog(
    BuildContext context,
    WidgetRef ref, {
    SupplierRow? supplier,
  }) {
    final nameController = TextEditingController(text: supplier?.name ?? '');
    final phoneController = TextEditingController(text: supplier?.phone ?? '');
    final noteController = TextEditingController(text: supplier?.note ?? '');
    final isEditing = supplier != null;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        final colors = ctx.appColors;
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(isEditing ? 'Edit Supplier' : 'New Supplier'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Supplier name',
                  hintText: 'e.g. Merkato Wholesale',
                  controller: nameController,
                  autofocus: true,
                ),
                const SizedBox(height: AppSpacing.m),
                AppTextField(
                  label: 'Phone number (optional)',
                  hintText: 'e.g. 0911234567',
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.m),
                AppTextField(
                  label: 'Note (optional)',
                  hintText: 'e.g. Shop #42, stall C',
                  controller: noteController,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final repo = ref.read(supplierRepositoryProvider);
                if (isEditing) {
                  await repo.update(
                    supplier.id,
                    SupplierInput(
                      name: name,
                      phone: phoneController.text.trim().isEmpty
                          ? null
                          : phoneController.text.trim(),
                      note: noteController.text.trim().isEmpty
                          ? null
                          : noteController.text.trim(),
                    ),
                  );
                } else {
                  await repo.add(
                    SupplierInput(
                      name: name,
                      phone: phoneController.text.trim().isEmpty
                          ? null
                          : phoneController.text.trim(),
                      note: noteController.text.trim().isEmpty
                          ? null
                          : noteController.text.trim(),
                    ),
                  );
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteSupplier(
    BuildContext context,
    WidgetRef ref,
    SupplierRow supplier,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Supplier?'),
          content: Text(
            'Are you sure you want to delete "${supplier.name}"? Past purchase records will remain intact.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(ctx);
                await ref
                    .read(supplierRepositoryProvider)
                    .softDelete(supplier.id);
                nav.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('Deleted ${supplier.name}')),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

final class _SupplierCard extends StatelessWidget {
  const _SupplierCard({
    required this.summary,
    required this.onEdit,
    required this.onDelete,
  });

  final SupplierSummary summary;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final s = summary.supplier;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
          if (s.phone != null && s.phone!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 14, color: colors.textMuted),
                const SizedBox(width: 4),
                Text(
                  s.phone!,
                  style: TextStyle(fontSize: 13, color: colors.textMuted),
                ),
              ],
            ),
          ],
          if (s.note != null && s.note!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              s.note!,
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.s),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: AppSpacing.s),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${summary.purchaseCount} purchases',
                style: TextStyle(fontSize: 12, color: colors.textMuted),
              ),
              Text(
                'Total: ${Money.etb(summary.totalSpentCents)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
