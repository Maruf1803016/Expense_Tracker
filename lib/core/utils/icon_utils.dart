import 'package:flutter/material.dart';

class IconUtils {
  static const Map<String, IconData> iconMap = {
    'restaurant': Icons.restaurant,
    'favorite': Icons.favorite,
    'directions_car': Icons.directions_car,
    'car': Icons.directions_car,
    'shopping_bag': Icons.shopping_bag,
    'bag': Icons.shopping_bag,
    'movie': Icons.movie,
    'receipt': Icons.receipt,
    'school': Icons.school,
    'account_balance_wallet': Icons.account_balance_wallet,
    'trending_up': Icons.trending_up,
    'trending-up': Icons.trending_up,
    'category': Icons.category,
    'work': Icons.work,
    'briefcase': Icons.work,
    'laptop': Icons.laptop,
    'home': Icons.home,
    'medical': Icons.medical_services,
    'gift': Icons.card_giftcard,
    'plus-circle': Icons.add_circle,
    'commute': Icons.commute,
    'fitness_center': Icons.fitness_center,
    'local_library': Icons.local_library,
    'security': Icons.security,
    'pets': Icons.pets,
    'flight': Icons.flight,
    'videogame_asset': Icons.videogame_asset,
    'payment': Icons.payment,
    'groceries': Icons.shopping_cart,
    'coffee': Icons.local_cafe,
    'fast_food': Icons.fastfood,
    'fuel': Icons.local_gas_station,
    'public_transit': Icons.directions_bus,
    'taxi': Icons.local_taxi,
    'parking': Icons.local_parking,
    'clothing': Icons.checkroom,
    'electronics': Icons.devices,
    'gifts': Icons.card_giftcard,
    'electricity': Icons.bolt,
    'water': Icons.water_drop,
    'internet': Icons.wifi,
    'phone': Icons.phone_android,
    'pharmacy': Icons.local_pharmacy,
    'doctor': Icons.medical_information,
    'insurance': Icons.verified_user,
    'rent': Icons.apartment,
    'maintenance': Icons.build,
    'furniture': Icons.chair,
  };

  static IconData getIcon(String? iconName) {
    return iconMap[iconName] ?? Icons.category;
  }

  static String getIconName(IconData icon) {
    for (var entry in iconMap.entries) {
      if (entry.value == icon) {
        return entry.key;
      }
    }
    return 'category';
  }

  static List<String> get availableIconNames => iconMap.keys.toList();
}
