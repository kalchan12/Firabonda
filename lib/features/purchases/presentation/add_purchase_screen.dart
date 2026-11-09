import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/money_field.dart';
import '../../../data/models/shop_models.dart';
import '../../../data/repositories/providers.dart';
import '../../settings/application/settings_controller.dart';
import '../application/purchases_controller.dart';
import 'widgets/add_category_dialog.dart';
import 'widgets/custom_color_dialog.dart';
import 'widgets/purchase_photo_picker.dart';

final class AddPurchaseScreen extends ConsumerStatefulWidget {
  const AddPurchaseScreen({super.key, this.initialPurchase});

  final PurchaseOverview? initialPurchase;

  @override
  ConsumerState<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

final class _AddPurchaseScreenState extends ConsumerState<AddPurchaseScreen> {
  static String? _lastCategoryId;
  static String? _lastSupplierId;

  final _unitCost = TextEditingController();
  final _sellingPrice = TextEditingController();
  final _size = TextEditingController();
  final _note = TextEditingController();

  int _quantity = 1;
  String? _selectedCategoryId;
  String? _selectedColorId;
  String? _selectedSupplierId;
  DateTime _date = DateTime.now();
  List<String> _photoPaths = [];
  bool _showSizeInput = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPurchase;
    if (initial != null) {
      _selectedCategoryId = initial.categoryId;
      _selectedColorId = initial.colorId;
      _selectedSupplierId = initial.supplierId;
      _quantity = initial.quantity;
      _unitCost.text = Money.amount(initial.unitCostCents);
      if (initial.sellingPriceCents != null) {
        _sellingPrice.text = Money.amount(initial.sellingPriceCents!);
      }
      if (initial.size != null && initial.size!.isNotEmpty) {
        _size.text = initial.size!;
        _showSizeInput = true;
      }
      if (initial.note != null) {
        _note.text = initial.note!;
      }
      _photoPaths = List<String>.from(initial.photoPaths);
      _date = initial.date;
    } else {
      // Smart default: remember category and supplier from last added purchase
      _selectedCategoryId = _lastCategoryId;
      _selectedSupplierId = _lastSupplierId;
    }
    _unitCost.addListener(_onCostOrPriceChanged);
    _sellingPrice.addListener(_onCostOrPriceChanged);
  }

  void _onCostOrPriceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _unitCost.removeListener(_onCostOrPriceChanged);
    _sellingPrice.removeListener(_onCostOrPriceChanged);
    _unitCost.dispose();
    _sellingPrice.dispose();
    _size.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _totalCents {
    final unit = _tryParseCents(_unitCost.text);
    return unit == null ? 0 : unit * _quantity;
  }

  static int? _tryParseCents(String text) {
    try {
      return Money.parseCents(text);
    } on FormatException {
      return null;
    }
  }

  Future<void> _onAddCategory() async {
    final result = await showAddCategoryDialog(context);
    if (result == null) return;
    try {
      final repo = ref.read(categoryRepositoryProvider);
      final created = await repo.add(name: result.$1, icon: result.$2);
      setState(() => _selectedCategoryId = created.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not add category: $e')));
      }
    }
  }

