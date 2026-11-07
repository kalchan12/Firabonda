import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/money_field.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/database/app_database.dart';
import '../../../data/models/shop_models.dart';
import '../../../data/repositories/providers.dart';

final class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final expensesAsync = ref.watch(expensesStreamProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Expense',
            onPressed: () => _showAddExpenseDialog(context, ref),
          ),
        ],
      ),
      body: expensesAsync.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.payments_outlined,
                message:
                    'No expenses yet. Record shop expenses like rent and transport to calculate accurate profit.',
                actionLabel: 'Add expense',
                onAction: () => _showAddExpenseDialog(context, ref),
              ),
            );
          }

          final totalExpenseCents = expenses.fold<int>(
            0,
            (sum, e) => sum + e.amount,
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
                        color: colors.loss.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.trending_down,
                        color: colors.loss,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total recorded expenses',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Money.etb(totalExpenseCents),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colors.loss,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              for (final expense in expenses) ...[
                _ExpenseCard(
                  expense: expense,
                  onDelete: () => _confirmDeleteExpense(context, ref, expense),
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
                  height: 80,
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
            'Error loading expenses: $err',
            style: TextStyle(color: colors.loss),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    var selectedDate = DateTime.now();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final colors = context.appColors;
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.screenPadding,
                right: AppSpacing.screenPadding,
                top: AppSpacing.l,
                bottom: bottomInset + AppSpacing.l,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Expense',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),
                    AppTextField(
                      label: 'Expense title',
                      hintText: 'e.g. Shop rent, Transport, Packaging',
                      controller: titleController,
                      autofocus: true,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    MoneyField(
                      label: 'Amount',
                      controller: amountController,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Date'),
                      subtitle: Text(
                        DateFormat.yMMMd().format(selectedDate),
                        style: TextStyle(color: colors.primary),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.m),
                    AppTextField(
                      label: 'Note (optional)',
                      hintText: 'Receipt number or description',
                      controller: noteController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.l),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final title = titleController.text.trim();
                          final amountCents =
                              Money.parseCents(amountController.text);
                          if (title.isEmpty || amountCents <= 0) return;

                          await ref.read(expenseRepositoryProvider).add(
                                ExpenseInput(
                                  title: title,
                                  amountCents: amountCents,
                                  date: selectedDate,
                                  note: noteController.text.trim().isEmpty
                                      ? null
                                      : noteController.text.trim(),
                                ),
                              );
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                        child: const Text('Record expense'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteExpense(
    BuildContext context,
    WidgetRef ref,
    ExpenseRow expense,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Expense?'),
          content: Text(
            'Delete "${expense.title}" (${Money.etb(expense.amount)})?',
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
                    .read(expenseRepositoryProvider)
                    .softDelete(expense.id);
                nav.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('Deleted ${expense.title}')),
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

final class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.onDelete,
  });

  final ExpenseRow expense;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat.yMMMd().format(expense.date.toLocal()),
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
                if (expense.note != null && expense.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    expense.note!,
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                  ),
                ],
              ],
            ),
          ),
          Text(
            Money.etb(expense.amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.loss,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}
