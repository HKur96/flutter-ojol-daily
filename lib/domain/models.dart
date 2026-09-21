/// Domain Data Models for Ojol Daily Financial Engine
library;

import 'package:ojol_daily/core/config/enum.dart';

import 'enums.dart';
import 'wallet.dart';

export 'wallet.dart';

/// Single income transaction record (PRD Section 2, 8.1)
class IncomeTransaction {
  final String id;
  final int amount; // IDR integer value
  final String category; // e.g. "Gojek", "Grab", "Maxim", "Tips"
  final String? note;
  final DateTime transactionDate;
  final String walletId; // Destination wallet ID (defaults to 'w_cash')
  final TransactionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const IncomeTransaction({
    required this.id,
    required this.amount,
    required this.category,
    this.note,
    required this.transactionDate,
    this.walletId = 'w_cash',
    this.status = TransactionStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'note': note,
      'transactionDate': transactionDate.toIso8601String(),
      'walletId': walletId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory IncomeTransaction.fromMap(Map<String, dynamic> map) {
    return IncomeTransaction(
      id: map['id'] as String,
      amount: (map['amount'] as num).toInt(),
      category: map['category'] as String,
      note: map['note'] as String?,
      transactionDate: DateTime.parse(map['transactionDate'] as String),
      walletId: (map['walletId'] as String?) ?? 'w_cash',
      status: TransactionStatus.values.byName(map['status'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  IncomeTransaction copyWith({
    String? id,
    int? amount,
    String? category,
    String? note,
    DateTime? transactionDate,
    String? walletId,
    TransactionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IncomeTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      transactionDate: transactionDate ?? this.transactionDate,
      walletId: walletId ?? this.walletId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Single expense transaction record (PRD Section 3, 9, 33, 34)
class ExpenseTransaction {
  final String id;
  final int amount; // IDR integer value
  final String category; // e.g. "Bensin", "Makan", "Servis Motor", "Keluarga"
  final String? note;
  final DateTime transactionDate;
  final String walletId; // Source wallet ID (defaults to 'w_cash')
  final ExpenseSource source; // FREE, ALLOCATED, MIXED
  final int freeAmountUsed;
  final int allocatedAmountUsed;
  final String?
  targetObligationId; // if allocated or mixed, which obligation's allocation was used
  final TransactionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExpenseTransaction({
    required this.id,
    required this.amount,
    required this.category,
    this.note,
    required this.transactionDate,
    this.walletId = 'w_cash',
    required this.source,
    required this.freeAmountUsed,
    required this.allocatedAmountUsed,
    this.targetObligationId,
    this.status = TransactionStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'note': note,
      'transactionDate': transactionDate.toIso8601String(),
      'walletId': walletId,
      'source': source.name,
      'freeAmountUsed': freeAmountUsed,
      'allocatedAmountUsed': allocatedAmountUsed,
      'targetObligationId': targetObligationId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ExpenseTransaction.fromMap(Map<String, dynamic> map) {
    return ExpenseTransaction(
      id: map['id'] as String,
      amount: (map['amount'] as num).toInt(),
      category: map['category'] as String,
      note: map['note'] as String?,
      transactionDate: DateTime.parse(map['transactionDate'] as String),
      walletId: (map['walletId'] as String?) ?? 'w_cash',
      source: ExpenseSource.values.byName(map['source'] as String),
      freeAmountUsed: (map['freeAmountUsed'] as num).toInt(),
      allocatedAmountUsed: (map['allocatedAmountUsed'] as num).toInt(),
      targetObligationId: map['targetObligationId'] as String?,
      status: TransactionStatus.values.byName(map['status'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  ExpenseTransaction copyWith({
    String? id,
    int? amount,
    String? category,
    String? note,
    DateTime? transactionDate,
    String? walletId,
    ExpenseSource? source,
    int? freeAmountUsed,
    int? allocatedAmountUsed,
    String? targetObligationId,
    TransactionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      transactionDate: transactionDate ?? this.transactionDate,
      walletId: walletId ?? this.walletId,
      source: source ?? this.source,
      freeAmountUsed: freeAmountUsed ?? this.freeAmountUsed,
      allocatedAmountUsed: allocatedAmountUsed ?? this.allocatedAmountUsed,
      targetObligationId: targetObligationId ?? this.targetObligationId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Allocation transaction securing money towards a specific obligation (PRD Section 4, 10)
class AllocationTransaction {
  final String id;
  final String obligationId;
  final int amount;
  final DateTime allocationDate;
  final AllocationStatus status;
  final int usedAmount; // amount consumed by emergency/allocated expenses
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AllocationTransaction({
    required this.id,
    required this.obligationId,
    required this.amount,
    required this.allocationDate,
    this.status = AllocationStatus.active,
    this.usedAmount = 0,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'obligationId': obligationId,
      'amount': amount,
      'allocationDate': allocationDate.toIso8601String(),
      'status': status.name,
      'usedAmount': usedAmount,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AllocationTransaction.fromMap(Map<String, dynamic> map) {
    return AllocationTransaction(
      id: map['id'] as String,
      obligationId: map['obligationId'] as String,
      amount: (map['amount'] as num).toInt(),
      allocationDate: DateTime.parse(map['allocationDate'] as String),
      status: AllocationStatus.values.byName(map['status'] as String),
      usedAmount: (map['usedAmount'] as num).toInt(),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  AllocationTransaction copyWith({
    String? id,
    String? obligationId,
    int? amount,
    DateTime? allocationDate,
    AllocationStatus? status,
    int? usedAmount,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AllocationTransaction(
      id: id ?? this.id,
      obligationId: obligationId ?? this.obligationId,
      amount: amount ?? this.amount,
      allocationDate: allocationDate ?? this.allocationDate,
      status: status ?? this.status,
      usedAmount: usedAmount ?? this.usedAmount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Definition of an obligation/financial liability (PRD Section 5, 6, 7, 12, 13, 14)
class ObligationDefinition {
  final String id;
  final String name; // e.g. "Cicilan Motor", "Token Listrik", "Kontrakan"
  final int targetAmount;
  final DateTime dueDate;
  final String category;
  final ObligationDefinitionType type;
  final bool isCancelled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ObligationDefinition({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.dueDate,
    required this.category,
    required this.type,
    this.isCancelled = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'dueDate': dueDate.toIso8601String(),
      'category': category,
      'type': type.name,
      'isCancelled': isCancelled ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ObligationDefinition.fromMap(Map<String, dynamic> map) {
    return ObligationDefinition(
      id: map['id'] as String,
      name: map['name'] as String,
      targetAmount: (map['targetAmount'] as num).toInt(),
      dueDate: DateTime.parse(map['dueDate'] as String),
      category: map['category'] as String,
      type: ObligationDefinitionType.fromString(map['type'] as String),
      isCancelled: map['isCancelled'] == 1 || map['isCancelled'] == true,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  ObligationDefinition copyWith({
    String? id,
    String? name,
    int? targetAmount,
    DateTime? dueDate,
    String? category,
    ObligationDefinitionType? type,
    bool? isCancelled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ObligationDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      type: type ?? this.type,
      isCancelled: isCancelled ?? this.isCancelled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Payment made towards an obligation (PRD Section 11, 12, FI-004)
class ObligationPayment {
  final String id;
  final String obligationId;
  final int amount;
  final DateTime paymentDate;
  final String? note;
  final List<ObligationPaymentSplit> splits; // Multi-wallet payment breakdown
  final TransactionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ObligationPayment({
    required this.id,
    required this.obligationId,
    required this.amount,
    required this.paymentDate,
    this.note,
    this.splits = const [],
    this.status = TransactionStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'obligationId': obligationId,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'note': note,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ObligationPayment.fromMap(
    Map<String, dynamic> map, {
    List<ObligationPaymentSplit> splits = const [],
  }) {
    return ObligationPayment(
      id: map['id'] as String,
      obligationId: map['obligationId'] as String,
      amount: (map['amount'] as num).toInt(),
      paymentDate: DateTime.parse(map['paymentDate'] as String),
      note: map['note'] as String?,
      splits: splits,
      status: TransactionStatus.values.byName(map['status'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  ObligationPayment copyWith({
    String? id,
    String? obligationId,
    int? amount,
    DateTime? paymentDate,
    String? note,
    List<ObligationPaymentSplit>? splits,
    TransactionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ObligationPayment(
      id: id ?? this.id,
      obligationId: obligationId ?? this.obligationId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      note: note ?? this.note,
      splits: splits ?? this.splits,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Monthly or periodic income target definition (PRD Section 22, 23, 24, 25, 26)
class TargetDefinition {
  final String id;
  final int monthlyTargetAmount;
  final int totalWorkingDays; // Days planned for work e.g. 26
  final int startBalance; // Saldo awal bulan (IDR)
  final String targetMonth; // Format "YYYY-MM"
  final TargetStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TargetDefinition({
    required this.id,
    required this.monthlyTargetAmount,
    required this.totalWorkingDays,
    this.startBalance = 0,
    required this.targetMonth,
    this.status = TargetStatus.inProgress,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'monthlyTargetAmount': monthlyTargetAmount,
      'totalWorkingDays': totalWorkingDays,
      'startBalance': startBalance,
      'targetMonth': targetMonth,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TargetDefinition.fromMap(Map<String, dynamic> map) {
    return TargetDefinition(
      id: map['id'] as String,
      monthlyTargetAmount: (map['monthlyTargetAmount'] as num).toInt(),
      totalWorkingDays: (map['totalWorkingDays'] as num).toInt(),
      startBalance: (map['startBalance'] as num?)?.toInt() ?? 0,
      targetMonth: map['targetMonth'] as String,
      status: TargetStatus.values.byName(map['status'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  TargetDefinition copyWith({
    String? id,
    int? monthlyTargetAmount,
    int? totalWorkingDays,
    int? startBalance,
    String? targetMonth,
    TargetStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TargetDefinition(
      id: id ?? this.id,
      monthlyTargetAmount: monthlyTargetAmount ?? this.monthlyTargetAmount,
      totalWorkingDays: totalWorkingDays ?? this.totalWorkingDays,
      startBalance: startBalance ?? this.startBalance,
      targetMonth: targetMonth ?? this.targetMonth,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Record of driver work activity per date (PRD Section 1.1)
class DayActivity {
  final String dateString; // Format "YYYY-MM-DD"
  final DayStatus status;
  final String? note;

  const DayActivity({
    required this.dateString,
    required this.status,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {'dateString': dateString, 'status': status.name, 'note': note};
  }

  factory DayActivity.fromMap(Map<String, dynamic> map) {
    return DayActivity(
      dateString: map['dateString'] as String,
      status: DayStatus.values.byName(map['status'] as String),
      note: map['note'] as String?,
    );
  }
}

/// Reminder settings configuration (PRD Section 48.9, 48.10)
class ReminderSettings {
  final bool enabled;
  final bool firstReminderEnabled;
  final String firstReminderTime; // Format "HH:mm" e.g. "20:00"
  final bool secondReminderEnabled;
  final String secondReminderTime; // Format "HH:mm" e.g. "22:00"
  final List<int>
  workDays; // List of ISO weekday numbers 1..7 (1=Monday, 7=Sunday)

  const ReminderSettings({
    this.enabled = true,
    this.firstReminderEnabled = true,
    this.firstReminderTime = '20:00',
    this.secondReminderEnabled = true,
    this.secondReminderTime = '22:00',
    this.workDays = const [1, 2, 3, 4, 5, 6, 7],
  });

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled ? 1 : 0,
      'firstReminderEnabled': firstReminderEnabled ? 1 : 0,
      'firstReminderTime': firstReminderTime,
      'secondReminderEnabled': secondReminderEnabled ? 1 : 0,
      'secondReminderTime': secondReminderTime,
      'workDays': workDays.join(','),
    };
  }

  factory ReminderSettings.fromMap(Map<String, dynamic> map) {
    return ReminderSettings(
      enabled: map['enabled'] == 1 || map['enabled'] == true,
      firstReminderEnabled:
          map['firstReminderEnabled'] == 1 ||
          map['firstReminderEnabled'] == true,
      firstReminderTime: (map['firstReminderTime'] as String?) ?? '20:00',
      secondReminderEnabled:
          map['secondReminderEnabled'] == 1 ||
          map['secondReminderEnabled'] == true,
      secondReminderTime: (map['secondReminderTime'] as String?) ?? '22:00',
      workDays:
          map['workDays'] != null && (map['workDays'] as String).isNotEmpty
          ? (map['workDays'] as String)
                .split(',')
                .map((e) => int.parse(e.trim()))
                .toList()
          : [1, 2, 3, 4, 5, 6, 7],
    );
  }

  ReminderSettings copyWith({
    bool? enabled,
    bool? firstReminderEnabled,
    String? firstReminderTime,
    bool? secondReminderEnabled,
    String? secondReminderTime,
    List<int>? workDays,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      firstReminderEnabled: firstReminderEnabled ?? this.firstReminderEnabled,
      firstReminderTime: firstReminderTime ?? this.firstReminderTime,
      secondReminderEnabled:
          secondReminderEnabled ?? this.secondReminderEnabled,
      secondReminderTime: secondReminderTime ?? this.secondReminderTime,
      workDays: workDays ?? this.workDays,
    );
  }
}

/// Reminder state per date to prevent duplicate notifications (PRD Section 48.12)
class ReminderLog {
  final String dateString; // Format "YYYY-MM-DD"
  final bool firstReminderSent;
  final bool secondReminderSent;
  final DateTime? firstReminderSentAt;
  final DateTime? secondReminderSentAt;

  const ReminderLog({
    required this.dateString,
    this.firstReminderSent = false,
    this.secondReminderSent = false,
    this.firstReminderSentAt,
    this.secondReminderSentAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'dateString': dateString,
      'firstReminderSent': firstReminderSent ? 1 : 0,
      'secondReminderSent': secondReminderSent ? 1 : 0,
      'firstReminderSentAt': firstReminderSentAt?.toIso8601String(),
      'secondReminderSentAt': secondReminderSentAt?.toIso8601String(),
    };
  }

  factory ReminderLog.fromMap(Map<String, dynamic> map) {
    return ReminderLog(
      dateString: map['dateString'] as String,
      firstReminderSent:
          map['firstReminderSent'] == 1 || map['firstReminderSent'] == true,
      secondReminderSent:
          map['secondReminderSent'] == 1 || map['secondReminderSent'] == true,
      firstReminderSentAt: map['firstReminderSentAt'] != null
          ? DateTime.parse(map['firstReminderSentAt'] as String)
          : null,
      secondReminderSentAt: map['secondReminderSentAt'] != null
          ? DateTime.parse(map['secondReminderSentAt'] as String)
          : null,
    );
  }

  ReminderLog copyWith({
    String? dateString,
    bool? firstReminderSent,
    bool? secondReminderSent,
    DateTime? firstReminderSentAt,
    DateTime? secondReminderSentAt,
  }) {
    return ReminderLog(
      dateString: dateString ?? this.dateString,
      firstReminderSent: firstReminderSent ?? this.firstReminderSent,
      secondReminderSent: secondReminderSent ?? this.secondReminderSent,
      firstReminderSentAt: firstReminderSentAt ?? this.firstReminderSentAt,
      secondReminderSentAt: secondReminderSentAt ?? this.secondReminderSentAt,
    );
  }
}
