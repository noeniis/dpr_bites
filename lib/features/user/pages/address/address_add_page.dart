import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/gradient_background.dart';
import '../../../../app/app_theme.dart';
import '../../../../common/widgets/custom_widgets.dart';
import '../../../../common/data/dummy_address.dart';

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
      _lokasiDipilih = true; // assume an existing address has location chosen
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
                        Text(
                          _lokasiDipilih
                              ? 'Lokasi sudah dipilih'
                              : 'Sebelum isi form, kamu harus pilih titik lokasi dulu',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.65),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() => _lokasiDipilih = true);
                          },
                          icon: const Icon(
                            Icons.place_outlined,
                            color: AppTheme.primaryColor,
                          ),
                          label: Text(
                            _lokasiDipilih
                                ? 'Lokasi Dipilih'
                                : 'Pilih Titik Lokasi',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                            ),
                          ),
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
