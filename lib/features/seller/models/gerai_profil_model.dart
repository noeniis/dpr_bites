class GeraiProfilModel {
  final int idGerai;
  final String namaGerai;
  final String bannerPath;
  final String listingPath;
  final String deskripsiGerai;
  final String hariBuka;
  final String jamBuka;
  final String jamTutup;
  final String detailAlamat;
  final double? latitude;
  final double? longitude;
  final String telepon;

  GeraiProfilModel({
    required this.idGerai,
    required this.namaGerai,
    required this.bannerPath,
    required this.listingPath,
    required this.deskripsiGerai,
    required this.hariBuka,
    required this.jamBuka,
    required this.jamTutup,
    required this.detailAlamat,
    required this.latitude,
    required this.longitude,
    required this.telepon,
  });

  factory GeraiProfilModel.fromJson(Map<String, dynamic> json) {
    return GeraiProfilModel(
      idGerai: json['id_gerai'] is int ? json['id_gerai'] : int.tryParse(json['id_gerai'].toString()) ?? 0,
      namaGerai: json['nama_gerai'] ?? '',
      bannerPath: json['banner_path'] ?? '',
      listingPath: json['listing_path'] ?? '',
      deskripsiGerai: json['deskripsi_gerai'] ?? '',
      hariBuka: json['hari_buka'] ?? '',
      jamBuka: json['jam_buka'] ?? '08:00',
      jamTutup: json['jam_tutup'] ?? '16:00',
      detailAlamat: json['detail_alamat'] ?? '',
      latitude: json['latitude'] != null && json['latitude'].toString().isNotEmpty ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null && json['longitude'].toString().isNotEmpty ? double.tryParse(json['longitude'].toString()) : null,
      telepon: json['telepon'] ?? '',
    );
  }
}
