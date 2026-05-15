import 'package:equatable/equatable.dart';

/// Pure domain entity representing the summary for a specific month.
/// Contains only raw calculation data.
class MonthlySummary extends Equatable {
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  
  /// Optional breakdown of totals per category ID
  final Map<String, double> categoryBreakdown;

  const MonthlySummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    this.categoryBreakdown = const {},
  });

  /// Factory for creating an empty summary
  factory MonthlySummary.empty() {
    return const MonthlySummary(
      totalIncome: 0.0,
      totalExpense: 0.0,
      netBalance: 0.0,
      categoryBreakdown: {},
    );
  }

  @override
  List<Object?> get props => [totalIncome, totalExpense, netBalance, categoryBreakdown];
}
