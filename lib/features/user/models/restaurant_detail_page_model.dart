import 'package:flutter/foundation.dart';

@immutable
class RestaurantDetailFetchResult {
  final Map<String, dynamic>? resto; // normalized for UI consumption
  final List<Map<String, dynamic>> menus; // normalized menu list
  final String? error;

  const RestaurantDetailFetchResult({
    this.resto,
    this.menus = const [],
    this.error,
  });

  bool get success => error == null && resto != null;
}

@immutable
class CartSnapshot {
  final Map<String, int> selectedMenus; // menuId -> qty
  final Map<String, List<int>> selectedAddons; // menuId -> addon ids
  final Map<String, String> selectedNotes; // menuId -> note
  final Set<String> multiVariantMenus; // menuIds with >1 variants in cart
  final int totalPrice; // server authoritative total if provided

  const CartSnapshot({
    required this.selectedMenus,
    required this.selectedAddons,
    required this.selectedNotes,
    required this.multiVariantMenus,
    required this.totalPrice,
  });
}
