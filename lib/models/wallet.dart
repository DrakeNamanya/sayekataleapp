class Wallet {
  final String id;
  final String userId;
  final double balance;
  final double pendingBalance;
  final String currency;
  final List<Transaction> recentTransactions;
  final DateTime createdAt;
  final DateTime updatedAt;

  Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    this.pendingBalance = 0.0,
    this.currency = 'UGX',
    this.recentTransactions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wallet.fromFirestore(Map<String, dynamic> data, String id) {
    return Wallet(
      id: id,
      userId: data['user_id'] ?? '',
      balance: (data['balance'] ?? 0.0).toDouble(),
      pendingBalance: (data['pending_balance'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'UGX',
      recentTransactions:
          (data['recent_transactions'] as List<dynamic>?)
              ?.map((item) => Transaction.fromMap(item))
              .toList() ??
          [],
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'balance': balance,
      'pending_balance': pendingBalance,
      'currency': currency,
      'recent_transactions': recentTransactions
          .map((item) => item.toMap())
          .toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Transaction {
  final String id;
  final String walletId;
  final TransactionType type;
  final double amount;
  final String currency;
  final String? orderId;
  final String? referenceId;
  final TransactionStatus status;
  final String? description;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    this.currency = 'UGX',
    this.orderId,
    this.referenceId,
    required this.status,
    this.description,
    required this.createdAt,
  });

  factory Transaction.fromMap(Map<String, dynamic> data) {
    return Transaction(
      id: data['id'] ?? '',
      walletId: data['wallet_id'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${data['type']}',
        orElse: () => TransactionType.payment,
      ),
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'UGX',
      orderId: data['order_id'],
      referenceId: data['reference_id'],
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString() == 'TransactionStatus.${data['status']}',
        orElse: () => TransactionStatus.pending,
      ),
      description: data['description'],
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'wallet_id': walletId,
      'type': type.toString().split('.').last,
      'amount': amount,
      'currency': currency,
      'order_id': orderId,
      'reference_id': referenceId,
      'status': status.toString().split('.').last,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

enum TransactionType { payment, refund, withdrawal, deposit, earning, purchase }

enum TransactionStatus { pending, processing, completed, failed, cancelled }

extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.payment:
        return 'Payment';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.withdrawal:
        return 'Withdrawal';
      case TransactionType.deposit:
        return 'Deposit';
      case TransactionType.earning:
        return 'Earning';
      case TransactionType.purchase:
        return 'Purchase';
    }
  }
}
