import 'package:flutter/material.dart';
import '../../../../app/app_theme.dart';
import '../../../../app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'pengajuan_selesai_page.dart';

class InformasiRekeningPage extends StatelessWidget {
  const InformasiRekeningPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pemegangController = TextEditingController();
    final bankController = TextEditingController();
    final noRekController = TextEditingController();
    final qrisController = TextEditingController();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            // Membungkus konten dengan SingleChildScrollView
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Lengkapi informasi rekening bank gerai Anda",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Penghasilan akan ditransfer secara otomatis ke rekening bank yang Anda daftarkan.",
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Detail rekening bank",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel("Pemegang rekening"),
                  _buildInput(
                    pemegangController,
                    "Masukkan nama pemegang rekening",
                  ),
                  const SizedBox(height: 16),
                  _buildLabel("Nama bank"),
                  _buildInput(bankController, "Bank"),
                  const SizedBox(height: 16),
                  _buildLabel("Nomor rekening bank"),
                  _buildInput(noRekController, "Nomor akun"),
                  const SizedBox(height: 16),
                  _buildLabel("Qris gerai Anda"),
                  const Text(
                    "NMID adalah kode unik untuk toko Anda yang dapat ditemukan pada kode QRIS",
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  _buildInput(qrisController, "Masukkan angka"),
                  const SizedBox(
                    height: 30,
                  ), // Menambahkan spasi untuk memberi ruang
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: CustomButtonKotak(
                        text: "Kirim",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PengajuanSelesaiPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textColor,
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
