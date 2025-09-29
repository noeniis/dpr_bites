import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/app/app_theme.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import '../../services/gerai_profil_service.dart';
import 'dart:convert';
import '../../services/seller_user_service.dart';
import 'package:http/http.dart' as http;
import 'package:dpr_bites/common/utils/base_url.dart';

class ProfileGeraiPage extends StatefulWidget {
  const ProfileGeraiPage({Key? key}) : super(key: key);

  @override
  State<ProfileGeraiPage> createState() => _ProfileGeraiPageState();
}

class _ProfileGeraiPageState extends State<ProfileGeraiPage> {
  bool _isLoading = true;
  String? _errorMsg;
  int? _idGerai;
  bool _isProfilExist = false;
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
  void initState() {
    super.initState();
    _loadProfilGerai();
  }

  // Helper: ambil status_pengajuan gerai saat ini dari API (via token-authenticated endpoint)
  Future<String?> _fetchCurrentGeraiStatus() async {
    try {
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) return null;
      final res = await http.post(
        Uri.parse('${getBaseUrl()}/get_gerai_by_user.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      if (body['success'] == true && body['data'] != null) {
        return body['data']['status_pengajuan']?.toString();
      }
      return null;
    } catch (e) {
      debugPrint('ERROR fetchCurrentGeraiStatus: $e');
      return null;
    }
  }

  Future<void> _loadProfilGerai() async {
    setState(() { _isLoading = true; _errorMsg = null; });
    final storage = FlutterSecureStorage();
    String? idUsers = await storage.read(key: 'id_users');
    if (idUsers == null || idUsers.isEmpty) {
      setState(() { _isLoading = false; _errorMsg = 'User belum login'; });
      return;
    }
    final response = await GeraiProfilService.fetchGeraiProfilByUser(idUsers);
    if (response == null) {
      setState(() { _isLoading = false; _errorMsg = 'ID Gerai tidak ditemukan'; });
      _idGerai = null;
      return;
    }
    _idGerai = response.idGerai;
    // Cek apakah data profil sudah ada
    _isProfilExist = response.deskripsiGerai.isNotEmpty || response.bannerPath.isNotEmpty;
    if (_isProfilExist) {
      // Data sudah ada, isi field
      _bannerUrl = response.bannerPath;
      _listingUrl = response.listingPath;
      menuController.text = response.deskripsiGerai;
      final hariBuka = response.hariBuka.split(',');
      for (var day in selectedDays.keys) {
        selectedDays[day] = hariBuka.contains(day);
      }
      final jamBuka = response.jamBuka.split(':');
      final jamTutup = response.jamTutup.split(':');
      if (jamBuka.length == 2) {
        selectedTimeStart = TimeOfDay(hour: int.tryParse(jamBuka[0]) ?? 8, minute: int.tryParse(jamBuka[1]) ?? 0);
      }
      if (jamTutup.length == 2) {
        selectedTimeEnd = TimeOfDay(hour: int.tryParse(jamTutup[0]) ?? 16, minute: int.tryParse(jamTutup[1]) ?? 0);
      }
    } else {
      // Data belum ada, field kosong
      _bannerUrl = null;
      _listingUrl = null;
      menuController.text = '';
      for (var day in selectedDays.keys) {
        selectedDays[day] = false;
      }
      selectedTimeStart = const TimeOfDay(hour: 8, minute: 0);
      selectedTimeEnd = const TimeOfDay(hour: 16, minute: 0);
    }
    setState(() { _isLoading = false; });
  }

