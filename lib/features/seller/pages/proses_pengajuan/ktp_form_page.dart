import 'ktp_camera_page.dart';
import 'halal_page.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../app/gradient_background.dart';
import '../../../../common/widgets/custom_widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/penjual_info_service.dart';
import '../../services/seller_user_service.dart';
import 'package:dpr_bites/features/seller/models/user_info_model.dart';
import 'package:dpr_bites/features/seller/models/ktp_info_model.dart';
import 'package:flutter/services.dart';

class KtpFormPage extends StatefulWidget {
  const KtpFormPage({super.key});

  @override
  State<KtpFormPage> createState() => _KtpFormPageState();
}

class _KtpFormPageState extends State<KtpFormPage> {
  final _storage = FlutterSecureStorage();
  String? ktpImagePath;
  final nameController = TextEditingController();
  final nikController = TextEditingController();
  final noTeleponPenjualController = TextEditingController();
  String? gender;
  final birthPlaceController = TextEditingController();
  final birthDateController = TextEditingController();
  DateTime? birthDate;

  Future<void> _prefillKtpData() async {
    final idUsers = await _storage.read(key: 'id_users') ?? '';
    final data = await PenjualInfoService.fetchPenjualInfo(idUsers);
    if (data != null && data['success'] == true && data['data'] != null) {
      final ktpInfo = KtpInfoModel.fromJson(data['data']);
      nikController.text = ktpInfo.nik;
      noTeleponPenjualController.text = ktpInfo.noTeleponPenjual;
      gender = ktpInfo.gender.isNotEmpty ? ktpInfo.gender : null;
      birthPlaceController.text = ktpInfo.tempatLahir;
      birthDateController.text = PenjualInfoService.toFormDate(ktpInfo.tanggalLahir);
      if (ktpInfo.fotoKtpPath.isNotEmpty) {
        ktpImagePath = ktpInfo.fotoKtpPath;
      }
      setState(() {});
    }
  }

  Future<void> _prefillNamaLengkap() async {
    final idUsers = await _storage.read(key: 'id_users') ?? '';
    final user = await SellerUserService.fetchUserById(idUsers);
    if (user != null) {
      final userInfo = UserInfoModel.fromJson(user);
      nameController.text = userInfo.namaLengkap;
      // Jika nomor telepon penjual belum terisi, isi dari user info
      if ((noTeleponPenjualController.text.isEmpty || noTeleponPenjualController.text == '') && userInfo.noHp.isNotEmpty) {
        noTeleponPenjualController.text = userInfo.noHp;
      }
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _prefillNoTeleponPenjual();
    _prefillKtpData();
    _prefillNamaLengkap();
    _debugIdGerai();
  }

  Future<void> _debugIdGerai() async {
    final idGerai = await _storage.read(key: 'id_gerai') ?? '';
    print('[DEBUG] id_gerai pada initState ktp_form_page: $idGerai');
  }

  Future<void> _prefillNoTeleponPenjual() async {
    final teleponGerai = await _storage.read(key: 'telepon_gerai');
    if (teleponGerai != null && teleponGerai.isNotEmpty) {
      noTeleponPenjualController.text = teleponGerai;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    nikController.dispose();
    noTeleponPenjualController.dispose();
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
            try {
              final parts = ocr['tanggalLahir'].split('-');
              if (parts.length == 3) {
                birthDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                birthDateController.text = "${birthDate!.day.toString().padLeft(2, '0')}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.year}";
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
                            child: ktpImagePath!.startsWith('http')
                              ? Image.network(ktpImagePath!, fit: BoxFit.contain)
                              : Image.file(File(ktpImagePath!), fit: BoxFit.contain),
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
                    controller: noTeleponPenjualController,
                    hintText: 'No Telepon Penjual',
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
                  Text('MAKSIMAL 16 DIGIT', style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                  value: gender, 
                  items: const [
                    DropdownMenuItem(
                      value: 'laki-laki',
                      child: Text(
                        'LAKI-LAKI',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, letterSpacing: 1),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'perempuan',
                      child: Text(
                        'PEREMPUAN',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, letterSpacing: 1),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => gender = val),
                  decoration: InputDecoration(
                    labelText: 'JENIS KELAMIN',
                    labelStyle: const TextStyle(color: Colors.black, letterSpacing: 1),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFD53D3D), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFD53D3D), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFD53D3D), width: 2.0),
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
                        prefixIcon:
                            const Icon(Icons.calendar_today, color: Color(0xFFD53D3D)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        // >>> ini harus di level Scaffold, bukan di dalam GestureDetector
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: CustomButtonKotak(
                text: 'Simpan',
                onPressed: () async {
                  try {
                    // Simpan ke flutter_secure_storage
                    await _storage.write(key: 'no_telepon_penjual', value: noTeleponPenjualController.text);

                    // Kirim data ke backend
                    final idUsers = await _storage.read(key: 'id_users') ?? '';
                    final idGerai = await _storage.read(key: 'id_gerai') ?? '';
                    print('[DEBUG] id_gerai sebelum submit: $idGerai');
                    final Map<String, dynamic> data = {
                      'id_users': idUsers,
                      'id_gerai': idGerai,
                      'no_telepon_penjual': noTeleponPenjualController.text,
                      'nik': nikController.text,
                      'tempat_lahir': birthPlaceController.text,
                      'tanggal_lahir': PenjualInfoService.toDbDate(birthDateController.text),
                      'jenis_kelamin': gender ?? '',
                    };

                    if (ktpImagePath != null && ktpImagePath!.isNotEmpty) {
                      if (ktpImagePath!.startsWith('http')) {
                        data['foto_ktp_path'] = ktpImagePath;
                      } else {
                        data['foto_ktp_file'] = File(ktpImagePath!);
                      }
                    }

                    final success = await PenjualInfoService.addOrUpdatePenjualInfo(data);
                    if (success) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => HalalPage()),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal menyimpan data, coba lagi')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Terjadi error: $e')),
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
