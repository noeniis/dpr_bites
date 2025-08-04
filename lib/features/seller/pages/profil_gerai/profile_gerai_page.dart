import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/app_theme.dart';
import '../../../../app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';

class ProfilGeraiPage extends StatefulWidget {
  const ProfilGeraiPage({super.key});

  @override
  State<ProfilGeraiPage> createState() => _ProfilGeraiPageState();
}

class _ProfilGeraiPageState extends State<ProfilGeraiPage> {
  final String cloudName = 'dip8i3f6x';
  final String uploadPreset = 'dpr_bites';

  XFile? _bannerImage;
  XFile? _listingImage;

  final menuController = TextEditingController();
  TimeOfDay selectedTimeStart = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay selectedTimeEnd = const TimeOfDay(hour: 16, minute: 0);

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

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? '';
  }

  bool _validateFields() {
    if (_bannerImage == null || _listingImage == null) return false;
    if (menuController.text.trim().isEmpty) return false;
    final selected = selectedDays.entries.where((e) => e.value).map((e) => e.key).toList();
    return selected.isNotEmpty;
  }

  Future<void> _pickBannerImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _bannerImage = image);
    }
  }

  Future<void> _pickListingImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _listingImage = image);
    }
  }

  Future<void> _selectTimeStart(BuildContext context) async {
    final picked = await showTimePicker(context: context, initialTime: selectedTimeStart);
    if (picked != null) setState(() => selectedTimeStart = picked);
  }

  Future<void> _selectTimeEnd(BuildContext context) async {
    final picked = await showTimePicker(context: context, initialTime: selectedTimeEnd);
    if (picked != null) setState(() => selectedTimeEnd = picked);
  }

  Future<String?> _uploadToCloudinary(XFile? image, String publicId) async {
    if (image == null) return null;
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['public_id'] = publicId
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final result = json.decode(resStr);
      return result['secure_url'];
    } else {
      return null;
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
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Gambar banner & gambar listing", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _bannerImage != null
                              ? Image.file(File(_bannerImage!.path), height: 100, fit: BoxFit.cover)
                              : const Text("Belum ada banner"),
                          ElevatedButton(onPressed: _pickBannerImage, child: const Text("Pilih Banner")),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _listingImage != null
                              ? Image.file(File(_listingImage!.path), height: 100, fit: BoxFit.cover)
                              : const Text("Belum ada listing"),
                          ElevatedButton(onPressed: _pickListingImage, child: const Text("Pilih Listing")),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text("Kategori/Jenis masakan", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: menuController,
                  decoration: const InputDecoration(
                    hintText: "Contoh: Nasi, Kopi",
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Hari operasional", style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: operationalDays.map((day) {
                    return FilterChip(
                      label: Text(day),
                      selected: selectedDays[day]!,
                      onSelected: (val) => setState(() => selectedDays[day] = val),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Buka: ${selectedTimeStart.format(context)}'),
                    ElevatedButton(onPressed: () => _selectTimeStart(context), child: const Text('Pilih Jam')),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tutup: ${selectedTimeEnd.format(context)}'),
                    ElevatedButton(onPressed: () => _selectTimeEnd(context), child: const Text('Pilih Jam')),
                  ],
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: CustomButtonKotak(
            text: "Kirim",
            onPressed: () async {
              if (!_validateFields()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Semua field wajib diisi')),
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
                final bannerUrl = await _uploadToCloudinary(_bannerImage, 'stores_detail/$userId/banner');
                final listingUrl = await _uploadToCloudinary(_listingImage, 'stores_detail/$userId/listing');

                if (bannerUrl == null || listingUrl == null) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal upload gambar ke Cloudinary')),
                  );
                  return;
                }

                final selected = selectedDays.entries.where((e) => e.value).map((e) => e.key).toList();
                final data = {
                  'userId': userId,
                  'bannerUrl': bannerUrl,
                  'listingUrl': listingUrl,
                  'menu': menuController.text.trim(),
                  'operationalDays': selected,
                  'openTime': selectedTimeStart.format(context),
                  'closeTime': selectedTimeEnd.format(context),
                  'onboardingStep1': true,
                  'createdAt': FieldValue.serverTimestamp(),
                };

                await FirebaseFirestore.instance.collection('stores_detail').add(data);

                final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
                final doc = await userDoc.get();
                List<bool> steps = List<bool>.from(doc.data()?['onboardingSteps'] ?? [false, false, false]);
                steps[1] = true;
                await userDoc.update({
                  'onboardingSteps': steps,
                  'onboardingCompleted': steps.every((e) => e),
                });

                if (mounted) {
                  Navigator.of(context).pop();
                  Navigator.pushNamedAndRemoveUntil(context, '/onboarding_checklist', (r) => false);
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
    );
  }
}
