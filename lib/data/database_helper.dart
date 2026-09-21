/// SQLite Database Helper utilizing sqflite
library;

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _dbName = 'ojol_daily.db';
  static const int _dbVersion = 4;

  static Database? _database;
  final Database? customDatabase;

  DatabaseHelper({this.customDatabase});

  Future<Database> get database async {
    if (customDatabase != null) return customDatabase!;
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Income Transactions table
    await db.execute('''
      CREATE TABLE income_transactions (
        id TEXT PRIMARY KEY,
        amount INTEGER NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        transactionDate TEXT NOT NULL,
        walletId TEXT NOT NULL DEFAULT 'w_cash',
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Expense Transactions table
    await db.execute('''
      CREATE TABLE expense_transactions (
        id TEXT PRIMARY KEY,
        amount INTEGER NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        transactionDate TEXT NOT NULL,
        walletId TEXT NOT NULL DEFAULT 'w_cash',
        source TEXT NOT NULL,
        freeAmountUsed INTEGER NOT NULL,
        allocatedAmountUsed INTEGER NOT NULL,
        targetObligationId TEXT,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Allocation Transactions table
    await db.execute('''
      CREATE TABLE allocation_transactions (
        id TEXT PRIMARY KEY,
        obligationId TEXT NOT NULL,
        amount INTEGER NOT NULL,
        allocationDate TEXT NOT NULL,
        status TEXT NOT NULL,
        usedAmount INTEGER NOT NULL DEFAULT 0,
        note TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Obligation Definitions table
    await db.execute('''
      CREATE TABLE obligation_definitions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        targetAmount INTEGER NOT NULL,
        dueDate TEXT NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'bulanan',
        isCancelled INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Obligation Payments table
    await db.execute('''
      CREATE TABLE obligation_payments (
        id TEXT PRIMARY KEY,
        obligationId TEXT NOT NULL,
        amount INTEGER NOT NULL,
        paymentDate TEXT NOT NULL,
        note TEXT,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Target Definitions table
    await db.execute('''
      CREATE TABLE target_definitions (
        id TEXT PRIMARY KEY,
        monthlyTargetAmount INTEGER NOT NULL,
        totalWorkingDays INTEGER NOT NULL,
        startBalance INTEGER NOT NULL DEFAULT 0,
        targetMonth TEXT NOT NULL,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Day Activities table
    await db.execute('''
      CREATE TABLE day_activities (
        dateString TEXT PRIMARY KEY,
        status TEXT NOT NULL,
        note TEXT
      )
    ''');

    // Reminder Settings table (PRD Section 48.9)
    await db.execute('''
      CREATE TABLE reminder_settings (
        id INTEGER PRIMARY KEY DEFAULT 1,
        enabled INTEGER NOT NULL DEFAULT 1,
        firstReminderEnabled INTEGER NOT NULL DEFAULT 1,
        firstReminderTime TEXT NOT NULL DEFAULT '20:00',
        secondReminderEnabled INTEGER NOT NULL DEFAULT 1,
        secondReminderTime TEXT NOT NULL DEFAULT '22:00',
        workDays TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7'
      )
    ''');

    // Reminder Logs table (PRD Section 48.12)
    await db.execute('''
      CREATE TABLE reminder_logs (
        dateString TEXT PRIMARY KEY,
        firstReminderSent INTEGER NOT NULL DEFAULT 0,
        secondReminderSent INTEGER NOT NULL DEFAULT 0,
        firstReminderSentAt TEXT,
        secondReminderSentAt TEXT
      )
    ''');

    // Wallets table (PRD Section 49)
    await db.execute('''
      CREATE TABLE wallets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        iconName TEXT NOT NULL DEFAULT 'account_balance_wallet',
        colorHex TEXT NOT NULL DEFAULT '#4CAF50',
        isDefault INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Obligation Payment Splits table
    await db.execute('''
      CREATE TABLE obligation_payment_splits (
        id TEXT PRIMARY KEY,
        paymentId TEXT NOT NULL,
        walletId TEXT NOT NULL,
        amount INTEGER NOT NULL
      )
    ''');

    // Wallet Transfers table
    await db.execute('''
      CREATE TABLE wallet_transfers (
        id TEXT PRIMARY KEY,
        fromWalletId TEXT NOT NULL,
        toWalletId TEXT NOT NULL,
        amount INTEGER NOT NULL,
        transferDate TEXT NOT NULL,
        note TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await _seedDefaultWallets(db);
  }

  Future<void> _seedDefaultWallets(Database db) async {
    final now = DateTime.now().toIso8601String();
    await db.insert('wallets', {
      'id': 'w_cash',
      'name': 'Tunai',
      'iconName': 'payments',
      'colorHex': '#4CAF50',
      'isDefault': 1,
      'createdAt': now,
      'updatedAt': now,
    });
    await db.insert('wallets', {
      'id': 'w_gopay',
      'name': 'GoPay',
      'iconName': 'phone_android',
      'colorHex': '#00AED6',
      'isDefault': 0,
      'createdAt': now,
      'updatedAt': now,
    });
    await db.insert('wallets', {
      'id': 'w_bca',
      'name': 'Bank BCA',
      'iconName': 'account_balance',
      'colorHex': '#005CA9',
      'isDefault': 0,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE obligation_definitions ADD COLUMN type TEXT NOT NULL DEFAULT 'bulanan'");
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute("ALTER TABLE target_definitions ADD COLUMN startBalance INTEGER NOT NULL DEFAULT 0");
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute("ALTER TABLE income_transactions ADD COLUMN walletId TEXT NOT NULL DEFAULT 'w_cash'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE expense_transactions ADD COLUMN walletId TEXT NOT NULL DEFAULT 'w_cash'");
      } catch (_) {}
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS wallets (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            iconName TEXT NOT NULL DEFAULT 'account_balance_wallet',
            colorHex TEXT NOT NULL DEFAULT '#4CAF50',
            isDefault INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
      } catch (_) {}
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS obligation_payment_splits (
            id TEXT PRIMARY KEY,
            paymentId TEXT NOT NULL,
            walletId TEXT NOT NULL,
            amount INTEGER NOT NULL
          )
        ''');
      } catch (_) {}
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS wallet_transfers (
            id TEXT PRIMARY KEY,
            fromWalletId TEXT NOT NULL,
            toWalletId TEXT NOT NULL,
            amount INTEGER NOT NULL,
            transferDate TEXT NOT NULL,
            note TEXT,
            createdAt TEXT NOT NULL
          )
        ''');
      } catch (_) {}

      final count = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM wallets"));
      if (count == 0 || count == null) {
        await _seedDefaultWallets(db);
      }
    }
  }

  /// Reset/clear all database tables (useful for backup/restore or testing)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('income_transactions');
    await db.delete('expense_transactions');
    await db.delete('allocation_transactions');
    await db.delete('obligation_definitions');
    await db.delete('obligation_payments');
    await db.delete('target_definitions');
    await db.delete('day_activities');
    await db.delete('reminder_settings');
    await db.delete('reminder_logs');
    await db.delete('wallets');
    await db.delete('obligation_payment_splits');
    await db.delete('wallet_transfers');
    await _seedDefaultWallets(db);
  }
}
