
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/app/app_theme.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';

class KelolaProfilGeraiPage extends StatefulWidget {
  const KelolaProfilGeraiPage({Key? key}) : super(key: key);

  @override
  State<KelolaProfilGeraiPage> createState() => _KelolaProfilGeraiPageState();
}

class _KelolaProfilGeraiPageState extends State<KelolaProfilGeraiPage> {
  bool _isEdit = false;
  XFile? _bannerImage;
  XFile? _listingImage;
  String? _bannerUrl;
  String? _listingUrl;
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

  @override
  void dispose() {
    menuController.dispose();
    super.dispose();
  }

  Future<void> _pickBannerImage() async {
    if (!_isEdit) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _bannerImage = picked;
        _bannerUrl = picked.path;
      });
    }
  }

  Future<void> _pickListingImage() async {
    if (!_isEdit) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _listingImage = picked;
        _listingUrl = picked.path;
      });
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

  bool _validateFields() {
    if ((_bannerImage == null && (_bannerUrl == null || _bannerUrl!.isEmpty)) || (_listingImage == null && (_listingUrl == null || _listingUrl!.isEmpty))) return false;
    if (menuController.text.trim().isEmpty) return false;
    final selected = selectedDays.entries.where((e) => e.value).map((e) => e.key).toList();
    return selected.isNotEmpty;
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
            "Edit Profil Gerai",
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
                              : (_bannerUrl != null && _bannerUrl!.isNotEmpty)
                                  ? Image.file(File(_bannerUrl!), height: 100, fit: BoxFit.cover)
                                  : const Text("Belum ada banner"),
                          ElevatedButton(
                            onPressed: _isEdit ? _pickBannerImage : null,
                            child: const Text("Pilih Banner"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _listingImage != null
                              ? Image.file(File(_listingImage!.path), height: 100, fit: BoxFit.cover)
                              : (_listingUrl != null && _listingUrl!.isNotEmpty)
                                  ? Image.file(File(_listingUrl!), height: 100, fit: BoxFit.cover)
                                  : const Text("Belum ada listing"),
                          ElevatedButton(
                            onPressed: _isEdit ? _pickListingImage : null,
                            child: const Text("Pilih Listing"),
                          ),
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
                  enabled: _isEdit,
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
                      onSelected: _isEdit ? (val) => setState(() => selectedDays[day] = val) : null,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Buka: ${selectedTimeStart.format(context)}'),
                    ElevatedButton(
                      onPressed: _isEdit ? () => _selectTimeStart(context) : null,
                      child: const Text('Pilih Jam'),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tutup: ${selectedTimeEnd.format(context)}'),
                    ElevatedButton(
                      onPressed: _isEdit ? () => _selectTimeEnd(context) : null,
                      child: const Text('Pilih Jam'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: CustomButtonKotak(
            text: _isEdit ? "Simpan Perubahan" : "Edit Profil",
            onPressed: () async {
              if (!_isEdit) {
                setState(() {
                  _isEdit = true;
                });
                return;
              }
              if (!_validateFields()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Semua field wajib diisi')),
                );
                return;
              }
              setState(() {
                _isEdit = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profil gerai berhasil disimpan (dummy, belum ke database)')),
              );
            },
          ),
        ),
      ),
    );
  }
  }