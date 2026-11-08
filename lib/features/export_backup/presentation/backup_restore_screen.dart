import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/database/app_database.dart';
import '../application/backup_service.dart';

final class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  final _restorePathController = TextEditingController();
  bool _isBackingUp = false;
  bool _isRestoring = false;

  @override
  void dispose() {
    _restorePathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final db = ref.watch(appDatabaseProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Text(
            'Create Backup',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.backup_outlined, color: colors.primary),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Local Database Backup',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Exports your complete offline shop database.',
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
                const SizedBox(height: AppSpacing.m),
                Text(
                  'Includes all purchases, sales, customers debts, supplier records, expenses and settings. Save to Google Drive, Telegram, email, or your phone files.',
                  style: TextStyle(fontSize: 13, color: colors.textMuted),
                ),
                const SizedBox(height: AppSpacing.l),
                if (_isBackingUp)
                  const Center(child: CircularProgressIndicator())
                else
                  AppButton(
                    label: 'Create & Share Backup',
                    icon: Icons.share_outlined,
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Share Backup File?'),
                          content: const Text(
                            'This file contains your complete shop data (purchases, sales, debts, expenses). Share it only with people you trust or save it to your personal storage.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () async {
                                Navigator.of(ctx).pop();
                                final messenger = ScaffoldMessenger.of(context);
                                setState(() => _isBackingUp = true);
                                try {
                                  await BackupService.createBackup(db);
                                } catch (e) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Backup failed: $e'),
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => _isBackingUp = false);
                                  }
                                }
                              },
                              child: const Text('Continue'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Restore Database',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.restore, color: colors.warning),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Restore from Backup File',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Replaces current database with a saved file.',
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
                const SizedBox(height: AppSpacing.m),
                Text(
                  'A safety copy of your current database will be saved before restoring. Please restart the app after restoring.',
                  style: TextStyle(fontSize: 13, color: colors.textMuted),
                ),
                const SizedBox(height: AppSpacing.m),
                AppTextField(
                  label: 'Backup file path',
                  hintText:
                      '/storage/emulated/0/Download/firabonda_backup.sqlite',
                  controller: _restorePathController,
                ),
                const SizedBox(height: AppSpacing.l),
                if (_isRestoring)
                  const Center(child: CircularProgressIndicator())
                else
                  AppButton(
                    label: 'Verify & Restore',
                    icon: Icons.restore_page_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _confirmRestore(db),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRestore(AppDatabase db) {
    final path = _restorePathController.text.trim();
    if (path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the backup file path')),
      );
      return;
    }

    final file = File(path);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File not found at specified path')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Restore?'),
        content: const Text(
          'This will overwrite existing records with the data from the backup file. A safety copy of your current data will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);
              nav.pop();
              setState(() => _isRestoring = true);
              try {
                await BackupService.restoreDatabase(
                  backupFile: file,
                  currentDb: db,
                );
                if (!mounted) return;
                showDialog<void>(
                  context: context,
                  builder: (alertCtx) => AlertDialog(
                    title: const Text('Restore Successful'),
                    content: const Text(
                      'Database restored successfully. Please restart Fira Bonda to refresh all screens.',
                    ),
                    actions: [
                      FilledButton(
                        onPressed: () => Navigator.of(alertCtx).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Restore failed: $e')),
                );
              } finally {
                if (mounted) setState(() => _isRestoring = false);
              }
            },
            child: const Text('Proceed with Restore'),
          ),
        ],
      ),
    );
  }
}
