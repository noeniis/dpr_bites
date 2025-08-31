import 'package:flutter/material.dart';
import '../../../../app/app_theme.dart';
import '../../../../app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ProfilGeraiPage extends StatefulWidget {
  const ProfilGeraiPage({super.key});

  @override
  State<ProfilGeraiPage> createState() => _ProfilGeraiPageState();
}

class _ProfilGeraiPageState extends State<ProfilGeraiPage> {
  // Fungsi untuk mendapatkan base URL
  String getBaseUrl() {
    return 'http://10.255.40.182:80/dpr_bites_api'; // Ganti dengan base URL yang sesuai
  }

  // Fungsi untuk mengirim data profil ke gerai_profil.php
  Future<bool> saveProfilGerai(Map<String, dynamic> data) async {
    try {
      // Jika gambar ada, encode menjadi base64
      if (_bannerImage != null) {
        final bannerBytes = await _bannerImage!.readAsBytes();
        data['banner'] = base64Encode(
          bannerBytes,
        ); // Mengirim gambar banner dalam format base64
      }
      if (_listingImage != null) {
        final listingBytes = await _listingImage!.readAsBytes();
        data['listing'] = base64Encode(
          listingBytes,
        ); // Mengirim gambar listing dalam format base64
      }

      final response = await http.post(
        Uri.parse(
          '${getBaseUrl()}/gerai_profil.php',
        ), // Ganti dengan base URL yang sesuai
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data), // Kirim data dalam format JSON
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result is Map && result.containsKey('success')) {
          return result['success']; // Mengembalikan status sukses
        } else {
          debugPrint(
            'Response JSON tidak mengandung kunci success: ${response.body}',
          );
          return false;
        }
      } else {
        debugPrint('HTTP error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception saat save profil gerai: ${e.toString()}');
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    timeStartController ??= TextEditingController(
      text: selectedTimeStart.format(context),
    );
    timeEndController ??= TextEditingController(
      text: selectedTimeEnd.format(context),
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
    );
    if (picked != null && picked != selectedTimeStart) {
      setState(() {
        selectedTimeStart = picked;
      });
    }
  }

  // Method untuk memilih jam tutup
  Future<void> _selectTimeEnd(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTimeEnd,
    );
    if (picked != null && picked != selectedTimeEnd) {
      setState(() {
        selectedTimeEnd = picked;
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
                final data = {
                  "menu_masakan": menuController.text,
                  "jam_buka": timeStartController?.text,
                  "jam_tutup": timeEndController?.text,
                  "hari_buka": selectedDays
                      .asMap()
                      .entries
                      .where((entry) => entry.value)
                      .map((entry) => days[entry.key])
                      .toList(),
                };

                final success = await saveProfilGerai(data);

                if (success) {
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
