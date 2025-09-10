class SearchMenuModel {
  final dynamic id; // keep dynamic to support int/string ids
  final String name;
  final String desc;
  final int price;
  final String image;

  SearchMenuModel({
    required this.id,
    required this.name,
    required this.desc,
    required this.price,
    required this.image,
  });

  factory SearchMenuModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['menu_id'];
    final name = (json['name'] ?? json['nama_menu'] ?? '').toString();
    final desc = (json['desc'] ?? json['deskripsi_menu'] ?? '').toString();
    final priceRaw = json['price'] ?? json['harga'] ?? 0;
    final price = int.tryParse(priceRaw.toString()) ?? 0;
    final image = (json['image'] ?? json['gambar_menu'] ?? '').toString();
    return SearchMenuModel(
      id: id,
      name: name,
      desc: desc,
      price: price,
      image: image,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'desc': desc,
    'price': price,
    'image': image,
  };
}

class SearchRestaurantModel {
  final dynamic id;
  final String name;
  final String profilePic;
  final String rating;
  final String ratingCount;
  final dynamic minPrice;
  final dynamic maxPrice;
  final String desc;
  final List<SearchMenuModel> menus;

  SearchRestaurantModel({
    required this.id,
    required this.name,
    required this.profilePic,
    required this.rating,
    required this.ratingCount,
    required this.minPrice,
    required this.maxPrice,
    required this.desc,
    required this.menus,
  });

  factory SearchRestaurantModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['id_gerai'] ?? json['gerai_id'];
    final name = (json['name'] ?? json['nama'] ?? json['nama_gerai'] ?? '')
        .toString();
    final profilePic =
        (json['profilePic'] ?? json['foto'] ?? json['gambar'] ?? '').toString();
    final rating = (json['rating'] ?? '0').toString();
    final ratingCount = (json['ratingCount'] ?? '0').toString();
    final minPrice = json['minPrice'];
    final maxPrice = json['maxPrice'];
    final desc = (json['desc'] ?? json['deskripsi'] ?? '').toString();
    final menusJson = json['menus'];
    final menus = (menusJson is List)
        ? menusJson
              .map(
                (e) => SearchMenuModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList()
        : <SearchMenuModel>[];
    return SearchRestaurantModel(
      id: id,
      name: name,
      profilePic: profilePic,
      rating: rating,
      ratingCount: ratingCount,
      minPrice: minPrice,
      maxPrice: maxPrice,
      desc: desc,
      menus: menus,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'profilePic': profilePic,
    'rating': rating,
    'ratingCount': ratingCount,
    'minPrice': minPrice,
    'maxPrice': maxPrice,
    'desc': desc,
    'menus': menus.map((m) => m.toMap()).toList(),
  };
}
