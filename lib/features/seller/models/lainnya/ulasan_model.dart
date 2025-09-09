class UlasanModel {
  final int idUlasan;
  final String name;
  final String komentar;
  final String pesanan;
  final int rating;
  final String photo;
  final String balasan;

  UlasanModel({
    required this.idUlasan,
    required this.name,
    required this.komentar,
    required this.pesanan,
    required this.rating,
    required this.photo,
    required this.balasan,
  });

  factory UlasanModel.fromJson(Map<String, dynamic> json) {
    return UlasanModel(
      idUlasan: json['id_ulasan'] ?? 0,
      name: json['name'] ?? '-',
      komentar: json['komentar'] ?? '',
      pesanan: json['pesanan'] ?? '',
      rating: json['rating'] ?? 0,
      photo: json['photo'] ?? '',
      balasan: json['balasan'] ?? '',
    );
  }
}
