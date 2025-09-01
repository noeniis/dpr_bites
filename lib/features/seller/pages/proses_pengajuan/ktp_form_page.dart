import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../app/gradient_background.dart';
import '../../../../common/widgets/custom_widgets.dart';
import 'halal_page.dart';
import 'ktp_camera_page.dart';

class KtpFormPage extends StatefulWidget {
  const KtpFormPage({super.key});

  @override
  State<KtpFormPage> createState() => _KtpFormPageState();
}

class _KtpFormPageState extends State<KtpFormPage> {
  String? ktpImagePath;
  final nameController = TextEditingController();
  final nikController = TextEditingController();
  String? gender;
  final birthPlaceController = TextEditingController();
  final birthDateController = TextEditingController();
  DateTime? birthDate;

  @override
  void dispose() {
    nameController.dispose();
    nikController.dispose();
    birthPlaceController.dispose();
    birthDateController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => birthDate = picked);
    }
  }

  Future<void> openCamera() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KtpCameraPage()),
    );
    if (!mounted) return; // Periksa apakah widget masih terpasang

    if (result is Map && result['imagePath'] != null) {
      setState(() {
        ktpImagePath = result['imagePath'];

        // Isi otomatis field dari hasil OCR jika ada
        final ocr = result['ocr'] ?? {};
        if (ocr['nama'] != null && ocr['nama'].toString().isNotEmpty) {
          nameController.text = ocr['nama'];
        }
        if (ocr['nik'] != null && ocr['nik'].toString().isNotEmpty) {
          nikController.text = ocr['nik'];
        }
        if (ocr['gender'] != null && ocr['gender'].toString().isNotEmpty) {
          gender = ocr['gender'];
        }
        if (ocr['tempatLahir'] != null &&
            ocr['tempatLahir'].toString().isNotEmpty) {
          birthPlaceController.text = ocr['tempatLahir'];
        }
        if (ocr['tanggalLahir'] != null &&
            ocr['tanggalLahir'].toString().isNotEmpty) {
          try {
            final parts = ocr['tanggalLahir'].split('-');
            if (parts.length == 3) {
              birthDate = DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
              birthDateController.text =
                  "${birthDate!.day.toString().padLeft(2, '0')}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.year}";
            }
          } catch (_) {}
        }
      });
    }
  }

  // Fungsi untuk mengirim data ke penjual_info.php
  Future<void> _sendDataToPhp() async {
    final data = {
      'nik': nikController.text,
      'nama': nameController.text,
      'gender': gender,
      'tempatLahir': birthPlaceController.text,
      'tanggalLahir': birthDateController.text,
    };

    try {
      final response = await http.post(
        Uri.parse(
          'http://localhost:80/dpr_bites_api/penjual_info.php',
        ), // Ganti dengan URL PHP
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success']) {
          // Jika berhasil, lanjutkan ke halaman berikutnya atau beri notifikasi
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HalalPage()),
          );
        } else {
          _showErrorDialog("Gagal mengirim data ke server");
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
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Data KTP',
            style: TextStyle(
              color: Color(0xFF602829),
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF602829)),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD53D3D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                      icon: const Icon(Icons.camera_alt, size: 20),
                      label: const Text(
                        'Ambil Foto KTP',
                        style: TextStyle(fontSize: 13),
                      ),
                      onPressed: openCamera,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (ktpImagePath != null && ktpImagePath!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AspectRatio(
                            aspectRatio: 85.6 / 53.98,
                            child: Image.file(
                              File(ktpImagePath!),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  CustomInputField(
                    controller: nameController,
                    hintText: 'Nama Lengkap',
                  ),
                  const SizedBox(height: 14),
                  CustomInputField(
                    controller: nikController,
                    hintText: 'NIK',
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'MAKSIMAL 16 DIGIT',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: gender,
                    items: const [
                      DropdownMenuItem(
                        value: 'Laki-laki',
                        child: Text(
                          'LAKI-LAKI',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Perempuan',
                        child: Text(
                          'PEREMPUAN',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => gender = val),
                    decoration: InputDecoration(
                      labelText: 'JENIS KELAMIN',
                      labelStyle: const TextStyle(
                        color: Colors.black,
                        letterSpacing: 1,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFD53D3D),
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFD53D3D),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFD53D3D),
                          width: 2.0,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  CustomInputField(
                    controller: birthPlaceController,
                    hintText: 'Tempat Lahir',
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () async {
                      await pickDate();
                      if (birthDate != null) {
                        birthDateController.text =
                            "${birthDate!.day.toString().padLeft(2, '0')}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.year}";
                      }
                    },
                    child: AbsorbPointer(
                      child: CustomInputField(
                        controller: birthDateController,
                        hintText: 'Tanggal Lahir',
                        prefixIcon: const Icon(
                          Icons.calendar_today,
                          color: Color(0xFFD53D3D),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButtonKotak(
                    text: 'Simpan',
                    onPressed: _sendDataToPhp, // Kirim data ke PHP
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
