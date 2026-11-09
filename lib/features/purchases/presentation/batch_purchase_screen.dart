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
import 'widgets/purchase_photo_picker.dart';

final class _BatchItemDraft {
  _BatchItemDraft({
    this.categoryId,
    this.colorId,
    this.quantity = 1,
    TextEditingController? unitCostController,
    TextEditingController? plannedSellingPriceController,
    this.note,
  }) : unitCostController = unitCostController ?? TextEditingController(),
       plannedSellingPriceController =
           plannedSellingPriceController ?? TextEditingController();

  String? categoryId;
  String? colorId;
  int quantity;
  final TextEditingController unitCostController;
  final TextEditingController plannedSellingPriceController;
  String? note;

  int? get parsedUnitCostCents {
    try {
      final t = unitCostController.text.trim();
      if (t.isEmpty) return null;
      return Money.parseCents(t);
    } catch (_) {
      return null;
    }
  }

  int? get parsedPlannedSellingPriceCents {
    try {
      final t = plannedSellingPriceController.text.trim();
      if (t.isEmpty) return null;
      return Money.parseCents(t);
    } catch (_) {
      return null;
    }
  }

  int get itemTotalCostCents {
    final cost = parsedUnitCostCents ?? 0;
    return cost * quantity;
  }

  int get itemTotalPlannedSellingCents {
    final price = parsedPlannedSellingPriceCents ?? 0;
    return price * quantity;
  }

  int get itemTotalPlannedProfitCents {
    final cost = parsedUnitCostCents ?? 0;
    final price = parsedPlannedSellingPriceCents ?? 0;
    return (price - cost) * quantity;
  }

  bool get hasData {
    return categoryId != null ||
        colorId != null ||
        unitCostController.text.trim().isNotEmpty ||
        plannedSellingPriceController.text.trim().isNotEmpty ||
        photoPaths.isNotEmpty;
  }

  final List<String> photoPaths = [];

  _BatchItemDraft copy() {
    final draft = _BatchItemDraft(
      categoryId: categoryId,
      colorId: colorId,
      quantity: quantity,
      note: note,
    );
    draft.photoPaths.addAll(photoPaths);
    draft.unitCostController.text = unitCostController.text;
    draft.plannedSellingPriceController.text =
        plannedSellingPriceController.text;
    return draft;
  }

  void dispose() {
    unitCostController.dispose();
    plannedSellingPriceController.dispose();
  }
}

final class BatchPurchaseScreen extends ConsumerStatefulWidget {
  const BatchPurchaseScreen({super.key});

  @override
  ConsumerState<BatchPurchaseScreen> createState() =>
      _BatchPurchaseScreenState();
}

final class _BatchPurchaseScreenState
    extends ConsumerState<BatchPurchaseScreen> {
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  String? _selectedSupplierId;
  String _selectedAccountId = 'acc_cash';
  bool _isSaving = false;

  final List<_BatchItemDraft> _items = [];

  @override
  void initState() {
    super.initState();
    _addItem(_BatchItemDraft());
  }

  @override
  void dispose() {
    _noteController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  int get _totalPieces =>
      _items.fold<int>(0, (sum, item) => sum + item.quantity);

  int get _totalCostCents =>
      _items.fold<int>(0, (sum, item) => sum + item.itemTotalCostCents);

  void _addItem([_BatchItemDraft? initialDraft]) {
    setState(() {
      final defaultCat = _items.isNotEmpty ? _items.last.categoryId : null;
      final defaultColor = _items.isNotEmpty ? _items.last.colorId : null;
      final draft =
          initialDraft ??
          _BatchItemDraft(
            categoryId: defaultCat,
            colorId: defaultColor,
            quantity: 1,
          );
      draft.unitCostController.addListener(_onItemControllerChanged);
      draft.plannedSellingPriceController.addListener(_onItemControllerChanged);
      _items.add(draft);
    });
  }

  void _onItemControllerChanged() {
    if (mounted) setState(() {});
  }

  void _duplicateItem(int index) {
    setState(() {
      final clone = _items[index].copy();
      clone.unitCostController.addListener(_onItemControllerChanged);
      clone.plannedSellingPriceController.addListener(_onItemControllerChanged);
      _items.insert(index + 1, clone);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Item #${index + 1} duplicated'),
      ),
    );
  }

  Future<void> _confirmDeleteItem(int index) async {
    if (_items.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A batch must have at least one item')),
      );
      return;
    }

    final item = _items[index];
    if (item.hasData) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove item?'),
          content: Text('Remove item #${index + 1} from this batch?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() {
      final removed = _items.removeAt(index);
      removed.dispose();
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
    final totalCost = _totalCostCents;
    if (totalCost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid purchase prices for items'),
        ),
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

    final repo = ref.read(purchaseRepositoryProvider);

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

      final cost = item.parsedUnitCostCents;
      if (cost == null || cost <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter purchase price for item #${i + 1}'),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final List<BatchItemInput> batchItems = [];

      for (final draft in _items) {
        final unitCost = draft.parsedUnitCostCents;
        final sellingPrice = draft.parsedPlannedSellingPriceCents;

        batchItems.add(
          BatchItemInput(
            categoryId: draft.categoryId!,
            colorId: draft.colorId!,
            quantity: draft.quantity,
            unitCostCents: unitCost,
            sellingPriceCents: sellingPrice,
            photoPath: draft.photoPaths.isEmpty
                ? null
                : draft.photoPaths.join('|'),
            note: draft.note,
          ),
        );
      }

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
              'Batch purchase saved! ($_totalPieces pieces added to stock)',
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

    final totalCost = _totalCostCents;
    final totalPieces = _totalPieces;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Batch Purchase'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add item',
            onPressed: _addItem,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.s,
            AppSpacing.screenPadding,
            AppSpacing.m,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.border)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: $totalPieces pcs',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textMuted,
                    ),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        Money.etb(totalCost),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Sora',
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              AppButton(
                key: const ValueKey('save_batch_purchase_button'),
                label: _isSaving
                    ? 'Saving...'
                    : 'Save Batch (${Money.etb(totalCost)})',
                onPressed: _isSaving ? null : _saveBatch,
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.m,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          children: [
            // Batch Details Header Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Batch Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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

                  // Supplier picker (selected from existing suppliers)
                  suppliersAsync.when(
                    data: (suppliers) => DropdownButtonFormField<String?>(
                      initialValue: _selectedSupplierId,
                      decoration: const InputDecoration(
                        labelText: 'Supplier (optional)',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('No supplier (optional)'),
                        ),
                        for (final s in suppliers)
                          DropdownMenuItem(value: s.id, child: Text(s.name)),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedSupplierId = val);
                      },
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // Payment Account Selection
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

                  // Batch note
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Batch note (optional)',
                      hintText: 'e.g. Merkato order #4',
                      prefixIcon: Icon(Icons.note_alt_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.m),

            // Items Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Batch Items (${_items.length})',
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
                key: ObjectKey(_items[i]),
                index: i,
                draft: _items[i],
                categoriesAsync: categoriesAsync,
                colorsAsync: colorsAsync,
                onDuplicate: () => _duplicateItem(i),
                onRemove: () => _confirmDeleteItem(i),
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.m),
            ],
          ],
        ),
      ),
    );
  }
}

