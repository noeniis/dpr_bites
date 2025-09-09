class PengajuanModel {
  final int idGerai;
  final String namaGerai;
  final String namaLengkap;
  final String statusPengajuan;
  final String? fotoKtpPath;
  final String? nik;
  final String? tempatLahir;
  final String? tanggalLahir;
  final String? jenisKelamin;
  final String? detailAlamat;
  final String? qrisPath;
  final String? hariBuka;
  final String? jamBuka;
  final String? jamTutup;
  final int? step1;
  final int? step2;

  PengajuanModel({
    required this.idGerai,
    required this.namaGerai,
    required this.namaLengkap,
    required this.statusPengajuan,
    this.fotoKtpPath,
    this.nik,
    this.tempatLahir,
    this.tanggalLahir,
    this.jenisKelamin,
    this.detailAlamat,
    this.qrisPath,
    this.hariBuka,
    this.jamBuka,
    this.jamTutup,
    this.step1,
    this.step2,
  });

  factory PengajuanModel.fromJson(Map<String, dynamic> json) {
    return PengajuanModel(
      idGerai: int.tryParse(json['id_gerai'].toString()) ?? 0,
      namaGerai: json['nama_gerai']?.toString() ?? '-',
      namaLengkap: json['nama_lengkap']?.toString() ?? '-',
      statusPengajuan: json['status_pengajuan']?.toString() ?? 'pending',
      fotoKtpPath: json['foto_ktp_path']?.toString(),
      nik: json['nik']?.toString(),
      tempatLahir: json['tempat_lahir']?.toString(),
      tanggalLahir: json['tanggal_lahir']?.toString(),
      jenisKelamin: json['jenis_kelamin']?.toString(),
      detailAlamat: json['detail_alamat']?.toString(),
      qrisPath: json['qris_path']?.toString(),
      hariBuka: json['hari_buka']?.toString(),
      jamBuka: json['jam_buka']?.toString(),
      jamTutup: json['jam_tutup']?.toString(),
      step1: json['step1'] != null ? int.tryParse(json['step1'].toString()) : null,
      step2: json['step2'] != null ? int.tryParse(json['step2'].toString()) : null,
    );
  }
}
