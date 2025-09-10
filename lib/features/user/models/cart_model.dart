class CartMenuItemModel {
  final int? idKeranjangItem;
  final int menuId;
  final String name;
  final String desc;
  final String image;
  final int price;
  final int qty;
  final List<String> addon; // labels
  final int addonPrice;
  final List<Map<String, dynamic>> addonOptions;
  final String note;

  CartMenuItemModel({
    required this.idKeranjangItem,
    required this.menuId,
    required this.name,
    required this.desc,
    required this.image,
    required this.price,
    required this.qty,
    required this.addon,
    required this.addonPrice,
    required this.addonOptions,
    required this.note,
  });

  factory CartMenuItemModel.fromJson(Map<String, dynamic> json) {
    return CartMenuItemModel(
      idKeranjangItem: int.tryParse(
        (json['id_keranjang_item'] ?? '').toString(),
      ),
      menuId: int.tryParse((json['menu_id'] ?? json['id']).toString()) ?? 0,
      name: (json['name'] ?? json['nama_menu'] ?? '').toString(),
      desc: (json['desc'] ?? json['deskripsi_menu'] ?? '').toString(),
      image: (json['image'] ?? json['gambar_menu'] ?? '').toString(),
      price:
          int.tryParse((json['price'] ?? json['harga'] ?? 0).toString()) ?? 0,
      qty: int.tryParse((json['qty'] ?? 1).toString()) ?? 1,
      addon: (json['addon'] as List? ?? const [])
          .whereType<dynamic>()
          .map((e) => e.toString())
          .toList(),
      addonPrice: int.tryParse((json['addonPrice'] ?? 0).toString()) ?? 0,
      addonOptions: (json['addonOptions'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      note: (json['note'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id_keranjang_item': idKeranjangItem,
    'menu_id': menuId,
    'name': name,
    'desc': desc,
    'image': image,
    'price': price,
    'qty': qty,
    'addon': addon,
    'addonPrice': addonPrice,
    'addonOptions': addonOptions,
    'note': note,
  };
}

class CartRestaurantModel {
  final int? idKeranjang;
  final int idGerai;
  final String restaurantName;
  final String estimate;
  final List<CartMenuItemModel> menus;

  CartRestaurantModel({
    required this.idKeranjang,
    required this.idGerai,
    required this.restaurantName,
    required this.estimate,
    required this.menus,
  });

  factory CartRestaurantModel.fromJson(Map<String, dynamic> json) {
    final menus = (json['menus'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => CartMenuItemModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return CartRestaurantModel(
      idKeranjang: int.tryParse((json['id_keranjang'] ?? '').toString()),
      idGerai: int.tryParse((json['id_gerai'] ?? 0).toString()) ?? 0,
      restaurantName: (json['restaurantName'] ?? json['nama_gerai'] ?? '')
          .toString(),
      estimate: (json['estimate'] ?? '15-20 menit').toString(),
      menus: menus,
    );
  }

  Map<String, dynamic> toMap() => {
    'id_keranjang': idKeranjang,
    'id_gerai': idGerai,
    'restaurantName': restaurantName,
    'estimate': estimate,
    'menus': menus.map((m) => m.toMap()).toList(),
  };
}

class CartFetchResult {
  final List<Map<String, dynamic>> carts;
  final String? error;

  CartFetchResult({required this.carts, this.error});
}
