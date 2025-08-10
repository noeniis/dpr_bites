import 'package:flutter/material.dart';
import '../../../common/widgets/custom_widgets.dart';
import '../../../app/gradient_background.dart';
import 'reset_password_success_page.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("Forgot Password"),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: SafeArea(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(28),
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      red: 0.08,
                      green: 0.08,
                      blue: 0.08,
                      alpha: 1,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Reset Password",
                    style: TextStyle(
                      color: Color(0xFFD53D3D),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Masukkan email Anda untuk reset password.",
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  CustomInputField(
                    hintText: "Masukkan email",
                    controller: emailController,
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFFD53D3D),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomButtonKotak(
                    text: "Kirim Link Reset",
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ResetPasswordSuccessPage(),
                        ),
                      );
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
