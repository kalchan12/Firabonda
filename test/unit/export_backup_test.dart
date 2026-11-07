import 'dart:io';

import 'package:drift/native.dart';
import 'package:firabonda/data/database/app_database.dart';
import 'package:firabonda/features/export_backup/application/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  group('BackupService validation', () {
    test('rejects non-existent file', () async {
      final nonExistent = File('/tmp/non_existent_firabonda_backup.sqlite');
      expect(
        () => BackupService.restoreDatabase(
          backupFile: nonExistent,
          currentDb: db,
        ),
        throwsA(isA<InvalidBackupException>()),
      );
    });

    test('rejects file without SQLite header', () async {
      final tempFile = File('${Directory.systemTemp.path}/fake_backup.sqlite');
      await tempFile.writeAsString('This is just plain text, not a sqlite database!');
      addTearDown(() {
        if (tempFile.existsSync()) tempFile.deleteSync();
      });

      expect(
        () => BackupService.restoreDatabase(
          backupFile: tempFile,
          currentDb: db,
        ),
        throwsA(isA<InvalidBackupException>()),
      );
    });
  });
}
