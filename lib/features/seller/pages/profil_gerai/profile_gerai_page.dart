import 'package:flutter/material.dart';
import '../../../../app/app_theme.dart';
import '../../../../app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilGeraiPage extends StatefulWidget {
  const ProfilGeraiPage({super.key});

  @override
  State<ProfilGeraiPage> createState() => _ProfilGeraiPageState();
}

class _ProfilGeraiPageState extends State<ProfilGeraiPage> {
  // Helper untuk salin gambar ke local storage dan return path lokal
  Future<String?> _saveImageLocally(XFile? image, String filename) async {
    if (image == null) return null;
    final file = File(image.path);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File gambar tidak ditemukan di perangkat')),
      );
      return null;
    }
    final userId = await _getUserId();
    final appDir = await getApplicationDocumentsDirectory();
    final dirPath = '${appDir.path}/stores_details/$userId';
    await Directory(dirPath).create(recursive: true);
    final localPath = '$dirPath/$filename';
    await file.copy(localPath);
    return localPath;
  }

  // Helper untuk ambil userId dari SharedPreferences
  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? '';
  }

  // Validasi field
  bool _validateFields() {
    if (_bannerImage == null || _listingImage == null) return false;
    if (menuController.text.trim().isEmpty) return false;
    final selected = selectedDays.entries.where((e) => e.value).map((e) => e.key).toList();
    if (selected.isEmpty) return false;
    return true;
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
  TimeOfDay selectedTimeEnd = TimeOfDay(hour: 16, minute: 0);

  // Hari operasional
  final List<String> operationalDays = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
  ];
  final Map<String, bool> selectedDays = {
    'Senin': false,
    'Selasa': false,
    'Rabu': false,
    'Kamis': false,
    'Jumat': false,
    'Sabtu': false,
    'Minggu': false,
  };

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
              fontSize: 20,
              fontFamily: 'Afacad',
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          centerTitle: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ...existing code...

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
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _pickBannerImage,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Center(
                                child: Text("Pilih Gambar Banner"),
                              ),
                            ),
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
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _pickListingImage,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Center(
                                child: Text("Pilih Gambar Listing"),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Kategori/Jenis masakan
                const Text(
                  "Kategori/Jenis masakan",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: menuController,
                  decoration: InputDecoration(
                    hintText: "Cth: Ayam, Nasi, Kopi, dll",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
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
                // Checklist hari operasional
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: operationalDays.map((day) {
                    return FilterChip(
                      label: Text(day,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textColor,
                        ),
                      ),
                      selected: selectedDays[day]!,
                      backgroundColor: Colors.white,
                      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      checkmarkColor: AppTheme.primaryColor,
                      onSelected: (bool value) {
                        setState(() {
                          selectedDays[day] = value;
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: selectedDays[day]!
                              ? AppTheme.primaryColor
                              : Colors.grey[300]!,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Buka: ${selectedTimeStart.format(context)}',
                      style: const TextStyle(fontSize: 15, fontFamily: 'Inter'),
                    ),
                    ElevatedButton(
                      onPressed: () => _selectTimeStart(context),
                      child: const Text('Pilih Jam'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tutup: ${selectedTimeEnd.format(context)}',
                      style: const TextStyle(fontSize: 15, fontFamily: 'Inter'),
                    ),
                    ElevatedButton(
                      onPressed: () => _selectTimeEnd(context),
                      child: const Text('Pilih Jam'),
                    ),
                  ],
                ),

                SizedBox(height: 30),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: SizedBox(
            width: double.infinity,
            child: CustomButtonKotak(
              text: "Kirim",
              onPressed: () async {
                // Validasi
                if (!_validateFields()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Semua field wajib diisi!')),
                  );
                  return;
                }
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );
                try {
                  final userId = await _getUserId();
                  // Salin gambar ke local storage
                  final bannerPath = await _saveImageLocally(_bannerImage, 'banner.jpg');
                  final listingPath = await _saveImageLocally(_listingImage, 'listing.jpg');
                  // Siapkan data
                  final selected = selectedDays.entries.where((e) => e.value).map((e) => e.key).toList();
                  final data = {
                    'userId': userId,
                    'bannerImagePath': bannerPath,
                    'listingImagePath': listingPath,
                    'menu': menuController.text.trim(),
                    'operationalDays': selected,
                    'openTime': selectedTimeStart.format(context),
                    'closeTime': selectedTimeEnd.format(context),
                    'onboardingStep1': true,
                    'createdAt': FieldValue.serverTimestamp(),
                  };
                  await FirebaseFirestore.instance.collection('stores_detail').add(data);
                  // Update onboardingSteps di users
                  final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
                  final doc = await userDoc.get();
                  List<bool> steps = List<bool>.from(doc.data()?['onboardingSteps'] ?? [false, false, false]);
                  steps[1] = true;
                  bool completed = steps.every((e) => e);
                  await userDoc.update({
                    'onboardingSteps': steps,
                    'onboardingCompleted': completed,
                  });
                  if (mounted) {
                    Navigator.of(context).pop(); // tutup dialog
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/onboarding_checklist',
                      (route) => false,
                    );
                  }
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menyimpan data: $e')),
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
