import 'package:flutter/material.dart';

class IconUtils {
  static const Map<String, IconData> iconMap = {
    'restaurant': Icons.restaurant,
    'favorite': Icons.favorite,
    'directions_car': Icons.directions_car,
    'shopping_bag': Icons.shopping_bag,
    'movie': Icons.movie,
    'receipt': Icons.receipt,
    'school': Icons.school,
    'account_balance_wallet': Icons.account_balance_wallet,
    'trending_up': Icons.trending_up,
    'category': Icons.category,
    'work': Icons.work,
    'home': Icons.home,
    'commute': Icons.commute,
    'fitness_center': Icons.fitness_center,
    'local_library': Icons.local_library,
    'security': Icons.security,
    'pets': Icons.pets,
    'flight': Icons.flight,
    'videogame_asset': Icons.videogame_asset,
    'payment': Icons.payment,
  };

  static IconData getIcon(String? iconName) {
    return iconMap[iconName] ?? Icons.category;
  }

  static List<String> get availableIconNames => iconMap.keys.toList();
}
