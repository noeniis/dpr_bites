// lib/features/seller/pages/profil/profil_seller.dart
import 'package:flutter/material.dart';
import '../../../../app/gradient_background.dart';
import '../../../../common/widgets/custom_widgets.dart';
import 'package:dpr_bites/common/data/dummy_users.dart';

class ProfilSellerPage extends StatefulWidget {
  const ProfilSellerPage({super.key});

  @override
  State<ProfilSellerPage> createState() => _ProfilSellerPageState();
}

class _ProfilSellerPageState extends State<ProfilSellerPage> {
  late Map<String, Object> user;
  late List<String> phones;

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void initState() {
    super.initState();
    // Ambil data dari "tabel users" (sementara: dummy_users.dart)
    user = Map<String, Object>.from(dummyUser);
    phones = (user['phone'] as List<dynamic>).cast<String>();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String name = (user['name'] as String?) ?? '-';
    final String email = (user['email'] as String?) ?? '-';
    final String nik = (user['nik'] as String?) ?? '-';
    final String ttl = (user['ttl'] as String?) ?? '-';

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Profil Pengguna (Penjual)'),
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
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ===== Identitas (Nama, NIK, TTL) =====
                      CustomEmptyCard(
                        margin: const EdgeInsets.only(bottom: 18),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFieldLine(
                                label: 'NIK',
                                value: nik,
                                editable: false,
                              ),
                              TextFieldLine(
                                label: 'Tanggal Lahir (TTL)',
                                value: ttl,
                                editable: false,
                              ),
                              const SizedBox(height: 4),
                              const Text(
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

                      // ===== Info Kontak (Email + Multi Phone) =====
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
                                value: email,
                                editable: false,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'No. Telepon',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (phones.isEmpty)
                                const Text('- (belum ada nomor)'),
                              if (phones.isNotEmpty)
                                Column(
                                  children: [
                                    for (int i = 0; i < phones.length; i++)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: TextFieldLine(
                                          label: 'Nomor ${i + 1}',
                                          value: phones[i],
                                          editable: false,
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),

                      // ===== Ganti Kata Sandi (pakai code lama) =====
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

                              // Kata sandi saat ini
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

                              // Kata sandi baru
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
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Kata sandi berhasil diubah',
                                      ),
                                    ),
                                  );
                                },
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
