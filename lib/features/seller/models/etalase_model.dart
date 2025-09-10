class EtalaseModel {
  final int idEtalase;
  final int idGerai;
  final String namaEtalase;

  EtalaseModel({
    required this.idEtalase,
    required this.idGerai,
    required this.namaEtalase,
  });

  factory EtalaseModel.fromJson(Map<String, dynamic> json) {
    return EtalaseModel(
      idEtalase: int.tryParse(json['id_etalase'].toString()) ?? 0,
      idGerai: int.tryParse(json['id_gerai'].toString()) ?? 0,
      namaEtalase: json['nama_etalase'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_etalase': idEtalase,
      'id_gerai': idGerai,
      'nama_etalase': namaEtalase,
    };
  }
}
