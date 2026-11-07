import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';

/// "More" hub with the theme switcher. Secondary features land here in
/// Phase 6.
final class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final themeMode = ref.watch(themeControllerProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            Text('More', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.l),
            _ThemeSection(
              selected: themeMode,
              onSelect: (mode) =>
                  ref.read(themeControllerProvider.notifier).setMode(mode),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Business',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            const _MoreTile(
              icon: Icons.local_shipping_outlined,
              label: 'Suppliers',
            ),
            const _MoreTile(icon: Icons.payments_outlined, label: 'Expenses'),
            const _MoreTile(
              icon: Icons.handshake_outlined,
              label: 'Debts & credit',
            ),
            const _MoreTile(icon: Icons.category_outlined, label: 'Categories'),
            const _MoreTile(icon: Icons.palette_outlined, label: 'Colors'),
            const SizedBox(height: AppSpacing.l),
            Text(
              'Data',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            const _MoreTile(
              icon: Icons.picture_as_pdf_outlined,
              label: 'Export report',
            ),
            const _MoreTile(
              icon: Icons.backup_outlined,
              label: 'Backup & restore',
            ),
            const _MoreTile(icon: Icons.settings_outlined, label: 'Settings'),
            const SizedBox(height: 96),
          ],
        ),
      ),
    );
  }
}

final class _ThemeSection extends StatelessWidget {
  const _ThemeSection({required this.selected, required this.onSelect});

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Theme', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                      ),
                    ],
                    selected: {selected},
                    onSelectionChanged: (selection) =>
                        onSelect(selection.first),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Card(
      child: ListTile(
        onTap: () {},
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        leading: Icon(icon, color: colors.textMuted),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: colors.textMuted,
          semanticLabel: 'Open $label',
        ),
      ),
    );
  }
}
