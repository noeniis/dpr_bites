class OtpVerifyRequest {
  final String email;
  final String otp;
  const OtpVerifyRequest({required this.email, required this.otp});

  Map<String, dynamic> toJson() => {'email': email, 'otp': otp};
}

class OtpVerifyResult {
  final bool success;
  final String? message;
  const OtpVerifyResult({required this.success, this.message});
}
