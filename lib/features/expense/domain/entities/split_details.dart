import 'package:equatable/equatable.dart';

class SplitItem extends Equatable {
  final String name;
  final double amount;
  final bool isSettled;
  final DateTime? settledAt;

  const SplitItem({
    required this.name,
    required this.amount,
    this.isSettled = false,
    this.settledAt,
  });

  SplitItem copyWith({
    String? name,
    double? amount,
    bool? isSettled,
    DateTime? settledAt,
  }) {
    return SplitItem(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      isSettled: isSettled ?? this.isSettled,
      settledAt: settledAt ?? this.settledAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'isSettled': isSettled,
      if (settledAt != null) 'settledAt': settledAt!.toIso8601String(),
    };
  }

  factory SplitItem.fromMap(Map<String, dynamic> map) {
    return SplitItem(
      name: map['name'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      isSettled: map['isSettled'] ?? false,
      settledAt: map['settledAt'] != null ? DateTime.tryParse(map['settledAt']) : null,
    );
  }

  @override
  List<Object?> get props => [name, amount, isSettled, settledAt];
}

class SplitDetails extends Equatable {
  final bool isSplit;
  final String paidBy; // 'me' or counterparty name
  final double totalBillAmount;
  final double amountOwedToPayer;
  final List<SplitItem> splits;

  const SplitDetails({
    this.isSplit = false,
    this.paidBy = 'me',
    required this.totalBillAmount,
    required this.amountOwedToPayer,
    required this.splits,
  });

  bool get isPaidByMe => paidBy.trim().toLowerCase() == 'me';

  bool get isFullySettled {
    if (splits.isEmpty) return true;
    return splits.every((s) => s.isSettled);
  }

  double get pendingReceivableAmount {
    if (!isPaidByMe) return 0.0;
    return splits.where((s) => !s.isSettled).fold(0.0, (sum, s) => sum + s.amount);
  }

  double get myShare {
    if (isPaidByMe) {
      final othersTotal = splits.fold(0.0, (sum, s) => sum + s.amount);
      final remaining = totalBillAmount - othersTotal;
      return remaining > 0 ? remaining : 0.0;
    } else {
      return amountOwedToPayer;
    }
  }

  SplitDetails copyWith({
    bool? isSplit,
    String? paidBy,
    double? totalBillAmount,
    double? amountOwedToPayer,
    List<SplitItem>? splits,
  }) {
    return SplitDetails(
      isSplit: isSplit ?? this.isSplit,
      paidBy: paidBy ?? this.paidBy,
      totalBillAmount: totalBillAmount ?? this.totalBillAmount,
      amountOwedToPayer: amountOwedToPayer ?? this.amountOwedToPayer,
      splits: splits ?? this.splits,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isSplit': isSplit,
      'paidBy': paidBy,
      'totalBillAmount': totalBillAmount,
      'amountOwedToPayer': amountOwedToPayer,
      'splits': splits.map((s) => s.toMap()).toList(),
    };
  }

  factory SplitDetails.fromMap(Map<String, dynamic> map) {
    final rawSplits = map['splits'] as List<dynamic>? ?? [];
    return SplitDetails(
      isSplit: map['isSplit'] ?? true,
      paidBy: map['paidBy'] ?? 'me',
      totalBillAmount: (map['totalBillAmount'] as num?)?.toDouble() ?? 0.0,
      amountOwedToPayer: (map['amountOwedToPayer'] as num?)?.toDouble() ?? 0.0,
      splits: rawSplits.map((item) => SplitItem.fromMap(Map<String, dynamic>.from(item))).toList(),
    );
  }

  @override
  List<Object?> get props => [isSplit, paidBy, totalBillAmount, amountOwedToPayer, splits];
}
