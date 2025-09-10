class SellerUserModel {
  final String idUsers;
  final int step1;
  final int step2;
  final int step3;
  final String statusPengajuanGerai;
  final String alasanTolak;

  SellerUserModel({
    required this.idUsers,
    required this.step1,
    required this.step2,
    required this.step3,
    required this.statusPengajuanGerai,
    required this.alasanTolak,
  });

  factory SellerUserModel.fromJson(Map<String, dynamic> json, {String? statusPengajuanGerai, String? alasanTolak}) {
    return SellerUserModel(
      idUsers: json['id_users']?.toString() ?? '',
      step1: int.tryParse(json['step1']?.toString() ?? '0') ?? 0,
      step2: int.tryParse(json['step2']?.toString() ?? '0') ?? 0,
      step3: int.tryParse(json['step3']?.toString() ?? '0') ?? 0,
      statusPengajuanGerai: statusPengajuanGerai ?? '',
      alasanTolak: alasanTolak ?? '',
    );
  }
}
