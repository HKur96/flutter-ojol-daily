/// Financial State Data Model representing calculated financial position (PRD Sections 16, 30, 31, 45)
library;

import 'enums.dart';

class ObligationSummary {
  final String id;
  final String name;
  final int targetAmount;
  final int allocatedAmount;
  final int paidAmount;
  final int remainingAmount; // MAX(0, targetAmount - paidAmount)
  final double
  allocationProgressPercent; // (allocatedAmount / targetAmount) * 100
  final double paymentProgressPercent; // (paidAmount / targetAmount) * 100
  final DateTime dueDate;
  final ObligationStatus status;
  final int
  shortfall; // if this specific obligation allocation is underfunded due to emergency expense

  const ObligationSummary({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.allocatedAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.allocationProgressPercent,
    required this.paymentProgressPercent,
    required this.dueDate,
    required this.status,
    required this.shortfall,
  });
}

class TargetSummary {
  final int monthlyTargetAmount;
  final int totalIncome;
  final int remainingTargetAmount; // MAX(0, monthlyTargetAmount - totalIncome)
  final int totalWorkingDays;
  final int remainingWorkingDays;
  final int
  requiredDailyIncome; // MAX(0, remainingTargetAmount / remainingWorkingDays)
  final double progressPercent;
  final TargetStatus status;

  const TargetSummary({
    required this.monthlyTargetAmount,
    required this.totalIncome,
    required this.remainingTargetAmount,
    required this.totalWorkingDays,
    required this.remainingWorkingDays,
    required this.requiredDailyIncome,
    required this.progressPercent,
    required this.status,
  });
}

class FinancialState {
  final int totalIncome;
  final int totalExpense;
  final int startBalance; // Saldo awal bulan
  final int cashAvailable; // startBalance + totalIncome - totalExpense
  final int totalActiveAllocation; // sum of active allocations
  final int freeCash; // MAX(0, cashAvailable - totalActiveAllocation)
  final int
  allocationShortfall; // MAX(0, totalActiveAllocation - cashAvailable)
  final bool hasShortfall;
  final List<ObligationSummary> obligationSummaries;
  final TargetSummary? targetSummary;
  final double expenseToIncomeRatio; // (totalExpense / totalIncome) * 100
  final double fuelToIncomeRatio; // (fuelExpense / totalIncome) * 100

  const FinancialState({
    required this.totalIncome,
    required this.totalExpense,
    this.startBalance = 0,
    required this.cashAvailable,
    required this.totalActiveAllocation,
    required this.freeCash,
    required this.allocationShortfall,
    required this.hasShortfall,
    required this.obligationSummaries,
    this.targetSummary,
    required this.expenseToIncomeRatio,
    required this.fuelToIncomeRatio,
  });

  ObligationSummary? get obligationShortestDue {
    if (obligationSummaries.isEmpty) {
      return null;
    }
    
    return obligationSummaries.reduce(
      (a, b) => a.dueDate.isBefore(b.dueDate) ? a : b,
    );
  }

  factory FinancialState.initial() {
    return const FinancialState(
      totalIncome: 0,
      totalExpense: 0,
      startBalance: 0,
      cashAvailable: 0,
      totalActiveAllocation: 0,
      freeCash: 0,
      allocationShortfall: 0,
      hasShortfall: false,
      obligationSummaries: [],
      targetSummary: null,
      expenseToIncomeRatio: 0.0,
      fuelToIncomeRatio: 0.0,
    );
  }
}
