class AddonOrderModel {
  final int idAddon;
  final String namaAddon;
  final int harga;

  AddonOrderModel({required this.idAddon, required this.namaAddon, required this.harga});

  factory AddonOrderModel.fromJson(Map<String, dynamic> json) {
    return AddonOrderModel(
      idAddon: json['id_addon'] is int ? json['id_addon'] : int.tryParse(json['id_addon'].toString()) ?? 0,
      namaAddon: json['nama_addon']?.toString() ?? '',
      harga: json['harga'] is int ? json['harga'] : int.tryParse(json['harga'].toString()) ?? 0,
    );
  }
}

class DetailOrderModel {
  final String namaMenu;
  final int jumlah;
  final int harga;
  final List<AddonOrderModel> addons;
  final String? note;

  DetailOrderModel({
    required this.namaMenu,
    required this.jumlah,
    required this.harga,
    this.addons = const [],
    this.note,
  });

  int get totalHarga => jumlah * harga;

  factory DetailOrderModel.fromJson(Map<String, dynamic> json) {
    return DetailOrderModel(
      namaMenu: json['name']?.toString() ?? '',
      jumlah: json['qty'] is int ? json['qty'] : int.tryParse(json['qty'].toString()) ?? 0,
      harga: json['harga_satuan'] is int ? json['harga_satuan'] : int.tryParse(json['harga_satuan'].toString()) ?? 0,
      addons: (json['addons'] is List)
          ? (json['addons'] as List).map((e) => AddonOrderModel.fromJson(e)).toList()
          : [],
      note: json['note']?.toString(),
    );
  }
}