  Future<void> _onAddColor() async {
    final result = await showCustomColorDialog(context);
    if (result == null) return;
    try {
      final repo = ref.read(colorRepositoryProvider);
      final created = await repo.add(name: result.$1, hex: result.$2);
      setState(() => _selectedColorId = created.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not add color: $e')));
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    final categoryId =
        _selectedCategoryId ??
        ref.read(categoriesStreamProvider).value?.firstOrNull?.id;
    if (categoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }
    final colorId =
        _selectedColorId ??
        ref.read(colorsStreamProvider).value?.firstOrNull?.id;
    if (colorId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a color')));
      return;
    }
    final unitCostCents = _tryParseCents(_unitCost.text);
    if (unitCostCents == null || unitCostCents <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid unit cost')),
      );
      return;
    }

    final sellingPriceCents = _sellingPrice.text.trim().isEmpty
        ? null
        : _tryParseCents(_sellingPrice.text);

    setState(() => _isSaving = true);
    try {
      final input = PurchaseInput(
        categoryId: categoryId,
        colorId: colorId,
        supplierId: _selectedSupplierId,
        size: _size.text.trim().isEmpty ? null : _size.text.trim(),
        quantity: _quantity,
        unitCostCents: unitCostCents,
        sellingPriceCents: sellingPriceCents,
        photoPath: _photoPaths.isEmpty ? null : _photoPaths.join('|'),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        date: _date,
      );

      final repo = ref.read(purchaseRepositoryProvider);
      if (widget.initialPurchase == null) {
        await repo.add(input);
      } else {
        await repo.update(widget.initialPurchase!.id, input);
      }

      _lastCategoryId = categoryId;
      _lastSupplierId = _selectedSupplierId;
      await HapticFeedback.lightImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.initialPurchase == null
                  ? 'Purchase saved successfully'
                  : 'Purchase updated successfully',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving purchase: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final initial = widget.initialPurchase;
    if (initial == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete purchase?'),
        content: Text(
          initial.stockLeft < initial.quantity
              ? 'This purchase has ${initial.quantity - initial.stockLeft} sales recorded. Deleting it will also remove those sales from calculations. Continue?'
              : 'Are you sure you want to delete this purchase?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(purchaseRepositoryProvider);
      await repo.softDelete(initial.id);
      await HapticFeedback.mediumImpact();
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Purchase deleted'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () async {
                await repo.restore(initial.id);
              },
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final colorsAsync = ref.watch(colorsStreamProvider);
    final suppliersAsync = ref.watch(suppliersStreamProvider);
    final showSizeSetting = ref.watch(showSizeFieldProvider);

    final activeCategoryId =
        _selectedCategoryId ?? categoriesAsync.value?.firstOrNull?.id;
    final activeColorId =
        _selectedColorId ?? colorsAsync.value?.firstOrNull?.id;

    // Price memory lookup
    final priceMemoryAsync = activeCategoryId == null
        ? null
        : ref.watch(
            priceMemoryProvider((
              categoryId: activeCategoryId,
              colorId: activeColorId,
            )),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialPurchase == null ? 'Add purchase' : 'Edit purchase',
        ),
        actions: [
          if (widget.initialPurchase != null)
            IconButton(
              icon: Icon(Icons.delete_outline, color: colors.loss),
              tooltip: 'Delete purchase',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            // Category section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Category',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: _onAddCategory,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add new'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            categoriesAsync.when(
              data: (categories) => Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  for (final category in categories)
                    AppChip(
                      label: category.name,
                      selected: category.id == activeCategoryId,
                      onTap: () =>
                          setState(() => _selectedCategoryId = category.id),
                    ),
                ],
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Text(
                'Error loading categories: $err',
                style: TextStyle(color: colors.loss),
              ),
            ),
            const SizedBox(height: AppSpacing.l),

            // Color section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Color', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: _onAddColor,
                  icon: const Icon(Icons.palette_outlined, size: 18),
                  label: const Text('Custom color'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            colorsAsync.when(
              data: (colorList) => Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  for (final c in colorList)
                    AppChip(
                      label: c.name,
                      dotColor: Color(
                        int.tryParse(c.hex.replaceFirst('#', '0xFF')) ??
                            0xFF000000,
                      ),
                      selected: c.id == activeColorId,
                      onTap: () => setState(() => _selectedColorId = c.id),
                    ),
                ],
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Text(
                'Error loading colors: $err',
                style: TextStyle(color: colors.loss),
              ),
            ),
            const SizedBox(height: AppSpacing.l),

            // Quantity stepper
            Text('Quantity', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                _StepperButton(
                  key: const ValueKey('stepper_remove'),
                  icon: Icons.remove,
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StepperButton(
                  key: const ValueKey('stepper_add'),
                  icon: Icons.add,
                  onPressed: () => setState(() => _quantity++),
                ),
                const Spacer(),
                ActionChip(
                  label: const Text('+1'),
                  onPressed: () => setState(() => _quantity += 1),
                ),
                const SizedBox(width: 4),
                ActionChip(
                  label: const Text('+5'),
                  onPressed: () => setState(() => _quantity += 5),
                ),
                const SizedBox(width: 4),
                ActionChip(
                  label: const Text('+10'),
                  onPressed: () => setState(() => _quantity += 10),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),

            // Unit cost and price memory hint
            MoneyField(
              label: 'Unit cost',
              controller: _unitCost,
              quantity: _quantity,
            ),
            if (priceMemoryAsync != null)
              priceMemoryAsync.when(
                data: (lastCostCents) {
                  if (lastCostCents == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 4),
                    child: InkWell(
                      onTap: () {
                        _unitCost.text = Money.amount(lastCostCents);
                        setState(() {});
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 16,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Last time: ${Money.etb(lastCostCents)} each',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(tap to use)',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
              ),
            const SizedBox(height: AppSpacing.m),

            // Computed total cost preview
            AppCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _quantity > 1
                            ? 'Total cost ($_quantity pcs)'
                            : 'Total cost',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        Money.etb(_totalCents),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (_tryParseCents(_sellingPrice.text) != null &&
                      _tryParseCents(_sellingPrice.text)! > 0) ...[
                    const SizedBox(height: 8),
                    Divider(color: colors.border, height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _quantity > 1
                              ? 'Target revenue ($_quantity pcs)'
                              : 'Target revenue',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          Money.etb(
                            _tryParseCents(_sellingPrice.text)! * _quantity,
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Expected profit',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        () {
                          final unitCost = _tryParseCents(_unitCost.text) ?? 0;
                          final unitSell =
                              _tryParseCents(_sellingPrice.text) ?? 0;
                          final totalProfit = (unitSell - unitCost) * _quantity;
                          final unitProfit = unitSell - unitCost;
                          final isProfit = totalProfit >= 0;
                          return Text(
                            isProfit
                                ? '+${Money.etb(totalProfit)}${_quantity > 1 ? ' (+${Money.etb(unitProfit)} each)' : ''}'
                                : '-${Money.etb(totalProfit.abs())}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isProfit ? colors.profit : colors.loss,
                            ),
                          );
                        }(),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),

            // Optional planned selling price
            MoneyField(
              label: 'Planned selling price (optional)',
              controller: _sellingPrice,
              quantity: _quantity,
              helperText: 'Prefills price when marking items as sold',
            ),
            const SizedBox(height: AppSpacing.m),

            // Optional Supplier
            Text('Supplier', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            suppliersAsync.when(
              data: (suppliers) {
                if (suppliers.isEmpty) {
                  return Text(
                    'No suppliers added yet',
                    style: TextStyle(fontSize: 13, color: colors.textMuted),
                  );
                }
                return Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.s,
                  children: [
                    AppChip(
                      label: 'None',
                      selected: _selectedSupplierId == null,
                      onTap: () => setState(() => _selectedSupplierId = null),
                    ),
                    for (final s in suppliers)
                      AppChip(
                        label: s.name,
                        selected: s.id == _selectedSupplierId,
                        onTap: () => setState(() => _selectedSupplierId = s.id),
                      ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.l),

            // Date picker tile
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: colors.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Date: ${DateFormat.yMMMd().format(_date)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: colors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.m),

            // Size field (optional, hidden by default per PRD / Settings)
            if (showSizeSetting || _showSizeInput) ...[
              AppTextField(
                label: 'Size (optional)',
                controller: _size,
                hintText: 'e.g. M, L, XL, 32',
              ),
              const SizedBox(height: AppSpacing.m),
            ] else ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _showSizeInput = true),
                  icon: const Icon(Icons.straighten, size: 16),
                  label: const Text('Add size'),
                ),
              ),
            ],

            // Note field
            AppTextField(
              label: 'Note (optional)',
              controller: _note,
              hintText: 'Any extra details',
            ),
            const SizedBox(height: AppSpacing.m),

            // Photo picker
            PurchasePhotoPicker(
              photoPaths: _photoPaths,
              maxPhotos: _quantity,
              onPhotosChanged: (updated) =>
                  setState(() => _photoPaths = updated),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Save button
            AppButton(
              label: widget.initialPurchase == null
                  ? (_isSaving ? 'Saving...' : 'Save purchase')
                  : (_isSaving ? 'Updating...' : 'Update purchase'),
              onPressed: _isSaving ? () {} : _save,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

final class _StepperButton extends StatelessWidget {
  const _StepperButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final enabled = onPressed != null;
    return Material(
      color: enabled ? colors.surfaceVariant : colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: enabled ? colors.textPrimary : colors.textMuted,
          ),
        ),
      ),
    );
  }
}
