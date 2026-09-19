import 'package:flutter_test/flutter_test.dart';
import 'package:ojol_daily/core/config/enum.dart';
import 'package:ojol_daily/domain/enums.dart';
import 'package:ojol_daily/domain/financial_calculator.dart';
import 'package:ojol_daily/domain/models.dart';

void main() {
  final now = DateTime(2026, 9, 18);

  group('Financial Engine Unit Tests (PRD Section 47)', () {
    // 1. Single income transaction
    test('1. Single income transaction calculation', () {
      final income = IncomeTransaction(
        id: 'inc-1',
        amount: 200000,
        category: 'Gojek',
        transactionDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final state = FinancialCalculator.calculateState(
        incomeList: [income],
        expenseList: [],
        allocationList: [],
        obligationList: [],
        paymentList: [],
        todayDate: now,
      );

      expect(state.totalIncome, 200000);
      expect(state.cashAvailable, 200000);
      expect(state.freeCash, 200000);
      expect(state.allocationShortfall, 0);
      expect(state.hasShortfall, false);
    });

    // 2. Multiple income transactions
    test('2. Multiple income transactions sum correctly', () {
      final incomes = [
        IncomeTransaction(id: '1', amount: 150000, category: 'Gojek', transactionDate: now, createdAt: now, updatedAt: now),
        IncomeTransaction(id: '2', amount: 80000, category: 'Grab', transactionDate: now, createdAt: now, updatedAt: now),
        IncomeTransaction(id: '3', amount: 20000, category: 'Tips', transactionDate: now, createdAt: now, updatedAt: now),
      ];

      final state = FinancialCalculator.calculateState(
        incomeList: incomes,
        expenseList: [],
        allocationList: [],
        obligationList: [],
        paymentList: [],
        todayDate: now,
      );

      expect(state.totalIncome, 250000);
      expect(state.cashAvailable, 250000);
    });

    // 3. Expenses reducing Cash Available
    test('3. Actual expenses reduce Cash Available', () {
      final incomes = [
        IncomeTransaction(id: '1', amount: 200000, category: 'Gojek', transactionDate: now, createdAt: now, updatedAt: now),
      ];
      final expenses = [
        ExpenseTransaction(
          id: 'exp-1',
          amount: 45000,
          category: 'Bensin',
          transactionDate: now,
          source: ExpenseSource.free,
          freeAmountUsed: 45000,
          allocatedAmountUsed: 0,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final state = FinancialCalculator.calculateState(
        incomeList: incomes,
        expenseList: expenses,
        allocationList: [],
        obligationList: [],
        paymentList: [],
        todayDate: now,
      );

      expect(state.totalIncome, 200000);
      expect(state.totalExpense, 45000);
      expect(state.cashAvailable, 155000);
      expect(state.freeCash, 155000);
    });

    // 4. Allocations securing money
    test('4. Allocations secure money away from Free Cash', () {
      final incomes = [
        IncomeTransaction(id: '1', amount: 600000, category: 'Gojek', transactionDate: now, createdAt: now, updatedAt: now),
      ];
      final allocations = [
        AllocationTransaction(
          id: 'alloc-1',
          obligationId: 'ob-motor',
          amount: 500000,
          allocationDate: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final state = FinancialCalculator.calculateState(
        incomeList: incomes,
        expenseList: [],
        allocationList: allocations,
        obligationList: [],
        paymentList: [],
        todayDate: now,
      );

      expect(state.cashAvailable, 600000);
      expect(state.totalActiveAllocation, 500000);
      expect(state.freeCash, 100000);
      expect(state.allocationShortfall, 0);
    });

    // 5. Obligation progress & status evaluation
    test('5. Obligation progress & status calculation', () {
      final ob = ObligationDefinition(
        id: 'ob-motor',
        name: 'Cicilan Motor',
        targetAmount: 500000,
        dueDate: now.add(const Duration(days: 10)),
        category: 'Motor',
        type: ObligationDefinitionType.bulanan,
        createdAt: now,
        updatedAt: now,
      );
      final allocations = [
        AllocationTransaction(
          id: 'a1',
          obligationId: 'ob-motor',
          amount: 300000,
          allocationDate: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final state = FinancialCalculator.calculateState(
        incomeList: [IncomeTransaction(id: '1', amount: 600000, category: 'Gojek', transactionDate: now, createdAt: now, updatedAt: now)],
        expenseList: [],
        allocationList: allocations,
        obligationList: [ob],
        paymentList: [],
        todayDate: now,
      );

      expect(state.obligationSummaries.length, 1);
      final summary = state.obligationSummaries.first;
      expect(summary.allocatedAmount, 300000);
      expect(summary.paidAmount, 0);
      expect(summary.remainingAmount, 500000);
      expect(summary.allocationProgressPercent, 60.0);
      expect(summary.paymentProgressPercent, 0.0);
      expect(summary.status, ObligationStatus.inProgress);
    });

    // 6. Obligation payment & FI-004 overpayment prevention
    test('6. Obligation payment updates status & prevents overpayment (FI-004)', () {
      final ob = ObligationDefinition(
        id: 'ob-listrik',
        name: 'Listrik',
        targetAmount: 100000,
        dueDate: now.add(const Duration(days: 5)),
        category: 'Rumah',
        type: ObligationDefinitionType.bulanan,
        createdAt: now,
        updatedAt: now,
      );
      final payments = [
        ObligationPayment(
          id: 'p1',
          obligationId: 'ob-listrik',
          amount: 100000,
          paymentDate: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final state = FinancialCalculator.calculateState(
        incomeList: [IncomeTransaction(id: '1', amount: 200000, category: 'Gojek', transactionDate: now, createdAt: now, updatedAt: now)],
        expenseList: [],
        allocationList: [],
        obligationList: [ob],
        paymentList: payments,
        todayDate: now,
      );

      final summary = state.obligationSummaries.first;
      expect(summary.paidAmount, 100000);
      expect(summary.remainingAmount, 0);
      expect(summary.status, ObligationStatus.paid);

      // Verify FI-004
      final isValidOverpay = FinancialCalculator.validateObligationPayment(
        currentPaidAmount: 100000,
        targetAmount: 100000,
        newPaymentAmount: 50000,
      );
      expect(isValidOverpay, false);
    });

    // 7. Emergency spending consuming allocation (PRD Section 19 & 44)
    test('7. Emergency spending consuming allocation updates state correctly', () {
      // Setup: Income 600k, Allocation Motor 500k, Free Cash 100k
      final incomes = [IncomeTransaction(id: '1', amount: 600000, category: 'Gojek', transactionDate: now, createdAt: now, updatedAt: now)];
      final allocations = [
        AllocationTransaction(id: 'a1', obligationId: 'ob-motor', amount: 500000, allocationDate: now, createdAt: now, updatedAt: now),
      ];
      // Emergency expense 150k: 100k from Free, 50k from Motor Allocation
      final expenses = [
        ExpenseTransaction(
          id: 'e1',
          amount: 150000,
          category: 'Kesehatan (Anak Sakit)',
          transactionDate: now,
          source: ExpenseSource.mixed,
          freeAmountUsed: 100000,
          allocatedAmountUsed: 50000,
          targetObligationId: 'ob-motor',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // Update allocation to mark 50k used
      final updatedAllocations = [
        allocations.first.copyWith(usedAmount: 50000),
      ];

      final state = FinancialCalculator.calculateState(
        incomeList: incomes,
        expenseList: expenses,
        allocationList: updatedAllocations,
        obligationList: [],
        paymentList: [],
        todayDate: now,
      );

      expect(state.cashAvailable, 450000); // 600k - 150k
      expect(state.totalActiveAllocation, 450000); // 500k - 50k used
      expect(state.freeCash, 0);
      expect(state.allocationShortfall, 0);
    });

    // 8. Expense from free cash
    test('8. Expense from free cash only reduces free cash', () {
      final incomes = [IncomeTransaction(id: '1', amount: 600000, category: 'Gojek', transactionDate: now, createdAt: now, updatedAt: now)];
      final allocations = [
        AllocationTransaction(id: 'a1', obligationId: 'ob-1', amount: 400000, allocationDate: now, createdAt: now, updatedAt: now),
      ];
      final expenses = [
        ExpenseTransaction(
          id: 'e1',
          amount: 50000,
          category: 'Makan',
          transactionDate: now,
          source: ExpenseSource.free,
          freeAmountUsed: 50000,
          allocatedAmountUsed: 0,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final state = FinancialCalculator.calculateState(
        incomeList: incomes,
        expenseList: expenses,
        allocationList: allocations,
        obligationList: [],
        paymentList: [],
        todayDate: now,
      );

      expect(state.cashAvailable, 550000);
      expect(state.totalActiveAllocation, 400000);
      expect(state.freeCash, 150000);
      expect(state.allocationShortfall, 0);
    });

    // 9. Expense from allocated cash
    test('9. Expense from allocated cash reduces allocation & cash available', () {
      final incomes = [IncomeTransaction(id: '1', amount: 600000, category: 'Gojek', transactionDate: now, createdAt: now, updatedAt: now)];
      final allocations = [
        AllocationTransaction(id: 'a1', obligationId: 'ob-servis', amount: 150000, usedAmount: 85000, allocationDate: now, createdAt: now, updatedAt: now),
      ];
      final expenses = [
        ExpenseTransaction(
          id: 'e1',
          amount: 85000,
          category: 'Servis Motor',
          transactionDate: now,
          source: ExpenseSource.allocated,
          freeAmountUsed: 0,
          allocatedAmountUsed: 85000,
          targetObligationId: 'ob-servis',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final state = FinancialCalculator.calculateState(
        incomeList: incomes,
        expenseList: expenses,
        allocationList: allocations,
        obligationList: [],
        paymentList: [],
        todayDate: now,
      );

      expect(state.cashAvailable, 515000); // 600k - 85k
      expect(state.totalActiveAllocation, 65000); // 150k - 85k
      expect(state.freeCash, 450000); // 515k - 65k
    });

    // 10. Allocation Shortfall detection (PRD Section 30 & FI-006)
    test('10. Allocation Shortfall triggers when Allocated > Cash Available', () {
      final incomes = [IncomeTransaction(id: '1', amount: 600000, category: 'Gojek', transactionDate: now, createdAt: now, updatedAt: now)];
      // User allocated 600k
      final allocations = [
        AllocationTransaction(id: 'a1', obligationId: 'ob-1', amount: 600000, allocationDate: now, createdAt: now, updatedAt: now),
      ];
      // Sudden expense 100k recorded without reducing allocation record directly
      final expenses = [
        ExpenseTransaction(
          id: 'e1',
          amount: 100000,
          category: 'Emergency',
          transactionDate: now,
          source: ExpenseSource.free,
          freeAmountUsed: 100000,
          allocatedAmountUsed: 0,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final state = FinancialCalculator.calculateState(
        incomeList: incomes,
        expenseList: expenses,
        allocationList: allocations,
        obligationList: [],
        paymentList: [],
        todayDate: now,
      );

      expect(state.cashAvailable, 500000);
      expect(state.totalActiveAllocation, 600000);
      expect(state.freeCash, 0);
      expect(state.allocationShortfall, 100000);
      expect(state.hasShortfall, true);
    });

    // 11. Days marked OFF (PRD Section 1.1, 23, FI-008, FI-009)
    test('11. Days marked OFF do not penalize daily target denominator', () {
      final target = TargetDefinition(
        id: 't1',
        monthlyTargetAmount: 4000000,
        totalWorkingDays: 26,
        targetMonth: '2026-09',
        createdAt: now,
        updatedAt: now,
      );

      // User marks 2 days OFF
      final dayActivities = [
        const DayActivity(dateString: '2026-09-05', status: DayStatus.off),
        const DayActivity(dateString: '2026-09-12', status: DayStatus.off),
      ];

      final state = FinancialCalculator.calculateState(
        incomeList: [IncomeTransaction(id: '1', amount: 2900000, category: 'Gojek', transactionDate: now, createdAt: now, updatedAt: now)],
        expenseList: [],
        allocationList: [],
        obligationList: [],
        paymentList: [],
        currentTarget: target,
        dayActivities: dayActivities,
        todayDate: now,
      );

      expect(state.targetSummary!.remainingTargetAmount, 1100000);
      expect(state.targetSummary!.remainingWorkingDays, 24); // 26 - 2 OFF days
      // 1.100.000 ~/ 24 = 45833
      expect(state.targetSummary!.requiredDailyIncome, 45833);
    });

    // 12. Dynamic daily target calculation (PRD Section 22 & 24)
    test('12. Dynamic daily target calculation', () {
      final target = TargetDefinition(
        id: 't1',
        monthlyTargetAmount: 4000000,
        totalWorkingDays: 26,
        targetMonth: '2026-09',
        createdAt: now,
        updatedAt: now,
      );

      final state = FinancialCalculator.calculateState(
        incomeList: [],
        expenseList: [],
        allocationList: [],
        obligationList: [],
        paymentList: [],
        currentTarget: target,
        todayDate: now,
      );

      // 4.000.000 ~/ 26 = 153846
      expect(state.targetSummary!.requiredDailyIncome, 153846);
    });

    // 13. Target achieved status
    test('13. Target status transitions to ACHIEVED when total income >= target', () {
      final target = TargetDefinition(
        id: 't1',
        monthlyTargetAmount: 4000000,
        totalWorkingDays: 26,
        targetMonth: '2026-09',
        createdAt: now,
        updatedAt: now,
      );

      final state = FinancialCalculator.calculateState(
        incomeList: [IncomeTransaction(id: '1', amount: 4200000, category: 'Gojek', transactionDate: now, createdAt: now, updatedAt: now)],
        expenseList: [],
        allocationList: [],
        obligationList: [],
        paymentList: [],
        currentTarget: target,
        todayDate: now,
      );

      expect(state.targetSummary!.status, TargetStatus.achieved);
      expect(state.targetSummary!.remainingTargetAmount, 0);
      expect(state.targetSummary!.requiredDailyIncome, 0);
    });

    // 14. Target in progress status
    test('14. Target status is IN_PROGRESS when income is between 0 and target', () {
      final target = TargetDefinition(
        id: 't1',
        monthlyTargetAmount: 4000000,
        totalWorkingDays: 26,
        targetMonth: '2026-09',
        createdAt: now,
        updatedAt: now,
      );

      final state = FinancialCalculator.calculateState(
        incomeList: [IncomeTransaction(id: '1', amount: 1500000, category: 'Gojek', transactionDate: now, createdAt: now, updatedAt: now)],
        expenseList: [],
        allocationList: [],
        obligationList: [],
        paymentList: [],
        currentTarget: target,
        todayDate: now,
      );

      expect(state.targetSummary!.status, TargetStatus.inProgress);
    });

    // 15. Transaction edits recalculate state
    test('15. Transaction edit recalculates financial state cleanly', () {
      final originalIncome = IncomeTransaction(id: '1', amount: 200000, category: 'Gojek', transactionDate: now, createdAt: now, updatedAt: now);
      final editedIncome = originalIncome.copyWith(amount: 250000);

      final stateBefore = FinancialCalculator.calculateState(
        incomeList: [originalIncome],
        expenseList: [],
        allocationList: [],
        obligationList: [],
        paymentList: [],
        todayDate: now,
      );
      expect(stateBefore.cashAvailable, 200000);

      final stateAfter = FinancialCalculator.calculateState(
        incomeList: [editedIncome],
        expenseList: [],
        allocationList: [],
        obligationList: [],
        paymentList: [],
        todayDate: now,
      );
      expect(stateAfter.cashAvailable, 250000);
    });

    // 16. Transaction deletion handling (PRD Section 37)
    test('16. Soft-deleted transactions are ignored from financial calculation', () {
      final incomes = [
        IncomeTransaction(id: '1', amount: 200000, category: 'Gojek', transactionDate: now, status: TransactionStatus.active, createdAt: now, updatedAt: now),
        IncomeTransaction(id: '2', amount: 300000, category: 'Grab', transactionDate: now, status: TransactionStatus.deleted, createdAt: now, updatedAt: now),
      ];

      final state = FinancialCalculator.calculateState(
        incomeList: incomes,
        expenseList: [],
        allocationList: [],
        obligationList: [],
        paymentList: [],
        todayDate: now,
      );

      expect(state.totalIncome, 200000);
      expect(state.cashAvailable, 200000);
    });

    // 17. Data clear / empty state
    test('17. Empty state initializes safely to zeros', () {
      final state = FinancialCalculator.calculateState(
        incomeList: [],
        expenseList: [],
        allocationList: [],
        obligationList: [],
        paymentList: [],
        todayDate: now,
      );

      expect(state.totalIncome, 0);
      expect(state.totalExpense, 0);
      expect(state.cashAvailable, 0);
      expect(state.freeCash, 0);
      expect(state.allocationShortfall, 0);
      expect(state.hasShortfall, false);
    });

    // 18. Zero values division safety (PRD Section 39)
    test('18. Division by zero safety for ratios & targets', () {
      final state = FinancialCalculator.calculateState(
        incomeList: [],
        expenseList: [],
        allocationList: [],
        obligationList: [],
        paymentList: [],
        currentTarget: TargetDefinition(
          id: 't0',
          monthlyTargetAmount: 0,
          totalWorkingDays: 0,
          targetMonth: '2026-09',
          createdAt: now,
          updatedAt: now,
        ),
        todayDate: now,
      );

      expect(state.expenseToIncomeRatio, 0.0);
      expect(state.fuelToIncomeRatio, 0.0);
      expect(state.targetSummary!.requiredDailyIncome, 0);
      expect(state.targetSummary!.progressPercent, 0.0);
    });

    // 19. Integer IDR rounding
    test('19. Integer IDR values maintained without floating point corruption', () {
      final income = IncomeTransaction(id: '1', amount: 153846, category: 'Gojek', transactionDate: now, createdAt: now, updatedAt: now);
      final expense = IncomeTransaction(id: '2', amount: 45000, category: 'Makan', transactionDate: now, createdAt: now, updatedAt: now);

      expect(income.amount.isFinite, true);
      expect(expense.amount.runtimeType, int);
    });

    // 20. Multiple obligations sorted by due date priority (PRD Section 21)
    test('20. Multiple obligations sorted by due date priority', () {
      final ob1 = ObligationDefinition(
        id: 'ob-motor',
        name: 'Cicilan Motor',
        targetAmount: 500000,
        dueDate: now.add(const Duration(days: 15)),
        category: 'Motor',
        type: ObligationDefinitionType.bulanan,
        createdAt: now,
        updatedAt: now,
      );
      final ob2 = ObligationDefinition(
        id: 'ob-listrik',
        name: 'Token Listrik',
        targetAmount: 100000,
        dueDate: now.add(const Duration(days: 3)),
        category: 'Rumah',
        type: ObligationDefinitionType.bulanan,
        createdAt: now,
        updatedAt: now,
      );

      final state = FinancialCalculator.calculateState(
        incomeList: [],
        expenseList: [],
        allocationList: [],
        obligationList: [ob1, ob2],
        paymentList: [],
        todayDate: now,
      );

      expect(state.obligationSummaries.first.id, 'ob-listrik'); // Listrik due in 3 days comes first!
      expect(state.obligationSummaries.last.id, 'ob-motor');
    });
  });
}
