import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';

class BackupService {
  final DatabaseHelper dbHelper;

  BackupService({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper();

  static const List<String> _tableNames = [
    'income_transactions',
    'expense_transactions',
    'allocation_transactions',
    'obligation_definitions',
    'obligation_payments',
    'obligation_payment_splits',
    'target_definitions',
    'day_activities',
    'reminder_settings',
    'reminder_logs',
    'wallets',
    'wallet_transfers',
  ];

  /// Generates a formatted JSON string containing all application data.
  Future<String> exportBackupJson() async {
    final db = await dbHelper.database;
    final Map<String, dynamic> backupData = {
      'appName': 'ojol_daily',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'tables': <String, dynamic>{},
    };

    final Map<String, dynamic> tablesData = {};
    for (final table in _tableNames) {
      final rows = await db.query(table);
      tablesData[table] = rows;
    }

    backupData['tables'] = tablesData;
    return const JsonEncoder.withIndent('  ').convert(backupData);
  }

  /// Parses and validates a JSON backup string, returning a summary map.
  /// Throws [FormatException] if validation fails.
  Map<String, dynamic> parseAndValidateBackup(String jsonStr) {
    if (jsonStr.trim().isEmpty) {
      throw const FormatException('Data JSON backup tidak boleh kosong.');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(jsonStr);
    } catch (e) {
      throw FormatException('Format JSON tidak valid: ${e.toString()}');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Struktur data backup harus berupa JSON Object.');
    }

    if (!decoded.containsKey('tables') || decoded['tables'] is! Map) {
      throw const FormatException('File backup tidak memiliki atribut "tables" yang valid.');
    }

    final Map<String, dynamic> tables = Map<String, dynamic>.from(decoded['tables'] as Map);

    int totalIncome = (tables['income_transactions'] as List?)?.length ?? 0;
    int totalExpense = (tables['expense_transactions'] as List?)?.length ?? 0;
    int totalObligations = (tables['obligation_definitions'] as List?)?.length ?? 0;
    int totalWallets = (tables['wallets'] as List?)?.length ?? 0;

    return {
      'exportedAt': decoded['exportedAt'] ?? 'Tidak diketahui',
      'appName': decoded['appName'] ?? 'ojol_daily',
      'version': decoded['version'] ?? 1,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'totalObligations': totalObligations,
      'totalWallets': totalWallets,
      'tablesData': tables,
    };
  }

  /// Restores SQLite database from a JSON backup string inside a single transaction.
  Future<void> restoreBackupJson(String jsonStr) async {
    final summary = parseAndValidateBackup(jsonStr);
    final Map<String, dynamic> tables = summary['tablesData'] as Map<String, dynamic>;

    final db = await dbHelper.database;

    await db.transaction((txn) async {
      // 1. Clear all existing data
      for (final table in _tableNames) {
        await txn.delete(table);
      }

      // 2. Insert records table by table
      for (final table in _tableNames) {
        if (tables.containsKey(table) && tables[table] is List) {
          final List rows = tables[table] as List;
          for (final row in rows) {
            if (row is Map) {
              await txn.insert(
                table,
                Map<String, dynamic>.from(row),
              );
            }
          }
        }
      }

      // 3. Ensure default wallets exist if wallets table ended up empty
      final walletCount = (await txn.query('wallets')).length;
      if (walletCount == 0) {
        final now = DateTime.now().toIso8601String();
        await txn.insert('wallets', {
          'id': 'w_cash',
          'name': 'Tunai',
          'iconName': 'payments',
          'colorHex': '#4CAF50',
          'isDefault': 1,
          'createdAt': now,
          'updatedAt': now,
        });
      }
    });

    // Mark setup completed if target definitions exist
    final targets = await db.query('target_definitions');
    final prefs = await SharedPreferences.getInstance();
    if (targets.isNotEmpty) {
      await prefs.setBool('financial_setup_completed', true);
    }
  }

  /// Saves backup string to a local JSON file in application documents / temp folder.
  Future<File> writeBackupToFile(String jsonStr) async {
    final directory = kIsWeb
        ? await getTemporaryDirectory()
        : await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final filePath = '${directory.path}/ojol_daily_backup_$timestamp.json';
    final file = File(filePath);
    return await file.writeAsString(jsonStr);
  }

  /// Triggers standard system share sheet with the backup file.
  Future<void> shareBackupFile() async {
    final jsonStr = await exportBackupJson();
    final file = await writeBackupToFile(jsonStr);
    final xFile = XFile(file.path, mimeType: 'application/json');
    // ignore: deprecated_member_use
    await Share.shareXFiles(
      [xFile],
      text: 'Backup Data Keuangan Ojol Daily (${DateTime.now().toString().substring(0, 10)})',
      subject: 'Ojol Daily Backup Data',
    );
  }

  /// Pick a backup file using FilePicker and return its content string.
  Future<String?> pickAndReadBackupFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final platformFile = result.files.first;

    // Handle bytes (Web or memory loaded)
    if (platformFile.bytes != null) {
      return utf8.decode(platformFile.bytes!);
    }

    // Handle file path (Desktop / Mobile)
    if (platformFile.path != null) {
      final file = File(platformFile.path!);
      return await file.readAsString();
    }

    return null;
  }
}
