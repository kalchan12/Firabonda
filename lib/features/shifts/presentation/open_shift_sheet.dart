import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/repositories/providers.dart';

Future<String?> showOpenShiftSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const OpenShiftSheet(),
  );
}

final class OpenShiftSheet extends ConsumerStatefulWidget {
  const OpenShiftSheet({super.key});

  @override
  ConsumerState<OpenShiftSheet> createState() => _OpenShiftSheetState();
}

final class _OpenShiftSheetState extends ConsumerState<OpenShiftSheet> {
  final _cashController = TextEditingController(text: '0');
  bool _isSaving = false;

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  int? get _parsedCashCents {
    try {
      final text = _cashController.text.trim();
      if (text.isEmpty) return 0;
      return Money.parseCents(text);
    } catch (_) {
      return null;
    }
  }

  Future<void> _startShift() async {
    final cashCents = _parsedCashCents ?? 0;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(shiftRepositoryProvider);
      final shiftId = await repo.openShift(openingCashCents: cashCents);

      await HapticFeedback.lightImpact();

      if (mounted) {
        Navigator.of(context).pop(shiftId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Shift started with ${Money.etb(cashCents)} opening cash',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting shift: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.85,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle & Title
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.m,
                  AppSpacing.screenPadding,
                  AppSpacing.s,
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: AppSpacing.m),
                        decoration: BoxDecoration(
                          color: colors.border,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                      ),
                    ),
                    Text(
                      'Open Shift',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: colors.border, height: 1),

              // Scrollable Middle Form (Flexible prevents keyboard overflow)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Opening cash in drawer',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.s),
                      TextField(
                        controller: _cashController,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        style: const TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                        decoration: InputDecoration(
                          prefixText: 'ETB ',
                          hintText: '0',
                          filled: true,
                          fillColor:
                              colors.surfaceVariant.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.button),
                            borderSide: BorderSide(color: colors.border),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action Footer
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
                child: AppButton(
                  label: _isSaving ? 'Opening Shift...' : 'Open Shift',
                  onPressed: _isSaving ? null : _startShift,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
