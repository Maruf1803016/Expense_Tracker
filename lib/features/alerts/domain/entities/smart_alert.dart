import 'package:equatable/equatable.dart';

enum AlertType {
  spendingSpike,
  budgetExceeded,
  unusualActivity,
  trendWarning,
}

enum AlertSeverity {
  low,
  medium,
  high,
}

/// Domain entity representing an intelligent financial alert.
class SmartAlert extends Equatable {
  final String id;
  final AlertType type;
  final String title;
  final String message;
  final AlertSeverity severity;
  final String? categoryId;
  final double? amount;
  final DateTime createdAt;

  const SmartAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    this.categoryId,
    this.amount,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        message,
        severity,
        categoryId,
        amount,
        createdAt,
      ];
}
