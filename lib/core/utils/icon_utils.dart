import 'package:flutter/material.dart';

class IconUtils {
  static const Map<String, String> assetIconMap = {
    'visa': 'assets/icons/visa.png',
    'mastercard': 'assets/icons/mastercard.png',
    'credit_text': 'assets/icons/credit_text.png',
    'cards': 'assets/icons/cards.png',
    'shield_card': 'assets/icons/shield_card.png',
  };

  static const Map<String, IconData> iconMap = {
    // Food & Dining
    'restaurant': Icons.restaurant,
    'utensils': Icons.restaurant,
    'dining': Icons.restaurant,
    'food': Icons.restaurant,
    'coffee': Icons.local_cafe,
    'cafe': Icons.local_cafe,
    'fast_food': Icons.fastfood,
    'groceries': Icons.shopping_basket_rounded,
    'shopping_cart': Icons.shopping_cart_rounded,
    'cooking': Icons.outdoor_grill_rounded,

    // Transport & Travel
    'directions_car': Icons.directions_car_rounded,
    'car': Icons.directions_car_rounded,
    'commute': Icons.commute_rounded,
    'public_transit': Icons.directions_bus_rounded,
    'bus': Icons.directions_bus_rounded,
    'taxi': Icons.local_taxi_rounded,
    'parking': Icons.local_parking_rounded,
    'fuel': Icons.local_gas_station_rounded,
    'gas': Icons.local_gas_station_rounded,
    'flight': Icons.flight_rounded,
    'plane': Icons.flight_rounded,
    'train': Icons.train_rounded,
    'hotel': Icons.hotel_rounded,
    'luggage': Icons.luggage_rounded,

    // Shopping & Personal
    'shopping_bag': Icons.shopping_bag_rounded,
    'bag': Icons.shopping_bag_rounded,
    'clothing': Icons.checkroom_rounded,
    'shirt': Icons.checkroom_rounded,
    'electronics': Icons.devices_rounded,
    'gadgets': Icons.devices_rounded,
    'laptop': Icons.laptop_mac_rounded,
    'phone': Icons.phone_android_rounded,
    'gift': Icons.card_giftcard_rounded,
    'gifts': Icons.card_giftcard_rounded,
    'heart': Icons.favorite_rounded,
    'favorite': Icons.favorite_rounded,

    // Bills, Home & Utilities
    'receipt': Icons.receipt_long_rounded,
    'bill': Icons.receipt_long_rounded,
    'home': Icons.home_rounded,
    'house': Icons.home_rounded,
    'apartment': Icons.apartment_rounded,
    'rent': Icons.apartment_rounded,
    'electricity': Icons.bolt_rounded,
    'power': Icons.bolt_rounded,
    'water': Icons.water_drop_rounded,
    'internet': Icons.wifi_rounded,
    'wifi': Icons.wifi_rounded,
    'maintenance': Icons.build_rounded,
    'tools': Icons.build_rounded,
    'furniture': Icons.chair_rounded,

    // Entertainment & Leisure
    'movie': Icons.movie_rounded,
    'film': Icons.movie_rounded,
    'videogame_asset': Icons.sports_esports_rounded,
    'gaming': Icons.sports_esports_rounded,
    'music': Icons.music_note_rounded,
    'theater': Icons.theater_comedy_rounded,
    'sports': Icons.sports_soccer_rounded,

    // Health & Wellness
    'medical': Icons.medical_services_rounded,
    'health': Icons.favorite_border_rounded,
    'hospital': Icons.local_hospital_rounded,
    'pharmacy': Icons.local_pharmacy_rounded,
    'doctor': Icons.medical_information_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'fitness': Icons.fitness_center_rounded,
    'gym': Icons.fitness_center_rounded,

    // Finance, Work & Education
    'account_balance_wallet': Icons.account_balance_wallet_rounded,
    'wallet': Icons.account_balance_wallet_rounded,
    'work': Icons.work_rounded,
    'briefcase': Icons.work_rounded,
    'school': Icons.school_rounded,
    'book': Icons.menu_book_rounded,
    'education': Icons.school_rounded,
    'local_library': Icons.local_library_rounded,
    'security': Icons.security_rounded,
    'shield': Icons.shield_rounded,
    'insurance': Icons.verified_user_rounded,
    'taxes': Icons.account_balance_rounded,
    'bank': Icons.account_balance_rounded,
    'trending_up': Icons.trending_up_rounded,
    'trending-up': Icons.trending_up_rounded,
    'salary': Icons.payments_rounded,
    'cash': Icons.payments_rounded,
    'payments': Icons.payments_rounded,
    'payment': Icons.payment_rounded,
    'pets': Icons.pets_rounded,
    'delivery': Icons.delivery_dining_rounded,

    // Custom asset dummy keys
    'visa': Icons.credit_card_rounded,
    'mastercard': Icons.credit_card_rounded,
    'credit_text': Icons.credit_card_rounded,
    'cards': Icons.credit_card_rounded,
    'shield_card': Icons.credit_card_rounded,
  };

