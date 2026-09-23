import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ojol_daily/core/config/enum.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database_helper.dart';
import '../../data/repositories.dart';
import '../../domain/enums.dart';
import '../../domain/financial_calculator.dart';
import '../../domain/financial_state.dart';
import '../../domain/models.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../services/backup_service.dart';
import '../../services/google_drive_service.dart';
import '../../services/notification_service.dart';

class FinancialProvider extends ChangeNotifier {
  final FinancialRepository repository;

  FinancialProvider({required this.repository});

  factory FinancialProvider.create() {
    return FinancialProvider(repository: FinancialRepository(DatabaseHelper()));
  }

  FinancialState _state = FinancialState.initial();
  FinancialState get state => _state;

  List<IncomeTransaction> _incomes = [];
  List<ExpenseTransaction> _expenses = [];
  List<AllocationTransaction> _allocations = [];
  List<ObligationDefinition> _obligations = [];
  List<ObligationPayment> _payments = [];
  List<DayActivity> _dayActivities = [];
  List<Wallet> _wallets = [];
  List<WalletTransfer> _transfers = [];
  TargetDefinition? _currentTarget;
  ReminderSettings _reminderSettings = const ReminderSettings();
  ReminderLog? _todayReminderLog;

  List<IncomeTransaction> get incomes => _incomes;
  List<ExpenseTransaction> get expenses => _expenses;
  List<AllocationTransaction> get allocations => _allocations;
  List<ObligationDefinition> get obligations => _obligations;
  List<ObligationPayment> get payments => _payments;
  List<DayActivity> get dayActivities => _dayActivities;
  List<Wallet> get wallets => _wallets;
  List<WalletTransfer> get transfers => _transfers;
  TargetDefinition? get currentTarget => _currentTarget;
  ReminderSettings get reminderSettings => _reminderSettings;
  ReminderLog? get todayReminderLog => _todayReminderLog;

  int get incomeTodayAmount {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _incomes
        .where(
          (i) =>
              i.status == TransactionStatus.active &&
              DateFormat('yyyy-MM-dd').format(i.transactionDate) == todayStr,
        )
        .fold<int>(0, (sum, i) => sum + i.amount);
  }

  int get expenseTodayAmount {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _expenses
        .where(
          (e) =>
              e.status == TransactionStatus.active &&
              DateFormat('yyyy-MM-dd').format(e.transactionDate) == todayStr,
        )
        .fold<int>(0, (sum, e) => sum + e.amount);
  }

  /// Total active income per day for current week (Monday to Sunday)
  List<double> get weeklyIncomes {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(
      Duration(days: now.weekday - 1),
    );
    final List<double> result = List.filled(7, 0.0);

    for (int i = 0; i < 7; i++) {
      final dayDate = monday.add(Duration(days: i));
      final dayStr = DateFormat('yyyy-MM-dd').format(dayDate);
      final dayTotal = _incomes
          .where(
            (inc) =>
                inc.status == TransactionStatus.active &&
                DateFormat('yyyy-MM-dd').format(inc.transactionDate) == dayStr,
          )
          .fold<int>(0, (sum, inc) => sum + inc.amount);
      result[i] = dayTotal.toDouble();
    }

    return result;
  }

  /// Sum of all active incomes in the current week (Monday to Sunday)
  int get totalWeeklyIncome {
    return weeklyIncomes.fold<double>(0.0, (sum, val) => sum + val).toInt();
  }

