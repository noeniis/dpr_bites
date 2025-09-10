class ForgotPasswordRequest {
  final String email;
  const ForgotPasswordRequest(this.email);

  Map<String, dynamic> toJson() => {'email': email};
}

class ForgotPasswordResult {
  final bool success;
  final String? message;

  const ForgotPasswordResult({required this.success, this.message});
}
