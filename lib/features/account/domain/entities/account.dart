import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Account extends Equatable {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final double initialBalance;
  final bool isDefault;
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.initialBalance,
    required this.isDefault,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, icon, color, initialBalance, isDefault, createdAt];
}
