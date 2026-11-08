import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/money_field.dart';
import '../../../data/database/app_database.dart';
import '../../../data/models/shop_models.dart';
import '../../../data/repositories/providers.dart';

final class BatchPurchaseScreen extends ConsumerStatefulWidget {
  const BatchPurchaseScreen({super.key});

  @override
  ConsumerState<BatchPurchaseScreen> createState() =>
      _BatchPurchaseScreenState();
}

final class _BatchItemDraft {
  _BatchItemDraft({
    this.categoryId,
    this.colorId,
    this.quantity = 1,
    TextEditingController? priceController,
  }) : priceController = priceController ?? TextEditingController();

  String? categoryId;
  String? colorId;
  int quantity;
  final TextEditingController priceController;

  void dispose() {
    priceController.dispose();
  }
}

final class _BatchPurchaseScreenState
    extends ConsumerState<BatchPurchaseScreen> {
  final _totalCostController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  String? _selectedSupplierId;
  String _selectedAccountId = 'acc_cash';
  bool _isSaving = false;

  final List<_BatchItemDraft> _items = [];

  @override
  void initState() {
    super.initState();
    _totalCostController.addListener(() => setState(() {}));
    // Start with 1 empty item draft
    _items.add(_BatchItemDraft());
  }

  @override
  void dispose() {
    _totalCostController.dispose();
    _noteController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  int? get _parsedTotalCostCents {
    try {
      return Money.parseCents(_totalCostController.text);
    } catch (_) {
      return null;
    }
  }

  int get _totalPieces =>
      _items.fold<int>(0, (sum, item) => sum + item.quantity);

  void _addItem() {
    setState(() {
      final defaultCat = _items.isNotEmpty ? _items.last.categoryId : null;
      final defaultColor = _items.isNotEmpty ? _items.last.colorId : null;
      _items.add(
        _BatchItemDraft(
          categoryId: defaultCat,
          colorId: defaultColor,
          quantity: 1,
        ),
      );
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      final item = _items.removeAt(index);
      item.dispose();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _saveBatch() async {
    final totalCost = _parsedTotalCostCents;
    if (totalCost == null || totalCost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid total batch cost')),
      );
      return;
    }

    if (_items.isEmpty || _totalPieces <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item to the batch'),
        ),
      );
      return;
    }

    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.categoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select category for item #${i + 1}')),
        );
        return;
      }
      if (item.colorId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select color for item #${i + 1}')),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(purchaseRepositoryProvider);
      final batchItems = _items.map((draft) {
        int? sellingPrice;
        try {
          if (draft.priceController.text.trim().isNotEmpty) {
            sellingPrice = Money.parseCents(draft.priceController.text);
          }
        } catch (_) {}

        return BatchItemInput(
          categoryId: draft.categoryId!,
          colorId: draft.colorId!,
          quantity: draft.quantity,
          sellingPriceCents: sellingPrice,
        );
      }).toList();

      await repo.addBatch(
        BatchPurchaseInput(
          supplierId: _selectedSupplierId,
          totalCostCents: totalCost,
          date: _date,
          accountId: _selectedAccountId,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          items: batchItems,
        ),
      );

      await HapticFeedback.lightImpact();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Batch purchase saved! ($_totalPieces items added to inventory)',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving batch purchase: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final colorsAsync = ref.watch(colorsStreamProvider);
    final suppliersAsync = ref.watch(suppliersStreamProvider);

    final totalCost = _parsedTotalCostCents;
    final totalPieces = _totalPieces;
    final avgCostPerPiece = (totalCost != null && totalPieces > 0)
        ? (totalCost ~/ totalPieces)
        : 0;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Batch Purchase (Bundle Lot)')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.m,
            AppSpacing.screenPadding,
            100, // Clearance for nav bar
          ),
          children: [
            // Batch Total & Date Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bundle Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  MoneyField(
                    label: 'Total batch cost (entire bundle)',
                    controller: _totalCostController,
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // Date picker row
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: colors.textMuted,
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Text(
                        'Date: ${DateFormat.yMMMd().format(_date)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _pickDate,
                        child: const Text('Change date'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s),

                  // Payment Account
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Text(
                          'Paid from:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.textMuted,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        ChoiceChip(
                          label: const Text('Cash'),
                          selected: _selectedAccountId == 'acc_cash',
                          onSelected: (val) {
                            if (val) {
                              setState(() => _selectedAccountId = 'acc_cash');
                            }
                          },
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        ChoiceChip(
                          label: const Text('Telebirr'),
                          selected: _selectedAccountId == 'acc_telebirr',
                          onSelected: (val) {
                            if (val) {
                              setState(
                                () => _selectedAccountId = 'acc_telebirr',
                              );
                            }
                          },
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        ChoiceChip(
                          label: const Text('Bank'),
                          selected: _selectedAccountId == 'acc_bank',
                          onSelected: (val) {
                            if (val) {
                              setState(() => _selectedAccountId = 'acc_bank');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // Optional note
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Batch note (optional)',
                      hintText: 'e.g. Dubai bale #4, Men winter jackets',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.m),

            // Cost allocation banner
            if (totalCost != null && totalCost > 0 && totalPieces > 0)
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.pie_chart_outline_rounded,
                      color: colors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$totalPieces pieces in bundle',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Avg cost: ~${Money.etb(avgCostPerPiece)} / piece (allocated exactly)',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.m),

            // Supplier selector
            suppliersAsync.when(
              data: (suppliers) {
                if (suppliers.isEmpty) return const SizedBox.shrink();
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Supplier (optional)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.s),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final s in suppliers)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(s.name),
                                  selected: _selectedSupplierId == s.id,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedSupplierId = selected
                                          ? s.id
                                          : null;
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.m),

            // Items List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bundle items (${_items.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add item'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),

            // List of item drafts
            for (var i = 0; i < _items.length; i++) ...[
              _BatchItemCard(
                index: i,
                draft: _items[i],
                categoriesAsync: categoriesAsync,
                colorsAsync: colorsAsync,
                onRemove: _items.length > 1 ? () => _removeItem(i) : null,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.m),
            ],

            const SizedBox(height: AppSpacing.l),

            // Save Batch button
            AppButton(
              label: _isSaving
                  ? 'Saving batch...'
                  : 'Save batch purchase ($totalPieces items)',
              onPressed: _isSaving ? () {} : _saveBatch,
            ),
          ],
        ),
      ),
    );
  }
}

