class CheckoutFetchResult {
  final bool success;
  final String restaurantName;
  final int deliveryFee;
  final String? qrisPath;
  final double? latitude;
  final double? longitude;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic>? address;
  final int? selectedAddressId;
  final bool noSelectionMatch;
  final List<int> missingSelectedIds;

  CheckoutFetchResult({
    required this.success,
    required this.restaurantName,
    required this.deliveryFee,
    required this.items,
    this.qrisPath,
    this.latitude,
    this.longitude,
    this.address,
    this.selectedAddressId,
    this.noSelectionMatch = false,
    List<int>? missingSelectedIds,
  }) : missingSelectedIds = missingSelectedIds ?? const [];

  CheckoutFetchResult copyWith({
    bool? success,
    String? restaurantName,
    int? deliveryFee,
    String? qrisPath,
    double? latitude,
    double? longitude,
    List<Map<String, dynamic>>? items,
    Map<String, dynamic>? address,
    int? selectedAddressId,
    bool? noSelectionMatch,
    List<int>? missingSelectedIds,
  }) {
    return CheckoutFetchResult(
      success: success ?? this.success,
      restaurantName: restaurantName ?? this.restaurantName,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      qrisPath: qrisPath ?? this.qrisPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      items: items ?? this.items,
      address: address ?? this.address,
      selectedAddressId: selectedAddressId ?? this.selectedAddressId,
      noSelectionMatch: noSelectionMatch ?? this.noSelectionMatch,
      missingSelectedIds: missingSelectedIds ?? this.missingSelectedIds,
    );
  }
}

class MenuDetailUserResult {
  final List<Map<String, dynamic>> addonOptions;
  MenuDetailUserResult({required this.addonOptions});
}

class UpdateCartItemResult {
  final Map<String, dynamic>? updatedItem; // from server 'item'
  UpdateCartItemResult({this.updatedItem});
}

class CreateTransactionResult {
  final bool success;
  final String? bookingId;
  final String? message;
  CreateTransactionResult({
    required this.success,
    this.bookingId,
    this.message,
  });
}
