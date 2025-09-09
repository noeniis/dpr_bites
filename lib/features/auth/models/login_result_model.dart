class LoginResultModel {
  final bool success;
  final String? message;
  final String? idUsers;
  final String? role;
  final bool step1;
  final bool step2;
  final bool step3;

  LoginResultModel({
    required this.success,
    this.message,
    this.idUsers,
    this.role,
    this.step1 = false,
    this.step2 = false,
    this.step3 = false,
  });

  factory LoginResultModel.fromJson(Map<String, dynamic> json) {
    return LoginResultModel(
      success: json['success'] == true,
      message: json['message'],
      idUsers: json['id_users']?.toString(),
      role: json['role']?.toString(),
      step1: json['step1'] == true,
      step2: json['step2'] == true,
      step3: json['step3'] == true,
    );
  }
}
