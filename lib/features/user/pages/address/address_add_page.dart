import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/gradient_background.dart';
import '../../../../app/app_theme.dart';
import '../../../../common/widgets/custom_widgets.dart';
import '../../../../common/data/dummy_address.dart';
import 'address_maps_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AddressAddPage extends StatefulWidget {
  final DummyAddress? initial;
  const AddressAddPage({super.key, this.initial});

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
    final init = widget.initial;
    if (init != null) {
      _namaGedungC.text = init.namaGedung;
      _detailPengantaranC.text = init.detailPengantaran;
      _namaPenerimaC.text = init.namaPenerima;
      _noHpC.text = init.noHp;
      _isDefault = init.isDefault; // preserve on edit
      _lat = init.latitude;
      _lon = init.longitude;
      _alamatLengkapMaps = init.alamatLengkapMaps;
      _lokasiDipilih = (_lat != null && _lon != null);
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

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final newAddr = DummyAddress(
      namaPenerima: _namaPenerimaC.text.trim(),
      namaGedung: _namaGedungC.text.trim(),
      detailPengantaran: _detailPengantaranC.text.trim(),
      noHp: _noHpC.text.trim(),
      isDefault: _isDefault,
      latitude: _lat,
      longitude: _lon,
      alamatLengkapMaps: _alamatLengkapMaps,
    );
    Navigator.pop(context, newAddr);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(isEdit ? 'Ubah Alamat' : 'Tambah Alamat Baru'),
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
                                setState(() {
                                  _lat = (result['lat'] as num?)?.toDouble();
                                  _lon = (result['lon'] as num?)?.toDouble();
                                  _alamatLengkapMaps =
                                      result['address'] as String?;
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
                    text: isEdit ? 'Simpan Perubahan' : 'Simpan Alamat',
                    onPressed: _save,
                  ),
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
