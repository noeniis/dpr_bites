import 'package:flutter/material.dart';
import '../../../common/widgets/custom_widgets.dart';
import '../../../app/gradient_background.dart';

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
                    CustomInputField(
                      hintText: "Username",
                      controller: usernameController,
                      prefixIcon: const Icon(Icons.person, color: Color(0xFFD53D3D)),
                    ),
                    const SizedBox(height: 16),
                    CustomInputField(
                      hintText: "Email",
                      controller: emailController,
                      prefixIcon: const Icon(Icons.email, color: Color(0xFFD53D3D)),
                    ),
                    const SizedBox(height: 16),
                    CustomInputField(
                      hintText: "Nomor Telepon",
                      controller: phoneController,
                      prefixIcon: const Icon(Icons.phone, color: Color(0xFFD53D3D)),
                    ),
                    const SizedBox(height: 16),
                    CustomInputField(
                      hintText: "Password",
                      controller: passwordController,
                      prefixIcon: const Icon(Icons.lock, color: Color(0xFFD53D3D)),
                    ),
                    const SizedBox(height: 16),

                    // Pilihan Role (Dropdown)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD53D3D)),
                      ),
                      child: DropdownButton<String>(
                        value: selectedRole,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFD53D3D)),
                        underline: Container(),
                        items: const [
                          DropdownMenuItem(
                            value: "Pegawai",
                            child: Text("Pegawai", style: TextStyle(fontSize: 16)),
                          ),
                          DropdownMenuItem(
                            value: "Penjual",
                            child: Text("Penjual", style: TextStyle(fontSize: 16)),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => selectedRole = value);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    CustomButtonKotak(
                      text: "Registrasi",
                      onPressed: () {
                        // TODO: logic signup
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