  DayStatus get todayDayStatus {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final activity = _dayActivities.firstWhere(
      (a) => a.dateString == todayStr,
      orElse: () {
        final isWorkDay = _reminderSettings.workDays.contains(now.weekday);
        return DayActivity(
          dateString: todayStr,
          status: isWorkDay ? DayStatus.working : DayStatus.off,
        );
      },
    );

    return activity.status;
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  /// Load all data from SQLite repository and recalculate FinancialState
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _incomes = await repository.getAllIncomes();
      _expenses = await repository.getAllExpenses();
      _allocations = await repository.getAllAllocations();
      _obligations = await repository.getAllObligations();
      _payments = await repository.getAllObligationPayments();
      _dayActivities = await repository.getAllDayActivities();
      _wallets = await repository.getAllWallets();
      _transfers = await repository.getAllWalletTransfers();

      // Auto-complete obligations that have been fully paid
      for (final ob in _obligations) {
        if (!ob.isCancelled && ob.targetAmount > 0) {
          final obPayments = _payments.where(
            (p) =>
                p.obligationId == ob.id && p.status == TransactionStatus.active,
          );
          final paidTotal = obPayments.fold<int>(0, (sum, p) => sum + p.amount);
          if (paidTotal >= ob.targetAmount) {
            await repository.updateObligation(
              ob.copyWith(isCancelled: true, updatedAt: DateTime.now()),
            );
          }
        }
      }
      _obligations = await repository.getAllObligations();

      final currentMonthStr =
          "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";
      _currentTarget = await repository.getTargetForMonth(currentMonthStr);
      _reminderSettings = await repository.getReminderSettings();

      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _todayReminderLog = await repository.getReminderLog(todayStr);

      await initGoogleDrive();

      _recalculateState();

      // Notification sync
      if (_reminderSettings.enabled &&
          incomeTodayAmount == 0 &&
          todayDayStatus != DayStatus.off) {
        await NotificationService().scheduleDailyReminders(_reminderSettings);
      } else {
        await NotificationService().cancelAllReminders();
      }
    } catch (e) {
      debugPrint("Error loading financial data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveReminderSettings(ReminderSettings settings) async {
    _reminderSettings = settings;
    await repository.saveReminderSettings(settings);
    if (settings.enabled) {
      await NotificationService().scheduleDailyReminders(settings);
    } else {
      await NotificationService().cancelAllReminders();
    }
    notifyListeners();
  }

  void _recalculateState() {
    _state = FinancialCalculator.calculateState(
      incomeList: _incomes,
      expenseList: _expenses,
      allocationList: _allocations,
      obligationList: _obligations,
      paymentList: _payments,
      currentTarget: _currentTarget,
      dayActivities: _dayActivities,
      wallets: _wallets,
      transfers: _transfers,
    );
  }

  // --- Wallet Actions ---
  Future<void> addWallet({
    required String name,
    String iconName = 'account_balance_wallet',
    String colorHex = '#4CAF50',
    bool isDefault = false,
  }) async {
    final now = DateTime.now();
    final wallet = Wallet(
      id: 'w_${now.millisecondsSinceEpoch}',
      name: name,
      iconName: iconName,
      colorHex: colorHex,
      isDefault: isDefault,
      createdAt: now,
      updatedAt: now,
    );
    await repository.insertWallet(wallet);
    await loadData();
  }

  Future<void> updateWallet(Wallet wallet) async {
    await repository.updateWallet(wallet.copyWith(updatedAt: DateTime.now()));
    await loadData();
  }

  Future<void> deleteWallet(String id) async {
    await repository.deleteWallet(id);
    await loadData();
  }

  Future<void> transferBetweenWallets({
    required String fromWalletId,
    required String toWalletId,
    required int amount,
    String? note,
  }) async {
    final now = DateTime.now();
    final transfer = WalletTransfer(
      id: 'tf_${now.millisecondsSinceEpoch}',
      fromWalletId: fromWalletId,
      toWalletId: toWalletId,
      amount: amount,
      transferDate: now,
      note: note,
      createdAt: now,
    );
    await repository.insertWalletTransfer(transfer);
    await loadData();
  }

  // --- Income Actions ---
  Future<void> addIncome({
    required int amount,
    required String category,
    required DateTime transactionDate,
    String walletId = 'w_cash',
    String? note,
  }) async {
    final now = DateTime.now();
    final income = IncomeTransaction(
      id: 'inc_${now.millisecondsSinceEpoch}',
      amount: amount,
      category: category,
      walletId: walletId,
      note: note,
      transactionDate: transactionDate,
      createdAt: now,
      updatedAt: now,
    );
    await repository.insertIncome(income);
    await loadData();
  }

  Future<void> deleteIncome(String id) async {
    final index = _incomes.indexWhere((i) => i.id == id);
    if (index != -1) {
      final updated = _incomes[index].copyWith(
        status: TransactionStatus.deleted,
        updatedAt: DateTime.now(),
      );
      await repository.updateIncome(updated);
      await loadData();
    }
  }

  // --- Expense Actions ---
  Future<void> addExpense({
    required int amount,
    required String category,
    required ExpenseSource source,
    required DateTime transactionDate,
    String walletId = 'w_cash',
    int freeAmountUsed = 0,
    int allocatedAmountUsed = 0,
    String? targetObligationId,
    String? note,
  }) async {
    final now = DateTime.now();
    final expense = ExpenseTransaction(
      id: 'exp_${now.millisecondsSinceEpoch}',
      amount: amount,
      category: category,
      walletId: walletId,
      source: source,
      freeAmountUsed: freeAmountUsed,
      allocatedAmountUsed: allocatedAmountUsed,
      targetObligationId: targetObligationId,
      note: note,
      transactionDate: transactionDate,
      createdAt: now,
      updatedAt: now,
    );
    await repository.insertExpense(expense);

    // If allocated amount was used, update the target allocation transaction usedAmount
    if (allocatedAmountUsed > 0 && targetObligationId != null) {
      final obAllocations = _allocations.where(
        (a) =>
            a.obligationId == targetObligationId &&
            a.status == AllocationStatus.active,
      );
      int remainingToDeduct = allocatedAmountUsed;

      for (final alloc in obAllocations) {
        if (remainingToDeduct <= 0) break;
        final availableInAlloc = alloc.amount - alloc.usedAmount;
        final deduct = remainingToDeduct > availableInAlloc
            ? availableInAlloc
            : remainingToDeduct;

        final updatedAlloc = alloc.copyWith(
          usedAmount: alloc.usedAmount + deduct,
          status: (alloc.usedAmount + deduct >= alloc.amount)
              ? AllocationStatus.fullyUsed
              : AllocationStatus.partiallyUsed,
          updatedAt: now,
        );
        await repository.updateAllocation(updatedAlloc);
        remainingToDeduct -= deduct;
      }
    }

    await loadData();
  }

  Future<void> deleteExpense(String id) async {
    final index = _expenses.indexWhere((e) => e.id == id);
    if (index != -1) {
      final updated = _expenses[index].copyWith(
        status: TransactionStatus.deleted,
        updatedAt: DateTime.now(),
      );
      await repository.updateExpense(updated);
      await loadData();
    }
  }

  // --- Allocation Actions ---
  Future<void> addAllocation({
    required String obligationId,
    required int amount,
    String? note,
  }) async {
    final now = DateTime.now();
    final allocation = AllocationTransaction(
      id: 'alloc_${now.millisecondsSinceEpoch}',
      obligationId: obligationId,
      amount: amount,
      allocationDate: now,
      note: note,
      createdAt: now,
      updatedAt: now,
    );
    await repository.insertAllocation(allocation);
    await loadData();
  }

  // --- Obligation Actions ---
  Future<void> addObligation({
    required String name,
    required int targetAmount,
    required DateTime dueDate,
    required String category,
    required ObligationDefinitionType type,
  }) async {
    final now = DateTime.now();
    final obligation = ObligationDefinition(
      id: 'ob_${now.millisecondsSinceEpoch}',
      name: name,
      targetAmount: targetAmount,
      dueDate: dueDate,
      category: category,
      type: type,
      createdAt: now,
      updatedAt: now,
    );
    await repository.insertObligation(obligation);
    await loadData();
  }

  Future<void> updateObligation({
    required String id,
    required String name,
    required int targetAmount,
    required DateTime dueDate,
    required String category,
    required ObligationDefinitionType type,
  }) async {
    final index = _obligations.indexWhere((o) => o.id == id);
    if (index != -1) {
      final updated = _obligations[index].copyWith(
        name: name,
        targetAmount: targetAmount,
        dueDate: dueDate,
        category: category,
        type: type,
        updatedAt: DateTime.now(),
      );
      await repository.updateObligation(updated);
      await loadData();
    }
  }

  Future<void> deleteObligation(String id) async {
    await repository.deleteObligation(id);
    await loadData();
  }

  Future<bool> payObligation({
    required String obligationId,
    required int amount,
    List<ObligationPaymentSplit> splits = const [],
    String? note,
  }) async {
    final obSummary = _state.obligationSummaries.firstWhere(
      (o) => o.id == obligationId,
    );

    // Validate FI-004 overpayment prevention
    if (!FinancialCalculator.validateObligationPayment(
      currentPaidAmount: obSummary.paidAmount,
      targetAmount: obSummary.targetAmount,
      newPaymentAmount: amount,
    )) {
      return false; // Payment exceeds obligation target
    }

    final now = DateTime.now();
    final payment = ObligationPayment(
      id: 'pay_${now.millisecondsSinceEpoch}',
      obligationId: obligationId,
      amount: amount,
      paymentDate: now,
      note: note,
      splits: splits,
      createdAt: now,
      updatedAt: now,
    );
    await repository.insertObligationPayment(payment);

    // If payment completes the obligation (paidAmount + amount >= targetAmount),
    // mark obligation as completed/cancelled to remove from active list while preserving payment history in DB.
    if (obSummary.paidAmount + amount >= obSummary.targetAmount) {
      final obDefIndex = _obligations.indexWhere((o) => o.id == obligationId);
      if (obDefIndex != -1) {
        final updatedOb = _obligations[obDefIndex].copyWith(
          isCancelled: true,
          updatedAt: now,
        );
        await repository.updateObligation(updatedOb);
      }
    }

    await loadData();
    return true;
  }

  // --- Target & Day Activity Actions ---
  Future<void> saveMonthlyTarget({
    required int monthlyTargetAmount,
    required int totalWorkingDays,
    int startBalance = 0,
  }) async {
    final now = DateTime.now();
    final currentMonthStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}";
    final target = TargetDefinition(
      id: 'target_$currentMonthStr',
      monthlyTargetAmount: monthlyTargetAmount,
      totalWorkingDays: totalWorkingDays,
      startBalance: startBalance,
      targetMonth: currentMonthStr,
      createdAt: now,
      updatedAt: now,
    );
    await repository.saveTarget(target);
    await loadData();
  }

