class ResetPasswordRequest {
  final String email;
  final String otp;
  final String newPassword;
  const ResetPasswordRequest({
    required this.email,
    required this.otp,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'otp': otp,
    'new_password': newPassword,
  };
}

class ResetPasswordResult {
  final bool success;
  final String? message;
  const ResetPasswordResult({required this.success, this.message});
}
