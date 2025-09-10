import 'package:flutter/material.dart';
import '../../../common/widgets/custom_widgets.dart';
import '../../../app/gradient_background.dart';
import '../models/register_page_model.dart';
import '../services/register_page_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _showPassword = false;
  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  String selectedRole = "Pegawai"; // default

  IconData _iconForRole(String role) {
    switch (role) {
      case 'Pegawai':
        return Icons.badge_outlined;
      case 'Penjual':
        return Icons.storefront_outlined;
      default:
        return Icons.work_outline;
    }
  }

  void _openRolePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              _roleOption("Pegawai", Icons.badge_outlined),
              _roleOption("Penjual", Icons.storefront_outlined),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _roleOption(String value, IconData icon) {
    final isSelected = selectedRole == value;
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFD53D3D)),
      title: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Color(0xFFD53D3D))
          : null,
      onTap: () {
        setState(() => selectedRole = value);
        Navigator.pop(context);
      },
    );
  }

  Future<bool> registerUser(Map<String, dynamic> data) async {
    final req = RegisterRequest(
      namaLengkap: data['nama_lengkap'] ?? '',
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      noHp: data['no_hp'] ?? '',
      password: data['password'] ?? '',
      role: data['role'] ?? '0',
    );
    final result = await RegisterPageService.register(req);
    return result.success;
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              margin: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.11),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Sign Up",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  // Nama Lengkap (paling atas)
                  CustomInputField(
                    hintText: "Nama Lengkap",
                    controller: fullNameController,
                    prefixIcon: const Icon(
                      Icons.person,
                      color: Color(0xFFD53D3D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomInputField(
                    hintText: "Username",
                    controller: usernameController,
                    prefixIcon: const Icon(
                      Icons.person,
                      color: Color(0xFFD53D3D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomInputField(
                    hintText: "Email",
                    controller: emailController,
                    prefixIcon: const Icon(
                      Icons.email,
                      color: Color(0xFFD53D3D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomInputField(
                    hintText: "Nomor Telepon",
                    controller: phoneController,
                    prefixIcon: const Icon(
                      Icons.phone,
                      color: Color(0xFFD53D3D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomInputField(
                    hintText: "Password",
                    controller: passwordController,
                    prefixIcon: const Icon(
                      Icons.lock,
                      color: Color(0xFFD53D3D),
                    ),
                    obscureText: !_showPassword,
                    obscuringCharacter: '*',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                        color: Color(0xFFD53D3D),
                      ),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pilihan Role (Bottom Sheet Picker - minimal & modern)
                  InkWell(
                    onTap: _openRolePicker,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD53D3D)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _iconForRole(selectedRole),
                            color: const Color(0xFFD53D3D),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              selectedRole,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Icon(Icons.expand_more, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  CustomButtonKotak(
                    text: "Registrasi",
                    onPressed: () async {
                      // Mapping role ke value enum string ('0', '1')
                      String roleValue;
                      if (selectedRole == "Pegawai") {
                        roleValue = '0';
                      } else if (selectedRole == "Penjual") {
                        roleValue = '1';
                      } else {
                        roleValue = '0'; // default fallback
                      }

                      final data = {
                        "nama_lengkap": fullNameController.text,
                        "username": usernameController.text,
                        "email": emailController.text,
                        "no_hp": phoneController.text,
                        "password": passwordController.text,
                        "role": roleValue,
                      };

                      final success = await registerUser(data);
                      if (success) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 32,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.green,
                                    size: 64,
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    "Registrasi Berhasil!",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Akun Anda berhasil dibuat.\nSilakan login untuk melanjutkan.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFD53D3D),
                                        foregroundColor:
                                            Colors.white, // pastikan teks putih
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context); // tutup dialog
                                        Navigator.pop(
                                          context,
                                        ); // kembali ke login
                                      },
                                      child: const Text(
                                        "Login Sekarang",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text("Registrasi Gagal"),
                            content: Text(
                              "Cek kembali data Anda atau coba lagi nanti.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text("OK"),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
