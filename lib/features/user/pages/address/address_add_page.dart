import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/gradient_background.dart';
import '../../../../app/app_theme.dart';
import '../../../../common/widgets/custom_widgets.dart';
import 'package:dpr_bites/features/user/models/address_add_page_model.dart';
import 'package:dpr_bites/features/user/services/address_add_page_service.dart';
import 'address_maps_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  String? _userId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
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

  Future<void> _bootstrap() async {
    setState(() => _loadingDetail = widget.idAlamat != null);
  final uidRaw = await AddressAddPageService.getUserIdFromPrefs();
  final String? uid = uidRaw?.toString();
  _userId = uid;
  if (uid == null || uid.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User belum login')));
      }
      setState(() => _loadingDetail = false);
      return;
    }
    if (widget.idAlamat != null) {
      final res = await AddressAddPageService.fetchDetail(
        idAlamat: widget.idAlamat!,
        userId: uid,
      );
      if (res.detail != null) {
        final a = res.detail!;
        _namaPenerimaC.text = a.namaPenerima;
        _namaGedungC.text = a.namaGedung;
        _detailPengantaranC.text = a.detailPengantaran;
        _noHpC.text = a.noHp;
        _lat = a.latitude;
        _lon = a.longitude;
        _lokasiDipilih = _lat != null && _lon != null;
        if (_lat != null && _lon != null) {
          _alamatLengkapMaps = await _getAddressFromLatLng(_lat!, _lon!);
        } else {
          _alamatLengkapMaps = null;
        }
        _isDefault = a.alamatUtama;
      } else if (res.error != null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(res.error!)));
        }
      }
      if (mounted) setState(() => _loadingDetail = false);
    } else {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  Future<String?> _getAddressFromLatLng(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon',
      );
      final res = await http.get(
        url,
        headers: {'User-Agent': 'dpr-bites/1.0 (contact: example@example.com)'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final disp = (data['display_name'] as String?)?.trim();
        if (disp != null && disp.isNotEmpty) return disp;
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
  final idUsersRaw = _userId ?? await AddressAddPageService.getUserIdFromPrefs();
  final String? idUsers = idUsersRaw?.toString();
  if (idUsers == null || idUsers.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User belum login')));
      setState(() => _loading = false);
      return;
    }
    final req = AddressUpsertRequest(
      idAlamat: widget.idAlamat,
      namaPenerima: _namaPenerimaC.text.trim(),
      namaGedung: _namaGedungC.text.trim(),
      detailPengantaran: _detailPengantaranC.text.trim(),
      latitude: _lat!,
      longitude: _lon!,
      noHp: _noHpC.text.trim(),
      alamatUtama: _isDefault,
    );
    final res = await AddressAddPageService.saveAddress(
      request: req,
      userId: idUsers,
    );
    if (res.success) {
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) {
        final isEdit = widget.idAlamat != null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res.message ??
                  (isEdit ? 'Gagal mengubah alamat' : 'Gagal menyimpan alamat'),
            ),
          ),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
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
                                final addrFromMap =
                                    (result['address'] as String?)?.trim();
                                String? alamat =
                                    (addrFromMap != null &&
                                        addrFromMap.isNotEmpty)
                                    ? addrFromMap
                                    : null;
                                if (alamat == null &&
                                    lat != null &&
                                    lon != null) {
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
