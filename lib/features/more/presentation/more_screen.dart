import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/app_card.dart';

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
              isDark: themeMode == ThemeMode.dark,
              onToggle: (enableDark) => ref
                  .read(themeControllerProvider.notifier)
                  .setMode(enableDark ? ThemeMode.dark : ThemeMode.light),
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
            _MoreTile(
              icon: Icons.local_shipping_outlined,
              label: 'Suppliers',
              onTap: () => context.push('/suppliers'),
            ),
            _MoreTile(
              icon: Icons.payments_outlined,
              label: 'Expenses',
              onTap: () => context.push('/expenses'),
            ),
            _MoreTile(
              icon: Icons.handshake_outlined,
              label: 'Debts & credit',
              onTap: () => context.push('/debts'),
            ),
            _MoreTile(
              icon: Icons.inventory_2_outlined,
              label: 'Stock adjustments (Losses)',
              onTap: () => context.push('/stock-adjustments'),
            ),
            _MoreTile(
              icon: Icons.fact_check_outlined,
              label: 'Reconciliation & audit',
              onTap: () => context.push('/reconciliation'),
            ),
            _MoreTile(
              icon: Icons.history_toggle_off_rounded,
              label: 'Shift history',
              onTap: () => context.push('/shift-history'),
            ),
            _MoreTile(
              icon: Icons.category_outlined,
              label: 'Categories & colors',
              onTap: () => context.push('/categories-colors'),
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              'Data & Backup',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            _MoreTile(
              icon: Icons.picture_as_pdf_outlined,
              label: 'Export report',
              onTap: () => context.push('/export'),
            ),
            _MoreTile(
              icon: Icons.backup_outlined,
              label: 'Backup & restore',
              onTap: () => context.push('/backup-restore'),
            ),
            _MoreTile(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => context.push('/settings'),
            ),
            const SizedBox(height: 96),
          ],
        ),
      ),
    );
  }
}

final class _ThemeSection extends StatelessWidget {
  const _ThemeSection({required this.isDark, required this.onToggle});

  final bool isDark;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? colors.primary.withValues(alpha: 0.15)
                      : colors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: isDark ? colors.primary : colors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dark mode',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDark ? 'Dark theme active' : 'Light theme active',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: isDark,
            activeThumbColor: colors.primary,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}

final class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
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
