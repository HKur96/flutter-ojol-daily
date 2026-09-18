/// Pure Dart Financial Engine implementing exact calculations & invariants (PRD Sections 8 - 45)
library;

import 'enums.dart';
import 'financial_state.dart';
import 'models.dart';

class FinancialCalculator {
  /// Pure function to calculate complete FinancialState from raw active transactions and definitions
  static FinancialState calculateState({
    required List<IncomeTransaction> incomeList,
    required List<ExpenseTransaction> expenseList,
    required List<AllocationTransaction> allocationList,
    required List<ObligationDefinition> obligationList,
    required List<ObligationPayment> paymentList,
    TargetDefinition? currentTarget,
    List<DayActivity> dayActivities = const [],
    DateTime? todayDate,
  }) {
    final today = todayDate ?? DateTime.now();

    // 1. Total Income (PRD 8.1 - FI-001)
    final activeIncomes = incomeList.where((i) => i.status == TransactionStatus.active);
    final totalIncome = activeIncomes.fold<int>(0, (sum, item) => sum + item.amount);

    // 2. Total Expense (PRD 9 - FI-002)
    final activeExpenses = expenseList.where((e) => e.status == TransactionStatus.active);
    final totalExpense = activeExpenses.fold<int>(0, (sum, item) => sum + item.amount);

    // 3. Cash Available (PRD 16, 31)
    final rawCash = totalIncome - totalExpense;
    final cashAvailable = rawCash < 0 ? 0 : rawCash;

    // Fuel expense calculation for Fuel Ratio (PRD 28)
    final fuelExpense = activeExpenses
        .where((e) => e.category.toLowerCase().contains('bensin') || e.category.toLowerCase().contains('fuel'))
        .fold<int>(0, (sum, item) => sum + item.amount);

    // 4. Total Active Allocations (PRD 10 - FI-003)
    final activeAllocations = allocationList.where((a) => a.status != AllocationStatus.cancelled);
    final totalActiveAllocation = activeAllocations.fold<int>(0, (sum, item) => sum + item.amount - item.usedAmount);

    // 5. Free Cash & Allocation Shortfall (PRD 15, 16, 30, 31, FI-005, FI-006)
    final freeCash = (cashAvailable - totalActiveAllocation) < 0 ? 0 : (cashAvailable - totalActiveAllocation);
    final rawShortfall = totalActiveAllocation - cashAvailable;
    final allocationShortfall = rawShortfall < 0 ? 0 : rawShortfall;
    final hasShortfall = allocationShortfall > 0;

    // 6. Obligation Summaries (PRD 5, 6, 7, 12, 13, 14, 21)
    final obligationSummaries = <ObligationSummary>[];

    for (final ob in obligationList) {
      // Sum allocations for this obligation
      final obAllocations = activeAllocations.where((a) => a.obligationId == ob.id);
      final obAllocatedAmount = obAllocations.fold<int>(0, (sum, a) => sum + a.amount - a.usedAmount);

      // Sum payments for this obligation (PRD 11)
      final obPayments = paymentList.where((p) => p.obligationId == ob.id && p.status == TransactionStatus.active);
      final obPaidAmount = obPayments.fold<int>(0, (sum, p) => sum + p.amount);

      // Sisa Kewajiban (PRD 12)
      final rawRemaining = ob.targetAmount - obPaidAmount;
      final remainingAmount = rawRemaining < 0 ? 0 : rawRemaining;

      // Progress percentages (PRD 13, 14)
      final allocationProgressPercent = ob.targetAmount > 0
          ? ((obAllocatedAmount / ob.targetAmount) * 100.0).clamp(0.0, 100.0)
          : 0.0;

      final paymentProgressPercent = ob.targetAmount > 0
          ? ((obPaidAmount / ob.targetAmount) * 100.0).clamp(0.0, 100.0)
          : 0.0;

      // Status evaluation (PRD 5 & 6)
      final status = evaluateObligationStatus(
        isCancelled: ob.isCancelled,
        targetAmount: ob.targetAmount,
        allocatedAmount: obAllocatedAmount,
        paidAmount: obPaidAmount,
        dueDate: ob.dueDate,
        today: today,
      );

      // Individual shortfall
      final individualShortfall = (obAllocatedAmount > cashAvailable) ? (obAllocatedAmount - cashAvailable) : 0;

      obligationSummaries.add(ObligationSummary(
        id: ob.id,
        name: ob.name,
        targetAmount: ob.targetAmount,
        allocatedAmount: obAllocatedAmount,
        paidAmount: obPaidAmount,
        remainingAmount: remainingAmount,
        allocationProgressPercent: allocationProgressPercent,
        paymentProgressPercent: paymentProgressPercent,
        dueDate: ob.dueDate,
        status: status,
        shortfall: individualShortfall,
      ));
    }

    // Sort obligations by priority & due date (PRD 21)
    obligationSummaries.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // 7. Target Summary (PRD 22, 23, 24, 25, 26)
    TargetSummary? targetSummary;
    if (currentTarget != null) {
      final monthlyTarget = currentTarget.monthlyTargetAmount;
      final remainingTarget = (monthlyTarget - totalIncome) < 0 ? 0 : (monthlyTarget - totalIncome);

      // Days off count (PRD 1.1, 23, FI-009)
      final offDaysCount = dayActivities.where((d) => d.status == DayStatus.off).length;

      // Remaining working days = Total planned working days - OFF days
      final effectiveWorkingDays = currentTarget.totalWorkingDays - offDaysCount;
      final remainingWorkingDays = effectiveWorkingDays <= 0 ? 1 : effectiveWorkingDays;

      // Required Daily Income (PRD 24)
      final requiredDailyIncome = remainingTarget > 0 ? (remainingTarget ~/ remainingWorkingDays) : 0;

      final progressPercent = monthlyTarget > 0
          ? ((totalIncome / monthlyTarget) * 100.0).clamp(0.0, 100.0)
          : 0.0;

      // Target status evaluation (PRD 26)
      TargetStatus targetStatus;
      if (totalIncome == 0) {
        targetStatus = TargetStatus.notStarted;
      } else if (totalIncome >= monthlyTarget) {
        targetStatus = TargetStatus.achieved;
      } else {
        targetStatus = TargetStatus.inProgress;
      }

      targetSummary = TargetSummary(
        monthlyTargetAmount: monthlyTarget,
        totalIncome: totalIncome,
        remainingTargetAmount: remainingTarget,
        totalWorkingDays: currentTarget.totalWorkingDays,
        remainingWorkingDays: remainingWorkingDays,
        requiredDailyIncome: requiredDailyIncome,
        progressPercent: progressPercent,
        status: targetStatus,
      );
    }

    // Expense Ratio (PRD 27) & Fuel Ratio (PRD 28)
    final expenseToIncomeRatio = totalIncome > 0 ? ((totalExpense / totalIncome) * 100.0) : 0.0;
    final fuelToIncomeRatio = totalIncome > 0 ? ((fuelExpense / totalIncome) * 100.0) : 0.0;

    return FinancialState(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      cashAvailable: cashAvailable,
      totalActiveAllocation: totalActiveAllocation,
      freeCash: freeCash,
      allocationShortfall: allocationShortfall,
      hasShortfall: hasShortfall,
      obligationSummaries: obligationSummaries,
      targetSummary: targetSummary,
      expenseToIncomeRatio: expenseToIncomeRatio,
      fuelToIncomeRatio: fuelToIncomeRatio,
    );
  }

