import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../app/gradient_background.dart';
import '../../../../../app/app_theme.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';

class KelolaProfilGeraiPage extends StatefulWidget {
  const KelolaProfilGeraiPage({Key? key}) : super(key: key);

  @override
  State<KelolaProfilGeraiPage> createState() => _KelolaProfilGeraiPageState();
}

class _KelolaProfilGeraiPageState extends State<KelolaProfilGeraiPage> {
  bool _isEdit = false;
  final String cloudName = 'dip8i3f6x';
  final String uploadPreset = 'dpr_bites';

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

  bool _loading = true;

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? '';
  }

  

  Future<void> _fetchProfile() async {
    final userId = await _getUserId();
    final query = await FirebaseFirestore.instance.collection('stores_detail').where('userId', isEqualTo: userId).get();
    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();
      setState(() {
        _bannerUrl = data['bannerUrl'];
        _listingUrl = data['listingUrl'];
        menuController.text = data['menu'] ?? '';
        List days = data['operationalDays'] ?? [];
        for (var day in operationalDays) {
          selectedDays[day] = days.contains(day);
        }
        selectedTimeStart = _parseTime(data['openTime']) ?? selectedTimeStart;
        selectedTimeEnd = _parseTime(data['closeTime']) ?? selectedTimeEnd;
      });
    }
    setState(() {
      _loading = false;
    });
  }

  TimeOfDay? _parseTime(dynamic timeStr) {
    if (timeStr is String && timeStr.contains(':')) {
      final parts = timeStr.split(':');
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    return null;
  }

  Future<void> _pickBannerImage() async {
    if (!_isEdit) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      // Upload ke Cloudinary - exactly like edit_menu.dart
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/dip8i3f6x/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = 'dpr_bites'
        ..files.add(await http.MultipartFile.fromPath('file', picked.path));
      final response = await request.send();
      Navigator.of(context).pop();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);
        if (mounted) {
          setState(() {
            _bannerImage = picked;
            _bannerUrl = data['secure_url'] ?? '';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Banner berhasil diupload')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal upload gambar banner')),
          );
        }
      }
    }
  }

  Future<void> _pickListingImage() async {
    if (!_isEdit) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      // Upload ke Cloudinary - exactly like edit_menu.dart
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/dip8i3f6x/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = 'dpr_bites'
        ..files.add(await http.MultipartFile.fromPath('file', picked.path));
      final response = await request.send();
      Navigator.of(context).pop();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);
        if (mounted) {
          setState(() {
            _listingImage = picked;
            _listingUrl = data['secure_url'] ?? '';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Listing image berhasil diupload')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal upload gambar listing')),
          );
        }
      }
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

  Future<void> _saveProfile() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final userId = await _getUserId();
      final selected = selectedDays.entries.where((e) => e.value).map((e) => e.key).toList();
      
      // Pastikan URL gambar sudah ada sebelum save
      if (_bannerUrl == null || _bannerUrl!.isEmpty) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner image belum diupload')),
        );
        return;
      }
      
      if (_listingUrl == null || _listingUrl!.isEmpty) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing image belum diupload')),
        );
        return;
      }
      
      final data = {
        'userId': userId,
        'bannerUrl': _bannerUrl,
        'listingUrl': _listingUrl,
        'menu': menuController.text.trim(),
        'operationalDays': selected,
        'openTime': selectedTimeStart.format(context),
        'closeTime': selectedTimeEnd.format(context),
        'onboardingStep1': true,
        'editedAt': FieldValue.serverTimestamp(),
      };
      
      final query = await FirebaseFirestore.instance.collection('stores_detail').where('userId', isEqualTo: userId).get();
      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update(data);
      } else {
        await FirebaseFirestore.instance.collection('stores_detail').add(data);
      }
      
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil gerai berhasil diupdate')),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update profil: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchProfile();
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
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
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
                                        ? Image.network(_bannerUrl!, height: 100, fit: BoxFit.cover)
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
                                        ? Image.network(_listingUrl!, height: 100, fit: BoxFit.cover)
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
              await _saveProfile();
              setState(() {
                _isEdit = false;
                
              });
            },
          ),
        ),
      ),
    );
  }
}

class CustomSaldoCard extends StatelessWidget {
  final double saldo;
  final VoidCallback onTarik;
  const CustomSaldoCard({required this.saldo, required this.onTarik, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Image.asset(
            'assets/images/saldo_icon.png',
            width: 40,
            height: 40,
            errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet, size: 40, color: Colors.green),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Saldo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Rp ${saldo.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 6,
              shadowColor: Colors.black26,
            ),
            onPressed: saldo > 0 ? onTarik : null,
            child: const Text(
              'Tarik saldo',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomRekeningInfo extends StatelessWidget {
  final String nama, bank, norek, nmId;
  const CustomRekeningInfo({required this.nama, required this.bank, required this.norek, required this.nmId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(nama, style: const TextStyle(fontSize: 16, color: Colors.black)),
        const SizedBox(height: 8),
        Text(bank, style: const TextStyle(fontSize: 16, color: Colors.black)),
        const SizedBox(height: 8),
        Text(norek, style: const TextStyle(fontSize: 16, color: Colors.black)),
        const SizedBox(height: 8),
        Text(nmId, style: const TextStyle(fontSize: 16, color: Colors.black)),
      ],
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  const CustomBottomNavBar({required this.selectedIndex, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8E6E6),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
    );
  }
}