  String formatTime24(TimeOfDay time) {
    final hour = time.hour == 0 ? 24 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickBannerImage() async {
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
  // Selalu bisa pilih gambar
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

  Future<void> _saveProfilGerai() async {
  final hariSelected = selectedDays.entries.where((e) => e.value).map((e) => e.key).join(',');
  print('Hari dipilih (akan dikirim ke API): $hariSelected');
    setState(() { _isLoading = true; });
    String? bannerUrl = _bannerUrl;
    String? listingUrl = _listingUrl;
    // Upload gambar jika ada perubahan (file lokal)
    if (_bannerImage != null) {
      final url = await GeraiProfilService.uploadQrisToCloudinary(File(_bannerImage!.path));
      if (url != null) bannerUrl = url;
    }
    if (_listingImage != null) {
      final url = await GeraiProfilService.uploadQrisToCloudinary(File(_listingImage!.path));
      if (url != null) listingUrl = url;
    }
    final jamBuka = formatTime24(selectedTimeStart);
    final jamTutup = formatTime24(selectedTimeEnd);
  final storage = FlutterSecureStorage();
  final idUsers = await storage.read(key: 'id_users');
  final idGerai = _idGerai;
    if (idGerai == null || idUsers == null) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID gerai atau user tidak ditemukan')),);
      return;
    }
    final data = {
      "id_gerai": idGerai.toString(),
      "id_users": idUsers,
      "deskripsi_gerai": menuController.text.trim(),
      "jam_buka": jamBuka,
      "jam_tutup": jamTutup,
      "hari_buka": hariSelected,
      "banner_path": bannerUrl ?? "",
      "listing_path": listingUrl ?? "",
      "status_pengajuan": "pending",
    };
    bool success = false;
    if (_isProfilExist) {
      // Update
      final service = GeraiProfilService();
      success = await service.updateGeraiProfil(
        idGerai: idGerai,
        bannerPath: bannerUrl ?? '',
        listingPath: listingUrl ?? '',
        deskripsiGerai: menuController.text.trim(),
        hariBuka: hariSelected,
        jamBuka: jamBuka,
        jamTutup: jamTutup,
      );
      // Cek status_pengajuan saat ini. Jika sebelumnya 'rejected' atau tidak ada, ubah jadi 'pending'.
      try {
        final currentStatus = await _fetchCurrentGeraiStatus();
        debugPrint('[PROFILE GERAI] currentStatus: $currentStatus');
        if (currentStatus == null || currentStatus.isEmpty || currentStatus == 'rejected') {
          final token = await storage.read(key: 'jwt_token');
          final headers = <String, String>{'Content-Type': 'application/json'};
          if (token != null && token.isNotEmpty) {
            headers['Authorization'] = 'Bearer $token';
          }
          await http.post(
            Uri.parse('${getBaseUrl()}/update_status_pengajuan.php'),
            headers: headers,
            body: jsonEncode({
              "id_gerai": idGerai.toString(),
              "status_pengajuan": "pending",
            }),
          );
        } else {
          debugPrint('[PROFILE GERAI] status_pengajuan tidak diubah (saat ini: $currentStatus)');
        }
      } catch (e) {
        debugPrint('ERROR updating status_pengajuan: $e');
      }

      // Update step2 di tabel users
      await SellerUserService.updateStepSellerStatus(idUsers, step2: 1);
    } else {
      // Insert
      success = await GeraiProfilService.insertGeraiProfil(data);
      // Setelah insert, update status_pengajuan dan step2
      // Untuk insert, set status_pengajuan ke 'pending' (karena belum ada sebelumnya)
      try {
        final token = await storage.read(key: 'jwt_token');
        final headers = <String, String>{'Content-Type': 'application/json'};
        if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
        await http.post(
          Uri.parse('${getBaseUrl()}/update_status_pengajuan.php'),
          headers: headers,
          body: jsonEncode({
            "id_gerai": idGerai.toString(),
            "status_pengajuan": "pending",
          }),
        );
      } catch (e) {
        debugPrint('ERROR setting status_pengajuan after insert: $e');
      }
      await SellerUserService.updateStepSellerStatus(idUsers, step2: 1);
    }
    setState(() { _isLoading = false; });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(success ? 'Berhasil' : 'Gagal'),
        content: Text(success ? 'Profil gerai berhasil disimpan' : 'Gagal simpan profil gerai'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/onboarding_checklist',
        (route) => false,
      );
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
                                      onPressed: _pickBannerImage,
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
                                      onPressed: _pickListingImage,
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
                            enabled: true,
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
                                onSelected: (val) {
                                  setState(() {
                                    selectedDays[day] = val;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Buka: ${formatTime24(selectedTimeStart)}'),
                              ElevatedButton(
                                onPressed: () => _selectTimeStart(context),
                                child: const Text('Pilih Jam'),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Tutup: ${formatTime24(selectedTimeEnd)}'),
                              ElevatedButton(
                                onPressed: () => _selectTimeEnd(context),
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
              text: _isLoading ? "Menyimpan..." : "Simpan dan lanjutkan",
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (!_validateFields()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Semua field wajib diisi')),
                        );
                        return;
                      }
                      await _saveProfilGerai();
                    },
            ),
        ),
      ),
    );
  }
}
