import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/database/app_database.dart';

final class InvalidBackupException implements Exception {
  const InvalidBackupException([this.message = 'The selected file is not a valid SQLite database backup.']);
  final String message;

  @override
  String toString() => message;
}

final class BackupService {
  const BackupService._();

  /// Flushes the active database journal and shares a timestamped backup copy.
  static Future<File> createBackup(AppDatabase db) async {
    // Flush WAL to main SQLite file
    try {
      await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    } catch (_) {
      // Memory db in tests doesn't support WAL checkpoints
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(docsDir.path, dbFileName));

    if (!dbFile.existsSync()) {
      throw const InvalidBackupException('Database file not found on device.');
    }

    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final tempDir = await getTemporaryDirectory();
    final backupCopy = File(
      p.join(tempDir.path, 'firabonda_backup_$timestamp.sqlite'),
    );

    await dbFile.copy(backupCopy.path);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(backupCopy.path)],
        text: 'Fira Bonda Database Backup ($timestamp)',
        subject: 'Fira Bonda Backup $timestamp',
      ),
    );

    return backupCopy;
  }

  /// Validates the SQLite header and restores the database file.
  static Future<void> restoreDatabase({
    required File backupFile,
    required AppDatabase currentDb,
  }) async {
    if (!backupFile.existsSync()) {
      throw const InvalidBackupException('Backup file does not exist.');
    }

    // 1. Verify SQLite header
    final headerBytes = await backupFile.openRead(0, 16).first;
    final headerStr = String.fromCharCodes(headerBytes);
    if (!headerStr.startsWith('SQLite format 3')) {
      throw const InvalidBackupException(
        'Invalid file format. The file is not a valid SQLite database.',
      );
    }

    // 2. Locate active database
    final docsDir = await getApplicationDocumentsDirectory();
    final activeDbFile = File(p.join(docsDir.path, dbFileName));

    // 3. Keep safety copy of active database
    if (activeDbFile.existsSync()) {
      final safetyFile = File(p.join(docsDir.path, '$dbFileName.safety'));
      await activeDbFile.copy(safetyFile.path);
    }

    // 4. Overwrite active database with backup
    await backupFile.copy(activeDbFile.path);
  }
}