  /// Update only the startBalance on the current month's target.
  Future<void> updateStartBalance(int startBalance) async {
    if (_currentTarget == null) return;
    final updated = _currentTarget!.copyWith(
      startBalance: startBalance,
      updatedAt: DateTime.now(),
    );
    await repository.saveTarget(updated);
    await loadData();
  }

  Future<void> setDayStatus(String dateString, DayStatus status) async {
    final activity = DayActivity(dateString: dateString, status: status);
    await repository.setDayActivity(activity);
    await loadData();
  }

  Future<void> clearAllData() async {
    await repository.dbHelper.clearAllData();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('financial_setup_completed', false);
    await loadData();
  }

  // --- Backup & Restore Actions ---
  final BackupService _backupService = BackupService();

  Future<String> exportBackupJson() async {
    return await _backupService.exportBackupJson();
  }

  Map<String, dynamic> parseAndValidateBackup(String jsonStr) {
    return _backupService.parseAndValidateBackup(jsonStr);
  }

  Future<void> restoreBackupJson(String jsonStr) async {
    await _backupService.restoreBackupJson(jsonStr);
    await loadData();
  }

  Future<void> shareBackupFile() async {
    await _backupService.shareBackupFile();
  }

  Future<String?> pickBackupFile() async {
    return await _backupService.pickAndReadBackupFile();
  }

