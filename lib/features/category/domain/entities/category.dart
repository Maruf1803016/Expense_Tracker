import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum CategoryType { income, expense, transfer }

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
    // 8 Curated Expense Categories
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
        SubCategory(name: 'Delivery & Takeaway', icon: Icons.delivery_dining),
        SubCategory(name: 'Home Cooking', icon: Icons.soup_kitchen),
      ],
    ),
    const Category(
      id: 'home',
      name: 'Home',
      type: CategoryType.expense,
      icon: Icons.home,
      subCategories: [
        SubCategory(name: 'Rent/Mortgage', icon: Icons.apartment),
        SubCategory(name: 'Maintenance & Repairs', icon: Icons.build),
        SubCategory(name: 'Furniture', icon: Icons.chair),
        SubCategory(name: 'Household Supplies', icon: Icons.cleaning_services),
      ],
    ),
    const Category(
      id: 'bills_utilities',
      name: 'Bills & Utilities',
      type: CategoryType.expense,
      icon: Icons.receipt_long,
      subCategories: [
        SubCategory(name: 'Electricity', icon: Icons.bolt),
        SubCategory(name: 'Water', icon: Icons.water_drop),
        SubCategory(name: 'Internet', icon: Icons.wifi),
        SubCategory(name: 'Phone', icon: Icons.phone_android),
      ],
    ),
    const Category(
      id: 'transport_travel',
      name: 'Transport & Travel',
      type: CategoryType.expense,
      icon: Icons.directions_car,
      subCategories: [
        SubCategory(name: 'Fuel', icon: Icons.local_gas_station),
        SubCategory(name: 'Public Transit', icon: Icons.directions_bus),
        SubCategory(name: 'Taxi/Rideshare', icon: Icons.local_taxi),
        SubCategory(name: 'Parking', icon: Icons.local_parking),
        SubCategory(name: 'Flights & Tickets', icon: Icons.flight),
        SubCategory(name: 'Trips & Stays', icon: Icons.hotel),
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
      id: 'health_personal_care',
      name: 'Health & Personal Care',
      type: CategoryType.expense,
      icon: Icons.medical_services,
      subCategories: [
        SubCategory(name: 'Pharmacy', icon: Icons.local_pharmacy),
        SubCategory(name: 'Doctor', icon: Icons.medical_information),
        SubCategory(name: 'Insurance', icon: Icons.shield),
        SubCategory(name: 'Fitness & Wellbeing', icon: Icons.fitness_center),
        SubCategory(name: 'Personal Care', icon: Icons.spa),
      ],
    ),
    const Category(
      id: 'entertainment',
      name: 'Entertainment',
      type: CategoryType.expense,
      icon: Icons.movie,
      subCategories: [
        SubCategory(name: 'Subscriptions', icon: Icons.subscriptions),
        SubCategory(name: 'Movies & Events', icon: Icons.theater_comedy),
        SubCategory(name: 'Hobbies', icon: Icons.palette),
      ],
    ),
    const Category(
      id: 'finance_other',
      name: 'Finance & Other',
      type: CategoryType.expense,
      icon: Icons.account_balance,
      subCategories: [
        SubCategory(name: 'Taxes', icon: Icons.receipt),
        SubCategory(name: 'Bank Fees', icon: Icons.payment),
        SubCategory(name: 'Insurance & Protection', icon: Icons.security),
        SubCategory(name: 'Miscellaneous', icon: Icons.more_horiz),
      ],
    ),

    // 5 Curated Income Categories
    const Category(
      id: 'salary',
      name: 'Salary',
      type: CategoryType.income,
      icon: Icons.work,
      subCategories: [
        SubCategory(name: 'Bonus', icon: Icons.card_giftcard),
        SubCategory(name: 'Overtime', icon: Icons.more_time),
      ],
    ),
    const Category(
      id: 'freelance',
      name: 'Freelance',
      type: CategoryType.income,
      icon: Icons.laptop_mac,
      subCategories: [
        SubCategory(name: 'Client Work', icon: Icons.business_center),
        SubCategory(name: 'Business Sales', icon: Icons.storefront),
      ],
    ),
    const Category(
      id: 'investment',
      name: 'Investment',
      type: CategoryType.income,
      icon: Icons.trending_up,
      subCategories: [
        SubCategory(name: 'Interest & Dividends', icon: Icons.account_balance),
        SubCategory(name: 'Rental Income', icon: Icons.apartment),
        SubCategory(name: 'Capital Gains', icon: Icons.show_chart),
      ],
    ),
    const Category(
      id: 'gift',
      name: 'Gift',
      type: CategoryType.income,
      icon: Icons.redeem,
      subCategories: [],
    ),
  ];

  @override
  List<Object?> get props => [id, name, type, icon, subCategories];
}
