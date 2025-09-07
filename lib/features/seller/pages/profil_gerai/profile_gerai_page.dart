import 'package:flutter/material.dart';
import '../../../../app/app_theme.dart';
import '../../../../app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:dpr_bites/features/seller/services/menu_service.dart';

class ProfilGeraiPage extends StatefulWidget {
  const ProfilGeraiPage({super.key});

  @override
  State<ProfilGeraiPage> createState() => _ProfilGeraiPageState();
}

class _ProfilGeraiPageState extends State<ProfilGeraiPage> {
  Future<void> updateStep2User() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idUsers = prefs.getString('id_users');
      if (idUsers == null) return;
      await http.post(
        Uri.parse('${getBaseUrl()}/update_step2.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_users': idUsers, 'step2': 1}),
      );
    } catch (e) {
      debugPrint('Gagal update step2: $e');
    }
  }

  // Fungsi untuk mendapatkan base URL
  String getBaseUrl() {
    return 'http://10.144.183.182:80/dpr_bites_api'; // Ganti dengan base URL yang sesuai
  }

  // Fungsi untuk mengirim data profil ke gerai_profil.php
  Future<bool> saveProfilGerai(Map<String, dynamic> data) async {
    debugPrint('Data yang dikirim ke backend: ' + data.toString());
    try {
      // Upload gambar ke Cloudinary jika ada, lalu kirim URL-nya
      if (_bannerImage != null) {
        final url = await MenuService.uploadImageToCloudinary(
          File(_bannerImage!.path),
        );
        if (url != null) {
          data['banner_path'] = url;
        }
      }
      if (_listingImage != null) {
        final url = await MenuService.uploadImageToCloudinary(
          File(_listingImage!.path),
        );
        if (url != null) {
          data['listing_path'] = url;
        }
      }

      final response = await http.post(
        Uri.parse('${getBaseUrl()}/gerai_profil.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result is Map && result['status'] == 'success') {
          return true;
        } else {
          debugPrint(
            'Response JSON tidak mengandung kunci success: \\${response.body}',
          );
          return false;
        }
      } else {
        debugPrint('HTTP error: \\${response.statusCode} - \\${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception saat save profil gerai: \\${e.toString()}');
      return false;
    }
  }

  // Hari buka (Senin-Minggu)
  final List<String> days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  List<bool> selectedDays = List.generate(7, (_) => false);

  TextEditingController? timeStartController;
  TextEditingController? timeEndController;

  String _format24(TimeOfDay t) =>
      t.hour.toString().padLeft(2, '0') +
      ':' +
      t.minute.toString().padLeft(2, '0');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    timeStartController ??= TextEditingController(
      text: _format24(selectedTimeStart),
    );
    timeEndController ??= TextEditingController(
      text: _format24(selectedTimeEnd),
    );
  }

  @override
  void dispose() {
    timeStartController?.dispose();
    timeEndController?.dispose();
    super.dispose();
  }

  // State untuk gambar banner dan listing
  XFile? _bannerImage;
  XFile? _listingImage;

  Future<void> _pickBannerImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _bannerImage = image;
      });
    }
  }

  Future<void> _pickListingImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _listingImage = image;
      });
    }
  }

  // Controller untuk inputan
  final bannerController = TextEditingController();
  final listingController = TextEditingController();
  final menuController = TextEditingController();
  final qrisController = TextEditingController();

  // Controller untuk jam operasional
  TimeOfDay selectedTimeStart = TimeOfDay(hour: 8, minute: 0);
  TimeOfDay selectedTimeEnd = TimeOfDay(hour: 17, minute: 0);

  // Method untuk memilih jam buka
  Future<void> _selectTimeStart(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTimeStart,
      builder: (ctx, child) {
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedTimeStart) {
      setState(() {
        selectedTimeStart = picked;
        timeStartController?.text = _format24(picked);
      });
    }
  }

  // Method untuk memilih jam tutup
  Future<void> _selectTimeEnd(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTimeEnd,
      builder: (ctx, child) {
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedTimeEnd) {
      setState(() {
        selectedTimeEnd = picked;
        timeEndController?.text = _format24(picked);
      });
    }
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
          title: const Text(
            "Profil Gerai",
            style: TextStyle(
              color: AppTheme.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              fontFamily: 'Afacad',
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gambar banner & listing
                  const Text(
                    "Gambar banner & gambar listing",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Afacad',
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _bannerImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(_bannerImage!.path),
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Text("Belum ada gambar banner"),
                                    ),
                                  ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _pickBannerImage,
                              child: const Text("Pilih Gambar Banner"),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _listingImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(_listingImage!.path),
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Text("Belum ada gambar listing"),
                                    ),
                                  ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _pickListingImage,
                              child: const Text("Pilih Gambar Listing"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Menu masakan
                  const Text(
                    "Menu masakan",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Afacad',
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  CustomInputField(
                    controller: menuController,
                    hintText: "Cth. Ayam, Nasi, Kopi",
                  ),
                  const SizedBox(height: 20),

                  // Hari buka
                  const Text(
                    "Hari buka",
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: List.generate(days.length, (i) {
                      return FilterChip(
                        label: Text(days[i]),
                        selected: selectedDays[i],
                        onSelected: (val) {
                          setState(() {
                            selectedDays[i] = val;
                          });
                        },
                        selectedColor: const Color(0xFFD53D3D),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: selectedDays[i] ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Jam operasional
                  const Text(
                    "Jam operasional",
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            await _selectTimeStart(context);
                            if (timeStartController != null) {
                              timeStartController!.text = selectedTimeStart
                                  .format(context);
                            }
                          },
                          child: AbsorbPointer(
                            child: CustomInputField(
                              controller: timeStartController,
                              hintText: 'Jam Buka',
                              prefixIcon: const Icon(
                                Icons.access_time,
                                color: Color(0xFFD53D3D),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            await _selectTimeEnd(context);
                            if (timeEndController != null) {
                              timeEndController!.text = selectedTimeEnd.format(
                                context,
                              );
                            }
                          },
                          child: AbsorbPointer(
                            child: CustomInputField(
                              controller: timeEndController,
                              hintText: 'Jam Tutup',
                              prefixIcon: const Icon(
                                Icons.access_time,
                                color: Color(0xFFD53D3D),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: SizedBox(
            width: double.infinity,
            child: CustomButtonKotak(
              text: "Simpan dan lanjutkan",
              onPressed: () async {
                // Validasi gambar banner
                if (_bannerImage == null) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("Gambar Banner Wajib"),
                      content: Text(
                        "Silakan pilih gambar banner terlebih dahulu.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("OK"),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                // Validasi hari buka
                final hariBukaList = selectedDays
                    .asMap()
                    .entries
                    .where((entry) => entry.value)
                    .map((entry) => days[entry.key])
                    .toList();
                if (hariBukaList.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("Hari Buka Wajib"),
                      content: Text("Silakan pilih minimal satu hari buka."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("OK"),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                final idGerai = await MenuService.getIdGerai();
                if (idGerai == null) {
                  if (!mounted) return;
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("Gagal Mendapatkan ID Gerai"),
                      content: Text(
                        "Pastikan Anda sudah login dan memiliki gerai.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("OK"),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                final prefs = await SharedPreferences.getInstance();
                final idUsers = prefs.getString('id_users');
                final data = {
                  "id_gerai": idGerai.toString(),
                  "id_users": idUsers,
                  "deskripsi_gerai": menuController
                      .text, // Atau tambahkan field deskripsi khusus
                  "jam_buka": timeStartController?.text,
                  "jam_tutup": timeEndController?.text,
                  "hari_buka": hariBukaList,
                };

                final success = await saveProfilGerai(data);
                if (success) {
                  await updateStep2User();
                  if (!mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/onboarding_checklist',
                    (route) => false,
                  );
                } else {
                  if (!mounted) return;
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("Gagal Menyimpan Profil"),
                      content: Text("Coba lagi nanti."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("OK"),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
