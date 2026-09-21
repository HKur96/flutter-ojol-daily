/// Repositories providing CRUD data access layer
library;

import 'package:sqflite/sqflite.dart';
import '../domain/models.dart';
import 'database_helper.dart';

class FinancialRepository {
  final DatabaseHelper dbHelper;

  FinancialRepository(this.dbHelper);

  // --- Income Transactions ---
  Future<List<IncomeTransaction>> getAllIncomes() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'income_transactions',
      orderBy: 'transactionDate DESC',
    );
    return maps.map((m) => IncomeTransaction.fromMap(m)).toList();
  }

  Future<void> insertIncome(IncomeTransaction income) async {
    final db = await dbHelper.database;
    await db.insert('income_transactions', income.toMap());
  }

  Future<void> updateIncome(IncomeTransaction income) async {
    final db = await dbHelper.database;
    await db.update(
      'income_transactions',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  Future<void> deleteIncome(String id) async {
    final db = await dbHelper.database;
    await db.delete('income_transactions', where: 'id = ?', whereArgs: [id]);
  }

  // --- Expense Transactions ---
  Future<List<ExpenseTransaction>> getAllExpenses() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'expense_transactions',
      orderBy: 'transactionDate DESC',
    );
    return maps.map((m) => ExpenseTransaction.fromMap(m)).toList();
  }

  Future<void> insertExpense(ExpenseTransaction expense) async {
    final db = await dbHelper.database;
    await db.insert('expense_transactions', expense.toMap());
  }

  Future<void> updateExpense(ExpenseTransaction expense) async {
    final db = await dbHelper.database;
    await db.update(
      'expense_transactions',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> deleteExpense(String id) async {
    final db = await dbHelper.database;
    await db.delete('expense_transactions', where: 'id = ?', whereArgs: [id]);
  }

  // --- Allocation Transactions ---
  Future<List<AllocationTransaction>> getAllAllocations() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'allocation_transactions',
      orderBy: 'allocationDate DESC',
    );
    return maps.map((m) => AllocationTransaction.fromMap(m)).toList();
  }

  Future<void> insertAllocation(AllocationTransaction allocation) async {
    final db = await dbHelper.database;
    await db.insert('allocation_transactions', allocation.toMap());
  }

  Future<void> updateAllocation(AllocationTransaction allocation) async {
    final db = await dbHelper.database;
    await db.update(
      'allocation_transactions',
      allocation.toMap(),
      where: 'id = ?',
      whereArgs: [allocation.id],
    );
  }

  // --- Obligation Definitions ---
  Future<List<ObligationDefinition>> getAllObligations() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'obligation_definitions',
      orderBy: 'dueDate ASC',
    );
    return maps.map((m) => ObligationDefinition.fromMap(m)).toList();
  }

  Future<void> insertObligation(ObligationDefinition obligation) async {
    final db = await dbHelper.database;
    await db.insert('obligation_definitions', obligation.toMap());
  }

  Future<void> updateObligation(ObligationDefinition obligation) async {
    final db = await dbHelper.database;
    await db.update(
      'obligation_definitions',
      obligation.toMap(),
      where: 'id = ?',
      whereArgs: [obligation.id],
    );
  }

  Future<void> deleteObligation(String id) async {
    final db = await dbHelper.database;
    await db.delete('obligation_definitions', where: 'id = ?', whereArgs: [id]);
  }

  // --- Obligation Payments ---
  Future<List<ObligationPayment>> getAllObligationPayments() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'obligation_payments',
      orderBy: 'paymentDate DESC',
    );
    final splitMaps = await db.query('obligation_payment_splits');
    final allSplits = splitMaps
        .map((m) => ObligationPaymentSplit.fromMap(m))
        .toList();

    return maps.map((m) {
      final paymentId = m['id'] as String;
      final paymentSplits = allSplits
          .where((s) => s.paymentId == paymentId)
          .toList();
      return ObligationPayment.fromMap(m, splits: paymentSplits);
    }).toList();
  }

  Future<void> insertObligationPayment(ObligationPayment payment) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert('obligation_payments', payment.toMap());
      for (final split in payment.splits) {
        await txn.insert('obligation_payment_splits', split.toMap());
      }
    });
  }

  // --- Wallets ---
  Future<List<Wallet>> getAllWallets() async {
    final db = await dbHelper.database;
    final maps = await db.query('wallets', orderBy: 'isDefault DESC, name ASC');
    return maps.map((m) => Wallet.fromMap(m)).toList();
  }

  Future<void> insertWallet(Wallet wallet) async {
    final db = await dbHelper.database;
    await db.insert('wallets', wallet.toMap());
  }

  Future<void> updateWallet(Wallet wallet) async {
    final db = await dbHelper.database;
    await db.update(
      'wallets',
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }

  Future<void> deleteWallet(String id) async {
    final db = await dbHelper.database;
    await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }

  // --- Wallet Transfers ---
  Future<List<WalletTransfer>> getAllWalletTransfers() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'wallet_transfers',
      orderBy: 'transferDate DESC',
    );
    return maps.map((m) => WalletTransfer.fromMap(m)).toList();
  }

  Future<void> insertWalletTransfer(WalletTransfer transfer) async {
    final db = await dbHelper.database;
    await db.insert('wallet_transfers', transfer.toMap());
  }

  // --- Target Definitions ---
  Future<TargetDefinition?> getTargetForMonth(String monthStr) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'target_definitions',
      where: 'targetMonth = ?',
      whereArgs: [monthStr],
    );
    if (maps.isEmpty) return null;
    return TargetDefinition.fromMap(maps.first);
  }

  Future<void> saveTarget(TargetDefinition target) async {
    final db = await dbHelper.database;
    await db.insert(
      'target_definitions',
      target.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Day Activities ---
  Future<List<DayActivity>> getAllDayActivities() async {
    final db = await dbHelper.database;
    final maps = await db.query('day_activities');
    return maps.map((m) => DayActivity.fromMap(m)).toList();
  }

  Future<void> setDayActivity(DayActivity dayActivity) async {
    final db = await dbHelper.database;
    await db.rawInsert(
      '''
      INSERT OR REPLACE INTO day_activities (dateString, status, note)
      VALUES (?, ?, ?)
    ''',
      [dayActivity.dateString, dayActivity.status.name, dayActivity.note],
    );
  }

  // --- Reminder Settings & Logs ---
  Future<ReminderSettings> getReminderSettings() async {
    final db = await dbHelper.database;
    final maps = await db.query('reminder_settings', where: 'id = 1');
    if (maps.isEmpty) {
      const defaultSettings = ReminderSettings();
      await saveReminderSettings(defaultSettings);
      return defaultSettings;
    }
    return ReminderSettings.fromMap(maps.first);
  }

  Future<void> saveReminderSettings(ReminderSettings settings) async {
    final db = await dbHelper.database;
    final map = settings.toMap()..['id'] = 1;
    await db.insert(
      'reminder_settings',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ReminderLog?> getReminderLog(String dateString) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'reminder_logs',
      where: 'dateString = ?',
      whereArgs: [dateString],
    );
    if (maps.isEmpty) return null;
    return ReminderLog.fromMap(maps.first);
  }

  Future<void> saveReminderLog(ReminderLog log) async {
    final db = await dbHelper.database;
    await db.insert(
      'reminder_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
