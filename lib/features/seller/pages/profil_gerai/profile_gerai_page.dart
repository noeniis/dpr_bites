import 'dart:convert';
import 'dart:io';

import 'package:dpr_bites/app/app_theme.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/common/data/onboarding_checklist_storage.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:dpr_bites/features/seller/pages/pick_map_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

/// ---- API dummy simpan data gerai
Future<void> saveStoreData(
  String storeName,
  String address,
  LatLng location,
) async {
  const url = 'https://example.com/api/saveStore'; // ganti saat ada API

  final data = {
    'store_name': storeName,
    'address': address,
    'latitude': location.latitude,
    'longitude': location.longitude,
  };

  final response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: json.encode(data),
  );

  if (response.statusCode == 200) {
    debugPrint('Data berhasil disimpan');
  } else {
    debugPrint('Gagal menyimpan data: ${response.statusCode}');
  }
}

class ProfilGeraiPage extends StatefulWidget {
  const ProfilGeraiPage({super.key});

  @override
  State<ProfilGeraiPage> createState() => _ProfilGeraiPageState();
}

class _ProfilGeraiPageState extends State<ProfilGeraiPage> {
  // Gambar
  XFile? _bannerImage;
  XFile? _listingImage;

  // Lokasi
  LatLng? selectedLocation;

  // Controllers
  final menuController = TextEditingController();
  final qrisController = TextEditingController();

  // Jam operasional
  TimeOfDay selectedTimeStart = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay selectedTimeEnd = const TimeOfDay(hour: 17, minute: 0);

  // Picker
  Future<void> _pickBannerImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _bannerImage = img);
  }

  Future<void> _pickListingImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _listingImage = img);
  }

  // Time pickers
  Future<void> _selectTimeStart(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTimeStart,
    );
    if (picked != null && picked != selectedTimeStart) {
      setState(() => selectedTimeStart = picked);
    }
  }

  Future<void> _selectTimeEnd(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTimeEnd,
    );
    if (picked != null && picked != selectedTimeEnd) {
      setState(() => selectedTimeEnd = picked);
    }
  }

  Widget _imagePreview(XFile? file, {double height = 100}) {
    if (file == null) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text("Belum ada gambar")),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: kIsWeb
          ? Image.network(file.path, height: height, fit: BoxFit.cover)
          : Image.file(File(file.path), height: height, fit: BoxFit.cover),
    );
  }

  @override
  void dispose() {
    menuController.dispose();
    qrisController.dispose();
    super.dispose();
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Profil Gerai",
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 20),

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
                          _imagePreview(_bannerImage),
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
                          _imagePreview(_listingImage),
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
                TextField(
                  controller: menuController,
                  decoration: InputDecoration(
                    hintText: "Masukkan menu masakan",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

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

                const SizedBox(height: 30),

                const Text(
                  "Lokasi Gerai",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () async {
                    final location = await Navigator.push<LatLng?>(
                      context,
                      MaterialPageRoute(builder: (_) => const PickMapPage()),
                    );
                    if (location != null) {
                      setState(() => selectedLocation = location);
                    }
                  },
                  child: const Text('Pilih Lokasi di Peta'),
                ),

                if (selectedLocation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Lokasi: Lat: ${selectedLocation!.latitude}, Lng: ${selectedLocation!.longitude}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: 'Afacad',
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Tombol tetap di bawah, aman di semua ukuran layar
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: SizedBox(
              width: double.infinity,
              child: CustomButtonKotak(
                text: "Simpan dan lanjutkan",
                onPressed: () async {
                  if (selectedLocation == null) {
                    debugPrint('Lokasi belum dipilih!');
                    return;
                  }
                  final storeName = menuController.text;
                  final address = 'Jl. X No. Y'; // ganti sesuai input

                  await saveStoreData(storeName, address, selectedLocation!);
                  await OnboardingChecklistStorage.setStatus(1, true);

                  if (!context.mounted) {
                    return;
                  }
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/onboarding_checklist',
                    (route) => false,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