  // --- Google Drive Backup & Restore Actions ---
  final GoogleDriveService _googleDriveService = GoogleDriveService();

  GoogleSignInAccount? get googleUser => _googleDriveService.currentUser;

  bool _isGoogleDriveLoading = false;
  bool get isGoogleDriveLoading => _isGoogleDriveLoading;

  DateTime? _lastGoogleBackupTime;
  DateTime? get lastGoogleBackupTime => _lastGoogleBackupTime;

  Future<void> initGoogleDrive() async {
    await _googleDriveService.init();
    _lastGoogleBackupTime = await _googleDriveService.getLastBackupTime();
  }

  Future<void> signInGoogle() async {
    _isGoogleDriveLoading = true;
    notifyListeners();
    await _googleDriveService.signIn();
    _lastGoogleBackupTime = await _googleDriveService.getLastBackupTime();
    _isGoogleDriveLoading = false;
    notifyListeners();
  }

  Future<void> signOutGoogle() async {
    _isGoogleDriveLoading = true;
    notifyListeners();
    await _googleDriveService.signOut();
    _isGoogleDriveLoading = false;
    notifyListeners();
  }

  Future<bool> backupToGoogleDrive() async {
    _isGoogleDriveLoading = true;
    notifyListeners();
    try {
      final jsonStr = await exportBackupJson();
      final success = await _googleDriveService.uploadBackupToDrive(jsonStr);
      if (success) {
        _lastGoogleBackupTime = await _googleDriveService.getLastBackupTime();
      }
      return success;
    } finally {
      _isGoogleDriveLoading = false;
      notifyListeners();
    }
  }

  Future<String?> downloadBackupFromGoogleDrive() async {
    _isGoogleDriveLoading = true;
    notifyListeners();
    try {
      return await _googleDriveService.downloadBackupFromDrive();
    } finally {
      _isGoogleDriveLoading = false;
      notifyListeners();
    }
  }
}
