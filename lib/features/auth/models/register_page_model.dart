class RegisterRequest {
  final String namaLengkap;
  final String username;
  final String email;
  final String noHp;
  final String password;
  final String role; // '0' pegawai, '1' penjual

  const RegisterRequest({
    required this.namaLengkap,
    required this.username,
    required this.email,
    required this.noHp,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    'nama_lengkap': namaLengkap,
    'username': username,
    'email': email,
    'no_hp': noHp,
    'password': password,
    'role': role,
  };
}

class RegisterResult {
  final bool success;
  final String? message;

  const RegisterResult({required this.success, this.message});
}
