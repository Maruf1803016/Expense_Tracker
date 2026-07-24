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

  static List<Category> get defaultCategories => [
    const Category(
      id: 'food_dining',
      name: 'Food & Dining',
      type: CategoryType.expense,
      icon: Icons.restaurant,
      subCategories: [
        SubCategory(name: 'Groceries', icon: Icons.shopping_cart),
        SubCategory(name: 'Restaurant', icon: Icons.restaurant),
        SubCategory(name: 'Coffee', icon: Icons.local_cafe),
        SubCategory(name: 'Fast Food', icon: Icons.fastfood),
      ],
    ),
    const Category(
      id: 'transport',
      name: 'Transport',
      type: CategoryType.expense,
      icon: Icons.directions_car,
      subCategories: [
        SubCategory(name: 'Fuel', icon: Icons.local_gas_station),
        SubCategory(name: 'Public Transit', icon: Icons.directions_bus),
        SubCategory(name: 'Taxi/Rideshare', icon: Icons.local_taxi),
        SubCategory(name: 'Parking', icon: Icons.local_parking),
      ],
    ),
    const Category(
      id: 'shopping',
      name: 'Shopping',
      type: CategoryType.expense,
      icon: Icons.shopping_bag,
      subCategories: [
        SubCategory(name: 'Clothing', icon: Icons.checkroom),
        SubCategory(name: 'Electronics', icon: Icons.devices),
        SubCategory(name: 'Gifts', icon: Icons.card_giftcard),
      ],
    ),
    const Category(
      id: 'bills_utilities',
      name: 'Bills & Utilities',
      type: CategoryType.expense,
      icon: Icons.receipt,
      subCategories: [
        SubCategory(name: 'Electricity', icon: Icons.bolt),
        SubCategory(name: 'Water', icon: Icons.water_drop),
        SubCategory(name: 'Internet', icon: Icons.wifi),
        SubCategory(name: 'Phone', icon: Icons.phone_android),
      ],
    ),
    const Category(
      id: 'health',
      name: 'Health',
      type: CategoryType.expense,
      icon: Icons.medical_services,
      subCategories: [
        SubCategory(name: 'Pharmacy', icon: Icons.local_pharmacy),
        SubCategory(name: 'Doctor', icon: Icons.medical_information),
        SubCategory(name: 'Insurance', icon: Icons.shield),
      ],
    ),
    const Category(
      id: 'home',
      name: 'Home',
      type: CategoryType.expense,
      icon: Icons.home,
      subCategories: [
        SubCategory(name: 'Rent', icon: Icons.apartment),
        SubCategory(name: 'Maintenance', icon: Icons.build),
        SubCategory(name: 'Furniture', icon: Icons.chair),
      ],
    ),
    const Category(
      id: 'salary',
      name: 'Salary',
      type: CategoryType.income,
      icon: Icons.work,
      subCategories: [],
    ),
    const Category(
      id: 'freelance',
      name: 'Freelance',
      type: CategoryType.income,
      icon: Icons.laptop,
      subCategories: [],
    ),
    const Category(
      id: 'investment',
      name: 'Investment',
      type: CategoryType.income,
      icon: Icons.trending_up,
      subCategories: [],
    ),
    const Category(
      id: 'gift',
      name: 'Gift',
      type: CategoryType.income,
      icon: Icons.card_giftcard,
      subCategories: [],
    ),
  ];

  @override
  List<Object?> get props => [id, name, type, icon, subCategories];
}
