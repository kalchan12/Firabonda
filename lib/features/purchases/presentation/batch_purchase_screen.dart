import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/money_field.dart';
import '../../../data/database/app_database.dart';
import '../../../data/models/shop_models.dart';
import '../../../data/repositories/providers.dart';

enum BatchColorMode { oneColor, twoColors, mixed }

final class _BatchItemDraft {
  _BatchItemDraft({
    this.categoryId,
    this.colorMode = BatchColorMode.oneColor,
    this.colorIdA,
    this.colorIdB,
    this.quantity = 1,
    this.quantityA,
    this.quantityB,
    TextEditingController? unitCostController,
    TextEditingController? plannedSellingPriceController,
    this.note,
  }) : unitCostController = unitCostController ?? TextEditingController(),
       plannedSellingPriceController =
           plannedSellingPriceController ?? TextEditingController();

  String? categoryId;
  BatchColorMode colorMode;
  String? colorIdA;
  String? colorIdB;
  int quantity;
  int? quantityA;
  int? quantityB;
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

  int get effectiveQuantityA {
    if (colorMode != BatchColorMode.twoColors) return quantity;
    final a = quantityA ?? ((quantity + 1) ~/ 2);
    return a.clamp(1, quantity - 1);
  }

  int get effectiveQuantityB {
    if (colorMode != BatchColorMode.twoColors) return 0;
    return (quantity - effectiveQuantityA).clamp(1, quantity - 1);
  }

  int get lineTotalCostCents {
    final cost = parsedUnitCostCents ?? 0;
    return cost * quantity;
  }

  bool get hasData {
    return categoryId != null ||
        unitCostController.text.trim().isNotEmpty ||
        plannedSellingPriceController.text.trim().isNotEmpty;
  }

