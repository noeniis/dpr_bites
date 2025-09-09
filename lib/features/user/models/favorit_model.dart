class FavoriteMenuModel {
  final String id; // menu id as string
  final String name;
  final String desc;
  final int price;
  final String image;
  final String restaurantId;

  FavoriteMenuModel({
    required this.id,
    required this.name,
    required this.desc,
    required this.price,
    required this.image,
    required this.restaurantId,
  });

  factory FavoriteMenuModel.fromJson(Map<String, dynamic> json) {
    final id = (json['menu_id'] ?? json['id'] ?? '').toString();
    final name = (json['name'] ?? json['nama_menu'] ?? '').toString();
    final desc = (json['desc'] ?? json['deskripsi_menu'] ?? '').toString();
    final priceRaw = json['price'] ?? json['harga'] ?? 0;
    final price = int.tryParse(priceRaw.toString()) ?? 0;
    final image = (json['image'] ?? json['gambar_menu'] ?? '').toString();
    // restaurant may be nested
    String restaurantId = '';
    final r = json['restaurant'];
    if (r is Map) {
      restaurantId = (r['id'] ?? r['id_gerai'] ?? '').toString();
    }
    restaurantId = (json['restaurantId'] ?? restaurantId).toString();
    return FavoriteMenuModel(
      id: id,
      name: name,
      desc: desc,
      price: price,
      image: image,
      restaurantId: restaurantId,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'desc': desc,
    'price': price,
    'image': image,
    'restaurantId': restaurantId,
  };
}

class FavoriteRestaurantModel {
  final String id;
  final String name;
  final String desc;
  final dynamic rating; // keep dynamic to match UI rounding helper
  final dynamic ratingCount;
  final dynamic minPrice;
  final dynamic maxPrice;

  FavoriteRestaurantModel({
    required this.id,
    required this.name,
    required this.desc,
    required this.rating,
    required this.ratingCount,
    required this.minPrice,
    required this.maxPrice,
  });

  factory FavoriteRestaurantModel.fromJson(Map<String, dynamic> json) {
    return FavoriteRestaurantModel(
      id: (json['id'] ?? json['id_gerai'] ?? '').toString(),
      name: (json['name'] ?? json['nama'] ?? json['nama_gerai'] ?? '')
          .toString(),
      desc: (json['desc'] ?? json['deskripsi'] ?? '').toString(),
      rating: json['rating'] ?? 0,
      ratingCount: json['ratingCount'] ?? 0,
      minPrice: json['minPrice'],
      maxPrice: json['maxPrice'],
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'desc': desc,
    'rating': rating,
    'ratingCount': ratingCount,
    'minPrice': minPrice,
    'maxPrice': maxPrice,
  };
}

class FavoriteFetchResult {
  final List<Map<String, dynamic>> favorites; // normalized menus
  final Map<String, Map<String, dynamic>> restaurants; // id -> normalized resto
  final String? error;
  FavoriteFetchResult({
    required this.favorites,
    required this.restaurants,
    this.error,
  });
}

class CartUpdateResult {
  final bool success;
  final bool deleted;
  final int? qty; // updated qty if provided
  CartUpdateResult({required this.success, this.deleted = false, this.qty});
}

class ToggleFavoriteResult {
  final bool success;
  final bool? favorited; // null if not provided
  ToggleFavoriteResult({required this.success, this.favorited});
}