  static IconData getIcon(String? iconName, {String? categoryName}) {
    if (iconName != null && iconMap.containsKey(iconName.toLowerCase().trim())) {
      return iconMap[iconName.toLowerCase().trim()]!;
    }
    
    // Smart name fallback based on category name
    if (categoryName != null && categoryName.isNotEmpty) {
      final name = categoryName.toLowerCase();
      if (name.contains('food') || name.contains('dining') || name.contains('restaurant') || name.contains('cafe')) {
        return Icons.restaurant_rounded;
      } else if (name.contains('grocer') || name.contains('market')) {
        return Icons.shopping_basket_rounded;
      } else if (name.contains('delivery') || name.contains('takeout')) {
        return Icons.delivery_dining_rounded;
      } else if (name.contains('flight') || name.contains('ticket') || name.contains('travel') || name.contains('trip')) {
        return Icons.flight_rounded;
      } else if (name.contains('transit') || name.contains('fuel') || name.contains('gas') || name.contains('car') || name.contains('taxi')) {
        return Icons.directions_car_rounded;
      } else if (name.contains('park')) {
        return Icons.local_parking_rounded;
      } else if (name.contains('entertain') || name.contains('movie') || name.contains('leisure') || name.contains('game')) {
        return Icons.movie_rounded;
      } else if (name.contains('fitness') || name.contains('gym') || name.contains('wellb')) {
        return Icons.fitness_center_rounded;
      } else if (name.contains('health') || name.contains('pharm') || name.contains('doctor') || name.contains('medic')) {
        return Icons.medical_services_rounded;
      } else if (name.contains('gift') || name.contains('giving')) {
        return Icons.card_giftcard_rounded;
      } else if (name.contains('bill') || name.contains('utilit') || name.contains('power') || name.contains('water')) {
        return Icons.receipt_long_rounded;
      } else if (name.contains('home') || name.contains('rent') || name.contains('house')) {
        return Icons.home_rounded;
      } else if (name.contains('fee') || name.contains('tax') || name.contains('finance')) {
        return Icons.account_balance_rounded;
      } else if (name.contains('insur')) {
        return Icons.verified_user_rounded;
      } else if (name.contains('shop') || name.contains('cloth')) {
        return Icons.shopping_bag_rounded;
      } else if (name.contains('salary') || name.contains('income') || name.contains('wage')) {
        return Icons.payments_rounded;
      } else if (name.contains('personal')) {
        return Icons.person_outline_rounded;
      }
    }

    return Icons.category_rounded;
  }

  static String getIconName(IconData icon) {
    for (var entry in iconMap.entries) {
      if (entry.value.codePoint == icon.codePoint && entry.value.fontFamily == icon.fontFamily) {
        return entry.key;
      }
    }
    return 'category';
  }

  static List<String> get availableIconNames => iconMap.keys.toList();

  static Widget buildIcon(String iconName, {Color? color, double size = 24, String? categoryName}) {
    if (assetIconMap.containsKey(iconName)) {
      return Image.asset(
        assetIconMap[iconName]!,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
    return Icon(getIcon(iconName, categoryName: categoryName), color: color, size: size);
  }
}
