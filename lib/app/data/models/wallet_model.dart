class WalletTransactionModel {
  final String id;
  final double amount;
  final String type;
  final String? referenceId;
  final String? description;
  final DateTime createdAt;

  WalletTransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    this.referenceId,
    this.description,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] ?? '',
      amount: (json['amount'] != null) ? double.parse(json['amount'].toString()) : 0.0,
      type: json['type'] ?? 'PAYOUT',
      referenceId: json['referenceId'],
      description: json['description'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}

class WalletInfoModel {
  final double balance;
  final String currency;
  final List<WalletTransactionModel> transactions;

  WalletInfoModel({
    required this.balance,
    required this.currency,
    required this.transactions,
  });

  factory WalletInfoModel.fromJson(Map<String, dynamic> json) {
    return WalletInfoModel(
      balance: (json['balance'] != null) ? double.parse(json['balance'].toString()) : 0.0,
      currency: json['currency'] ?? 'USD',
      transactions: (json['transactions'] as List<dynamic>? ?? [])
          .map((item) => WalletTransactionModel.fromJson(item))
          .toList(),
    );
  }
}
