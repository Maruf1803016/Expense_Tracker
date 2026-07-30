import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/account/domain/entities/account.dart';
import 'package:expense_tracker/core/utils/icon_utils.dart';

class AccountModel extends Account {
  const AccountModel({
    required super.id,
    required super.name,
    required super.icon,
    required super.color,
    required super.initialBalance,
    required super.isDefault,
    required super.createdAt,
    super.holderName,
    super.accountNumber,
  });

  factory AccountModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AccountModel(
      id: documentId,
      name: map['name'] ?? '',
      icon: IconUtils.getIcon(map['icon'] as String?),
      color: Color(map['color'] as int? ?? 0xFF12141A),
      initialBalance: (map['initialBalance'] as num?)?.toDouble() ?? 0.0,
      isDefault: map['isDefault'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      holderName: map['holderName'] as String?,
      accountNumber: map['accountNumber'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': IconUtils.getIconName(icon),
      'color': color.value,
      'initialBalance': initialBalance,
      'isDefault': isDefault,
      'createdAt': createdAt,
      'holderName': holderName,
      'accountNumber': accountNumber,
    };
  }

  factory AccountModel.fromEntity(Account account) {
    return AccountModel(
      id: account.id,
      name: account.name,
      icon: account.icon,
      color: account.color,
      initialBalance: account.initialBalance,
      isDefault: account.isDefault,
      createdAt: account.createdAt,
      holderName: account.holderName,
      accountNumber: account.accountNumber,
    );
  }
}
