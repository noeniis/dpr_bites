import 'package:dpr_bites/features/user/pages/home/home_page.dart';
import 'package:dpr_bites/features/auth/services/auth_service.dart';
import 'package:flutter/material.dart';
import '../../../common/widgets/custom_widgets.dart';
import '../../../app/gradient_background.dart';
import 'forgot_password.dart';
import 'register_page.dart';
import 'package:dpr_bites/features/seller/pages/beranda/onboarding_checklist_page.dart';
import 'package:dpr_bites/features/seller/pages/beranda/dashboard_page.dart';
import 'package:dpr_bites/features/koperasi/homepage_koperasi.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  bool _showPassword = false;
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  String? errorMessage;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }


  void handleLogin() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();


    if (username == 'koperasi' && password == 'koperasi') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomepageKoperasi()),
      );
      return;
    }

    final result = await _authService.loginUser(username, password);
    if (result.success) {
      setState(() {
        errorMessage = null;
      });
      // Simpan id_users ke SharedPreferences dan print ke terminal
      if (result.idUsers != null) {
        await _authService.saveUserId(result.idUsers!);
        debugPrint('ID USERS LOGIN: ${result.idUsers}');
      }
      // Redirect sesuai role dari backend
      final roleStr = result.role ?? '';
      if (roleStr == '0') {
        // Pegawai
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else if (roleStr == '1') {
        // Penjual
        if (result.step1 && result.step2 && result.step3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SellerDashboardPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingChecklistPage()),
          );
        }
      } else if (roleStr == 'koperasi') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomepageKoperasi()),
        );
      } else {
        // Default: ke HomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } else {
      setState(() {
        errorMessage = result.message ?? 'Username atau password salah';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                // CARD UTAMA
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // HEADER LOGIN
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE5EC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.login,
                              color: Color(0xFFD53D3D),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Akses Masuk',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Masukkan kredensial Anda',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Username
                      const Text(
                        "Username",
                        style: TextStyle(
                          color: Color(0xFFD53D3D),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      CustomInputField(
                        hintText: "Masukkan username",
                        controller: usernameController,
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Color(0xFFD53D3D),
                        ),
                        obscureText: false,
                      ),
                      const SizedBox(height: 18),

                      // Password
                      const Text(
                        "Password",
                        style: TextStyle(
                          color: Color(0xFFD53D3D),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      CustomInputField(
                        hintText: "Masukkan password",
                        controller: passwordController,
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Color(0xFFD53D3D),
                        ),
                        obscureText: !_showPassword,
                        obscuringCharacter: '*',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
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

                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),

                      // Tombol Masuk
                      CustomButtonKotak(
                        text: " Masuk ke Sistem",
                        onPressed: handleLogin,
                      ),
                      const SizedBox(height: 10),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordPage(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size(0, 0),
                          ),
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: Color(0xFFD53D3D),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // "or" separator
                Row(
                  children: const [
                    Expanded(child: Divider(thickness: 1.2)),
                    SizedBox(width: 10),
                    Text(
                      "or",
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(child: Divider(thickness: 1.2)),
                  ],
                ),
                const SizedBox(height: 16),

                // Registrasi Akun Button
                CustomButtonKotak(
                  text: " Registrasi Akun",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterPage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Bantuan Card (bisa diklik untuk masuk onboarding checklist seller)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OnboardingChecklistPage()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE5EC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.help_outline,
                            color: Color(0xFFD53D3D),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Butuh Bantuan?',
                                style: TextStyle(
                                  color: Color(0xFFD53D3D),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Hubungi admin IT untuk bantuan teknis',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