final class _BatchItemCard extends StatelessWidget {
  const _BatchItemCard({
    required this.index,
    required this.draft,
    required this.categoriesAsync,
    required this.colorsAsync,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final _BatchItemDraft draft;
  final AsyncValue<List<CategoryRow>> categoriesAsync;
  final AsyncValue<List<ColorRow>> colorsAsync;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item #${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              if (onRemove != null)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: colors.loss,
                  ),
                  tooltip: 'Remove item',
                  onPressed: onRemove,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),

          // Category Dropdown
          categoriesAsync.when(
            data: (categories) => DropdownButtonFormField<String>(
              initialValue: draft.categoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final c in categories)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: (val) {
                draft.categoryId = val;
                onChanged();
              },
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const Text('Failed to load categories'),
          ),
          const SizedBox(height: AppSpacing.m),

          // Color Dropdown
          colorsAsync.when(
            data: (colorList) => DropdownButtonFormField<String>(
              initialValue: draft.colorId,
              decoration: const InputDecoration(labelText: 'Color'),
              items: [
                for (final c in colorList)
                  DropdownMenuItem(
                    value: c.id,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(
                              int.tryParse(c.hex.replaceFirst('#', '0xFF')) ??
                                  0xFF000000,
                            ),
                            border: Border.all(color: colors.border),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ],
                    ),
                  ),
              ],
              onChanged: (val) {
                draft.colorId = val;
                onChanged();
              },
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const Text('Failed to load colors'),
          ),
          const SizedBox(height: AppSpacing.m),

          // Quantity stepper
          Row(
            children: [
              const Text(
                'Quantity:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: AppSpacing.m),
              IconButton.outlined(
                icon: const Icon(Icons.remove, size: 18),
                onPressed: draft.quantity > 1
                    ? () {
                        draft.quantity--;
                        onChanged();
                      }
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                child: Text(
                  '${draft.quantity}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton.outlined(
                icon: const Icon(Icons.add, size: 18),
                onPressed: () {
                  draft.quantity++;
                  onChanged();
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),

          // Optional planned selling price
          MoneyField(
            label: 'Planned selling price per piece (optional)',
            controller: draft.priceController,
          ),
        ],
      ),
    );
  }
}
