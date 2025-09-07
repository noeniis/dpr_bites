import 'package:dpr_bites/features/user/pages/home/home_page.dart';
import 'package:http/http.dart' as http;
import 'package:dpr_bites/common/utils/base_url.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../common/widgets/custom_widgets.dart';
import '../../../app/gradient_background.dart';
import 'forgot_password.dart';
import 'register_page.dart';
import 'package:dpr_bites/features/seller/pages/beranda/onboarding_checklist_page.dart';
import 'package:dpr_bites/features/seller/pages/beranda/dashboard_page.dart';
import 'package:dpr_bites/features/koperasi/homepage_koperasi.dart';
import 'package:shared_preferences/shared_preferences.dart';

// NEW: untuk fallback mengambil id_gerai dari service
import 'package:dpr_bites/features/seller/services/menu_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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

  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result is Map<String, dynamic> ? result : {};
      } else {
        debugPrint('HTTP error: ${response.statusCode} - ${response.body}');
        return {'success': false, 'message': 'Server error'};
      }
    } catch (e) {
      debugPrint('Exception saat login: ${e.toString()}');
      return {'success': false, 'message': 'Terjadi kesalahan'};
    }
  }

  void handleLogin() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    // Username khusus koperasi (hardcode, jika tidak ada di database)
    if (username == 'koperasi' && password == 'koperasi') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomepageKoperasi()),
      );
      return;
    }

    final result = await loginUser(username, password);
    if (result['success'] == true) {
      setState(() {
        errorMessage = null;
      });
      // Simpan id_users ke SharedPreferences dan print ke terminal
      if (result['id_users'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('id_users', result['id_users'].toString());
        debugPrint('ID USERS LOGIN: ${result['id_users']}');

        // pastikan id_gerai juga tersedia di prefs
        try {
          final idGeraiFromLogin = result['id_gerai']?.toString();
          if (idGeraiFromLogin != null && idGeraiFromLogin.isNotEmpty) {
            await prefs.setString('id_gerai', idGeraiFromLogin);
            debugPrint('ID GERAI LOGIN: $idGeraiFromLogin');
          } else {
            final gid = await MenuService.getIdGerai();
            if (gid != null) {
              await prefs.setString('id_gerai', gid.toString());
              debugPrint('ID GERAI (fallback): $gid');
            }
          }
        } catch (e) {
          debugPrint('Gagal menyimpan id_gerai: $e');
        }
      }

      // Redirect sesuai role dari backend
      final roleStr = result['role'].toString();
      if (roleStr == '0') {
        // Pegawai
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else if (roleStr == '1') {
        // Penjual
        final step1 = result['step1'] == true;
        final step2 = result['step2'] == true;
        final step3 = result['step3'] == true;
        if (step1 && step2 && step3) {
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } else {
      setState(() {
        errorMessage = result['message'] ?? 'Username atau password salah';
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
                      CustomButtonKotak(
                        text: " Masuk ke Sistem",
                        onPressed: handleLogin,
                      ),
                      const SizedBox(height: 10),
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
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OnboardingChecklistPage(),
                      ),
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
