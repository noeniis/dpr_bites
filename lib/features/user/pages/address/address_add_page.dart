import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/gradient_background.dart';
import '../../../../app/app_theme.dart';
import '../../../../common/widgets/custom_widgets.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import 'address_maps_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AddressAddPage extends StatefulWidget {
  final int? idAlamat; // if set -> edit mode
  const AddressAddPage({Key? key, this.idAlamat}) : super(key: key);

  @override
  State<AddressAddPage> createState() => _AddressAddPageState();
}

class _AddressAddPageState extends State<AddressAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaGedungC = TextEditingController();
  final _detailPengantaranC = TextEditingController();
  final _namaPenerimaC = TextEditingController();
  final _noHpC = TextEditingController();
  bool _isDefault = false;
  bool _lokasiDipilih = false;
  double? _lat;
  double? _lon;
  String? _alamatLengkapMaps;

  @override
  void initState() {
    super.initState();
    // Jika edit mode, load detail alamat
    if (widget.idAlamat != null) {
      _loadDetail();
    }
  }

  @override
  void dispose() {
    _namaGedungC.dispose();
    _detailPengantaranC.dispose();
    _namaPenerimaC.dispose();
    _noHpC.dispose();
    super.dispose();
  }

  bool _loading = false; // saving state
  bool _loadingDetail = false; // loading detail in edit mode

  Future<void> _loadDetail() async {
    setState(() => _loadingDetail = true);
    final url = Uri.parse(
      'http://10.0.2.2/dpr_bites_api/alamat_pengantaran_get_detail.php',
    );
    try {
      final int idUsers = await _getCurrentUserId();
      if (idUsers <= 0) throw Exception('User tidak terautentikasi');
      final res = await http.post(
        url,
        body: jsonEncode({'id_alamat': widget.idAlamat}),
        headers: {
          'Content-Type': 'application/json',
          'X-User-Id': idUsers.toString(),
        },
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true && data['address'] != null) {
        final a = data['address'] as Map<String, dynamic>;
        _namaPenerimaC.text = (a['nama_penerima'] ?? '').toString();
        _namaGedungC.text = (a['nama_gedung'] ?? '').toString();
        _detailPengantaranC.text = (a['detail_pengantaran'] ?? '').toString();
        _noHpC.text = (a['no_hp'] ?? '').toString();
        final lat = (a['latitude']);
        final lon = (a['longitude']);
        _lat = (lat is num) ? lat.toDouble() : double.tryParse('$lat');
        _lon = (lon is num) ? lon.toDouble() : double.tryParse('$lon');
        _lokasiDipilih = _lat != null && _lon != null;
        if (_lat != null && _lon != null) {
          _alamatLengkapMaps = await _getAddressFromLatLng(_lat!, _lon!);
        } else {
          _alamatLengkapMaps = null;
        }
        _isDefault =
            (a['alamat_utama'] == 1 ||
            a['alamat_utama'] == true ||
            a['alamat_utama']?.toString() == '1');
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Gagal memuat detail alamat'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat detail alamat: $e')));
    } finally {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  Future<String?> _getAddressFromLatLng(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final address = [
          p.street,
          p.subLocality,
          p.locality,
          p.subAdministrativeArea,
          p.administrativeArea,
          p.postalCode,
          p.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
        return address.isNotEmpty ? address : null;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih titik lokasi terlebih dahulu')),
      );
      return;
    }
    setState(() => _loading = true);
    final int idUsers = await _getCurrentUserId();
    if (idUsers <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User belum login')));
      setState(() => _loading = false);
      return;
    }
    final isEdit = widget.idAlamat != null;
    final url = Uri.parse(
      isEdit
          ? 'http://10.0.2.2/dpr_bites_api/alamat_pengantaran_update.php'
          : 'http://10.0.2.2/dpr_bites_api/alamat_pengantaran_add.php',
    );
    final body = {
      'id_users': idUsers,
      if (isEdit) 'id_alamat': widget.idAlamat,
      'nama_penerima': _namaPenerimaC.text.trim(),
      'nama_gedung': _namaGedungC.text.trim(),
      'detail_pengantaran': _detailPengantaranC.text.trim(),
      'latitude': _lat,
      'longitude': _lon,
      'no_hp': _noHpC.text.trim(),
      'alamat_utama': _isDefault ? 1 : 0,
    };
    try {
      final res = await http.post(
        url,
        body: jsonEncode(body),
        headers: {
          'Content-Type': 'application/json',
          'X-User-Id': idUsers.toString(),
        },
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ??
                  (isEdit ? 'Gagal mengubah alamat' : 'Gagal menyimpan alamat'),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'Gagal mengubah alamat: $e' : 'Gagal menyimpan alamat: $e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<int> _getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? id = prefs.getInt('id_users');
      if (id != null) return id;
      final s = prefs.getString('id_users');
      if (s == null) return 0;
      return int.tryParse(s) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            widget.idAlamat == null ? 'Tambah Alamat Baru' : 'Ubah Alamat',
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_loadingDetail)
                    const LinearProgressIndicator(minHeight: 2),
                  // Titik Lokasi Alamat card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF767070),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Titik Lokasi Alamat',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (!_lokasiDipilih)
                          Text(
                            'Sebelum isi form, kamu harus pilih titik lokasi dulu',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.65),
                            ),
                          ),
                        if (_lokasiDipilih) ...[
                          // Map preview
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              height: 160,
                              width: double.infinity,
                              child: AbsorbPointer(
                                child: FlutterMap(
                                  options: MapOptions(
                                    initialCenter: LatLng(_lat ?? 0, _lon ?? 0),
                                    initialZoom: 16,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName:
                                          'com.example.dpr_bites',
                                    ),
                                    if (_lat != null && _lon != null)
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: LatLng(_lat!, _lon!),
                                            width: 40,
                                            height: 40,
                                            alignment: Alignment.topCenter,
                                            child: const Icon(
                                              Icons.location_on,
                                              size: 40,
                                              color: Color(0xFFD53D3D),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Alamat lengkap (Berdasarkan titik lokasi)',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.65),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _alamatLengkapMaps ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddressMapsPage(
                                    initialLat: _lat,
                                    initialLon: _lon,
                                    initialAddress: _alamatLengkapMaps,
                                  ),
                                ),
                              );
                              if (result is Map) {
                                final lat = (result['lat'] as num?)?.toDouble();
                                final lon = (result['lon'] as num?)?.toDouble();
                                String? alamat;
                                if (lat != null && lon != null) {
                                  alamat = await _getAddressFromLatLng(
                                    lat,
                                    lon,
                                  );
                                }
                                setState(() {
                                  _lat = lat;
                                  _lon = lon;
                                  _alamatLengkapMaps = alamat;
                                  _lokasiDipilih = _lat != null && _lon != null;
                                });
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppTheme.primaryColor,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 12,
                              ),
                            ),
                            child: Text(
                              _lokasiDipilih
                                  ? 'Ubah Titik Lokasi'
                                  : 'Pilih Titik Lokasi',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Nama gedung
                  const Text('Nama Gedung*'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _namaGedungC,
                    decoration: _inputDecoration('Contoh: Gedung Nusantara I'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),

                  // Detail pengantaran
                  const Text('Detail Pengantaran*'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _detailPengantaranC,
                    maxLines: 3,
                    decoration: _inputDecoration(
                      'Lantai/ruangan, patokan, dll',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),

                  // Nama penerima
                  const Text('Nama Penerima*'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _namaPenerimaC,
                    decoration: _inputDecoration('Nama lengkap'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),

                  // No HP
                  const Text('No. Handphone*'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _noHpC,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _inputDecoration('08xxxxxxxxxx'),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return 'Wajib diisi';
                      final ok = RegExp(r'^\d{10,13}$').hasMatch(s);
                      if (!ok) return 'Nomor HP harus 10–13 digit angka';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Default switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Jadikan sebagai alamat utama'),
                      Switch(
                        value: _isDefault,
                        activeColor: Colors.white,
                        activeTrackColor: AppTheme.primaryColor,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: const Color(0xFFB0B0B0),
                        onChanged: (val) => setState(() => _isDefault = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Save button using custom widget
                  CustomButtonKotak(
                    text: widget.idAlamat == null
                        ? 'Simpan Alamat'
                        : 'Ubah Alamat',
                    onPressed: (_loading || _loadingDetail) ? null : _save,
                  ),
                  if (_loading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.black.withOpacity(0.45)),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF767070), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    );
  }
}
