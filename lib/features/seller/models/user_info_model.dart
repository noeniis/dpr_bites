class UserInfoModel {
  final String namaLengkap;
  final String noHp;
  final String email;

  UserInfoModel({
    required this.namaLengkap,
    required this.noHp,
    required this.email,
  });

  factory UserInfoModel.fromJson(Map<String, dynamic> json) {
    return UserInfoModel(
      namaLengkap: json['nama_lengkap'] ?? '',
      noHp: json['no_hp'] ?? '',
      email: json['email'] ?? '',
    );
  }
}
