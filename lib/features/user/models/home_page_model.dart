import 'package:flutter/foundation.dart';

@immutable
class HomeAddressModel {
  final String buildingName;
  final String detailPengantaran;
  const HomeAddressModel({
    required this.buildingName,
    required this.detailPengantaran,
  });
}

@immutable
class HomeAddressFetchResult {
  final HomeAddressModel? address;
  final bool hasAddress;
  final String? error;
  const HomeAddressFetchResult({
    this.address,
    this.error,
    this.hasAddress = false,
  });
}

@immutable
class HomeRestaurantsFetchResult {
  final List<Map<String, dynamic>> restaurants;
  final String? error;
  const HomeRestaurantsFetchResult({required this.restaurants, this.error});
  bool get success => error == null;
}

// Optional model to normalize restaurant entries if needed later
@immutable
class HomeRestaurantModel {
  final Map<String, dynamic> raw; // keep raw to preserve UI expectations
  const HomeRestaurantModel(this.raw);

  factory HomeRestaurantModel.fromJson(Map<String, dynamic> m) {
    // No transformation to preserve existing UI keys/behavior
    return HomeRestaurantModel(Map<String, dynamic>.from(m));
  }

  Map<String, dynamic> toMap() => raw;
}
