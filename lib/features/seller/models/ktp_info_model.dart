class KtpInfoModel {
  final String nama;
  final String nik;
  final String noTeleponPenjual;
  final String gender;
  final String tempatLahir;
  final String tanggalLahir;
  final String fotoKtpPath;

  KtpInfoModel({
    required this.nama,
    required this.nik,
    required this.noTeleponPenjual,
    required this.gender,
    required this.tempatLahir,
    required this.tanggalLahir,
    required this.fotoKtpPath,
  });

  factory KtpInfoModel.fromJson(Map<String, dynamic> json) {
    return KtpInfoModel(
      nama: json['nama_lengkap'] ?? json['nama'] ?? '',
      nik: json['nik'] ?? '',
      noTeleponPenjual: json['no_telepon_penjual'] ?? '',
      gender: json['jenis_kelamin'] ?? '',
      tempatLahir: json['tempat_lahir'] ?? '',
      tanggalLahir: json['tanggal_lahir'] ?? '',
      fotoKtpPath: json['foto_ktp_path'] ?? '',
    );
  }
}
