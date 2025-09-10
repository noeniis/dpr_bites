class AddonModel {
  final int idAddon;
  final int idGerai;
  final String namaAddon;
  final int harga;
  final String deskripsi;
  final String imagePath;
  final int stok;
  bool tersedia;

  AddonModel({
    required this.idAddon,
    required this.idGerai,
    required this.namaAddon,
    required this.harga,
    required this.deskripsi,
    required this.imagePath,
    required this.stok,
    required this.tersedia,
  });

  factory AddonModel.fromJson(Map<String, dynamic> json) {
    return AddonModel(
      idAddon: int.tryParse(json['id_addon'].toString()) ?? 0,
      idGerai: int.tryParse(json['id_gerai'].toString()) ?? 0,
      namaAddon: json['nama_addon'] ?? '',
      harga: int.tryParse(json['harga'].toString()) ?? 0,
      deskripsi: json['deskripsi'] ?? '',
      imagePath: json['image_path'] ?? '',
      stok: int.tryParse(json['stok'].toString()) ?? 0,
      tersedia: json['tersedia'].toString() == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_addon': idAddon,
      'id_gerai': idGerai,
      'nama_addon': namaAddon,
      'harga': harga,
      'deskripsi': deskripsi,
      'image_path': imagePath,
      'stok': stok,
      'tersedia': tersedia ? '1' : '0',
    };
  }
}
