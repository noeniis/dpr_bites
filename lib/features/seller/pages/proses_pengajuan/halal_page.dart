import 'package:flutter/material.dart';
import '../../../../app/gradient_background.dart';
import '../../../../app/app_theme.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'informasi_rekening_page.dart';

class HalalPage extends StatefulWidget {
  const HalalPage({super.key});

  @override
  State<HalalPage> createState() => _HalalPageState();
}

class _HalalPageState extends State<HalalPage> {
  String? _selectedOption;

  // Fungsi untuk mengirim data ke PHP (add_gerai_profile.php)
  Future<void> submitHalalInfo() async {
    // Data yang akan dikirim ke PHP
    final data = {
      'id_users': 1, // Ganti dengan id_user yang sesuai
      'nama_gerai': 'Gerai A',
      'latitude': '10.1234',
      'longitude': '20.1234',
      'detail_alamat': 'Jl. Contoh No. 1',
      'telepon': '081234567890',
      'qris_path': 'path/to/qris/image',
      'sertifikasi_halal': _selectedOption, // 'Ya' or 'Tidak'
      'status_pengajuan': 'pending', // Status sesuai yang dipilih
    };
    // android ke 10.0.2.2:80 klo emulator 10.0.2.2
    try {
      final response = await http.post(
        Uri.parse(
          'http://localhost:80/dpr_bites_api/add_gerai_profile.php',
        ), // URL PHP
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data), // Kirim data dalam format JSON
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success']) {
          // Jika berhasil, lanjutkan ke halaman berikutnya
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InformasiRekeningPage()),
          );
        } else {
          _showErrorDialog("Gagal menyimpan informasi");
        }
      } else {
        _showErrorDialog("Terjadi kesalahan pada server");
      }
    } catch (e) {
      _showErrorDialog("Terjadi kesalahan: ${e.toString()}");
    }
  }

  // Menampilkan dialog kesalahan
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Lengkapi informasi jenis masakan",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Bantu pelanggan membuat pilihan yang tepat dengan memberikan informasi mengenai jenis masakan dan status kehalalan makanan.",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Jenis masakan dan sertifikasi",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Apakah gerai ini memiliki sertifikasi Halal?",
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                RadioListTile<String>(
                  title: const Text("Ya, kami memiliki sertifikat halal"),
                  value: 'ya',
                  groupValue: _selectedOption,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _selectedOption = value;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text(
                    "Tidak, kami tidak memiliki sertifikat halal",
                  ),
                  value: 'tidak',
                  groupValue: _selectedOption,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _selectedOption = value;
                    });
                  },
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: CustomButtonKotak(
                      text: "Simpan dan lanjutkan",
                      onPressed: () {
                        // Pastikan pilihan sudah dipilih sebelum melanjutkan
                        if (_selectedOption != null) {
                          submitHalalInfo(); // Kirim data ke PHP
                        } else {
                          _showErrorDialog(
                            "Pilih status halal terlebih dahulu",
                          );
                        }
                      },
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