final class _BatchItemCard extends StatelessWidget {
  const _BatchItemCard({
    super.key,
    required this.index,
    required this.draft,
    required this.categoriesAsync,
    required this.colorsAsync,
    required this.onDuplicate,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final _BatchItemDraft draft;
  final AsyncValue<List<CategoryRow>> categoriesAsync;
  final AsyncValue<List<ColorRow>> colorsAsync;
  final VoidCallback onDuplicate;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with Item title, Total badge, Duplicate, and Delete
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Item #${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    if (draft.parsedUnitCostCents != null)
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                AppRadius.chip,
                              ),
                            ),
                            child: Text(
                              'Total: ${Money.etb(draft.itemTotalCostCents)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                tooltip: 'Duplicate item',
                onPressed: onDuplicate,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: colors.loss),
                tooltip: 'Delete item',
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),

          // Category Dropdown
          categoriesAsync.when(
            data: (categories) => DropdownButtonFormField<String>(
              initialValue: draft.categoryId,
              decoration: const InputDecoration(labelText: 'Category *'),
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

          // Color Dropdown (includes Mixed!)
          colorsAsync.when(
            data: (colorList) => DropdownButtonFormField<String>(
              initialValue: draft.colorId,
              decoration: const InputDecoration(labelText: 'Color *'),
              items: [
                for (final c in colorList)
                  DropdownMenuItem(
                    value: c.id,
                    child: Row(
                      children: [
                        _ColorDot(
                          hex: c.hex,
                          isMixed: c.name.toLowerCase() == 'mixed',
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

          // Quantity Stepper
          Row(
            children: [
              const Text(
                'Quantity:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
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

          // Purchase price per piece
          MoneyField(
            label: 'Purchase price (per piece) *',
            controller: draft.unitCostController,
            quantity: draft.quantity,
          ),
          const SizedBox(height: AppSpacing.m),

          // Optional planned selling price
          MoneyField(
            label: 'Planned selling price per piece (optional)',
            controller: draft.plannedSellingPriceController,
            quantity: draft.quantity,
          ),
          if (draft.parsedPlannedSellingPriceCents != null &&
              draft.parsedPlannedSellingPriceCents! > 0) ...[
            const SizedBox(height: AppSpacing.s),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.s,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target revenue:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors.textMuted,
                        ),
                      ),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            draft.quantity > 1
                                ? '${Money.etb(draft.itemTotalPlannedSellingCents)} (${Money.etb(draft.parsedPlannedSellingPriceCents!)}/pc)'
                                : Money.etb(draft.itemTotalPlannedSellingCents),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Expected profit:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors.textMuted,
                        ),
                      ),
                      () {
                        final unitCost = draft.parsedUnitCostCents ?? 0;
                        final unitSell =
                            draft.parsedPlannedSellingPriceCents ?? 0;
                        final totalProfit = draft.itemTotalPlannedProfitCents;
                        final unitProfit = unitSell - unitCost;
                        final isProfit = totalProfit >= 0;
                        return Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              isProfit
                                  ? '+${Money.etb(totalProfit)}${draft.quantity > 1 ? ' (+${Money.etb(unitProfit)}/pc)' : ''}'
                                  : '-${Money.etb(totalProfit.abs())}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isProfit ? colors.profit : colors.loss,
                              ),
                            ),
                          ),
                        );
                      }(),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.m),

          // Photo picker for this item (supports 1 or up to draft.quantity images)
          PurchasePhotoPicker(
            photoPaths: draft.photoPaths,
            maxPhotos: draft.quantity,
            onPhotosChanged: (updated) {
              draft.photoPaths.clear();
              draft.photoPaths.addAll(updated);
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}

final class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.hex, this.isMixed = false});

  final String hex;
  final bool isMixed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (isMixed) {
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.border),
          gradient: const SweepGradient(
            colors: [
              Colors.red,
              Colors.orange,
              Colors.yellow,
              Colors.green,
              Colors.blue,
              Colors.purple,
              Colors.red,
            ],
          ),
        ),
      );
    }

    final intColor = int.tryParse(hex.replaceFirst('#', '0xFF')) ?? 0xFF000000;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(intColor),
        border: Border.all(color: colors.border),
      ),
    );
  }
}
