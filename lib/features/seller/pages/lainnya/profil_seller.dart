import 'package:flutter/material.dart';
import '../../../../app/gradient_background.dart';
import '../../../../common/widgets/custom_widgets.dart';

class ProfilSellerPage extends StatefulWidget {
  const ProfilSellerPage({Key? key}) : super(key: key);

  @override
  State<ProfilSellerPage> createState() => _ProfilSellerPageState();
}

class _ProfilSellerPageState extends State<ProfilSellerPage> {
  final TextEditingController _emailController = TextEditingController(
    text: 'seller@email.com',
  );
  final TextEditingController _phoneController = TextEditingController(
    text: '08123456789',
  );
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Profil Pengguna'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.black,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Nama dan Peran
                      CustomEmptyCard(
                        margin: const EdgeInsets.only(bottom: 18),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Ika Fahriza',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Peran: Owner',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Info Kontak
                      CustomEmptyCard(
                        margin: const EdgeInsets.only(bottom: 18),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFieldLine(
                                label: 'Email',
                                value: _emailController.text,
                                editable: false,
                              ),
                              TextFieldLine(
                                label: 'No. Telp',
                                value: _phoneController.text,
                                editable: false,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Ganti Kata Sandi
                      CustomEmptyCard(
                        margin: const EdgeInsets.only(bottom: 18),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ganti Kata Sandi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              CustomInputField(
                                hintText: 'Kata sandi saat ini',
                                controller: _currentPasswordController,
                                obscureText: _obscureCurrent,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureCurrent
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureCurrent = !_obscureCurrent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              CustomInputField(
                                hintText: 'Kata sandi baru',
                                controller: _newPasswordController,
                                obscureText: _obscureNew,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureNew
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureNew = !_obscureNew,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  child: const Text('Forgot Password?'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              CustomButtonOval(
                                text: 'Ubah Kata Sandi',
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomButtonKotak(text: 'Hapus Akun', onPressed: () {}),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
