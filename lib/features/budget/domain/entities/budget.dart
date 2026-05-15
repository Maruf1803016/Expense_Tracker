import 'package:equatable/equatable.dart';

class Budget extends Equatable {
  final String categoryId;
  final double monthlyLimit;
  final int month;
  final int year;

  const Budget({
    required this.categoryId,
    required this.monthlyLimit,
    required this.month,
    required this.year,
  });

  @override
  List<Object?> get props => [categoryId, monthlyLimit, month, year];
}
