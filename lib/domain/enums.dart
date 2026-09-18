/// Domain Enums for Ojol Daily Financial Engine
library;

/// Status of a specific date regarding driver work activity (PRD Section 1.1)
enum DayStatus {
  working,
  off,
  noData,
}

/// General transaction soft-delete status (PRD Section 2, 3)
enum TransactionStatus {
  active,
  deleted,
}

/// Status of money allocated towards goals/obligations (PRD Section 4)
enum AllocationStatus {
  active,
  partiallyUsed,
  fullyUsed,
  cancelled,
}

/// Status of obligation payments & deadlines (PRD Section 5, 6, 7)
enum ObligationStatus {
  cancelled,
  paid,
  overdue,
  partiallyPaid,
  ready,
  inProgress,
  upcoming,
}

/// Status of monthly/periodic income target (PRD Section 26)
enum TargetStatus {
  notStarted,
  inProgress,
  achieved,
  ended,
}

/// Source of funds for an expense transaction (PRD Section 33)
enum ExpenseSource {
  free,
  allocated,
  mixed,
}

/// Status of daily input reminders (PRD Section 48)
enum ReminderStatus {
  pending,
  completed,
  cancelled,
}

