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

final class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  DebtDirection _tab = DebtDirection.owedToMe;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final debtsAsync = ref.watch(debtsStreamProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Debts & Credit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Debt Record',
            onPressed: () =>
                _showAddDebtDialog(context, defaultDirection: _tab),
          ),
        ],
      ),
      body: debtsAsync.when(
        data: (allDebts) {
          final tabDebts = allDebts
              .where((d) => d.direction == _tab.dbValue)
              .toList();
          final unpaidTotalCents = tabDebts
              .where((d) => !d.isPaid)
              .fold<int>(0, (sum, d) => sum + d.amount);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.s,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<DebtDirection>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: DebtDirection.owedToMe,
                            label: Text('Owed to me'),
                          ),
                          ButtonSegment(
                            value: DebtDirection.iOwe,
                            label: Text('I owe'),
                          ),
                        ],
                        selected: {_tab},
                        onSelectionChanged: (set) =>
                            setState(() => _tab = set.first),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: tabDebts.isEmpty
                    ? Center(
                        child: EmptyState(
                          icon: Icons.handshake_outlined,
                          message: _tab == DebtDirection.owedToMe
                              ? 'No customer debts. Track credit taken by customers.'
                              : 'No supplier debts. Track credit taken from suppliers.',
                          actionLabel: 'Add debt record',
                          onAction: () => _showAddDebtDialog(
                            context,
                            defaultDirection: _tab,
                          ),
                        ),
                      )
                    : ListView(
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
                                    color:
                                        (_tab == DebtDirection.owedToMe
                                                ? colors.warning
                                                : colors.loss)
                                            .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _tab == DebtDirection.owedToMe
                                        ? Icons.call_received
                                        : Icons.call_made,
                                    color: _tab == DebtDirection.owedToMe
                                        ? colors.warning
                                        : colors.loss,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.m),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _tab == DebtDirection.owedToMe
                                          ? 'Total unpaid by customers'
                                          : 'Total unpaid to suppliers',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      Money.etb(unpaidTotalCents),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: _tab == DebtDirection.owedToMe
                                            ? colors.warning
                                            : colors.loss,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),
                          for (final debt in tabDebts) ...[
                            _DebtCard(
                              debt: debt,
                              onTogglePaid: () => ref
                                  .read(debtRepositoryProvider)
                                  .markPaid(debt.id, paid: !debt.isPaid),
                              onDelete: () => _confirmDeleteDebt(context, debt),
                            ),
                            const SizedBox(height: AppSpacing.s),
                          ],
                          const SizedBox(height: 80),
                        ],
                      ),
              ),
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
            'Error loading debts: $err',
            style: TextStyle(color: colors.loss),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDebtDialog(context, defaultDirection: _tab),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDebtDialog(
    BuildContext context, {
    required DebtDirection defaultDirection,
  }) {
    var direction = defaultDirection;
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    DateTime? dueDate;
    final noteController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final colors = context.appColors;
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SafeArea(
                top: false,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.bottomSheet),
                    ),
                    border: Border(top: BorderSide(color: colors.border)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenPadding,
                          AppSpacing.m,
                          AppSpacing.screenPadding,
                          AppSpacing.s,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Add Debt Record',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                          ],
                        ),
                      ),
                      Divider(color: colors.border, height: 1),
                      // Scrollable form
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenPadding,
                            AppSpacing.m,
                            AppSpacing.screenPadding,
                            AppSpacing.m,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: SegmentedButton<DebtDirection>(
                                      showSelectedIcon: false,
                                      segments: const [
                                        ButtonSegment(
                                          value: DebtDirection.owedToMe,
                                          label: Text('Customer owes me'),
                                        ),
                                        ButtonSegment(
                                          value: DebtDirection.iOwe,
                                          label: Text('I owe supplier'),
                                        ),
                                      ],
                                      selected: {direction},
                                      onSelectionChanged: (set) =>
                                          setState(() => direction = set.first),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.m),
                              AppTextField(
                                label: 'Person / Supplier name',
                                hintText: direction == DebtDirection.owedToMe
                                    ? 'Customer name'
                                    : 'Supplier name',
                                controller: nameController,
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
                                leading: const Icon(Icons.event_outlined),
                                title: const Text('Due date (optional)'),
                                subtitle: Text(
                                  dueDate == null
                                      ? 'No due date set'
                                      : DateFormat.yMMMd().format(dueDate!),
                                  style: TextStyle(
                                    color: dueDate == null
                                        ? colors.textMuted
                                        : colors.primary,
                                  ),
                                ),
                                trailing: dueDate != null
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () =>
                                            setState(() => dueDate = null),
                                      )
                                    : null,
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        dueDate ??
                                        DateTime.now().add(
                                          const Duration(days: 7),
                                        ),
                                    firstDate: DateTime.now().subtract(
                                      const Duration(days: 365),
                                    ),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 730),
                                    ),
                                  );
                                  if (picked != null) {
                                    setState(() => dueDate = picked);
                                  }
                                },
                              ),
                              const SizedBox(height: AppSpacing.m),
                              AppTextField(
                                label: 'Note (optional)',
                                hintText: 'Items taken or repayment agreement',
                                controller: noteController,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Fixed footer
                      Container(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenPadding,
                          AppSpacing.s,
                          AppSpacing.screenPadding,
                          AppSpacing.m,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          border: Border(top: BorderSide(color: colors.border)),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () async {
                              final name = nameController.text.trim();
                              final amountCents = Money.parseCents(
                                amountController.text,
                              );
                              if (name.isEmpty || amountCents <= 0) return;

                              await ref
                                  .read(debtRepositoryProvider)
                                  .add(
                                    DebtInput(
                                      personName: name,
                                      amountCents: amountCents,
                                      direction: direction,
                                      dueDate: dueDate,
                                      note: noteController.text.trim().isEmpty
                                          ? null
                                          : noteController.text.trim(),
                                    ),
                                  );
                              if (ctx.mounted) Navigator.of(ctx).pop();
                            },
                            child: const Text('Save record'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteDebt(BuildContext context, DebtRow debt) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Debt Record?'),
          content: Text(
            'Delete debt record for "${debt.personName}" (${Money.etb(debt.amount)})?',
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
                final repo = ref.read(debtRepositoryProvider);
                await repo.softDelete(debt.id);
                nav.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Deleted debt record for ${debt.personName}'),
                    action: SnackBarAction(
                      label: 'UNDO',
                      onPressed: () async {
                        await repo.restore(debt.id);
                      },
                    ),
                    duration: const Duration(seconds: 4),
                  ),
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

final class _DebtCard extends StatelessWidget {
  const _DebtCard({
    required this.debt,
    required this.onTogglePaid,
    required this.onDelete,
  });

  final DebtRow debt;
  final VoidCallback onTogglePaid;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: debt.isPaid,
                onChanged: (_) => onTogglePaid(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.personName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        decoration: debt.isPaid
                            ? TextDecoration.lineThrough
                            : null,
                        color: debt.isPaid
                            ? colors.textMuted
                            : colors.textPrimary,
                      ),
                    ),
                    if (debt.dueDate != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.event_outlined,
                            size: 13,
                            color: colors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Due ${DateFormat.yMMMd().format(debt.dueDate!.toLocal())}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Money.etb(debt.amount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      decoration: debt.isPaid
                          ? TextDecoration.lineThrough
                          : null,
                      color: debt.isPaid
                          ? colors.textMuted
                          : colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: debt.isPaid
                          ? colors.profit.withValues(alpha: 0.12)
                          : colors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      debt.isPaid ? 'PAID' : 'PENDING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: debt.isPaid ? colors.profit : colors.warning,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
          if (debt.note != null && debt.note!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 4),
              child: Text(
                debt.note!,
                style: TextStyle(fontSize: 12, color: colors.textMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
