import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/app/app_theme.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import '../../services/gerai_profil_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KelolaProfilGeraiPage extends StatefulWidget {
  const KelolaProfilGeraiPage({Key? key}) : super(key: key);

  @override
  State<KelolaProfilGeraiPage> createState() => _KelolaProfilGeraiPageState();
}

class _KelolaProfilGeraiPageState extends State<KelolaProfilGeraiPage> {
  Future<String?> uploadToCloudinary(File file) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/dip8i3f6x/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'dpr_bites'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = jsonDecode(respStr);
      return data['secure_url'];
    }
    return null;
  }
  bool _isLoading = true;
  String? _errorMsg;
  int? _idGeraiProfil;
  int? _idGerai;
  @override
  void initState() {
    super.initState();
    _loadProfilGerai();
  }

  Future<void> _loadProfilGerai() async {
    try {
      setState(() { _isLoading = true; _errorMsg = null; });
      final prefs = await SharedPreferences.getInstance();
      final idUsersStr = prefs.getString('id_users');
      final idUsers = idUsersStr != null ? int.tryParse(idUsersStr) : null;
      if (idUsers == null) {
        setState(() { _isLoading = false; _errorMsg = 'User belum login'; });
        return;
      }
      final service = GeraiProfilService();
      final data = await service.fetchGeraiProfil(idUsers);
      if (data == null) {
        setState(() { _isLoading = false; _errorMsg = 'Profil gerai tidak ditemukan'; });
        return;
      }
      setState(() {
        _idGerai = data['id_gerai'] is int ? data['id_gerai'] : int.tryParse(data['id_gerai'].toString());
        _bannerUrl = data['banner_path'];
        _listingUrl = data['listing_path'];
        menuController.text = data['deskripsi_gerai'] ?? '';
        // hari_buka: bisa berupa string, misal "Senin,Selasa"
        final hariBuka = (data['hari_buka'] ?? '').split(',');
        for (var day in selectedDays.keys) {
          selectedDays[day] = hariBuka.contains(day);
        }
        // jam_buka dan jam_tutup: "15:30:26" → ambil jam dan menit saja
        final jamBuka = (data['jam_buka'] ?? '08:00').split(':');
        final jamTutup = (data['jam_tutup'] ?? '16:00').split(':');
        selectedTimeStart = TimeOfDay(hour: int.parse(jamBuka[0]), minute: int.parse(jamBuka[1]));
        selectedTimeEnd = TimeOfDay(hour: int.parse(jamTutup[0]), minute: int.parse(jamTutup[1]));
        _isLoading = false;
      });
    } catch (e, s) {
      print('ERROR in _loadProfilGerai: $e\n$s');
      setState(() {
        _isLoading = false;
        _errorMsg = 'Terjadi error: $e';
      });
    }
  }
    String formatTime24(TimeOfDay time) {
    final hour = time.hour == 0 ? 24 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
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
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTimeStart,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => selectedTimeStart = picked);
  }

  Future<void> _selectTimeEnd(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTimeEnd,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
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
  print('DEBUG: build KelolaProfilGeraiPage dipanggil');
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMsg != null
                  ? Center(child: Text(_errorMsg!, style: const TextStyle(color: Colors.red)))
                  : SingleChildScrollView(
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
                    ? (_bannerUrl!.startsWith('http')
                      ? Image.network(_bannerUrl!, height: 100, fit: BoxFit.cover)
                      : Image.file(File(_bannerUrl!), height: 100, fit: BoxFit.cover))
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
                    ? (_listingUrl!.startsWith('http')
                      ? Image.network(_listingUrl!, height: 100, fit: BoxFit.cover)
                      : Image.file(File(_listingUrl!), height: 100, fit: BoxFit.cover))
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
                          Text('Buka: ${formatTime24(selectedTimeStart)}'),
                          ElevatedButton(
                            onPressed: _isEdit ? () => _selectTimeStart(context) : null,
                            child: const Text('Pilih Jam'),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tutup: ${formatTime24(selectedTimeEnd)}'),
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
              setState(() { _isLoading = true; });
              String? bannerUrl = _bannerUrl;
              String? listingUrl = _listingUrl;
              // Upload gambar jika ada perubahan (file lokal)
              if (_bannerImage != null) {
                final url = await uploadToCloudinary(File(_bannerImage!.path));
                if (url != null) bannerUrl = url;
              }
              if (_listingImage != null) {
                final url = await uploadToCloudinary(File(_listingImage!.path));
                if (url != null) listingUrl = url;
              }
              // Siapkan data update
              final hariSelected = selectedDays.entries.where((e) => e.value).map((e) => e.key).join(',');
              final jamBuka = selectedTimeStart.format(context);
              final jamTutup = selectedTimeEnd.format(context);
              // id_gerai didapat dari _idGerai (sudah diisi saat load profil)
              final idGerai = _idGerai;
              if (idGerai == null) {
                setState(() { _isLoading = false; });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ID gerai tidak ditemukan')),);
                return;
              }
              final service = GeraiProfilService();
              final success = await service.updateGeraiProfil(
                idGerai: idGerai,
                bannerPath: bannerUrl ?? '',
                listingPath: listingUrl ?? '',
                deskripsiGerai: menuController.text.trim(),
                hariBuka: hariSelected,
                jamBuka: jamBuka,
                jamTutup: jamTutup,
              );
              setState(() {
                _isEdit = false;
                _isLoading = false;
                if (success) {
                  _bannerUrl = bannerUrl;
                  _listingUrl = listingUrl;
                  _bannerImage = null;
                  _listingImage = null;
                }
              });
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(success ? 'Berhasil' : 'Gagal'),
                  content: Text(success ? 'Profil gerai berhasil diupdate' : 'Gagal update profil gerai'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  }