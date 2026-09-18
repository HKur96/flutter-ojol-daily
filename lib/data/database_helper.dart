/// SQLite Database Helper utilizing sqflite
library;

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _dbName = 'ojol_daily.db';
  static const int _dbVersion = 1;

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
        icon TEXT NOT NULL DEFAULT 'payments',
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
  }
}
