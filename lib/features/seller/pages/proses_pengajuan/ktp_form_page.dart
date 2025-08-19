import 'ktp_camera_page.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../app/gradient_background.dart';
import '../../../../common/widgets/custom_widgets.dart';
import 'package:flutter/services.dart';

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
  DateTime? birthDate;

  @override
  void dispose() {
    nameController.dispose();
    nikController.dispose();
    birthPlaceController.dispose();
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

  @override
  Widget build(BuildContext context) {
    Future<void> openCamera() async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const KtpCameraPage()),
      );
      if (result is Map && result['imagePath'] != null) {
        setState(() {
          ktpImagePath = result['imagePath'];
          // Isi otomatis field dari hasil OCR jika ada
          final ocr = result['ocr'] ?? {};
          if (ocr['nama'] != null && ocr['nama'].toString().isNotEmpty) nameController.text = ocr['nama'];
          if (ocr['nik'] != null && ocr['nik'].toString().isNotEmpty) nikController.text = ocr['nik'];
          if (ocr['gender'] != null && ocr['gender'].toString().isNotEmpty) gender = ocr['gender'];
          if (ocr['tempatLahir'] != null && ocr['tempatLahir'].toString().isNotEmpty) birthPlaceController.text = ocr['tempatLahir'];
          if (ocr['tanggalLahir'] != null && ocr['tanggalLahir'].toString().isNotEmpty) {
            // Parsing tanggal lahir ke DateTime jika memungkinkan
            try {
              final parts = ocr['tanggalLahir'].split('-');
              if (parts.length == 3) {
                birthDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
              }
            } catch (_) {}
          }
        });
      }
    }
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Data KTP', style: TextStyle(color: Color(0xFF602829), fontWeight: FontWeight.bold)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      icon: const Icon(Icons.camera_alt, size: 20),
                      label: const Text('Ambil Foto KTP', style: TextStyle(fontSize: 13)),
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
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500, letterSpacing: 1),
                    decoration: const InputDecoration(
                      labelText: 'NAMA LENGKAP',
                      labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Colors.black)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Colors.black)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Colors.black, width: 2)),
                      contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: nikController,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                    ],
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500, letterSpacing: 1),
                    decoration: const InputDecoration(
                      labelText: 'NIK',
                      labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Colors.black)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Colors.black)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Colors.black, width: 2)),
                      contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('MAKSIMAL 16 DIGIT', style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: gender,
                    items: const [
                      DropdownMenuItem(value: 'Laki-laki', child: Text('LAKI-LAKI', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, letterSpacing: 1))),
                      DropdownMenuItem(value: 'Perempuan', child: Text('PEREMPUAN', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, letterSpacing: 1))),
                    ],
                    onChanged: (val) => setState(() => gender = val),
                    decoration: const InputDecoration(
                      labelText: 'JENIS KELAMIN',
                      labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Colors.black)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Colors.black)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Colors.black, width: 2)),
                      contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500, letterSpacing: 1),
                    dropdownColor: Colors.white,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: birthPlaceController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500, letterSpacing: 1),
                    decoration: const InputDecoration(
                      labelText: 'TEMPAT LAHIR',
                      labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Colors.black)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Colors.black)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Colors.black, width: 2)),
                      contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 14),
                 
                  InkWell(
                    onTap: pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'TANGGAL LAHIR',
                        labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Colors.black)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Colors.black)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Colors.black, width: 2)),
                        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        alignLabelWithHint: true,
                        floatingLabelAlignment: FloatingLabelAlignment.start,
                      ),
                      child: Text(
                        birthDate != null
                            ? '${birthDate!.day.toString().padLeft(2, '0')}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.year}'
                            : '',
                        style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500, letterSpacing: 1),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButtonKotak(
                    text: 'Simpan',
                    onPressed: () {},
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