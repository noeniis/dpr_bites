
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:dpr_bites/features/seller/pages/proses_pengajuan/seller_pick_location_page.dart';
import 'package:dpr_bites/common/data/dummy_address.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/app/app_theme.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import '../../services/gerai_profil_service.dart';
import '../../models/gerai_profil_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KelolaProfilGeraiPage extends StatefulWidget {
  const KelolaProfilGeraiPage({super.key});

  @override
  State<KelolaProfilGeraiPage> createState() => _KelolaProfilGeraiPageState();
}

class _KelolaProfilGeraiPageState extends State<KelolaProfilGeraiPage> {
  Future<String?> uploadToCloudinary(File file) async {
    return await GeraiProfilService.uploadQrisToCloudinary(file);
  }
  bool _isLoading = true;
  String? _errorMsg;
  int? _idGerai;
  GeraiProfilModel? _profilGerai;
  @override
  void initState() {
    super.initState();
    _loadProfilGerai();
  }

  Future<void> _loadProfilGerai() async {
    try {
      setState(() { _isLoading = true; _errorMsg = null; });
      final storage = FlutterSecureStorage();
      String? idUsers = await storage.read(key: 'id_users');
      if (idUsers == null || idUsers.isEmpty) {
        debugPrint('[DEBUG] id_users tidak ditemukan di secure storage');
        if (!mounted) return;
        setState(() { _isLoading = false; _errorMsg = 'User belum login'; });
        return;
      }
      debugPrint('[DEBUG] id_users ditemukan: $idUsers');
      final profil = await GeraiProfilService.fetchGeraiProfilByUser(idUsers);
      if (profil == null) {
        setState(() { _isLoading = false; _errorMsg = 'Profil gerai tidak ditemukan'; });
        return;
      }
      _profilGerai = profil;
      _idGerai = profil.idGerai;
      // Ambil data gerai (tabel gerai) -- lokasi disimpan di tabel gerai
      final gerai = await GeraiProfilService.fetchGeraiByUser(idUsers);
      if (gerai != null && gerai['success'] == true && gerai['data'] != null) {
        final g = gerai['data'];
        _selectedLat = g['latitude'] != null && g['latitude'].toString().isNotEmpty ? double.tryParse(g['latitude'].toString()) : null;
        _selectedLng = g['longitude'] != null && g['longitude'].toString().isNotEmpty ? double.tryParse(g['longitude'].toString()) : null;
        _geraiNama = g['nama_gerai'] ?? profil.namaGerai;
        _geraiDetailAlamat = g['detail_alamat'] ?? profil.detailAlamat;
        _geraiTelepon = g['telepon'] ?? profil.telepon;
        debugPrint('PARSED GERAI: LAT=$_selectedLat, LNG=$_selectedLng, ALAMAT=$_geraiDetailAlamat');
        if (_selectedLat != null && _selectedLng != null) {
          // show detail_alamat immediately while reverse-geocoding in background
          _selectedAddress = _geraiDetailAlamat;
          locationController.text = _selectedAddress ?? '';
          // then try to get a nicer address and update when available
          final addr = await GeraiProfilService.reverseGeocode(_selectedLat!, _selectedLng!);
          if (addr != null && addr.isNotEmpty) {
            _selectedAddress = addr;
            locationController.text = _selectedAddress ?? '';
          }
        } else {
          // fallback: tampilkan detail_alamat jika lat/lng tidak ada
          _selectedAddress = _geraiDetailAlamat;
          locationController.text = _selectedAddress ?? '';
        }
      } else {
        // fallback ke profil
        _selectedLat = profil.latitude;
        _selectedLng = profil.longitude;
        _geraiNama = profil.namaGerai;
        _geraiDetailAlamat = profil.detailAlamat;
        _geraiTelepon = profil.telepon;
        debugPrint('FALLBACK PROFIL: LAT=$_selectedLat, LNG=$_selectedLng, ALAMAT=$_geraiDetailAlamat');
        if (_selectedLat != null && _selectedLng != null) {
          final addr = await GeraiProfilService.reverseGeocode(_selectedLat!, _selectedLng!);
          _selectedAddress = addr ?? profil.detailAlamat;
          locationController.text = _selectedAddress ?? '';
        } else {
          // fallback: tampilkan detail_alamat jika lat/lng tidak ada
          _selectedAddress = profil.detailAlamat;
          locationController.text = _selectedAddress ?? '';
        }
      }

      setState(() {
        _bannerUrl = profil.bannerPath;
        _listingUrl = profil.listingPath;
        menuController.text = profil.deskripsiGerai;
        final hariBuka = profil.hariBuka.split(',');
        for (var day in selectedDays.keys) {
          selectedDays[day] = hariBuka.contains(day);
        }
        final jamBuka = profil.jamBuka.split(':');
        final jamTutup = profil.jamTutup.split(':');
        selectedTimeStart = TimeOfDay(hour: int.parse(jamBuka[0]), minute: int.parse(jamBuka[1]));
        selectedTimeEnd = TimeOfDay(hour: int.parse(jamTutup[0]), minute: int.parse(jamTutup[1]));
        _isLoading = false;
      });
    } catch (e, s) {
      debugPrint('ERROR in _loadProfilGerai: $e\n$s');
      if (!mounted) return;
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
  final locationController = TextEditingController();
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

  // Location fields (gerai table)
  double? _selectedLat;
  double? _selectedLng;
  String? _selectedAddress;
  String? _geraiNama;
  String? _geraiDetailAlamat;
  String? _geraiTelepon;

  // Reuse point-in-polygon logic from SellerPickLocationPage
  bool _isInDprArea(LatLng point) {
    final x = point.longitude;
    final y = point.latitude;
    bool inside = false;
    for (int i = 0, j = dprPolygon.length - 1; i < dprPolygon.length; j = i++) {
      final xi = dprPolygon[i].longitude;
      final yi = dprPolygon[i].latitude;
      final xj = dprPolygon[j].longitude;
      final yj = dprPolygon[j].latitude;
      final intersect = ((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / ((yj - yi) == 0 ? 1e-12 : (yj - yi)) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  @override
  void dispose() {
    locationController.dispose();
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

  Future<void> handlePickLocation(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      debugPrint('handlePickLocation: called, _selectedLat=$_selectedLat, _selectedLng=$_selectedLng, _isEdit=$_isEdit');
      var status = await Permission.location.request();
      if (!mounted) return;
      if (!status.isGranted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Akses lokasi diperlukan untuk memilih lokasi.')),
        );
        return;
      }
      final dprLatitudes = dummyAddresses
          .where((a) => a.latitude != null)
          .map((a) => a.latitude!)
          .toList();
      final dprLongitudes = dummyAddresses
          .where((a) => a.longitude != null)
          .map((a) => a.longitude!)
          .toList();
      final dprSouthWest = LatLng(
        dprLatitudes.reduce((a, b) => a < b ? a : b),
        dprLongitudes.reduce((a, b) => a < b ? a : b),
      );
      final dprNorthEast = LatLng(
        dprLatitudes.reduce((a, b) => a > b ? a : b),
        dprLongitudes.reduce((a, b) => a > b ? a : b),
      );
      debugPrint('handlePickLocation: pushing SellerPickLocationPage');
      // If existing coordinates exist but are outside DPR polygon, don't use them as initialPosition
      LatLng? initialPos;
      if (_selectedLat != null && _selectedLng != null) {
        final candidate = LatLng(_selectedLat!, _selectedLng!);
        if (_isInDprArea(candidate)) {
          initialPos = candidate;
        } else {
          debugPrint('Existing coords outside DPR polygon, ignoring as initial position');
        }
      }
      final result = await navigator.push(
        MaterialPageRoute(
          builder: (_) => SellerPickLocationPage(
            dprSouthWest: dprSouthWest,
            dprNorthEast: dprNorthEast,
            initialPosition: initialPos,
          ),
        ),
      );
      if (result is Map<String, dynamic> && result['lat'] != null && result['lng'] != null) {
        setState(() {
          _selectedLat = (result['lat'] as num).toDouble();
          _selectedLng = (result['lng'] as num).toDouble();
          _selectedAddress = (result['address'] as String?)?.isNotEmpty == true
              ? result['address'] as String
              : 'Lat: ${_selectedLat!.toStringAsFixed(6)}, Lng: ${_selectedLng!.toStringAsFixed(6)}';
          // update displayed address
          locationController.text = _selectedAddress ?? '';
        });
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Terjadi error: $e')));
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
  debugPrint('DEBUG: build KelolaProfilGeraiPage dipanggil');
  debugPrint('DEBUG: locationController.text="${locationController.text}"');
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
                      const Text("Lokasi Gerai", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          if (_selectedLat != null && _selectedLng != null) {
                            // show detail
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Detail Lokasi'),
                                content: Text(_selectedAddress ?? '-'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
                                ],
                              ),
                            );
                          } else {
                            handlePickLocation(context);
                          }
                        },
                        onDoubleTap: _isEdit ? () async => await handlePickLocation(context) : null,
                        child: AbsorbPointer(
                          child: CustomInputField(
                            controller: locationController,
                            hintText: 'Pilih lokasi gerai',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _isEdit ? () => handlePickLocation(context) : null,
                        child: const Text('Pilih Lokasi di Peta'),
                      ),
                      const SizedBox(height: 12),
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
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              if (!_isEdit) {
                setState(() {
                  _isEdit = true;
                });
                return;
              }
              if (!_validateFields()) {
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('Semua field wajib diisi')),
                );
                return;
              }
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
              // Siapkan data update
              final hariSelected = selectedDays.entries.where((e) => e.value).map((e) => e.key).join(',');
              final jamBuka = formatTime24(selectedTimeStart);
              final jamTutup = formatTime24(selectedTimeEnd);
              // id_gerai didapat dari _idGerai (sudah diisi saat load profil)
              final idGerai = _idGerai;
              if (idGerai == null) {
                if (mounted) setState(() { _isLoading = false; });
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('ID gerai tidak ditemukan')),);
                return;
              }
              // Persist gerai (latitude/longitude/detail alamat/telepon) first
              final namaGeraiToSend = _geraiNama ?? _profilGerai?.namaGerai ?? '';
              final geraiData = {
                'id_gerai': idGerai.toString(),
                'nama_gerai': namaGeraiToSend,
                'latitude': _selectedLat?.toString() ?? (_profilGerai?.latitude?.toString() ?? ''),
                'longitude': _selectedLng?.toString() ?? (_profilGerai?.longitude?.toString() ?? ''),
                'detail_alamat': locationController.text.isNotEmpty ? locationController.text : (_geraiDetailAlamat ?? _profilGerai?.detailAlamat ?? ''),
                'telepon': _geraiTelepon ?? _profilGerai?.telepon ?? '',
              };
              final geraiSaved = await GeraiProfilService.addOrUpdateGerai(geraiData);
              if (!geraiSaved) {
                if (mounted) setState(() { _isLoading = false; _isEdit = false; });
                if (!mounted) return;
                navigator
                    .push<void>(
                      MaterialPageRoute(
                        builder: (_) => AlertDialog(
                          title: const Text('Gagal'),
                          content: const Text('Gagal menyimpan data lokasi gerai.'),
                          actions: [TextButton(onPressed: () => navigator.pop(), child: const Text('OK'))],
                        ),
                      ),
                    )
                    .then((_) {});
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
              if (mounted) {
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
                navigator
                    .push<void>(
                      MaterialPageRoute(
                        builder: (ctx) => AlertDialog(
                          title: Text(success ? 'Berhasil' : 'Gagal'),
                          content: Text(success ? 'Profil gerai berhasil diupdate' : 'Gagal update profil gerai'),
                          actions: [
                            TextButton(
                              onPressed: () => navigator.pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      ),
                    )
                    .then((_) {});
              }
            },
          ),
        ),
      ),
    );
  }
  }