  /// Evaluate Obligation Status according to PRD Sections 5, 6, & 7
  static ObligationStatus evaluateObligationStatus({
    required bool isCancelled,
    required int targetAmount,
    required int allocatedAmount,
    required int paidAmount,
    required DateTime dueDate,
    required DateTime today,
  }) {
    // 1. CANCELLED
    if (isCancelled) {
      return ObligationStatus.cancelled;
    }
    // 2. PAID
    if (paidAmount >= targetAmount && targetAmount > 0) {
      return ObligationStatus.paid;
    }
    // 3. OVERDUE
    final isPastDue = today.isAfter(dueDate) && !_isSameDay(today, dueDate);
    if (isPastDue && paidAmount < targetAmount) {
      return ObligationStatus.overdue;
    }
    // 4. PARTIALLY_PAID
    if (paidAmount > 0 && paidAmount < targetAmount) {
      return ObligationStatus.partiallyPaid;
    }
    // 5. READY
    if (allocatedAmount >= targetAmount && paidAmount == 0 && targetAmount > 0) {
      return ObligationStatus.ready;
    }
    // 6. IN_PROGRESS
    if (allocatedAmount > 0) {
      return ObligationStatus.inProgress;
    }
    // 7. UPCOMING
    return ObligationStatus.upcoming;
  }

  /// Financial Integrity Check FI-004: Validate payment amount against target amount
  static bool validateObligationPayment({
    required int currentPaidAmount,
    required int targetAmount,
    required int newPaymentAmount,
  }) {
    if (newPaymentAmount <= 0) return false;
    return (currentPaidAmount + newPaymentAmount) <= targetAmount;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