  _BatchItemDraft copy() {
    final draft = _BatchItemDraft(
      categoryId: categoryId,
      colorMode: colorMode,
      colorIdA: colorIdA,
      colorIdB: colorIdB,
      quantity: quantity,
      quantityA: quantityA,
      quantityB: quantityB,
      note: note,
    );
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

enum BatchPricingMode { pricePerLine, bundleTotal }

final class BatchPurchaseScreen extends ConsumerStatefulWidget {
  const BatchPurchaseScreen({super.key});

  @override
  ConsumerState<BatchPurchaseScreen> createState() =>
      _BatchPurchaseScreenState();
}

final class _BatchPurchaseScreenState
    extends ConsumerState<BatchPurchaseScreen> {
  final _bundleTotalCostController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  String? _selectedSupplierId;
  String _selectedAccountId = 'acc_cash';
  BatchPricingMode _pricingMode = BatchPricingMode.pricePerLine;
  bool _isSaving = false;

  final List<_BatchItemDraft> _items = [];

  @override
  void initState() {
    super.initState();
    _bundleTotalCostController.addListener(() => setState(() {}));
    _items.add(_BatchItemDraft());
  }

  @override
  void dispose() {
    _bundleTotalCostController.dispose();
    _noteController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  int? get _parsedBundleTotalCostCents {
    try {
      final t = _bundleTotalCostController.text.trim();
      if (t.isEmpty) return null;
      return Money.parseCents(t);
    } catch (_) {
      return null;
    }
  }

  int get _totalPieces =>
      _items.fold<int>(0, (sum, item) => sum + item.quantity);

  int get _totalCostCents {
    if (_pricingMode == BatchPricingMode.bundleTotal) {
      return _parsedBundleTotalCostCents ?? 0;
    }
    return _items.fold<int>(0, (sum, item) => sum + item.lineTotalCostCents);
  }

  void _addItem() {
    setState(() {
      final defaultCat = _items.isNotEmpty ? _items.last.categoryId : null;
      final defaultColorA = _items.isNotEmpty ? _items.last.colorIdA : null;
      _items.add(
        _BatchItemDraft(
          categoryId: defaultCat,
          colorIdA: defaultColorA,
          quantity: 1,
        ),
      );
    });
  }

  void _duplicateItem(int index) {
    setState(() {
      final clone = _items[index].copy();
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

  Future<void> _showAddSupplierDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Supplier'),
        content: Column(
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              try {
                final repo = ref.read(supplierRepositoryProvider);
                final supplier = await repo.add(
                  SupplierInput(
                    name: name,
                    phone: phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                  ),
                );
                if (mounted) {
                  setState(() => _selectedSupplierId = supplier.id);
                }
                if (ctx.mounted) {
                  Navigator.of(ctx).pop(true);
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Error adding supplier: $e')),
                  );
                }
              }
            },
            child: const Text('Save Supplier'),
          ),
        ],
      ),
    );

    nameController.dispose();
    phoneController.dispose();
    if (added == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier added and selected')),
      );
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

      if (_pricingMode == BatchPricingMode.pricePerLine) {
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

      switch (item.colorMode) {
        case BatchColorMode.oneColor:
          if (item.colorIdA == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please select color for item #${i + 1}')),
            );
            return;
          }
        case BatchColorMode.twoColors:
          if (item.colorIdA == null || item.colorIdB == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Please select both Color A and Color B for item #${i + 1}',
                ),
              ),
            );
            return;
          }
          if (item.quantity < 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Item #${i + 1} must have at least 2 pieces to split into 2 colors',
                ),
              ),
            );
            return;
          }
        case BatchColorMode.mixed:
          break;
      }
    }

    setState(() => _isSaving = true);
    try {
      final mixedColorId = await repo.getOrCreateMixedColorId();
      final List<BatchItemInput> batchItems = [];

      for (final draft in _items) {
        final unitCost = _pricingMode == BatchPricingMode.pricePerLine
            ? draft.parsedUnitCostCents
            : null;
        final sellingPrice = draft.parsedPlannedSellingPriceCents;

        if (draft.colorMode == BatchColorMode.twoColors) {
          final qtyA = draft.effectiveQuantityA;
          final qtyB = draft.effectiveQuantityB;

          batchItems.add(
            BatchItemInput(
              categoryId: draft.categoryId!,
              colorId: draft.colorIdA!,
              quantity: qtyA,
              unitCostCents: unitCost,
              sellingPriceCents: sellingPrice,
              note: draft.note,
            ),
          );

          batchItems.add(
            BatchItemInput(
              categoryId: draft.categoryId!,
              colorId: draft.colorIdB!,
              quantity: qtyB,
              unitCostCents: unitCost,
              sellingPriceCents: sellingPrice,
              note: draft.note,
            ),
          );
        } else if (draft.colorMode == BatchColorMode.mixed) {
          batchItems.add(
            BatchItemInput(
              categoryId: draft.categoryId!,
              colorId: mixedColorId,
              quantity: draft.quantity,
              unitCostCents: unitCost,
              sellingPriceCents: sellingPrice,
              note: draft.note != null
                  ? '${draft.note} (Mixed)'
                  : 'Mixed colors',
            ),
          );
        } else {
          batchItems.add(
            BatchItemInput(
              categoryId: draft.categoryId!,
              colorId: draft.colorIdA!,
              quantity: draft.quantity,
              unitCostCents: unitCost,
              sellingPriceCents: sellingPrice,
              note: draft.note,
            ),
          );
        }
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
        title: const Text('Batch Purchase (Bundle Lot)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add item line',
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
                    'Total pieces: $totalPieces pcs',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textMuted,
                    ),
                  ),
                  Text(
                    Money.etb(totalCost),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Sora',
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              AppButton(
                key: const ValueKey('save_batch_purchase_button'),
                label: _isSaving
                    ? 'Saving batch...'
                    : 'Save batch purchase ($totalPieces pcs • ${Money.etb(totalCost)})',
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
                    'Bundle Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // Pricing Mode: Price per line vs Bundle total
                  SegmentedButton<BatchPricingMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: BatchPricingMode.pricePerLine,
                        label: Text('Price per line (default)'),
                      ),
                      ButtonSegment(
                        value: BatchPricingMode.bundleTotal,
                        label: Text('Bundle total (split evenly)'),
                      ),
                    ],
                    selected: {_pricingMode},
                    onSelectionChanged: (val) {
                      setState(() => _pricingMode = val.first);
                    },
                  ),
                  const SizedBox(height: AppSpacing.m),

                  if (_pricingMode == BatchPricingMode.bundleTotal) ...[
                    MoneyField(
                      label: 'Total batch cost (entire bundle)',
                      controller: _bundleTotalCostController,
                    ),
                    const SizedBox(height: AppSpacing.m),
                  ],

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

                  // Supplier picker with inline "+ Add supplier"
                  suppliersAsync.when(
                    data: (suppliers) => Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            initialValue: _selectedSupplierId,
                            decoration: const InputDecoration(
                              labelText: 'Supplier (optional)',
                              prefixIcon: Icon(Icons.storefront_outlined),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('No supplier specified'),
                              ),
                              for (final s in suppliers)
                                DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name),
                                ),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedSupplierId = val);
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        IconButton.filledTonal(
                          tooltip: 'Add new supplier',
                          icon: const Icon(Icons.add),
                          onPressed: _showAddSupplierDialog,
                        ),
                      ],
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
                      hintText: 'e.g. Mercato bundle #4, quality A',
                      prefixIcon: Icon(Icons.note_alt_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.m),

            // Item Lines Header
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
                  label: const Text('Add item line'),
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
                pricingMode: _pricingMode,
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
    required this.pricingMode,
    required this.categoriesAsync,
    required this.colorsAsync,
    required this.onDuplicate,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final _BatchItemDraft draft;
  final BatchPricingMode pricingMode;
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
          // Header row with Line title, Total badge, Duplicate, and Delete
          Row(
            children: [
              Text(
                'Line #${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              if (pricingMode == BatchPricingMode.pricePerLine &&
                  draft.parsedUnitCostCents != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    'Total: ${Money.etb(draft.lineTotalCostCents)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                  ),
                ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                tooltip: 'Duplicate line',
                onPressed: onDuplicate,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: colors.loss),
                tooltip: 'Delete line',
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

          // Color Mode Segmented Button: One Color, Two Colors, Mixed
          Text(
            'Color option',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<BatchColorMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: BatchColorMode.oneColor,
                label: Text('One color'),
              ),
              ButtonSegment(
                value: BatchColorMode.twoColors,
                label: Text('Two colors'),
              ),
              ButtonSegment(value: BatchColorMode.mixed, label: Text('Mixed')),
            ],
            selected: {draft.colorMode},
            onSelectionChanged: (set) {
              draft.colorMode = set.first;
              if (draft.colorMode == BatchColorMode.twoColors &&
                  draft.quantity < 2) {
                draft.quantity = 2;
              }
              onChanged();
            },
          ),
          const SizedBox(height: AppSpacing.m),

          // Color pickers according to selected mode
          colorsAsync.when(
            data: (colorList) {
              switch (draft.colorMode) {
                case BatchColorMode.oneColor:
                  return DropdownButtonFormField<String>(
                    initialValue: draft.colorIdA,
                    decoration: const InputDecoration(labelText: 'Color *'),
                    items: [
                      for (final c in colorList)
                        DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              _ColorDot(hex: c.hex),
                              const SizedBox(width: 8),
                              Text(c.name),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (val) {
                      draft.colorIdA = val;
                      onChanged();
                    },
                  );

                case BatchColorMode.twoColors:
                  final qtyA = draft.effectiveQuantityA;
                  final qtyB = draft.effectiveQuantityB;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: draft.colorIdA,
                              decoration: const InputDecoration(
                                labelText: 'Color A *',
                              ),
                              items: [
                                for (final c in colorList)
                                  DropdownMenuItem(
                                    value: c.id,
                                    child: Row(
                                      children: [
                                        _ColorDot(hex: c.hex),
                                        const SizedBox(width: 6),
                                        Text(c.name),
                                      ],
                                    ),
                                  ),
                              ],
                              onChanged: (val) {
                                draft.colorIdA = val;
                                onChanged();
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.m),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: draft.colorIdB,
                              decoration: const InputDecoration(
                                labelText: 'Color B *',
                              ),
                              items: [
                                for (final c in colorList)
                                  DropdownMenuItem(
                                    value: c.id,
                                    child: Row(
                                      children: [
                                        _ColorDot(hex: c.hex),
                                        const SizedBox(width: 6),
                                        Text(c.name),
                                      ],
                                    ),
                                  ),
                              ],
                              onChanged: (val) {
                                draft.colorIdB = val;
                                onChanged();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s),
                      // Split ratio controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Split: $qtyA of A • $qtyB of B',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton.outlined(
                                icon: const Icon(Icons.remove, size: 16),
                                tooltip: 'Decrease Color A pieces',
                                onPressed: qtyA > 1
                                    ? () {
                                        draft.quantityA = qtyA - 1;
                                        draft.quantityB =
                                            draft.quantity - (qtyA - 1);
                                        onChanged();
                                      }
                                    : null,
                              ),
                              IconButton.outlined(
                                icon: const Icon(Icons.add, size: 16),
                                tooltip: 'Increase Color A pieces',
                                onPressed: qtyA < draft.quantity - 1
                                    ? () {
                                        draft.quantityA = qtyA + 1;
                                        draft.quantityB =
                                            draft.quantity - (qtyA + 1);
                                        onChanged();
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  );

                case BatchColorMode.mixed:
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                      vertical: AppSpacing.s,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                Colors.red,
                                Colors.yellow,
                                Colors.green,
                                Colors.blue,
                                Colors.purple,
                                Colors.red,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        const Text(
                          'Mixed pack (assorted / random colors)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
              }
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const Text('Failed to load colors'),
          ),
          const SizedBox(height: AppSpacing.m),

          // Quantity Stepper
          Row(
            children: [
              const Text(
                'Total quantity:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: AppSpacing.m),
              IconButton.outlined(
                icon: const Icon(Icons.remove, size: 18),
                onPressed:
                    draft.quantity >
                        (draft.colorMode == BatchColorMode.twoColors ? 2 : 1)
                    ? () {
                        draft.quantity--;
                        if (draft.colorMode == BatchColorMode.twoColors) {
                          draft.quantityA = (draft.quantity + 1) ~/ 2;
                          draft.quantityB = draft.quantity - draft.quantityA!;
                        }
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
                  if (draft.colorMode == BatchColorMode.twoColors) {
                    draft.quantityA = (draft.quantity + 1) ~/ 2;
                    draft.quantityB = draft.quantity - draft.quantityA!;
                  }
                  onChanged();
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),

          // Purchase price per piece (REQUIRED in pricePerLine mode)
          if (pricingMode == BatchPricingMode.pricePerLine) ...[
            MoneyField(
              label: 'Purchase price (per piece) *',
              controller: draft.unitCostController,
              quantity: draft.quantity,
            ),
            const SizedBox(height: AppSpacing.m),
          ],

          // Optional planned selling price (empty by default)
          MoneyField(
            label: 'Planned selling price per piece (optional)',
            controller: draft.plannedSellingPriceController,
          ),
        ],
      ),
    );
  }
}

final class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.hex});

  final String hex;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
