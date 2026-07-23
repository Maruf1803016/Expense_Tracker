import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum CategoryType { income, expense }

class SubCategory extends Equatable {
  final String name;
  final IconData icon;

  const SubCategory({
    required this.name,
    required this.icon,
  });

  @override
  List<Object?> get props => [name, icon];
}

class Category extends Equatable {
  final String id;
  final String name;
  final CategoryType type;
  final IconData icon;
  final List<SubCategory> subCategories;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.subCategories,
  });

  @override
  List<Object?> get props => [id, name, type, icon, subCategories];
}
