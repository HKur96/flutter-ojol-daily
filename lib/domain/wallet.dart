/// Domain Data Models for Wallet Management & Split Payments
library;

/// Representation of a financial wallet or account (e.g. Tunai, GoPay, Bank BCA)
class Wallet {
  final String id;
  final String name;
  final String iconName; // e.g. 'account_balance_wallet', 'phone_android', 'account_balance'
  final String colorHex; // e.g. '#4CAF50'
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Wallet({
    required this.id,
    required this.name,
    this.iconName = 'account_balance_wallet',
    this.colorHex = '#4CAF50',
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'colorHex': colorHex,
      'isDefault': isDefault ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] as String,
      name: map['name'] as String,
      iconName: (map['iconName'] as String?) ?? 'account_balance_wallet',
      colorHex: (map['colorHex'] as String?) ?? '#4CAF50',
      isDefault: map['isDefault'] == 1 || map['isDefault'] == true,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Wallet copyWith({
    String? id,
    String? name,
    String? iconName,
    String? colorHex,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Breakdown of an obligation payment across a specific wallet
class ObligationPaymentSplit {
  final String id;
  final String paymentId;
  final String walletId;
  final int amount;

  const ObligationPaymentSplit({
    required this.id,
    required this.paymentId,
    required this.walletId,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'paymentId': paymentId,
      'walletId': walletId,
      'amount': amount,
    };
  }

  factory ObligationPaymentSplit.fromMap(Map<String, dynamic> map) {
    return ObligationPaymentSplit(
      id: map['id'] as String,
      paymentId: map['paymentId'] as String,
      walletId: map['walletId'] as String,
      amount: (map['amount'] as num).toInt(),
    );
  }
}

/// Record of transferring funds between two wallets
class WalletTransfer {
  final String id;
  final String fromWalletId;
  final String toWalletId;
  final int amount;
  final DateTime transferDate;
  final String? note;
  final DateTime createdAt;

  const WalletTransfer({
    required this.id,
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    required this.transferDate,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromWalletId': fromWalletId,
      'toWalletId': toWalletId,
      'amount': amount,
      'transferDate': transferDate.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WalletTransfer.fromMap(Map<String, dynamic> map) {
    return WalletTransfer(
      id: map['id'] as String,
      fromWalletId: map['fromWalletId'] as String,
      toWalletId: map['toWalletId'] as String,
      amount: (map['amount'] as num).toInt(),
      transferDate: DateTime.parse(map['transferDate'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
